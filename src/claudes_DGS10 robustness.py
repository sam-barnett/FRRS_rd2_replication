"""
DGS10 Robustness Analysis
=========================
This script generates robustness figures for alternative specifications using DGS10
(10-Year Treasury Yield) as the primary rate measure.

Outputs are saved to FRRS_data/sandbox_jan2026/claudeDGS10rb/

Author: Claude
"""

#%% Imports and Setup
import pandas as pd
import numpy as np
import os
from pathlib import Path
import matplotlib.pyplot as plt
import statsmodels.api as sm
from linearmodels.panel import PanelOLS
import warnings
warnings.filterwarnings('ignore')

# Set paths relative to workspace root
BASE_DIR = Path(os.getcwd())
DATA_DIR = BASE_DIR / 'FRRS_data' / 'sandbox_jan2026'
OUTPUT_DIR = DATA_DIR / 'claudeDGS10rb'

# Create output directory
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
print(f"Output directory: {OUTPUT_DIR}")

#%% Load Data
print("\n" + "="*80)
print("LOADING DATA")
print("="*80)

# Load sandbox_data.csv (firm-level panel with FOMC shocks and rates)
sandbox_path = DATA_DIR / 'sandbox_data.csv'
if not sandbox_path.exists():
    raise FileNotFoundError(f"sandbox_data.csv not found at {sandbox_path}")

df = pd.read_csv(sandbox_path)
print(f"Loaded sandbox_data.csv: {len(df):,} observations")

# Load fomc_daily_rates.csv (daily rates data for each FOMC date)
rates_path = DATA_DIR / 'fomc_daily_rates.csv'
if rates_path.exists():
    df_rates = pd.read_csv(rates_path)
    print(f"Loaded fomc_daily_rates.csv: {len(df_rates):,} FOMC dates")
else:
    df_rates = None
    print("fomc_daily_rates.csv not found, using rates from sandbox_data.csv")

# Display available columns
print(f"\nKey columns in sandbox_data.csv:")
key_cols = ['daten', 'permno', 'shock_hf_30min', 'mp_klms_U', 'target',
            'target_ma5_forward', 'target_ma10_forward', 'DGS10', 'DGS10_minus_TP10',
            'TP10', 'synthed_10y', 'synthetic_1y_rate', 'ptile_consis', 'Fptile']
for col in key_cols:
    if col in df.columns:
        n_valid = df[col].notna().sum()
        print(f"  {col}: {n_valid:,} non-null values")
    else:
        print(f"  {col}: NOT FOUND")

#%% Data Preparation
print("\n" + "="*80)
print("DATA PREPARATION")
print("="*80)

# Convert Stata date to datetime
base_date = pd.Timestamp('1960-01-01')
df['date'] = df['daten'].apply(lambda x: base_date + pd.Timedelta(days=int(x)) if pd.notna(x) else pd.NaT)
df['year'] = df['date'].dt.year

# Create working dataset
df_work = df.copy()

# Ensure we have required columns
required_cols = ['shock_hf_30min', 'mp_klms_U', 'permno', 'daten', 'ptile_consis']
missing = [c for c in required_cols if c not in df_work.columns]
if missing:
    raise ValueError(f"Missing required columns: {missing}")

# Create percentile rank variable if not present
if 'ptile_consis' in df_work.columns:
    df_work['rank'] = df_work['ptile_consis']
else:
    df_work['rank'] = df_work['Fptile'] / 100 if 'Fptile' in df_work.columns else 0.5

print(f"\nWorking dataset: {len(df_work):,} observations")
print(f"Number of firms: {df_work['permno'].nunique():,}")
print(f"Number of FOMC dates: {df_work['daten'].nunique():,}")

#%% Define Alternative DGS10-based Specifications
print("\n" + "="*80)
print("DEFINING ALTERNATIVE SPECIFICATIONS")
print("="*80)

# Define alternative rate specifications for robustness
# All centered around DGS10 as the core measure
specifications = {
    'DGS10': {
        'col': 'DGS10',
        'label': 'DGS10',
        'description': '10-Year Treasury Yield (nominal)'
    },
    'DGS10_minus_TP10': {
        'col': 'DGS10_minus_TP10',
        'label': 'DGS10 - TP10',
        'description': '10Y Expected Rate Path (DGS10 minus Term Premium)'
    },
    'target_ma10_forward': {
        'col': 'target_ma10_forward',
        'label': '10Y Fwd MA',
        'description': '10-Year Forward Moving Average of Fed Funds Target'
    },
    'synthed_10y': {
        'col': 'synthed_10y',
        'label': 'Synth 10Y',
        'description': '10-Year Synthetic Rate from Futures (FF1, FF2, ED2-ED40)'
    },
}

# Check availability
print("\nSpecification availability:")
for spec_name, spec_info in specifications.items():
    col = spec_info['col']
    if col in df_work.columns:
        n_valid = df_work[col].notna().sum()
        pct = 100 * n_valid / len(df_work)
        print(f"  {spec_name}: {n_valid:,} obs ({pct:.1f}%)")
    else:
        print(f"  {spec_name}: NOT AVAILABLE")

#%% Helper Functions
def run_hf_regression(df, rate_var, time_effects=False, quiet=False):
    """
    Run high-frequency panel regression with rate interaction.

    Model:
        shock_hf_30min = α_i + β₁·ω + β₂·ω×Rank + β₃·ω×Rate + β₄·ω×Rank×Rate + ε

    Where:
        α_i = firm fixed effects
        ω = mp_klms_U (monetary policy shock)
        Rank = firm percentile by market value
        Rate = interest rate measure
    """
    df_reg = df.copy()

    # Drop missing values for required variables
    reg_vars = ['shock_hf_30min', 'mp_klms_U', 'rank', rate_var, 'permno', 'daten']
    df_reg = df_reg.dropna(subset=reg_vars)

    if len(df_reg) < 100:
        return None, 0, 0

    # Create interaction terms
    df_reg['omega'] = df_reg['mp_klms_U']
    df_reg['omega_rank'] = df_reg['mp_klms_U'] * df_reg['rank']
    df_reg[f'omega_{rate_var}'] = df_reg['mp_klms_U'] * df_reg[rate_var]
    df_reg[f'omega_rank_{rate_var}'] = df_reg['mp_klms_U'] * df_reg['rank'] * df_reg[rate_var]

    # Set up panel
    df_reg = df_reg.set_index(['permno', 'daten'])

    # Define regressors
    if time_effects:
        # TWFE: only cross-sectional interactions survive
        exog_cols = ['omega_rank', f'omega_rank_{rate_var}']
    else:
        exog_cols = ['omega', 'omega_rank', f'omega_{rate_var}', f'omega_rank_{rate_var}']

    # Run regression
    y = df_reg['shock_hf_30min']
    X = df_reg[exog_cols]

    try:
        mod = PanelOLS(y, X, entity_effects=True, time_effects=time_effects, drop_absorbed=True)
        res = mod.fit(cov_type='clustered', cluster_entity=False, cluster_time=True)
    except ValueError as e:
        if "fully absorbed" in str(e):
            if not quiet:
                print(f"  SKIPPED (variables absorbed by time FE)")
            return None, 0, 0
        raise

    n = res.nobs
    r2 = res.rsquared

    if not quiet:
        print(f"  N={n:,}, R²={r2:.4f}")

    return res, n, r2


def create_rolling_figure(df, rate_var, output_path, title_suffix='', twfe=False):
    """
    Create rolling interaction coefficient figure.

    Shows how the size-based differential response to MP shocks
    varies over time, overlaid with the interest rate level.
    """
    df_roll = df.copy()

    # Sort dates
    dates = sorted(df_roll['daten'].unique())
    window_size = 80  # ~10 years (8 meetings/year)
    step = 10

    rolling_dates = []
    rolling_coefs = []
    rolling_ses = []
    rolling_rates = []

    for i in range(0, len(dates) - window_size, step):
        window_dates = dates[i : i + window_size]
        date_val = dates[i + window_size // 2]

        df_window = df_roll[df_roll['daten'].isin(window_dates)].copy()

        # Rate at midpoint date
        rate_at_date = df_roll[df_roll['daten'] == date_val][rate_var].mean()

        # Create interaction
        df_window['interaction'] = df_window['mp_klms_U'] * df_window['rank']

        # Drop missing
        df_window = df_window.dropna(subset=['shock_hf_30min', 'interaction', 'permno', 'daten'])

        if len(df_window) < 50:
            rolling_dates.append(date_val)
            rolling_coefs.append(np.nan)
            rolling_ses.append(np.nan)
            rolling_rates.append(rate_at_date)
            continue

        df_window = df_window.set_index(['permno', 'daten'])

        try:
            mod = PanelOLS(df_window['shock_hf_30min'], df_window[['interaction']],
                          entity_effects=True, time_effects=twfe, drop_absorbed=True)
            res = mod.fit(cov_type='clustered', cluster_entity=True, cluster_time=False)

            rolling_coefs.append(res.params['interaction'])
            rolling_ses.append(res.std_errors['interaction'])
            rolling_rates.append(rate_at_date)
            rolling_dates.append(date_val)
        except:
            rolling_coefs.append(np.nan)
            rolling_ses.append(np.nan)
            rolling_rates.append(rate_at_date)
            rolling_dates.append(date_val)

    # Convert dates
    base_date = pd.Timestamp('1960-01-01')
    try:
        plot_dates = [base_date + pd.Timedelta(days=int(d)) for d in rolling_dates]
    except:
        plot_dates = rolling_dates

    # Create figure
    fig, ax1 = plt.subplots(figsize=(12, 6))

    # Plot coefficient
    color1 = 'tab:blue'
    ax1.set_xlabel('Date')
    ax1.set_ylabel('Interaction Coefficient (β for ω × Rank)', color=color1)
    ax1.plot(plot_dates, rolling_coefs, color=color1, linewidth=2)
    ax1.tick_params(axis='y', labelcolor=color1)
    ax1.axhline(0, color='gray', linestyle='--', alpha=0.5)

    # Plot rate on secondary axis
    ax2 = ax1.twinx()
    color2 = 'tab:red'
    ax2.set_ylabel(f'{rate_var} (%)', color=color2)
    ax2.plot(plot_dates, rolling_rates, color=color2, linestyle=':', linewidth=2, alpha=0.7)
    ax2.tick_params(axis='y', labelcolor=color2)

    twfe_str = ' (TWFE)' if twfe else ''
    plt.title(f'Rolling Mechanism Strength vs. {rate_var}{twfe_str}{title_suffix}')
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()

    return rolling_dates, rolling_coefs, rolling_rates


#%% PART 1: Main Robustness Table
print("\n" + "="*80)
print("PART 1: MAIN TABLE - HF ROBUSTNESS")
print("="*80)

results_table = {}

for spec_name, spec_info in specifications.items():
    col = spec_info['col']
    label = spec_info['label']

    if col not in df_work.columns:
        print(f"\n{spec_name}: SKIPPED (column not found)")
        continue

    if df_work[col].notna().sum() < 100:
        print(f"\n{spec_name}: SKIPPED (insufficient data)")
        continue

    print(f"\n{spec_name} ({label}):")

    # Run regression without time FE
    res, n, r2 = run_hf_regression(df_work, col, time_effects=False)
    if res is not None:
        results_table[spec_name] = {
            'res': res, 'n': n, 'r2': r2,
            'label': label, 'col': col
        }

    # Run TWFE version
    try:
        res_twfe, n_twfe, r2_twfe = run_hf_regression(df_work, col, time_effects=True, quiet=True)
        if res_twfe is not None:
            results_table[f'{spec_name}_twfe'] = {
                'res': res_twfe, 'n': n_twfe, 'r2': r2_twfe,
                'label': f'{label} (TWFE)', 'col': col
            }
    except Exception as e:
        print(f"  TWFE: Error - {e}")

# Save results summary
print("\n" + "-"*60)
print("SUMMARY OF RESULTS")
print("-"*60)

summary_rows = []
for spec_name, spec_data in results_table.items():
    res = spec_data['res']
    row = {
        'Specification': spec_name,
        'N': spec_data['n'],
        'R2': spec_data['r2']
    }

    # Extract key coefficients
    for param in res.params.index:
        pval = res.pvalues[param]
        stars = '***' if pval < 0.01 else '**' if pval < 0.05 else '*' if pval < 0.1 else ''
        row[param] = f"{res.params[param]:.4f}{stars} ({res.std_errors[param]:.4f})"

    summary_rows.append(row)

summary_df = pd.DataFrame(summary_rows)
summary_df.to_csv(OUTPUT_DIR / 'table_hf_robustness_claudeDGS10rb.csv', index=False)
print(f"\nSaved: table_hf_robustness_claudeDGS10rb.csv")


#%% PART 2: Rolling Interaction Figures
print("\n" + "="*80)
print("PART 2: ROLLING INTERACTION FIGURES")
print("="*80)

# Create figures for each specification
for spec_name, spec_info in specifications.items():
    col = spec_info['col']
    label = spec_info['label']

    if col not in df_work.columns or df_work[col].notna().sum() < 1000:
        print(f"\n{spec_name}: SKIPPED")
        continue

    print(f"\n{spec_name}:")

    # Standard FE version
    output_path = OUTPUT_DIR / f'rolling_mechanism_{spec_name}_claudeDGS10rb.png'
    create_rolling_figure(df_work, col, output_path, twfe=False)
    print(f"  Saved: rolling_mechanism_{spec_name}_claudeDGS10rb.png")

    # TWFE version
    output_path_twfe = OUTPUT_DIR / f'rolling_mechanism_{spec_name}_twfe_claudeDGS10rb.png'
    create_rolling_figure(df_work, col, output_path_twfe, twfe=True)
    print(f"  Saved: rolling_mechanism_{spec_name}_twfe_claudeDGS10rb.png")


#%% PART 3: Comparison Figure - All Specs Overlaid
print("\n" + "="*80)
print("PART 3: COMPARISON FIGURES")
print("="*80)

# Collect rolling coefficients for comparison
comparison_data = {}

for spec_name, spec_info in specifications.items():
    col = spec_info['col']

    if col not in df_work.columns or df_work[col].notna().sum() < 1000:
        continue

    # Get rolling data
    dates = sorted(df_work['daten'].unique())
    window_size = 80
    step = 10

    rolling_dates = []
    rolling_coefs = []

    for i in range(0, len(dates) - window_size, step):
        window_dates = dates[i : i + window_size]
        date_val = dates[i + window_size // 2]

        df_window = df_work[df_work['daten'].isin(window_dates)].copy()
        df_window['interaction'] = df_window['mp_klms_U'] * df_window['rank']
        df_window = df_window.dropna(subset=['shock_hf_30min', 'interaction', 'permno', 'daten'])

        if len(df_window) < 50:
            rolling_dates.append(date_val)
            rolling_coefs.append(np.nan)
            continue

        df_window = df_window.set_index(['permno', 'daten'])

        try:
            mod = PanelOLS(df_window['shock_hf_30min'], df_window[['interaction']],
                          entity_effects=True, drop_absorbed=True)
            res = mod.fit(cov_type='clustered', cluster_entity=True, cluster_time=False)
            rolling_coefs.append(res.params['interaction'])
            rolling_dates.append(date_val)
        except:
            rolling_coefs.append(np.nan)
            rolling_dates.append(date_val)

    comparison_data[spec_name] = {
        'dates': rolling_dates,
        'coefs': rolling_coefs,
        'label': spec_info['label']
    }

# Create comparison plot
if comparison_data:
    base_date = pd.Timestamp('1960-01-01')

    fig, ax = plt.subplots(figsize=(14, 7))
    colors = plt.cm.tab10(np.linspace(0, 1, len(comparison_data)))

    for (spec_name, data), color in zip(comparison_data.items(), colors):
        try:
            plot_dates = [base_date + pd.Timedelta(days=int(d)) for d in data['dates']]
        except:
            plot_dates = data['dates']

        ax.plot(plot_dates, data['coefs'], label=data['label'], color=color, linewidth=2, alpha=0.8)

    ax.axhline(0, color='black', linestyle='--', alpha=0.5)
    ax.set_xlabel('Date')
    ax.set_ylabel('Rolling Interaction Coefficient (β for ω × Rank)')
    ax.set_title('Comparison of Rolling Mechanism Coefficients Across Rate Specifications')
    ax.legend(loc='best')
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'comparison_rolling_all_specs_claudeDGS10rb.png', dpi=150)
    plt.close()
    print("\nSaved: comparison_rolling_all_specs_claudeDGS10rb.png")


#%% PART 4: Quarterly LP Regressions
print("\n" + "="*80)
print("PART 4: QUARTERLY LOCAL PROJECTIONS")
print("="*80)

# Load quarterly data
estdata_path = BASE_DIR / 'FRRS_data' / 'sandbox_jan2026' / 'estdata_update_ptilec_robustness.dta'

if not estdata_path.exists():
    estdata_path = BASE_DIR / 'FRRS_data' / 'data' / 'proc_analysis' / 'estdata_update_ptilec.dta'

if estdata_path.exists():
    print(f"Loading quarterly data from: {estdata_path}")
    df_qtr = pd.read_stata(estdata_path)
    print(f"Loaded: {len(df_qtr):,} observations")

    # Check for DGS10 in quarterly data
    if 'DGS10' in df_qtr.columns:
        print(f"DGS10 in quarterly data: {df_qtr['DGS10'].notna().sum():,} non-null")
    else:
        # Try to merge from daily rates
        if df_rates is not None and 'DGS10' in df_rates.columns:
            print("Merging DGS10 from daily rates...")
            df_rates_qtr = df_rates.copy()
            df_rates_qtr['year'] = (df_rates_qtr['daten'] - 10957) // 365 + 1990  # Approximate
            df_rates_qtr['quarter'] = ((df_rates_qtr['daten'] - 10957) % 365 // 90) + 1

            # Aggregate to quarterly
            qtr_agg = df_rates_qtr.groupby(['year', 'quarter']).agg({
                'DGS10': 'mean',
                'DGS10_minus_TP10': 'mean'
            }).reset_index()

            # Merge
            df_qtr = df_qtr.merge(qtr_agg, on=['year', 'quarter'], how='left', suffixes=('_old', ''))
            print(f"Merged DGS10: {df_qtr['DGS10'].notna().sum():,} non-null")
else:
    print("WARNING: Quarterly data file not found, skipping LP analysis")
    df_qtr = None

# Run LP regressions if data available
if df_qtr is not None and 'DGS10' in df_qtr.columns:

    def run_lp_regression_with_lags(df, shock_var, rate_var, yvar, horizon, n_lags=3):
        """
        Run single LP regression at given horizon with lagged controls.

        Model (following Ottonello-Winberry / main analysis):
            Δy_{i,j,t+h} = α_{j,t}^h + β_ZLB (ω_t × Leader_{i,t-1})
                         + β_Δ (ω_t × Leader_{i,t-1} × Rate_{t-1})
                         + δ' z_{i,j,t} + Σ_{ℓ=1}^{n_lags} Γ' θ_{i,j,t-ℓ} + ε

        Where lagged controls θ include: outcome, double_mp, triple_mp, Lileader, leader

        Parameters:
            n_lags: Number of lags to include (1, 2, 3, or 4 quarters)

        Returns:
            dict with coefficients, SEs, AIC, BIC, n_obs, log_likelihood
        """
        outcome = f"{yvar}{horizon}_gk"
        base_outcome = f"{yvar}0_gk"

        if outcome not in df.columns or base_outcome not in df.columns:
            return None

        # Create variables
        df_reg = df.copy()
        df_reg = df_reg.sort_values(['id', 'quarter_d'])

        # Leader indicator (top 5% by size)
        df_reg['leader'] = (df_reg['ptile_consis_ind'] >= 0.95).astype(float)

        # Lagged rate
        df_reg['L_rate'] = df_reg.groupby('id')[rate_var].shift(1)

        # Main interaction terms
        df_reg['double_mp'] = df_reg[shock_var] * df_reg['leader']
        df_reg['triple_mp'] = df_reg[shock_var] * df_reg['leader'] * df_reg['L_rate']

        # Level controls
        df_reg['Lileader'] = df_reg['L_rate'] * df_reg['leader']
        df_reg['leader_mcap'] = df_reg['leader']

        # Create lagged controls
        for lag in range(1, n_lags + 1):
            df_reg[f'L{lag}_{yvar}0_gk'] = df_reg.groupby('id')[base_outcome].shift(lag)
            df_reg[f'L{lag}_double_mp'] = df_reg.groupby('id')['double_mp'].shift(lag)
            df_reg[f'L{lag}_triple_mp'] = df_reg.groupby('id')['triple_mp'].shift(lag)
            df_reg[f'L{lag}_Lileader'] = df_reg.groupby('id')['Lileader'].shift(lag)
            df_reg[f'L{lag}_leader_mcap'] = df_reg.groupby('id')['leader_mcap'].shift(lag)

        # Build control list
        main_vars = ['double_mp', 'triple_mp', 'Lileader', 'leader_mcap']
        controls = []
        for lag in range(1, n_lags + 1):
            controls.extend([
                f'L{lag}_{yvar}0_gk',
                f'L{lag}_double_mp',
                f'L{lag}_triple_mp',
                f'L{lag}_Lileader',
                f'L{lag}_leader_mcap'
            ])

        # Required columns
        all_vars = [outcome] + main_vars + controls
        reg_cols = all_vars + ['id', 'quarter_d', 'industrytime']
        reg_cols = [c for c in reg_cols if c in df_reg.columns]
        df_reg = df_reg.dropna(subset=reg_cols)

        if len(df_reg) < 100:
            return None

        # Demean by industry-time (within transformation for FE)
        exog_vars = main_vars + [c for c in controls if c in df_reg.columns]

        group_means = df_reg.groupby('industrytime')[[outcome] + exog_vars].transform('mean')
        y_dm = df_reg[outcome] - group_means[outcome]
        X_dm = df_reg[exog_vars] - group_means[exog_vars]

        # Drop any remaining NaN
        valid_idx = ~(y_dm.isna() | X_dm.isna().any(axis=1))
        y_dm = y_dm[valid_idx]
        X_dm = X_dm[valid_idx]
        cluster_var = df_reg.loc[valid_idx, 'quarter_d']

        if len(y_dm) < 100:
            return None

        # Check rank and drop collinear columns
        X_arr = X_dm.values
        if np.linalg.matrix_rank(X_arr) < X_arr.shape[1]:
            keep_cols = []
            for col in exog_vars:
                if col not in X_dm.columns:
                    continue
                test_cols = keep_cols + [col]
                if np.linalg.matrix_rank(X_dm[test_cols].values) > len(keep_cols):
                    keep_cols.append(col)
            X_dm = X_dm[keep_cols]

        # OLS regression
        model = sm.OLS(y_dm, X_dm)
        result = model.fit(cov_type='cluster', cov_kwds={'groups': cluster_var})

        # Calculate AIC and BIC
        n = result.nobs
        k = len(result.params)  # number of parameters
        ll = result.llf  # log-likelihood

        aic = -2 * ll + 2 * k
        bic = -2 * ll + k * np.log(n)

        return {
            'beta_zlb': result.params.get('double_mp', np.nan),
            'se_zlb': result.bse.get('double_mp', np.nan),
            'beta_delta': result.params.get('triple_mp', np.nan),
            'se_delta': result.bse.get('triple_mp', np.nan),
            'aic': aic,
            'bic': bic,
            'n_obs': n,
            'k_params': k,
            'llf': ll,
            'r2': result.rsquared
        }

    # Outcome variables
    outcomes = ['Lborrowing_cost2', 'Llog_assets', 'Llogrev', 'Llog_ppe',
                'Pcapxq', 'Paqcq', 'Llog_debt', 'Lleverage']
    outcome_names = ['Borrowing Cost', 'Assets', 'Revenue', 'PPE',
                     'CapEx', 'Acquisitions', 'Debt', 'Leverage']

    # Rate specifications for LP
    lp_specs = {
        'DGS10': 'DGS10',
        'target_ma10_forward': 'target_ma10_forward'
    }

    # Lag lengths to test (quarterly data: 1-12 quarters = up to 3 years)
    lag_lengths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

    # Representative lags for IRF figures (to keep output manageable)
    irf_lag_lengths = [1, 4, 8, 12]

    # Check availability
    available_lp_specs = {k: v for k, v in lp_specs.items() if v in df_qtr.columns}
    print(f"\nAvailable LP specifications: {list(available_lp_specs.keys())}")
    print(f"Testing lag lengths: {lag_lengths}")

    # Store AIC/BIC comparison results
    lag_comparison_results = []

    # Run for each rate spec
    for spec_name, rate_var in available_lp_specs.items():
        print(f"\n{'='*60}")
        print(f"Running LPs for {spec_name} with lag length comparison")
        print(f"{'='*60}")

        # First: Compare lag lengths using AIC/BIC at horizon 0
        print(f"\n  Lag Selection (horizon=0):")
        print(f"  {'Outcome':<20} {'Lags':>6} {'AIC':>12} {'BIC':>12} {'N':>8} {'Best':>6}")
        print(f"  {'-'*70}")

        for yvar, name in zip(outcomes, outcome_names):
            base_yvar = f"{yvar}0_gk"
            if base_yvar not in df_qtr.columns:
                continue

            lag_results = {}
            for n_lags in lag_lengths:
                res = run_lp_regression_with_lags(df_qtr, 'mp_klms_U', rate_var, yvar, 0, n_lags)
                if res is not None:
                    lag_results[n_lags] = res

            if lag_results:
                # Find best by AIC and BIC
                best_aic_lag = min(lag_results.keys(), key=lambda x: lag_results[x]['aic'])
                best_bic_lag = min(lag_results.keys(), key=lambda x: lag_results[x]['bic'])

                for n_lags in lag_lengths:
                    if n_lags in lag_results:
                        res = lag_results[n_lags]
                        is_best = ''
                        if n_lags == best_aic_lag and n_lags == best_bic_lag:
                            is_best = 'AIC+BIC'
                        elif n_lags == best_aic_lag:
                            is_best = 'AIC'
                        elif n_lags == best_bic_lag:
                            is_best = 'BIC'

                        print(f"  {name:<20} {n_lags:>6} {res['aic']:>12.1f} {res['bic']:>12.1f} {res['n_obs']:>8} {is_best:>6}")

                        lag_comparison_results.append({
                            'rate_spec': spec_name,
                            'outcome': name,
                            'n_lags': n_lags,
                            'aic': res['aic'],
                            'bic': res['bic'],
                            'n_obs': res['n_obs'],
                            'best_aic': n_lags == best_aic_lag,
                            'best_bic': n_lags == best_bic_lag
                        })

        # Run full IRFs for representative lag lengths only
        for n_lags in irf_lag_lengths:
            print(f"\n  Computing IRFs with {n_lags} lag(s)...")

            all_results = {}

            for yvar, name in zip(outcomes, outcome_names):
                base_yvar = f"{yvar}0_gk"
                if base_yvar not in df_qtr.columns:
                    continue

                results = np.zeros((12, 7))  # 12 rows, 7 cols

                for h in range(11):
                    lp_result = run_lp_regression_with_lags(df_qtr, 'mp_klms_U', rate_var, yvar, h, n_lags)

                    if lp_result is not None:
                        results[h+1, 0] = lp_result['beta_zlb']
                        results[h+1, 1] = lp_result['beta_zlb'] + 1.96 * lp_result['se_zlb']
                        results[h+1, 2] = lp_result['beta_zlb'] - 1.96 * lp_result['se_zlb']
                        results[h+1, 3] = lp_result['beta_delta']
                        results[h+1, 4] = lp_result['beta_delta'] + 1.96 * lp_result['se_delta']
                        results[h+1, 5] = lp_result['beta_delta'] - 1.96 * lp_result['se_delta']
                        results[h+1, 6] = h + 1

                results[0, 6] = 0
                all_results[yvar] = {'results': results, 'name': name}

            # Create combined LP figure for this lag length
            if all_results:
                fig, axes = plt.subplots(4, 4, figsize=(16, 16))
                axes = axes.flatten()

                plot_idx = 0
                for yvar in outcomes:
                    if yvar not in all_results:
                        continue

                    results = all_results[yvar]['results']
                    name = all_results[yvar]['name']
                    ahead = results[:, 6]

                    # Beta ZLB
                    ax = axes[plot_idx]
                    ax.plot(ahead, results[:, 0], color='navy', linewidth=2)
                    ax.fill_between(ahead, results[:, 2], results[:, 1], color='navy', alpha=0.2)
                    ax.axhline(0, color='black', linewidth=0.5)
                    ax.set_title(f'{name}\n' + r'$\beta_{ZLB}$', fontsize=10)
                    ax.grid(True, alpha=0.3)
                    plot_idx += 1

                    # Beta Delta
                    ax = axes[plot_idx]
                    ax.plot(ahead, results[:, 3], color='navy', linewidth=2)
                    ax.fill_between(ahead, results[:, 5], results[:, 4], color='navy', alpha=0.2)
                    ax.axhline(0, color='black', linewidth=0.5)
                    ax.set_title(f'{name}\n' + r'$\beta_{\Delta}$', fontsize=10)
                    ax.grid(True, alpha=0.3)
                    plot_idx += 1

                # Hide unused
                for i in range(plot_idx, len(axes)):
                    axes[i].set_visible(False)

                plt.suptitle(f'Quarterly LP IRFs - {spec_name} ({n_lags} lag{"s" if n_lags > 1 else ""})', fontsize=14)
                plt.tight_layout()
                plt.savefig(OUTPUT_DIR / f'LP_IRFs_{spec_name}_lags{n_lags}_claudeDGS10rb.png', dpi=150)
                plt.close()
                print(f"    Saved: LP_IRFs_{spec_name}_lags{n_lags}_claudeDGS10rb.png")

    # Save lag comparison results
    if lag_comparison_results:
        df_lag_compare = pd.DataFrame(lag_comparison_results)
        df_lag_compare.to_csv(OUTPUT_DIR / 'LP_lag_selection_AIC_BIC_claudeDGS10rb.csv', index=False)
        print(f"\n  Saved: LP_lag_selection_AIC_BIC_claudeDGS10rb.csv")

        # Create summary of best lags
        print(f"\n  {'='*60}")
        print(f"  LAG SELECTION SUMMARY (by AIC/BIC)")
        print(f"  {'='*60}")

        for spec_name in available_lp_specs.keys():
            spec_data = df_lag_compare[df_lag_compare['rate_spec'] == spec_name]

            aic_best = spec_data[spec_data['best_aic']].groupby('n_lags').size()
            bic_best = spec_data[spec_data['best_bic']].groupby('n_lags').size()

            print(f"\n  {spec_name}:")
            print(f"    AIC selects: {dict(aic_best)}")
            print(f"    BIC selects: {dict(bic_best)}")

    # Create comparison figure: IRFs across different lag lengths (for one outcome)
    print(f"\n  Creating lag comparison figures...")

    for spec_name, rate_var in available_lp_specs.items():
        # Use Llog_assets as representative outcome
        test_yvar = 'Llog_assets'
        test_name = 'Assets'

        if f"{test_yvar}0_gk" not in df_qtr.columns:
            continue

        fig, axes = plt.subplots(2, 2, figsize=(14, 10))

        # Colors for representative lags in IRF comparison (top plots)
        irf_colors = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red']

        for ax_idx, (ax, coef_type) in enumerate(zip(axes.flatten()[:2], ['beta_zlb', 'beta_delta'])):
            for n_lags, color in zip(irf_lag_lengths, irf_colors):
                horizons = []
                coefs = []
                ci_lo = []
                ci_hi = []

                for h in range(11):
                    res = run_lp_regression_with_lags(df_qtr, 'mp_klms_U', rate_var, test_yvar, h, n_lags)
                    if res is not None:
                        horizons.append(h + 1)
                        coefs.append(res[coef_type])
                        se = res['se_zlb'] if coef_type == 'beta_zlb' else res['se_delta']
                        ci_lo.append(res[coef_type] - 1.96 * se)
                        ci_hi.append(res[coef_type] + 1.96 * se)

                if horizons:
                    ax.plot(horizons, coefs, color=color, linewidth=2, label=f'{n_lags} lag{"s" if n_lags > 1 else ""}')
                    ax.fill_between(horizons, ci_lo, ci_hi, color=color, alpha=0.1)

            ax.axhline(0, color='black', linewidth=0.5)
            ax.set_xlabel('Horizon (quarters)')
            ylabel = r'$\beta_{ZLB}$' if coef_type == 'beta_zlb' else r'$\beta_{\Delta}$'
            ax.set_ylabel(ylabel)
            ax.set_title(f'{test_name} - {ylabel}')
            ax.legend(loc='best')
            ax.grid(True, alpha=0.3)

        # Colormap for all 12 lags in bar charts (bottom plots)
        cmap = plt.cm.viridis
        bar_colors = [cmap(i / (len(lag_lengths) - 1)) for i in range(len(lag_lengths))]

        # AIC/BIC comparison bar chart
        ax = axes[1, 0]
        aic_by_lag = {n_lags: [] for n_lags in lag_lengths}
        for yvar in outcomes:
            for n_lags in lag_lengths:
                res = run_lp_regression_with_lags(df_qtr, 'mp_klms_U', rate_var, yvar, 0, n_lags)
                if res is not None:
                    aic_by_lag[n_lags].append(res['aic'])

        x = np.arange(len(lag_lengths))
        mean_aics = [np.mean(aic_by_lag[n]) if aic_by_lag[n] else np.nan for n in lag_lengths]
        ax.bar(x, mean_aics, color=bar_colors)
        ax.set_xticks(x)
        ax.set_xticklabels([str(n) for n in lag_lengths], fontsize=9)
        ax.set_xlabel('Number of lags')
        ax.set_ylabel('Mean AIC (lower is better)')
        ax.set_title('AIC by Lag Length (across outcomes)')
        ax.grid(True, alpha=0.3, axis='y')

        # BIC comparison
        ax = axes[1, 1]
        bic_by_lag = {n_lags: [] for n_lags in lag_lengths}
        for yvar in outcomes:
            for n_lags in lag_lengths:
                res = run_lp_regression_with_lags(df_qtr, 'mp_klms_U', rate_var, yvar, 0, n_lags)
                if res is not None:
                    bic_by_lag[n_lags].append(res['bic'])

        mean_bics = [np.mean(bic_by_lag[n]) if bic_by_lag[n] else np.nan for n in lag_lengths]
        ax.bar(x, mean_bics, color=bar_colors)
        ax.set_xticks(x)
        ax.set_xticklabels([str(n) for n in lag_lengths], fontsize=9)
        ax.set_xlabel('Number of lags')
        ax.set_ylabel('Mean BIC (lower is better)')
        ax.set_title('BIC by Lag Length (across outcomes)')
        ax.grid(True, alpha=0.3, axis='y')

        plt.suptitle(f'Lag Length Comparison - {spec_name}', fontsize=14)
        plt.tight_layout()
        plt.savefig(OUTPUT_DIR / f'LP_lag_comparison_{spec_name}_claudeDGS10rb.png', dpi=150)
        plt.close()
        print(f"    Saved: LP_lag_comparison_{spec_name}_claudeDGS10rb.png")


#%% PART 5: Summary Statistics and Diagnostics
print("\n" + "="*80)
print("PART 5: SUMMARY STATISTICS")
print("="*80)

# Rate correlations
rate_cols = [col for col in ['DGS10', 'DGS10_minus_TP10', 'target_ma10_forward', 'synthed_10y', 'TP10']
             if col in df_work.columns]

if len(rate_cols) > 1:
    # Get one observation per date
    df_date = df_work.groupby('daten')[rate_cols].first().reset_index()

    print("\nCorrelation matrix of rate measures:")
    corr_matrix = df_date[rate_cols].corr()
    print(corr_matrix.round(3))

    # Save correlation matrix
    corr_matrix.to_csv(OUTPUT_DIR / 'rate_correlations_claudeDGS10rb.csv')
    print("\nSaved: rate_correlations_claudeDGS10rb.csv")

    # Heatmap
    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.imshow(corr_matrix, cmap='RdBu_r', vmin=-1, vmax=1)

    ax.set_xticks(range(len(rate_cols)))
    ax.set_yticks(range(len(rate_cols)))
    ax.set_xticklabels(rate_cols, rotation=45, ha='right')
    ax.set_yticklabels(rate_cols)

    for i in range(len(rate_cols)):
        for j in range(len(rate_cols)):
            text = ax.text(j, i, f'{corr_matrix.iloc[i, j]:.2f}',
                          ha='center', va='center', color='black')

    plt.colorbar(im)
    plt.title('Correlation of Rate Measures')
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'rate_correlations_heatmap_claudeDGS10rb.png', dpi=150)
    plt.close()
    print("Saved: rate_correlations_heatmap_claudeDGS10rb.png")


#%% Final Summary
print("\n" + "="*80)
print("ANALYSIS COMPLETE")
print("="*80)
print(f"\nAll outputs saved to: {OUTPUT_DIR}")
print("\nFiles generated:")
for f in sorted(OUTPUT_DIR.glob('*')):
    print(f"  {f.name}")
