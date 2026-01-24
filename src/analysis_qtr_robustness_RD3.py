#%% Don't run interactively
import pandas as pd
import numpy as np
import datetime
import os
import matplotlib.pyplot as plt
import statsmodels.api as sm
import warnings
warnings.filterwarnings('ignore')

def main():
    # Paths - using relative paths assuming execution from workspace root
    daily_rates_path = r'FRRS_data/sandbox_jan2026/fomc_daily_rates.csv'
    estdata_path = r'FRRS_data/data/proc_analysis/estdata_update_ptilec.dta'
    # Save to sandbox as requested
    output_path = r'FRRS_data/sandbox_jan2026/estdata_update_ptilec_robustness.dta'

    print(f"Loading daily rates from {daily_rates_path}...")
    if not os.path.exists(daily_rates_path):
        print(f"Error: {daily_rates_path} not found.")
        return

    df_daily = pd.read_csv(daily_rates_path)
    
    # Process Dates
    # daten is Stata date (days since 1960-01-01)
    base_date = pd.Timestamp('1960-01-01')
    try:
        df_daily['date'] = df_daily['daten'].apply(lambda x: base_date + pd.Timedelta(days=x))
    except Exception as e:
        print(f"Error converting dates: {e}")
        # Fallback if daten is not present or weird
        if 'date' in df_daily.columns:
            df_daily['date'] = pd.to_datetime(df_daily['date'])

    # Create Quarter Spine
    df_daily['year'] = df_daily['date'].dt.year
    df_daily['quarter'] = df_daily['date'].dt.quarter
    
    # Calculate Quarter Bounds
    def get_quarter_bounds(row):
        y = row['year']
        q = row['quarter']
        if q == 1:
            start = pd.Timestamp(year=y, month=1, day=1)
            end = pd.Timestamp(year=y, month=3, day=31)
        elif q == 2:
            start = pd.Timestamp(year=y, month=4, day=1)
            end = pd.Timestamp(year=y, month=6, day=30)
        elif q == 3:
            start = pd.Timestamp(year=y, month=7, day=1)
            end = pd.Timestamp(year=y, month=9, day=30)
        else:
            start = pd.Timestamp(year=y, month=10, day=1)
            end = pd.Timestamp(year=y, month=12, day=31)
        return start, end

    bounds = df_daily.apply(get_quarter_bounds, axis=1)
    df_daily['q_start'] = [b[0] for b in bounds]
    df_daily['q_end'] = [b[1] for b in bounds]
    
    # Weights for aggregation (Ottonello and Winberry, 2020)
    # Weight = Days Remaining / Total Days in Quarter
    df_daily['days_in_q'] = (df_daily['q_end'] - df_daily['q_start']).dt.days + 1
    # Check bounds inclusivity: (End - Start).days gives difference. Add 1 for count.
    
    # Days Remaining after shock day
    # "s_1 happens on day 10... (80/90)*s1".
    # If day 10 (Jan 10), remaining is 80.
    # Jan 10 to Mar 31.
    # (Mar 31 - Jan 10).days = 80. Correct.
    df_daily['days_remaining'] = (df_daily['q_end'] - df_daily['date']).dt.days
    
    df_daily['weight_current'] = df_daily['days_remaining'] / df_daily['days_in_q']
    df_daily['weight_next'] = 1 - df_daily['weight_current'] 
    
    print("Aggregating shocks...")
    # Check if 'mp_klms_U' exists
    shock_var = 'mp_klms_U'
    if shock_var not in df_daily.columns:
        print(f"Warning: {shock_var} not found in daily rates.")
        # Fallback to similar user variables if necessary or error out
        # Try to find a shock variable
        possible_shocks = [c for c in df_daily.columns if 'klms' in c]
        if possible_shocks:
            print(f"Using {possible_shocks[0]} instead.")
            shock_var = possible_shocks[0]
    
    # Contributions to current Q
    df_curr = df_daily[['year', 'quarter', shock_var, 'weight_current']].copy()
    df_curr['weighted_shock'] = df_curr[shock_var] * df_curr['weight_current']
    
    # Contributions to next Q
    df_next = df_daily[['year', 'quarter', shock_var, 'weight_next']].copy()
    df_next['weighted_shock'] = df_next[shock_var] * df_next['weight_next']
    
    # Shift time for next Q
    def add_quarter_func(row):
        y, q = int(row['year']), int(row['quarter'])
        if q == 4:
            return y + 1, 1
        else:
            return y, q + 1
            
    next_periods = df_next.apply(add_quarter_func, axis=1)
    df_next['year'] = [x[0] for x in next_periods]
    df_next['quarter'] = [x[1] for x in next_periods]
    
    # Combine
    df_shocks = pd.concat([
        df_curr[['year', 'quarter', 'weighted_shock']],
        df_next[['year', 'quarter', 'weighted_shock']]
    ])
    
    agg_shocks = df_shocks.groupby(['year', 'quarter'])['weighted_shock'].sum().reset_index()
    agg_shocks.rename(columns={'weighted_shock': shock_var}, inplace=True)
    
    print("Aggregating rates...")
    rate_vars = ['target_ma5_forward', 'target_ma10_forward', 'synthetic_5y_rate', 'synthetic_10y_rate', 'target_ma3', 'target_ma5', 'target_ma10']
    valid_rates = [c for c in rate_vars if c in df_daily.columns]
    
    agg_rates = df_daily.groupby(['year', 'quarter'])[valid_rates].mean().reset_index()
    
    agg_data = pd.merge(agg_shocks, agg_rates, on=['year', 'quarter'], how='outer')

    # Linearly interpolate missing synthetic rates
    # print("Interpolating missing synthetic rates...")
    # agg_data = agg_data.sort_values(['year', 'quarter']).reset_index(drop=True)
    # for var in ['synthetic_5y_rate', 'synthetic_10y_rate']:
    #     if var in agg_data.columns:
    #         n_missing_before = agg_data[var].isna().sum()
    #         agg_data[var] = agg_data[var].interpolate(method='linear')
    #         n_missing_after = agg_data[var].isna().sum()
    #         print(f"  {var}: filled {n_missing_before - n_missing_after} missing values")

    # Load Stata File
    print(f"Loading {estdata_path}...")
    if not os.path.exists(estdata_path):
        print(f"Error: {estdata_path} not found.")
        return
        
    df_stata = pd.read_stata(estdata_path)
    
    # Drop mp_klms*
    print("Dropping mp_klms columns...")
    cols_to_drop = [c for c in df_stata.columns if c.startswith('mp_klms')]
    # Be careful not to drop the target merge key if it was named mp_klms (unlikely)
    df_stata.drop(columns=cols_to_drop, inplace=True)
    
    # Merge
    print("Merging new data...")
    agg_data['year'] = agg_data['year'].astype(float)
    agg_data['quarter'] = agg_data['quarter'].astype(float)
    df_stata['year'] = df_stata['year'].astype(float)
    df_stata['quarter'] = df_stata['quarter'].astype(float)
    
    df_merged = pd.merge(df_stata, agg_data, on=['year', 'quarter'], how='left')
    
    # Plot variables over quarters
    print("Generating plots...")
    plot_vars = ['target_ma5_forward', 'target_ma10_forward', 'synthetic_5y_rate', 'synthetic_10y_rate', 'mp_klms_U']
    plot_data = agg_data[['year', 'quarter'] + [v for v in plot_vars if v in agg_data.columns]].copy()
    plot_data = plot_data.dropna(subset=['year', 'quarter'])
    plot_data['quarter_date'] = pd.to_datetime(
        plot_data['year'].astype(int).astype(str) + 'Q' + plot_data['quarter'].astype(int).astype(str)
    )
    plot_data = plot_data.sort_values('quarter_date')

    fig, axes = plt.subplots(len(plot_vars), 1, figsize=(12, 3 * len(plot_vars)), sharex=True)
    if len(plot_vars) == 1:
        axes = [axes]

    for ax, var in zip(axes, plot_vars):
        if var in plot_data.columns:
            ax.plot(plot_data['quarter_date'], plot_data[var], marker='o', markersize=2, linewidth=1)
            ax.set_ylabel(var)
            ax.set_title(f'{var} over Quarters')
            ax.grid(True, alpha=0.3)
        else:
            ax.set_visible(False)
            print(f"Warning: {var} not found in aggregated data for plotting.")

    axes[-1].set_xlabel('Quarter')
    plt.tight_layout()

    plot_path = r'FRRS_data/sandbox_jan2026/quarterly_rates_plot.png'
    plt.savefig(plot_path, dpi=150)
    print(f"Plot saved to {plot_path}")
    plt.close()

    # Save
    print(f"Saving to {output_path}...")
    # Using version 117 (Stata 13) or 118 (Stata 14) for compatibility
    try:
        df_merged.to_stata(output_path, write_index=False, version=118)
    except Exception as e:
        print(f"Error saving dta: {e}")
        # Fallback to default
        df_merged.to_stata(output_path, write_index=False)
        
    print("Done with data preparation.")

    # Return merged data for LP analysis
    return df_merged


def run_lp_regressions(df, shock_var, rate_var, rate_label, output_dir):
    """
    Run local projection regressions replicating the Stata analysis.

    The model (from equation in paper):
        Δy_{i,j,t+h-1} = α_{j,t}^h + β_ZLB^h (ω_t * L_{i,j,t-1}) + β_Δ^h (ω_t * L_{i,j,t-1} * FFR_{t-1})
                         + δ'_h z_{i,j,t} + Σ_{ℓ=1}^{3} Γ'_h θ_{i,j,t-ℓ} + ε_{i,j,t+h-1}

    Where:
        - L_{i,j,t-1} = leader indicator (ptile_consis_ind >= 0.95)
        - ω_t = monetary policy shock (mp_klms_U)
        - FFR_{t-1} = lagged interest rate
        - z_{i,j,t} = current period controls (Lileader, leader_mcap)
        - θ_{i,j,t-ℓ} = lagged controls (lags of outcome, double, triple, Lileader)
    """
    print(f"\n{'='*60}")
    print(f"Running LP with rate interaction: {rate_label}")
    print(f"{'='*60}")

    # Outcome variables and names
    yvar_list = ['Lborrowing_cost2', 'Llog_assets', 'Llogrev', 'Llog_ppe',
                 'Pcapxq', 'Paqcq', 'Llog_debt', 'Lleverage']
    name_list = ['Borrowing Cost', 'Assets', 'Revenue', 'Property, Plant, and Equipment',
                 'Capital Expenditure', 'Acquisitions', 'Debt', 'Leverage']

    # Create leader indicator
    df = df.copy()
    df = df.sort_values(['id', 'quarter_d'])
    df['leader5'] = (df['ptile_consis_ind'] >= 0.95).astype(float)

    # Create lagged rate (L.FFR or L.rate_var)
    df['L_rate'] = df.groupby('id')[rate_var].shift(1)

    # Main regressors (using current shock, but lagged rate and leader status from t-1 perspective)
    # double_mp = ω_t * L_{i,j,t-1} (shock interacted with leader)
    df['double_mp'] = df[shock_var] * df['leader5']

    # triple_mp = ω_t * L_{i,j,t-1} * FFR_{t-1}
    df['triple_mp'] = df[shock_var] * df['leader5'] * df['L_rate']

    # Control variables z_{i,j,t}:
    # Lileader = L.rate * leader (level of rate times leader)
    df['Lileader'] = df['L_rate'] * df['leader5']
    # leader_mcap = leader indicator
    df['leader_mcap'] = df['leader5']

    # Store results for combined plot
    all_results = {}

    for yvar, name in zip(yvar_list, name_list):
        print(f"\n  Processing: {name} ({yvar})")

        # Check if outcome variables exist
        base_yvar = f"{yvar}0_gk"
        if base_yvar not in df.columns:
            print(f"    Warning: {base_yvar} not found, skipping...")
            continue

        # Pre-compute lagged controls for this outcome variable
        # Lags of outcome
        for lag in range(1, 4):
            df[f'L{lag}_{yvar}0_gk'] = df.groupby('id')[base_yvar].shift(lag)

        # Lags of double_mp, triple_mp, Lileader, leader_mcap
        for lag in range(1, 4):
            df[f'L{lag}_double_mp'] = df.groupby('id')['double_mp'].shift(lag)
            df[f'L{lag}_triple_mp'] = df.groupby('id')['triple_mp'].shift(lag)
            df[f'L{lag}_Lileader'] = df.groupby('id')['Lileader'].shift(lag)
            df[f'L{lag}_leader_mcap'] = df.groupby('id')['leader_mcap'].shift(lag)

        # Initialize results matrix: rows=horizons (0-10 + row for 0), cols=[beta_zlb, ub, lb, beta_delta, ub, lb, horizon]
        results = np.zeros((12, 7))
        results[0, :] = 0  # First row is zeros (horizon -1 for plotting)

        for h in range(11):  # horizons 0-10
            outcome_var = f"{yvar}{h}_gk"
            if outcome_var not in df.columns:
                print(f"    Warning: {outcome_var} not found for horizon {h}")
                continue

            # Build control variable list
            # Controls from Stata: l(1/3).yvar0_gk, l(1/3).double_mp, l(1/3).triple_mp,
            #                      l(1/3).Lileader, l(1/3).leader_mcap
            # Note: leader_mcap is time-invariant (ptile_consis_ind >= 0.95), so its lags
            # are identical. Stata's reghdfe will automatically drop collinear terms.
            # We include them here and let the rank check handle collinearity.
            controls = []
            for lag in range(1, 4):
                controls.append(f'L{lag}_{yvar}0_gk')
                controls.append(f'L{lag}_double_mp')
                controls.append(f'L{lag}_triple_mp')
                controls.append(f'L{lag}_Lileader')
                controls.append(f'L{lag}_leader_mcap')

            # Main regressors
            main_vars = ['double_mp', 'triple_mp', 'Lileader', 'leader_mcap']

            # Prepare regression data
            all_reg_vars = [outcome_var] + main_vars + controls
            all_reg_vars = [v for v in all_reg_vars if v in df.columns]

            reg_df = df[['id', 'quarter_d', 'industrytime'] + all_reg_vars].dropna()

            if len(reg_df) < 100:
                print(f"    Warning: insufficient observations for horizon {h}")
                continue

            # Set up panel
            reg_df = reg_df.set_index(['id', 'quarter_d'])

            # Exogenous variables (all regressors except outcome)
            exog_vars = main_vars + [c for c in controls if c in reg_df.columns]

            try:
                # Demean by industry-time FE (within transformation)
                # This is equivalent to reghdfe absorb(industrytime)
                reg_df_reset = reg_df.reset_index()

                # Group means for demeaning
                group_means = reg_df_reset.groupby('industrytime')[[outcome_var] + exog_vars].transform('mean')

                # Demean all variables
                y_dm = reg_df_reset[outcome_var] - group_means[outcome_var]
                X_dm = reg_df_reset[exog_vars] - group_means[exog_vars]

                # Drop any remaining NaN after demeaning
                valid_idx = ~(y_dm.isna() | X_dm.isna().any(axis=1))
                y_dm = y_dm[valid_idx]
                X_dm = X_dm[valid_idx]
                cluster_var = reg_df_reset.loc[valid_idx, 'quarter_d']

                if len(y_dm) < 100:
                    print(f"    Warning: insufficient observations after demeaning for horizon {h}")
                    continue

                # Check for rank deficiency and drop collinear columns
                X_arr = X_dm.values
                rank = np.linalg.matrix_rank(X_arr)
                if rank < X_arr.shape[1]:
                    # Keep only linearly independent columns, prioritizing main vars
                    keep_cols = []
                    for col in exog_vars:
                        if col not in X_dm.columns:
                            continue
                        test_cols = keep_cols + [col]
                        test_X = X_dm[test_cols].values
                        if np.linalg.matrix_rank(test_X) > len(keep_cols):
                            keep_cols.append(col)
                    X_dm = X_dm[keep_cols]
                    exog_vars_used = keep_cols
                else:
                    exog_vars_used = exog_vars

                # Run OLS on demeaned data
                model = sm.OLS(y_dm, X_dm)
                # Cluster by quarter_d
                result = model.fit(cov_type='cluster', cov_kwds={'groups': cluster_var})

                # Extract coefficients
                beta_zlb = result.params.get('double_mp', np.nan)
                se_zlb = result.bse.get('double_mp', np.nan)
                beta_delta = result.params.get('triple_mp', np.nan)
                se_delta = result.bse.get('triple_mp', np.nan)

                # Store results (row h+1 because row 0 is zeros)
                results[h + 1, 0] = beta_zlb
                results[h + 1, 1] = beta_zlb + 1.96 * se_zlb
                results[h + 1, 2] = beta_zlb - 1.96 * se_zlb
                results[h + 1, 3] = beta_delta
                results[h + 1, 4] = beta_delta + 1.96 * se_delta
                results[h + 1, 5] = beta_delta - 1.96 * se_delta
                results[h + 1, 6] = h + 1  # horizon for plotting

            except Exception as e:
                print(f"    Error at horizon {h}: {e}")
                continue

        # Set horizon column for row 0
        results[0, 6] = 0

        all_results[yvar] = {'results': results, 'name': name}

        # Create individual plot for this outcome
        fig, axes = plt.subplots(1, 2, figsize=(10, 4))

        ahead = results[:, 6]

        # Beta ZLB plot
        ax = axes[0]
        ax.plot(ahead, results[:, 0], color='navy', linewidth=2, label='Point estimate')
        ax.plot(ahead, results[:, 1], color='navy', linestyle='--', linewidth=1)
        ax.plot(ahead, results[:, 2], color='navy', linestyle='--', linewidth=1)
        ax.axhline(y=0, color='black', linewidth=0.5)
        ax.set_ylabel(r'$\beta_{ZLB}$')
        ax.set_title(f'{name}')
        ax.grid(True, alpha=0.3)

        # Beta Delta plot
        ax = axes[1]
        ax.plot(ahead, results[:, 3], color='navy', linewidth=2, label='Point estimate')
        ax.plot(ahead, results[:, 4], color='navy', linestyle='--', linewidth=1)
        ax.plot(ahead, results[:, 5], color='navy', linestyle='--', linewidth=1)
        ax.axhline(y=0, color='black', linewidth=0.5)
        ax.set_ylabel(r'$\beta_{\Delta}$')
        ax.set_title(f'{name}')
        ax.grid(True, alpha=0.3)

        plt.tight_layout()
        plot_path = os.path.join(output_dir, f'IRF_{yvar}_{rate_label}.png')
        plt.savefig(plot_path, dpi=150)
        plt.close()

    # Create combined 8-panel figure
    if len(all_results) > 0:
        fig, axes = plt.subplots(4, 4, figsize=(16, 16))
        axes = axes.flatten()

        plot_idx = 0
        for yvar in yvar_list:
            if yvar not in all_results:
                continue

            results = all_results[yvar]['results']
            name = all_results[yvar]['name']
            ahead = results[:, 6]

            # Beta ZLB
            ax = axes[plot_idx]
            ax.plot(ahead, results[:, 0], color='navy', linewidth=2)
            ax.fill_between(ahead, results[:, 2], results[:, 1], color='navy', alpha=0.2)
            ax.axhline(y=0, color='black', linewidth=0.5)
            ax.set_title(f'{name}\n' + r'$\beta_{ZLB}$', fontsize=10)
            ax.grid(True, alpha=0.3)
            plot_idx += 1

            # Beta Delta
            ax = axes[plot_idx]
            ax.plot(ahead, results[:, 3], color='navy', linewidth=2)
            ax.fill_between(ahead, results[:, 5], results[:, 4], color='navy', alpha=0.2)
            ax.axhline(y=0, color='black', linewidth=0.5)
            ax.set_title(f'{name}\n' + r'$\beta_{\Delta}$', fontsize=10)
            ax.grid(True, alpha=0.3)
            plot_idx += 1

        # Hide unused axes
        for i in range(plot_idx, len(axes)):
            axes[i].set_visible(False)

        plt.suptitle(f'LP IRFs - Rate interaction: {rate_label}', fontsize=14)
        plt.tight_layout()
        combined_path = os.path.join(output_dir, f'all8_IRFs_{rate_label}.png')
        plt.savefig(combined_path, dpi=150)
        plt.close()
        print(f"  Combined plot saved to {combined_path}")

    return all_results


def run_all_lp_specifications(df_merged, output_dir):
    """
    Run LP regressions for all 5 specifications:
    1. Baseline with O/W aggregated mp_klms_U and l.target
    2. Using l.target_ma5_forward as rate interaction
    3. Using l.target_ma10_forward as rate interaction
    4. Using l.synthetic_5y_rate as rate interaction
    5. Using l.synthetic_10y_rate as rate interaction
    """
    os.makedirs(output_dir, exist_ok=True)

    shock_var = 'mp_klms_U'

    # Check if shock variable exists
    if shock_var not in df_merged.columns:
        print(f"Error: {shock_var} not found in merged data.")
        return

    # Define specifications
    specifications = [
        ('target', 'baseline_target'),
        ('target_ma5_forward', 'ma5_forward'),
        ('target_ma10_forward', 'ma10_forward'),
        ('synthetic_5y_rate', 'synthetic_5y'),
        ('synthetic_10y_rate', 'synthetic_10y'),
    ]

    all_spec_results = {}

    for rate_var, label in specifications:
        if rate_var not in df_merged.columns:
            print(f"\nSkipping {label}: {rate_var} not found in data")
            continue

        results = run_lp_regressions(df_merged, shock_var, rate_var, label, output_dir)
        all_spec_results[label] = results

    # Create comparison plot across specifications for key outcomes
    print("\nCreating comparison plots across specifications...")
    key_outcomes = ['Lborrowing_cost2', 'Llog_assets', 'Pcapxq', 'Lleverage']

    for yvar in key_outcomes:
        fig, axes = plt.subplots(2, len(specifications), figsize=(4*len(specifications), 8))

        for col, (rate_var, label) in enumerate(specifications):
            if label not in all_spec_results or yvar not in all_spec_results[label]:
                continue

            results = all_spec_results[label][yvar]['results']
            name = all_spec_results[label][yvar]['name']
            ahead = results[:, 6]

            # Beta ZLB
            ax = axes[0, col]
            ax.plot(ahead, results[:, 0], color='navy', linewidth=2)
            ax.fill_between(ahead, results[:, 2], results[:, 1], color='navy', alpha=0.2)
            ax.axhline(y=0, color='black', linewidth=0.5)
            ax.set_title(f'{label}\n' + r'$\beta_{ZLB}$', fontsize=10)
            ax.grid(True, alpha=0.3)
            if col == 0:
                ax.set_ylabel(name)

            # Beta Delta
            ax = axes[1, col]
            ax.plot(ahead, results[:, 3], color='navy', linewidth=2)
            ax.fill_between(ahead, results[:, 5], results[:, 4], color='navy', alpha=0.2)
            ax.axhline(y=0, color='black', linewidth=0.5)
            ax.set_title(r'$\beta_{\Delta}$', fontsize=10)
            ax.grid(True, alpha=0.3)
            ax.set_xlabel('Quarters ahead')

        plt.suptitle(f'Comparison across rate specifications: {name}', fontsize=14)
        plt.tight_layout()
        comp_path = os.path.join(output_dir, f'comparison_{yvar}.png')
        plt.savefig(comp_path, dpi=150)
        plt.close()

    print(f"\nAll LP analysis complete. Results saved to {output_dir}")


if __name__ == "__main__":
    df_merged = main()

    if df_merged is not None:
        output_dir = r'FRRS_data/sandbox_jan2026/LP_results'
        run_all_lp_specifications(df_merged, output_dir)

# %% One robustness check could be the "Term premium" from THREEFYTP10, Kim and Wright (2005)


