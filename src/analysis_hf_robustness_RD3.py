"""
High-Frequency Stock Price Response - Robustness Checks for RD3

This script replicates Table 1 with alternative specifications to address
referee concerns about the POST dummy variable definition.

Specifications:
1. Continuous rate (instead of POST dummy)
2. POST = 2007-2021 (excluding 2022-2024 rate hikes)
3. Moving average rate (3-year centered MA)
4. Market expectations proxy (term structure slope)

Author: Analysis for R&R response
Date: 2026-01-20
"""

#%%
import pandas as pd
import numpy as np
import pyreadstat
from linearmodels.panel import PanelOLS
import matplotlib.pyplot as plt
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# ============================================================================
# SETUP
# ============================================================================

print("="*80)
print("HIGH-FREQUENCY ROBUSTNESS CHECKS - RD3")
print("="*80)

# Define paths (matching Stata setup_paths.do)
base_path = Path(r"c:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication")
data_path = base_path / "FRRS_data" / "data"
proc_analysis = data_path / "proc_analysis"
output_tab = base_path / "FRRS_data" / "output" / "tables" / "rd2_reports"
output_fig = base_path / "FRRS_data" / "output" / "figures" / "rd2_reports"

# Create output directories if needed
output_tab.mkdir(parents=True, exist_ok=True)
output_fig.mkdir(parents=True, exist_ok=True)

#%%
# ============================================================================
# PHASE 1: LOAD DATA
# ============================================================================

print("\n[1/9] Loading maintable_data.dta and FOMC-level data...")

# Load the main analysis dataset
dta_file = proc_analysis / "maintable_data.dta"
df, meta = pyreadstat.read_dta(str(dta_file))

print(f"   - Loaded firm-level data: {len(df):,} observations")
print(f"   - Variables: {len(df.columns)}")

# Load FOMC-level data with synthetic 1Y rate and yield curve
fomc_file = proc_analysis / "master_fomc_level_24.dta"
df_fomc, meta_fomc = pyreadstat.read_dta(str(fomc_file))
print(f"   - Loaded FOMC-level data: {len(df_fomc):,} observations")

# Merge FOMC-level variables into firm-level data
fomc_vars = ['daten', 'zcoupon_1y', 'shock_2Y_30min', 'shock_10Y_30min']
df = df.merge(df_fomc[fomc_vars], on='daten', how='left')
print(f"   - Merged FOMC-level variables: {fomc_vars[1:]}")

# ============================================================================
# CONSTRUCT SYNTHETIC 1Y FORWARD RATE FROM FUTURES
# ============================================================================

print("\n   Constructing synthetic 1Y forward rate from futures...")

# Helper: Stata date to Python datetime
from datetime import datetime, timedelta
def stata_to_date(stata_date):
    if pd.isna(stata_date):
        return pd.NaT
    return datetime(1960, 1, 1) + timedelta(days=int(stata_date))

# Load FOMC timing info and Contract mappings
print("   - Loading FOMC timing and contract mappings...")
fomc_timing_file = data_path / "highfreq" / "proc" / "fomc_hour_futures_ff.dta"
df_fomc_timing, _ = pyreadstat.read_dta(str(fomc_timing_file))
df_fomc_timing['date'] = df_fomc_timing['daten'].apply(stata_to_date)

# Load ED contract mapping
ed_mapping_file = data_path / "highfreq" / "proc" / "fomc_hour_bonds_eurodollar_14_24.dta"
df_ed_map, _ = pyreadstat.read_dta(str(ed_mapping_file))
# Merge mapping into timing/main dataframe
# Look for common columns to merge on, or daten/fomc_id
# usually date is enough
df_fomc_info = df_fomc_timing.merge(
    df_ed_map[['daten', 'quarter_1_ahead', 'quarter_2_ahead', 'quarter_3_ahead']], 
    on='daten', how='left'
)

# Get list of FOMC dates (in Stata format) for filtering
fomc_dates_stata = set(df_fomc_info['daten'].dropna().astype(int).tolist())

# Load FF futures data - filter to FOMC dates only to save memory
print("   - Loading FF futures (filtering to FOMC dates)...")
ff_futures_file = data_path / "highfreq" / "proc" / "FF_futures_alltrd_95_24.dta"
df_ff, _ = pyreadstat.read_dta(str(ff_futures_file))
# Filter to FOMC dates only
df_ff = df_ff[df_ff['daten'].isin(fomc_dates_stata)].copy()
df_ff['date'] = df_ff['daten'].apply(stata_to_date)
# Convert close to implied rate (close = 100 - rate, so rate = 100 - close)
df_ff['rate'] = 100 - df_ff['close']
print(f"   - Loaded FF futures: {len(df_ff):,} obs on FOMC dates")

# Load ED futures data - chunked reading
print("   - Loading ED futures (filtering to FOMC dates in chunks)...")
ed_futures_file = data_path / "highfreq" / "proc" / "eurodollar_futures_14_24.dta"
ed_shards = []
chunksize = 5_000_000 # Read in 5M chunks to be safe but reasonable speed

# Use pandas iterator for chunked reading
try:
    with pd.read_stata(ed_futures_file, chunksize=chunksize) as reader:
        for i, chunk in enumerate(reader):
            # Filter to FOMC dates
            filtered = chunk[chunk['daten'].isin(fomc_dates_stata)].copy()
            if not filtered.empty:
                # Keep only needed columns to save memory
                # Must include 'hour', 'minute' as 'timen' is numeric/ms
                cols = ['daten', 'timen', 'exp_quarter', 'close', 'hour', 'minute']
                # ED file might have 'sofr' too, keep if useful but exp_quarter is key
                if 'sofr' in filtered.columns:
                    cols.append('sofr')
                
                # Verify columns exist
                valid_cols = [c for c in cols if c in filtered.columns]
                ed_shards.append(filtered[valid_cols])
            print(f"     Processed chunk {i+1}...", end='\r')
    
    if ed_shards:
        df_ed = pd.concat(ed_shards, ignore_index=True)
        # Convert close to rate
        if 'close' in df_ed.columns:
             df_ed['rate'] = 100 - df_ed['close']
        df_ed['date'] = df_ed['daten'].apply(stata_to_date)
        # Ensure exp_quarter is int for matching
        if 'exp_quarter' in df_ed.columns:
            df_ed['exp_quarter'] = df_ed['exp_quarter'].astype(int)
        print(f"\n   - Loaded ED futures: {len(df_ed):,} obs on FOMC dates")
    else:
        print("\n   - WARNING: No matching ED futures data found")
        df_ed = pd.DataFrame()

except Exception as e:
    print(f"\n   - ERROR loading ED futures: {e}")
    df_ed = pd.DataFrame()

# Function to get pre-shock futures rate (last trade before FOMC window)
def get_preshock_rate(futures_df, fomc_date, fomc_hour, fomc_minute, contract_id, contract_col='exp_month', lower_min=-10):
    """
    Get the pre-shock futures rate: last trade before the FOMC announcement window.
    contract_id: the expiration identifier (month for FF, quarter for ED)
    contract_col: column name to match contract_id ('exp_month' or 'exp_quarter')
    """
    if futures_df.empty:
        return np.nan

    # Filter to FOMC date and contract
    # Ensure contract_id matching works (int vs int)
    mask = (futures_df['date'] == fomc_date) & (futures_df[contract_col] == int(contract_id))
    day_data = futures_df[mask].copy()

    if len(day_data) == 0:
        return np.nan

    # FOMC time in minutes from midnight
    fomc_time_min = fomc_hour * 60 + fomc_minute
    cutoff_min = fomc_time_min + lower_min  # 10 minutes before announcement

    # Get trades before cutoff
    # Prioritize usage of explicit hour/minute columns if available
    if 'hour' in day_data.columns and 'minute' in day_data.columns:
         day_data['trade_min'] = day_data['hour'] * 60 + day_data['minute']
    else:
        # Fallback to parsing timen
        sample_timen = day_data['timen'].iloc[0] if len(day_data) > 0 else None
        
        if sample_timen is not None:
            if hasattr(sample_timen, 'hour'):
                # datetime.time object
                day_data['trade_min'] = day_data['timen'].apply(
                    lambda x: x.hour * 60 + x.minute if pd.notna(x) else np.nan
                )
            elif isinstance(sample_timen, str) and ':' in sample_timen:
                # String format HH:MM:SS
                day_data['trade_min'] = day_data['timen'].apply(
                    lambda x: int(x.split(':')[0])*60 + int(x.split(':')[1]) if pd.notna(x) and ':' in str(x) else np.nan
                )
            else:
                # Numeric format, assume unhandled if hour/minute cols missing
                return np.nan
        else:
            return np.nan

    pre_shock = day_data[day_data['trade_min'] < cutoff_min]

    if len(pre_shock) == 0:
        return np.nan

    # Return the last pre-shock rate
    # sort by trade_min to be sure we get the last one
    pre_shock = pre_shock.sort_values('trade_min')
    return pre_shock.iloc[-1]['rate']

# Compute synthetic 1Y forward rate
synthetic_rates = []

for idx, row in df_fomc_info.iterrows():
    fomc_date = row['date']
    fomc_hour = row['hour']
    fomc_minute = row['minute']
    
    # Needs for FF
    current_month = row['current_month']
    
    # Needs for ED (ED2, ED3, ED4 maps to q1, q2, q3 ahead)
    ed2_q = row['quarter_1_ahead']
    ed3_q = row['quarter_2_ahead']
    ed4_q = row['quarter_3_ahead']

    if pd.isna(fomc_date) or pd.isna(current_month) or pd.isna(ed2_q):
        synthetic_rates.append({'daten': row['daten'], 'synthetic_1y_rate': np.nan})
        continue

    # 1. FF1 (Current Month)
    r_ff1 = get_preshock_rate(df_ff, fomc_date, fomc_hour, fomc_minute, current_month, 'exp_month')
    
    # 2. FF2 (Next Month)
    next_month = int(current_month) + 1
    r_ff2 = get_preshock_rate(df_ff, fomc_date, fomc_hour, fomc_minute, next_month, 'exp_month')

    # 3. ED2, ED3, ED4
    r_ed2 = get_preshock_rate(df_ed, fomc_date, fomc_hour, fomc_minute, ed2_q, 'exp_quarter')
    r_ed3 = get_preshock_rate(df_ed, fomc_date, fomc_hour, fomc_minute, ed3_q, 'exp_quarter')
    r_ed4 = get_preshock_rate(df_ed, fomc_date, fomc_hour, fomc_minute, ed4_q, 'exp_quarter')
    
    # Check if we have all components
    rates = [r_ff1, r_ff2, r_ed2, r_ed3, r_ed4]
    if all(pd.notna(r) for r in rates):
        # Geometric chaining
        # FF1: 1 month (1/12 of year)
        # FF2: 1 month (1/12 of year)
        # ED2: 3 months (3/12)
        # ED3: 3 months (3/12)
        # ED4: 3 months (3/12)
        # Total: 1+1+3+3+3 = 11 months. Missing 1 month?
        # Actually standard construction often ignores the gap or assumes ED starts immediately after FF2?
        # A common approx for 1-year rate is just the average of these, or compounded.
        # We will compound them over their respective durations.
        
        # Convert percentages to decimals
        d_ff1 = r_ff1 / 100
        d_ff2 = r_ff2 / 100
        d_ed2 = r_ed2 / 100
        d_ed3 = r_ed3 / 100
        d_ed4 = r_ed4 / 100
        
        # Compound
        # (1 + R_1y) = (1+FF1)^(1/12) * (1+FF2)^(1/12) * (1+ED2)^(3/12) * (1+ED3)^(3/12) * (1+ED4)^(3/12)
        term = (1+d_ff1)**(1/12) * (1+d_ff2)**(1/12) * (1+d_ed2)**(0.25) * (1+d_ed3)**(0.25) * (1+d_ed4)**(0.25)
        
        # Wait: 1/12 + 1/12 + 3/12 + 3/12 + 3/12 = 11/12. 
        # To get an annualized rate over this periods effective duration?
        # Or scale to 12 months? 
        # If we interpret this as a 11-month spot rate, we can annualize it.
        # Or assumes the last month is same as ED4?
        # Let's annualize the 11-month return to 12 months.
        # (1 + R_annual) = term^(12/11).
        
        # Alternatively, using these as proxies for the 1y rate:
        # Just simple average? GSS papers use path factor.
        # But for "synthetic 1Y rate level", calculating the zero-coupon equivalent is best.
        # Let's use the annualized version of the 11-month chain.
        
        R_1y = (term**(12/11) - 1) * 100
        
        synthetic_rates.append({
            'daten': row['daten'],
            'synthetic_1y_rate': R_1y,
            'components_count': 5
        })
    else:
        # Partial construction? 
        # If we have at least some, maybe simple average?
        # Sticky point: if missing any, better to be missing than wrong.
        synthetic_rates.append({'daten': row['daten'], 'synthetic_1y_rate': np.nan})

df_synthetic = pd.DataFrame(synthetic_rates)
n_valid = df_synthetic['synthetic_1y_rate'].notna().sum()
print(f"   - Constructed synthetic 1Y rate for {n_valid}/{len(df_synthetic)} FOMC dates")
if n_valid > 0:
    print(f"   - synthetic_1y_rate: mean = {df_synthetic['synthetic_1y_rate'].mean():.3f}, range = [{df_synthetic['synthetic_1y_rate'].min():.2f}, {df_synthetic['synthetic_1y_rate'].max():.2f}]")

# Merge synthetic rate into main data
if 'synthetic_1y_rate' in df.columns:
    df = df.drop(columns=['synthetic_1y_rate'])
df = df.merge(df_synthetic[['daten', 'synthetic_1y_rate']], on='daten', how='left')

# ============================================================================
# CONSTRUCT SYNTHETIC 10Y EXPECTED RATE
# ============================================================================
# Chain: FF1, FF2 (months 1-2), ED2-4 (months 3-12), 2Y, 5Y, 10Y Treasury yields
# This gives a measure of the expected average rate environment over the next 10 years
# ============================================================================

print("\n   Constructing synthetic 10Y expected rate...")

# Load bond highfreq data for pre-shock treasury yields
print("   - Loading bond highfreq data for 2Y, 5Y, 10Y yields...")

bond_pre_file = data_path / "highfreq" / "proc" / "bond_highfreq_pre_2009_final24.dta"
bond_post_file = data_path / "highfreq" / "proc" / "bond_highfreq_post_2009_final24.dta"

df_bonds = pd.DataFrame()
try:
    # Load pre-2009
    if bond_pre_file.exists():
        df_bond_pre, _ = pyreadstat.read_dta(str(bond_pre_file))
        df_bond_pre = df_bond_pre[df_bond_pre['daten'].isin(fomc_dates_stata)].copy()
        print(f"     Pre-2009 bonds: {len(df_bond_pre):,} obs on FOMC dates")
    else:
        df_bond_pre = pd.DataFrame()
        print(f"     WARNING: {bond_pre_file} not found")

    # Load post-2009
    if bond_post_file.exists():
        df_bond_post, _ = pyreadstat.read_dta(str(bond_post_file))
        df_bond_post = df_bond_post[df_bond_post['daten'].isin(fomc_dates_stata)].copy()
        print(f"     Post-2009 bonds: {len(df_bond_post):,} obs on FOMC dates")
    else:
        df_bond_post = pd.DataFrame()
        print(f"     WARNING: {bond_post_file} not found")

    # Combine
    if not df_bond_pre.empty or not df_bond_post.empty:
        df_bonds = pd.concat([df_bond_pre, df_bond_post], ignore_index=True)
        df_bonds['date'] = df_bonds['daten'].apply(stata_to_date)
        print(f"     Combined bonds: {len(df_bonds):,} obs")
        print(f"     Maturities available: {df_bonds['mat'].unique().tolist()}")

except Exception as e:
    print(f"   - ERROR loading bond data: {e}")

def get_preshock_bond_yield(bonds_df, fomc_date, fomc_hour, fomc_minute, maturity, lower_min=-10):
    """
    Get pre-shock bond yield for a given maturity (2Y, 5Y, 10Y).
    """
    if bonds_df.empty:
        return np.nan

    # Filter to FOMC date and maturity
    mask = (bonds_df['date'] == fomc_date) & (bonds_df['mat'] == maturity)
    day_data = bonds_df[mask].copy()

    if len(day_data) == 0:
        return np.nan

    # FOMC time in minutes from midnight
    fomc_time_min = fomc_hour * 60 + fomc_minute
    cutoff_min = fomc_time_min + lower_min  # 10 minutes before announcement

    # Get trades before cutoff
    day_data['trade_min'] = day_data['hour'] * 60 + day_data['minute']
    pre_shock = day_data[day_data['trade_min'] < cutoff_min]

    if len(pre_shock) == 0:
        return np.nan

    # Return the last pre-shock yield
    pre_shock = pre_shock.sort_values('trade_min')
    return pre_shock.iloc[-1]['yield']

# Compute synthetic 10Y expected rate
synthetic_10y_rates = []

for idx, row in df_fomc_info.iterrows():
    fomc_date = row['date']
    fomc_hour = row['hour']
    fomc_minute = row['minute']
    daten = row['daten']

    # Get 1Y synthetic rate components
    current_month = row['current_month']
    ed2_q = row['quarter_1_ahead']
    ed3_q = row['quarter_2_ahead']
    ed4_q = row['quarter_3_ahead']

    if pd.isna(fomc_date) or pd.isna(current_month) or pd.isna(ed2_q):
        synthetic_10y_rates.append({'daten': daten, 'synthetic_10y_rate': np.nan})
        continue

    # 1. Get futures rates (FF1, FF2, ED2-4) for year 1
    r_ff1 = get_preshock_rate(df_ff, fomc_date, fomc_hour, fomc_minute, current_month, 'exp_month')
    next_month = int(current_month) + 1
    r_ff2 = get_preshock_rate(df_ff, fomc_date, fomc_hour, fomc_minute, next_month, 'exp_month')
    r_ed2 = get_preshock_rate(df_ed, fomc_date, fomc_hour, fomc_minute, ed2_q, 'exp_quarter')
    r_ed3 = get_preshock_rate(df_ed, fomc_date, fomc_hour, fomc_minute, ed3_q, 'exp_quarter')
    r_ed4 = get_preshock_rate(df_ed, fomc_date, fomc_hour, fomc_minute, ed4_q, 'exp_quarter')

    # 2. Get Treasury yields for years 2-10
    r_2y = get_preshock_bond_yield(df_bonds, fomc_date, fomc_hour, fomc_minute, '2Y')
    r_5y = get_preshock_bond_yield(df_bonds, fomc_date, fomc_hour, fomc_minute, '5Y')
    r_10y = get_preshock_bond_yield(df_bonds, fomc_date, fomc_hour, fomc_minute, '10Y')

    # Check if we have all components
    futures_rates = [r_ff1, r_ff2, r_ed2, r_ed3, r_ed4]
    treasury_rates = [r_2y, r_5y, r_10y]

    if all(pd.notna(r) for r in futures_rates) and all(pd.notna(r) for r in treasury_rates):
        # Chain the rates to get 10-year expected average rate
        # Approach: Use forward rates implied by the term structure
        # - Year 0-1: Use futures chain (FF1, FF2, ED2-4)
        # - Year 1-2: Implied forward from 2Y yield
        # - Year 2-5: Implied forward from 5Y yield
        # - Year 5-10: Implied forward from 10Y yield

        # Convert to decimals
        d_ff1 = r_ff1 / 100
        d_ff2 = r_ff2 / 100
        d_ed2 = r_ed2 / 100
        d_ed3 = r_ed3 / 100
        d_ed4 = r_ed4 / 100
        d_2y = r_2y / 100
        d_5y = r_5y / 100
        d_10y = r_10y / 100

        # Compute 1Y rate from futures
        term_1y = (1+d_ff1)**(1/12) * (1+d_ff2)**(1/12) * (1+d_ed2)**(0.25) * (1+d_ed3)**(0.25) * (1+d_ed4)**(0.25)
        r_1y = (term_1y**(12/11) - 1)  # annualized, in decimal

        # Implied forward rates from Treasury curve
        f_1_2 = ((1+d_2y)**2 / (1+r_1y)**1)**(1/1) - 1
        f_2_5 = ((1+d_5y)**5 / (1+d_2y)**2)**(1/3) - 1
        f_5_10 = ((1+d_10y)**10 / (1+d_5y)**5)**(1/5) - 1

        # Average expected rate over 5 years (duration-weighted)
        # Year 0-1: r_1y, Year 1-2: f_1_2, Years 2-5: f_2_5
        avg_5y_rate = (1*r_1y + 1*f_1_2 + 3*f_2_5) / 5

        # Average expected rate over 10 years (duration-weighted)
        avg_10y_rate = (1*r_1y + 1*f_1_2 + 3*f_2_5 + 5*f_5_10) / 10

        # Convert back to percentage
        R_5y = avg_5y_rate * 100
        R_10y = avg_10y_rate * 100

        synthetic_10y_rates.append({
            'daten': daten,
            'synthetic_5y_rate': R_5y,
            'synthetic_10y_rate': R_10y,
            'r_1y': r_1y * 100,
            'f_1_2': f_1_2 * 100,
            'f_2_5': f_2_5 * 100,
            'f_5_10': f_5_10 * 100
        })
    else:
        # Track which components are missing for diagnostics
        missing_futures = [name for name, val in [('FF1', r_ff1), ('FF2', r_ff2), ('ED2', r_ed2), ('ED3', r_ed3), ('ED4', r_ed4)] if pd.isna(val)]
        missing_treasury = [name for name, val in [('2Y', r_2y), ('5Y', r_5y), ('10Y', r_10y)] if pd.isna(val)]
        synthetic_10y_rates.append({
            'daten': daten,
            'synthetic_5y_rate': np.nan,
            'synthetic_10y_rate': np.nan,
            'missing_futures': ','.join(missing_futures) if missing_futures else '',
            'missing_treasury': ','.join(missing_treasury) if missing_treasury else ''
        })

df_synthetic_10y = pd.DataFrame(synthetic_10y_rates)
n_valid_5y = df_synthetic_10y['synthetic_5y_rate'].notna().sum()
n_valid_10y = df_synthetic_10y['synthetic_10y_rate'].notna().sum()
n_missing = len(df_synthetic_10y) - n_valid_10y

# Diagnostic: Show why values are missing
if n_missing > 0:
    missing_df = df_synthetic_10y[df_synthetic_10y['synthetic_10y_rate'].isna()].copy()
    if 'missing_futures' in missing_df.columns and 'missing_treasury' in missing_df.columns:
        # Count missing by component
        futures_missing_count = missing_df['missing_futures'].apply(lambda x: len(x.split(',')) if x else 0).sum()
        treasury_missing_count = missing_df['missing_treasury'].apply(lambda x: len(x.split(',')) if x else 0).sum()

        # Find most common missing components
        all_missing_futures = ','.join(missing_df['missing_futures'].dropna()).split(',')
        all_missing_treasury = ','.join(missing_df['missing_treasury'].dropna()).split(',')

        from collections import Counter
        futures_counts = Counter([x for x in all_missing_futures if x])
        treasury_counts = Counter([x for x in all_missing_treasury if x])

        print(f"   - DIAGNOSTIC: {n_missing} FOMC dates missing synthetic rates")
        if futures_counts:
            print(f"     Missing futures: {dict(futures_counts)}")
        if treasury_counts:
            print(f"     Missing treasury: {dict(treasury_counts)}")

print(f"   - Constructed synthetic 5Y rate for {n_valid_5y}/{len(df_synthetic_10y)} FOMC dates")
if n_valid_5y > 0:
    print(f"   - synthetic_5y_rate: mean = {df_synthetic_10y['synthetic_5y_rate'].mean():.3f}, range = [{df_synthetic_10y['synthetic_5y_rate'].min():.2f}, {df_synthetic_10y['synthetic_5y_rate'].max():.2f}]")
print(f"   - Constructed synthetic 10Y rate for {n_valid_10y}/{len(df_synthetic_10y)} FOMC dates")
if n_valid_10y > 0:
    print(f"   - synthetic_10y_rate: mean = {df_synthetic_10y['synthetic_10y_rate'].mean():.3f}, range = [{df_synthetic_10y['synthetic_10y_rate'].min():.2f}, {df_synthetic_10y['synthetic_10y_rate'].max():.2f}]")

# Merge synthetic 5Y and 10Y rates into main data
for col in ['synthetic_5y_rate', 'synthetic_10y_rate']:
    if col in df.columns:
        df = df.drop(columns=[col])
df = df.merge(df_synthetic_10y[['daten', 'synthetic_5y_rate', 'synthetic_10y_rate']], on='daten', how='left')

# ============================================================================
# LOAD DGS2 FROM FRED
# ============================================================================
print("\n   Loading DGS2 (2-Year Treasury Yield) from FRED...")
try:
    url = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=DGS2"
    # Use pandas to read directly
    df_dgs2 = pd.read_csv(url)
    df_dgs2['date'] = pd.to_datetime(df_dgs2['observation_date'])
    # DGS2 has '.' for missing values
    df_dgs2['DGS2'] = pd.to_numeric(df_dgs2['DGS2'], errors='coerce')
    
    # Create Stata date for merging (days since 1960-01-01)
    base_date = datetime(1960, 1, 1)
    df_dgs2['daten'] = (df_dgs2['date'] - base_date).dt.days
    
    # Merge into main df
    if 'DGS2' in df.columns:
        df = df.drop(columns=['DGS2'])
        
    df = df.merge(df_dgs2[['daten', 'DGS2']], on='daten', how='left')
    
    # Check coverage
    n_dgs2 = df['DGS2'].notna().sum()
    print(f"   - Loaded and merged DGS2: {n_dgs2:,} non-missing observations")
    if n_dgs2 > 0:
         print(f"     Mean: {df['DGS2'].mean():.2f}, Min: {df['DGS2'].min():.2f}, Max: {df['DGS2'].max():.2f}")

except Exception as e:
    print(f"   - ERROR loading DGS2: {e}")

# ============================================================================
# LOAD EXPECTATIONS COMPONENTS (DGS3MO, T10Y3M, TERM PREMIUM)
# ============================================================================
print("\n   Loading Rate Expectation Components (DGS3MO, T10Y3M, Term Premium)...")
try:
    # 1. DGS3MO
    url_3mo = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=DGS3MO"
    df_3mo = pd.read_csv(url_3mo)
    df_3mo['date'] = pd.to_datetime(df_3mo['observation_date'])
    df_3mo['DGS3MO'] = pd.to_numeric(df_3mo['DGS3MO'], errors='coerce')
    df_3mo['daten'] = (df_3mo['date'] - datetime(1960, 1, 1)).dt.days
    
    # 2. T10Y3M
    url_spr = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=T10Y3M"
    df_spr = pd.read_csv(url_spr)
    df_spr['date'] = pd.to_datetime(df_spr['observation_date'])
    df_spr['T10Y3M'] = pd.to_numeric(df_spr['T10Y3M'], errors='coerce')
    df_spr['daten'] = (df_spr['date'] - datetime(1960, 1, 1)).dt.days
    
    # 3. Term Premium (Try THREEFYTP10 as proxy for ACMTP10 if unavailable)
    # Using Kim-Wright 10Y Term Premium (THREEFYTP10) which is available on FRED
    url_tp = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=THREEFYTP10" 
    df_tp = pd.read_csv(url_tp)
    df_tp['date'] = pd.to_datetime(df_tp['observation_date'])
    df_tp['TP10'] = pd.to_numeric(df_tp['THREEFYTP10'], errors='coerce')
    df_tp['daten'] = (df_tp['date'] - datetime(1960, 1, 1)).dt.days
    
    # Merge all
    for sub_df in [df_3mo, df_spr, df_tp]:
        cols = [c for c in sub_df.columns if c not in ['date', 'observation_date', 'THREEFYTP10']]
        # merge on daten (drop if exists)
        for c in cols:
            if c != 'daten' and c in df.columns:
                df = df.drop(columns=[c])
        df = df.merge(sub_df[cols], on='daten', how='left')
        
    # Compute Rate Expectations
    # rate_expectations = (DGS3MO + T10Y3M) - ACMTP10
    # Here we use TP10 (THREEFYTP10) as proxy
    df['rate_expectations'] = (df['DGS3MO'] + df['T10Y3M']) - df['TP10']
    
    n_exp = df['rate_expectations'].notna().sum()
    print(f"   - Constructed rate_expectations: {n_exp:,} observations")
    if n_exp > 0:
        print(f"     Mean: {df['rate_expectations'].mean():.2f}")
        
except Exception as e:
    print(f"   - ERROR constructing rate expectations: {e}")

#%%
# ============================================================================
# PHASE 2: EXPLORE AVAILABLE VARIABLES
# ============================================================================

print("\n[2/9] Exploring available variables...")

# Key variables we need
required_vars = ['shock_hf_30min', 'mp_klms_U', 'ptile_consis', 'post',
                 'permno', 'daten', 'unscheduled_meetings', 'year']

# Check which required variables exist
missing_vars = [v for v in required_vars if v not in df.columns]
if missing_vars:
    print(f"   WARNING: Missing variables: {missing_vars}")
    print(f"   Available variables: {sorted(df.columns.tolist())[:20]}...")
else:
    print(f"   - All required variables present")

# Check for rate-related variables
rate_vars = [col for col in df.columns if any(x in col.lower() for x in ['target', 'rate', 'ff', 'funds'])]
print(f"   - Found rate variables: {rate_vars[:10]}")

# Display basic summary
print(f"\n   Sample period: {df['year'].min():.0f} - {df['year'].max():.0f}")
print(f"   Unique firms: {df['permno'].nunique():,}")
print(f"   Unique dates: {df['daten'].nunique():,}")

# Filter to scheduled meetings
df_sched = df[df['unscheduled_meetings'] != 1].copy()
print(f"   - After filtering to scheduled meetings: {len(df_sched):,} obs")

#%%
# ============================================================================
# PHASE 3: CREATE ALTERNATIVE POST/RATE VARIABLES
# ============================================================================

print("\n[3/9] Creating alternative POST/rate variables...")

# Original POST (already in data): 1 if year >= 2007
df_sched['post_original'] = df_sched['post'].copy()
print(f"   - post_original: mean = {df_sched['post_original'].mean():.3f}")

# Spec 2: Alternative POST (2007-2021 only)
df_sched['post_alt'] = ((df_sched['year'] >= 2007) & (df_sched['year'] <= 2021)).astype(float)
print(f"   - post_alt (2007-2021): mean = {df_sched['post_alt'].mean():.3f}")

# Check if 'target' exists for Spec 1 and 3
if 'target' in df_sched.columns:
    print(f"   - target (fed funds rate): mean = {df_sched['target'].mean():.3f}, range = [{df_sched['target'].min():.2f}, {df_sched['target'].max():.2f}]")

    # Spec 3: 3-year centered moving average
    # Group by date and compute MA across time
    df_sched = df_sched.sort_values(['daten'])
    df_temp = df_sched.groupby('daten')['target'].first().reset_index()
    df_temp['target_ma3'] = df_temp['target'].rolling(window=3, center=True, min_periods=1).mean()
    df_sched = df_sched.merge(df_temp[['daten', 'target_ma3']], on='daten', how='left')
    print(f"   - target_ma3 (3-year MA): mean = {df_sched['target_ma3'].mean():.3f}")

    # Spec 3b: 5-year forward-looking moving average (shock year + 4 following years)
    # First create year-level average rates
    df_year_avg = df_sched.groupby('year')['target'].mean().reset_index()
    df_year_avg.columns = ['year', 'target_year_avg']

    # Compute forward MAs
    df_year_avg = df_year_avg.sort_values('year')
    df_year_avg['target_ma3_forward'] = df_year_avg['target_year_avg'].rolling(window=3, min_periods=1).mean()
    df_year_avg['target_ma5_forward'] = df_year_avg['target_year_avg'].rolling(window=5, min_periods=1).mean()
    df_year_avg['target_ma10_forward'] = df_year_avg['target_year_avg'].rolling(window=10, min_periods=1).mean()

    # Compute 5-year backward MA (current year + 4 preceding years)
    df_year_avg['target_ma5_backward'] = df_year_avg['target_year_avg'].shift(4).rolling(window=5, min_periods=1).mean()

    # Compute rate growth: forward MA - backward MA
    df_year_avg['rate_growth_5y'] = df_year_avg['target_ma5_forward'] - df_year_avg['target_ma5_backward']

    # Merge back to main data
    df_sched = df_sched.merge(df_year_avg[['year', 'target_ma3_forward', 'target_ma5_forward', 'target_ma10_forward', 'rate_growth_5y']], on='year', how='left')
    print(f"   - target_ma3_forward (3-year forward MA): mean = {df_sched['target_ma3_forward'].mean():.3f}")
    print(f"   - target_ma5_forward (5-year forward MA): mean = {df_sched['target_ma5_forward'].mean():.3f}")
    print(f"   - target_ma10_forward (10-year forward MA): mean = {df_sched['target_ma10_forward'].mean():.3f}")
    print(f"   - rate_growth_5y (5Y forward MA - 5Y backward MA): mean = {df_sched['rate_growth_5y'].mean():.3f}, range = [{df_sched['rate_growth_5y'].min():.2f}, {df_sched['rate_growth_5y'].max():.2f}]")

    # Spec 4a: Synthetic 1-year forward rate (from futures construction)
    # This is constructed from FF1, FF2, ED2, ED3, ED4 futures prices
    if 'synthetic_1y_rate' in df_sched.columns:
        n_valid = df_sched['synthetic_1y_rate'].notna().sum()
        print(f"   - synthetic_1y_rate (futures-based 1Y fwd): {n_valid:,} valid obs, mean = {df_sched['synthetic_1y_rate'].mean():.3f}, range = [{df_sched['synthetic_1y_rate'].min():.2f}, {df_sched['synthetic_1y_rate'].max():.2f}]")
    else:
        print("   WARNING: 'synthetic_1y_rate' not found in merged data")

    # Spec 4b: Simple term slope proxy
    # Use the difference between synthetic 1Y rate and current target as a slope measure
    # This captures whether expected rates (1Y ahead) are above/below current policy rate
    if 'synthetic_1y_rate' in df_sched.columns and 'target' in df_sched.columns:
        df_sched['rate_slope'] = df_sched['synthetic_1y_rate'] - df_sched['target']
        n_valid = df_sched['rate_slope'].notna().sum()
        print(f"   - rate_slope (1Y fwd - current target): {n_valid:,} valid obs, mean = {df_sched['rate_slope'].mean():.3f}, range = [{df_sched['rate_slope'].min():.2f}, {df_sched['rate_slope'].max():.2f}]")
    else:
        print("   WARNING: Cannot create rate_slope - missing synthetic_1y_rate or target")

    # Spec 4c: Synthetic 5-year expected rate (FF1, FF2, ED2-4, 2Y, 5Y Treasury)
    if 'synthetic_5y_rate' in df_sched.columns:
        n_valid = df_sched['synthetic_5y_rate'].notna().sum()
        print(f"   - synthetic_5y_rate (5Y expected avg rate): {n_valid:,} valid obs, mean = {df_sched['synthetic_5y_rate'].mean():.3f}, range = [{df_sched['synthetic_5y_rate'].min():.2f}, {df_sched['synthetic_5y_rate'].max():.2f}]")
    else:
        print("   WARNING: 'synthetic_5y_rate' not found in merged data")

    # Spec 4d: Synthetic 10-year expected rate (FF1, FF2, ED2-4, 2Y, 5Y, 10Y Treasury)
    # This is the average expected rate over the next 10 years
    if 'synthetic_10y_rate' in df_sched.columns:
        n_valid = df_sched['synthetic_10y_rate'].notna().sum()
        print(f"   - synthetic_10y_rate (10Y expected avg rate): {n_valid:,} valid obs, mean = {df_sched['synthetic_10y_rate'].mean():.3f}, range = [{df_sched['synthetic_10y_rate'].min():.2f}, {df_sched['synthetic_10y_rate'].max():.2f}]")
    else:
        print("   WARNING: 'synthetic_10y_rate' not found in merged data")
else:
    print("   WARNING: 'target' variable not found. Checking alternative names...")
    # Try to find it with alternative names
    alt_names = ['l_target', 'ffr', 'fed_funds_rate', 'effective_rate']
    found = False
    for alt in alt_names:
        if alt in df_sched.columns:
            df_sched['target'] = df_sched[alt]
            print(f"   - Using '{alt}' as target rate")
            found = True
            break
    if not found:
        print("   ERROR: No rate variable found. Specs 1 and 3 will be skipped.")

# Store working dataframe
df_work = df_sched.copy()

print(f"\n   Final working sample: {len(df_work):,} observations")

# Save sandbox data for analysis
sandbox_dir = Path(__file__).parent.parent.parent / "FRRS_data" / "sandbox_jan26"
sandbox_dir.mkdir(parents=True, exist_ok=True)
sandbox_file = sandbox_dir / "sandbox_data.csv"
df_work.to_csv(sandbox_file, index=False)
print(f"\n   Saved sandbox data to: {sandbox_file}")

# Save daily (FOMC-level) data with key rate measures and shock variable
print("\n   Saving daily FOMC-level rate data...")
fomc_rate_cols = ['daten', 'mp_klms_U', 'target_ma5_forward', 'target_ma10_forward',
                  'synthetic_5y_rate', 'synthetic_10y_rate']
# Filter to columns that exist
existing_cols = [c for c in fomc_rate_cols if c in df_work.columns]
missing_cols = [c for c in fomc_rate_cols if c not in df_work.columns]
if missing_cols:
    print(f"   - Warning: Missing columns: {missing_cols}")

# Get unique FOMC dates with these variables
df_fomc_daily = df_work[existing_cols].drop_duplicates(subset=['daten']).sort_values('daten')
fomc_daily_file = sandbox_dir / "fomc_daily_rates.csv"
df_fomc_daily.to_csv(fomc_daily_file, index=False)
print(f"   - Saved {len(df_fomc_daily)} FOMC dates to: {fomc_daily_file}")
print(f"   - Columns: {existing_cols}")

#%%
# ============================================================================
# PHASE 4: REGRESSION FUNCTION
# ============================================================================

def run_specification(df, post_var_name, spec_label, include_post_term=True,
                      extra_controls=None, sample_filter=None, quiet=False):
    """
    Run panel regression with firm FEs and clustered SEs

    Parameters:
    - df: DataFrame with panel structure
    - post_var_name: Name of POST/rate variable
    - spec_label: Description for output
    - include_post_term: Whether to include the post/rate variable directly
    - extra_controls: List of additional control variable names to include
    - sample_filter: Boolean mask to filter sample before regression
    - quiet: If True, suppress detailed output

    Returns:
    - results object, sample size, R-squared
    """
    if not quiet:
        print(f"\n{'='*60}")
        print(f"{spec_label}")
        print('='*60)

    # Create a clean working copy
    df_reg = df.copy()

    # Apply sample filter if provided
    if sample_filter is not None:
        df_reg = df_reg[sample_filter].copy()

    # Drop rows with missing values in key variables
    key_vars = ['shock_hf_30min', 'mp_klms_U', 'ptile_consis', post_var_name, 'permno', 'daten']
    df_reg = df_reg.dropna(subset=key_vars)

    if not quiet:
        print(f"Sample size after dropping missing: {len(df_reg):,}")

    # Generate interaction terms
    df_reg['omega_rank'] = df_reg['mp_klms_U'] * df_reg['ptile_consis']
    df_reg[f'omega_{post_var_name}'] = df_reg['mp_klms_U'] * df_reg[post_var_name]
    df_reg[f'omega_rank_{post_var_name}'] = df_reg['mp_klms_U'] * df_reg['ptile_consis'] * df_reg[post_var_name]

    # Generate window length interactions if window_shock_hf_30min is in extra_controls
    if extra_controls and 'window_shock_hf_30min' in extra_controls:
        df_reg['WLxSHOCK'] = df_reg['window_shock_hf_30min'] * df_reg['mp_klms_U']
        df_reg['WLxPOST'] = df_reg['window_shock_hf_30min'] * df_reg[post_var_name]
        df_reg['WLxFPTILE'] = df_reg['window_shock_hf_30min'] * df_reg['ptile_consis']
        df_reg['WLxTRIPLE'] = df_reg['window_shock_hf_30min'] * df_reg[f'omega_rank_{post_var_name}']

    # Specify exogenous variables
    if include_post_term:
        exog_vars = ['mp_klms_U', 'omega_rank', f'omega_{post_var_name}',
                     f'omega_rank_{post_var_name}', post_var_name]
    else:
        exog_vars = ['mp_klms_U', 'omega_rank', f'omega_{post_var_name}',
                     f'omega_rank_{post_var_name}']

    # Add extra controls
    if extra_controls:
        exog_vars.extend(extra_controls)

    # Set panel index (firm-date) - linearmodels requires MultiIndex with (entity, time)
    df_reg = df_reg.set_index(['permno', 'daten'])

    # Prepare dependent and independent variables
    y = df_reg['shock_hf_30min']
    X = df_reg[exog_vars]

    # Run panel OLS with firm fixed effects
    mod = PanelOLS(y, X, entity_effects=True, drop_absorbed=True)

    # Fit with clustered SEs at FOMC date level
    # For linearmodels, clusters should be passed as DataFrame/Series with matching index
    res = mod.fit(cov_type='clustered', cluster_time=True)

    # Extract summary stats
    n_obs = res.nobs
    r2 = res.rsquared

    if not quiet:
        print(f"\nResults:")
        print(f"  N = {n_obs:,}")
        print(f"  R² = {r2:.4f}")
        print(f"  Number of firms = {df_reg.index.get_level_values('permno').nunique():,}")
        print(f"  Number of dates = {df_reg.index.get_level_values('daten').nunique():,}")

        print(f"\nCoefficients:")
        for param in res.params.index:
            coef = res.params[param]
            se = res.std_errors[param]
            pval = res.pvalues[param]
            stars = '***' if pval < 0.01 else '**' if pval < 0.05 else '*' if pval < 0.10 else ''
            print(f"  {param:30s}: {coef:8.4f}{stars:3s}  (SE: {se:.4f}, p: {pval:.4f})")

    return res, n_obs, r2

#%%
# ============================================================================
# PHASE 5-8: RUN ALL SPECIFICATIONS
# ============================================================================

results_dict = {}

# Baseline: Replicate original Table 1 with POST dummy
print("\n[4/9] BASELINE: Original POST dummy (year >= 2007)...")
try:
    res, n, r2 = run_specification(df_work, 'post_original', 'BASELINE: POST (year >= 2007)')
    results_dict['Baseline: POST (≥2007)'] = {'res': res, 'n': n, 'r2': r2}
except Exception as e:
    print(f"ERROR in baseline: {e}")

# Spec 1: Continuous rate
print("\n[5/9] SPEC 1: Continuous federal funds rate...")
if 'target' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'target', 'SPEC 1: Continuous Rate')
        results_dict['Spec 1: Continuous Rate'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 1: {e}")
else:
    print("SKIPPED: No target rate variable available")

# Spec 2: Alternative POST (2007-2021)
print("\n[6/9] SPEC 2: POST = 2007-2021...")
try:
    res, n, r2 = run_specification(df_work, 'post_alt', 'SPEC 2: POST (2007-2021)')
    results_dict['Spec 2: POST (2007-2021)'] = {'res': res, 'n': n, 'r2': r2}
except Exception as e:
    print(f"ERROR in Spec 2: {e}")

# Spec 3: Moving average rate
print("\n[7/9] SPEC 3: 3-year moving average rate...")
if 'target_ma3' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'target_ma3', 'SPEC 3: 3-Year MA Rate')
        results_dict['Spec 3: 3-Year MA Rate'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 3: {e}")
else:
    print("SKIPPED: No moving average variable created")

# Spec 3a: 3-year forward moving average
print("\n[8/12] SPEC 3a: 3-year forward moving average rate...")
if 'target_ma3_forward' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'target_ma3_forward', 'SPEC 3a: 3-Year Forward MA Rate')
        results_dict['Spec 3a: 3-Year Forward MA'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 3a: {e}")
else:
    print("SKIPPED: No 3-year forward MA variable created")

# Spec 3b: 5-year forward moving average
print("\n[9/12] SPEC 3b: 5-year forward moving average rate...")
if 'target_ma5_forward' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'target_ma5_forward', 'SPEC 3b: 5-Year Forward MA Rate')
        results_dict['Spec 3b: 5-Year Forward MA'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 3b: {e}")
else:
    print("SKIPPED: No 5-year moving average variable created")

# Spec 3c: Rate growth (5Y forward MA - 5Y backward MA)
print("\n[10/12] SPEC 3c: Rate growth (5Y forward - 5Y backward MA)...")
if 'rate_growth_5y' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'rate_growth_5y', 'SPEC 3c: Rate Growth (5Y Fwd - 5Y Back)')
        results_dict['Spec 3c: Rate Growth'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 3c: {e}")
else:
    print("SKIPPED: No rate growth variable created")

# Spec 3d: 10-year forward moving average
print("\n[11/12] SPEC 3d: 10-year forward moving average rate...")
if 'target_ma10_forward' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'target_ma10_forward', 'SPEC 3d: 10-Year Forward MA Rate')
        results_dict['Spec 3d: 10-Year Forward MA'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 3d: {e}")
else:
    print("SKIPPED: No 10-year moving average variable created")

# Spec 4a: Synthetic 1-year forward rate (futures-based)
print("\n[12/17] SPEC 4a: Synthetic 1-year forward rate (futures-based)...")
if 'synthetic_1y_rate' in df_work.columns and df_work['synthetic_1y_rate'].notna().sum() > 0:
    try:
        res, n, r2 = run_specification(df_work, 'synthetic_1y_rate', 'SPEC 4a: Synthetic 1Y Forward Rate (Futures)')
        results_dict['Spec 4a: Synthetic 1Y Fwd Rate'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 4a: {e}")
else:
    print("SKIPPED: No synthetic_1y_rate variable found or all values missing")

# Spec 4b: 2-Year Treasury Yield (DGS2)
print("\n[13/16] SPEC 4b: 2-Year Treasury Yield (DGS2)...")
if 'DGS2' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'DGS2', 'SPEC 4b: 2-Year Yield')
        results_dict['Spec 4b: 2-Year Yield'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 4b: {e}")
else:
    print("SKIPPED: No DGS2 variable available")

# Spec 4c: Synthetic 5-year expected rate (FF1, FF2, ED2-4, 2Y, 5Y Treasury)
print("\n[14/18] SPEC 4c: Synthetic 5-Year Expected Rate...")
if 'synthetic_5y_rate' in df_work.columns and df_work['synthetic_5y_rate'].notna().sum() > 0:
    try:
        res, n, r2 = run_specification(df_work, 'synthetic_5y_rate', 'SPEC 4c: Synthetic 5Y Expected Rate')
        results_dict['Spec 4c: Synthetic 5Y Rate'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 4c: {e}")
else:
    print("SKIPPED: No synthetic_5y_rate variable found or all values missing")

# Spec 4d: Synthetic 10-year expected rate (FF1, FF2, ED2-4, 2Y, 5Y, 10Y Treasury)
print("\n[15/18] SPEC 4d: Synthetic 10-Year Expected Rate...")
if 'synthetic_10y_rate' in df_work.columns and df_work['synthetic_10y_rate'].notna().sum() > 0:
    try:
        res, n, r2 = run_specification(df_work, 'synthetic_10y_rate', 'SPEC 4d: Synthetic 10Y Expected Rate')
        results_dict['Spec 4d: Synthetic 10Y Rate'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 4d: {e}")
else:
    print("SKIPPED: No synthetic_10y_rate variable found or all values missing")

# Spec 5: Rate Expectations (Model-Based)
print("\n[16/18] SPEC 5: Rate Expectations (Risk-Neutral Yield)...")
if 'rate_expectations' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'rate_expectations', 'SPEC 5: Rate Expectations (10Y - Term Prem)')
        results_dict['Spec 5: Rate Exp'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 5: {e}")
else:
    print("SKIPPED: No rate_expectations variable available")

# Spec 6: Term Premium Only (Risk Proxy) 
# There is a positive coeff on the term premium interaction
# This means as term premia go up, ie perceived risk increases, the differential effect is attentuated (?)
# So the 10Y MA is not just about a super strong response in periods of high fear right before long rate cuts (?)
                                                                                                             
print("\n[17/18] SPEC 6: Term Premium (Kim-Wright 10Y)...")
if 'TP10' in df_work.columns:
    try:
        res, n, r2 = run_specification(df_work, 'TP10', 'SPEC 6: Term Premium (Kim-Wright 10Y)')
        results_dict['Spec 6: Term Premium'] = {'res': res, 'n': n, 'r2': r2}
    except Exception as e:
        print(f"ERROR in Spec 6: {e}")
else:
    print("SKIPPED: No TP10 variable available")

# ============================================================================
# PHASE 14: CREATE SUMMARY TABLE
# ============================================================================

print("\n[16/16] Creating summary table...")

if results_dict:
    # Extract coefficients for comparison table
    summary_rows = []

    for spec_name, spec_data in results_dict.items():
        res = spec_data['res']
        n = spec_data['n']
        r2 = spec_data['r2']

        row = {'Specification': spec_name, 'N': n, 'R²': r2}

        # Extract key coefficients
        params = res.params
        ses = res.std_errors
        pvals = res.pvalues

        for param in params.index:
            coef = params[param]
            se = ses[param]
            pval = pvals[param]
            stars = '***' if pval < 0.01 else '**' if pval < 0.05 else '*' if pval < 0.10 else ''

            # Format as "coef*** (se)"
            row[param] = f"{coef:.4f}{stars} ({se:.4f})"

        summary_rows.append(row)

    summary_df = pd.DataFrame(summary_rows)

    # Save to CSV
    output_file = output_tab / "table1_robustness_summary.csv"
    summary_df.to_csv(output_file, index=False)
    print(f"\nSummary table saved to: {output_file}")

    # Display summary (use ASCII-safe representation)
    print("\n" + "="*80)
    print("SUMMARY OF RESULTS")
    print("="*80)
    # Replace unicode characters for console display
    summary_str = summary_df.to_string(index=False).replace('≥', '>=')
    print(summary_str)

    # Save detailed output (use UTF-8 encoding to handle special characters)
    detail_file = output_tab / "table1_robustness_detailed.txt"
    with open(detail_file, 'w', encoding='utf-8') as f:
        f.write("="*80 + "\n")
        f.write("HIGH-FREQUENCY ROBUSTNESS CHECKS - DETAILED OUTPUT\n")
        f.write("="*80 + "\n\n")

        for spec_name, spec_data in results_dict.items():
            # Replace unicode characters for file output
            spec_name_clean = spec_name.replace('≥', '>=')
            f.write(f"\n{'='*60}\n")
            f.write(f"{spec_name_clean}\n")
            f.write(f"{'='*60}\n")
            f.write(spec_data['res'].summary.as_text())
            f.write("\n\n")

    print(f"Detailed results saved to: {detail_file}")

    print("\n" + "="*80)
    print("ANALYSIS COMPLETE")
    print("="*80)
    print(f"Total specifications run: {len(results_dict)}")

else:
    print("\nERROR: No specifications completed successfully")



#### Alternative approach (for later) -- try controlling for ACMTP10, te Adian Crump Moench term premium. 








#%% 
# Add window length robustness version

# ============================================================================
# WINDOW LENGTH ROBUSTNESS TABLE
# ============================================================================
# This replicates section (6) of analysis_KLMS.do but uses the moving average
# specification (target_ma3) instead of the POST dummy.
#
# Columns:
# 1. Baseline (no WL controls)
# 2. + window_shock_hf_30min, WLxSHOCK
# 3. + WLxPOST
# 4. + WLxFPTILE
# 5. + WLxTRIPLE
# 6. Drop WL > p90
# 7. Drop WL > p75
# 8. Drop WL > p50
# ============================================================================

print("\n" + "="*80)
print("WINDOW LENGTH ROBUSTNESS TABLE")
print("="*80)

# Check for window_shock_hf_30min variable
if 'window_shock_hf_30min' not in df_work.columns:
    print("ERROR: 'window_shock_hf_30min' not found in data. Cannot run window length robustness.")
else:
    rate_var = 'target_ma5_forward'  # Using 5-year forward MA rate for this robustness check

    if rate_var not in df_work.columns:
        print(f"ERROR: '{rate_var}' not found. Cannot run window length robustness.")
    else:
        print(f"\nUsing rate variable: {rate_var}")
        print(f"Window length variable: window_shock_hf_30min")

        # Compute window length percentiles
        wl_p90 = df_work['window_shock_hf_30min'].quantile(0.90)
        wl_p75 = df_work['window_shock_hf_30min'].quantile(0.75)
        wl_p50 = df_work['window_shock_hf_30min'].quantile(0.50)

        print(f"\nWindow length percentiles:")
        print(f"   p50 = {wl_p50:.1f} min")
        print(f"   p75 = {wl_p75:.1f} min")
        print(f"   p90 = {wl_p90:.1f} min")

        wl_results = {}

        # Column 1: Baseline (no WL controls)
        print("\n[WL-1/8] Baseline (no window length controls)...")
        try:
            res, n, r2 = run_specification(df_work, rate_var, 'WL Baseline', quiet=True)
            wl_results['(1) Baseline'] = {'res': res, 'n': n, 'r2': r2, 'controls': 'None'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 2: + window_shock_hf_30min, WLxSHOCK
        print("\n[WL-2/8] Adding window length + WLxSHOCK...")
        try:
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL +WLxSHOCK',
                extra_controls=['window_shock_hf_30min', 'WLxSHOCK'], quiet=True
            )
            wl_results['(2) +WL,WLxSHOCK'] = {'res': res, 'n': n, 'r2': r2, 'controls': 'WL, WLxSHOCK'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 3: + WLxPOST
        print("\n[WL-3/8] Adding WLxPOST...")
        try:
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL +WLxPOST',
                extra_controls=['window_shock_hf_30min', 'WLxSHOCK', 'WLxPOST'], quiet=True
            )
            wl_results['(3) +WLxPOST'] = {'res': res, 'n': n, 'r2': r2, 'controls': 'WL, WLxSHOCK, WLxPOST'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 4: + WLxFPTILE
        print("\n[WL-4/8] Adding WLxFPTILE...")
        try:
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL +WLxFPTILE',
                extra_controls=['window_shock_hf_30min', 'WLxSHOCK', 'WLxPOST', 'WLxFPTILE'], quiet=True
            )
            wl_results['(4) +WLxFPTILE'] = {'res': res, 'n': n, 'r2': r2, 'controls': 'WL, WLxSHOCK, WLxPOST, WLxFPTILE'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 5: + WLxTRIPLE
        print("\n[WL-5/8] Adding WLxTRIPLE...")
        try:
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL +WLxTRIPLE',
                extra_controls=['window_shock_hf_30min', 'WLxSHOCK', 'WLxPOST', 'WLxFPTILE', 'WLxTRIPLE'], quiet=True
            )
            wl_results['(5) +WLxTRIPLE'] = {'res': res, 'n': n, 'r2': r2, 'controls': 'All WL interactions'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 6: Drop WL > p90
        print("\n[WL-6/8] Drop window length > p90...")
        try:
            sample_p90 = df_work['window_shock_hf_30min'] <= wl_p90
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL Drop>p90',
                sample_filter=sample_p90, quiet=True
            )
            wl_results['(6) Drop>p90'] = {'res': res, 'n': n, 'r2': r2, 'controls': f'Drop WL>{wl_p90:.0f}min'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 7: Drop WL > p75
        print("\n[WL-7/8] Drop window length > p75...")
        try:
            sample_p75 = df_work['window_shock_hf_30min'] <= wl_p75
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL Drop>p75',
                sample_filter=sample_p75, quiet=True
            )
            wl_results['(7) Drop>p75'] = {'res': res, 'n': n, 'r2': r2, 'controls': f'Drop WL>{wl_p75:.0f}min'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Column 8: Drop WL > p50
        print("\n[WL-8/8] Drop window length > p50...")
        try:
            sample_p50 = df_work['window_shock_hf_30min'] <= wl_p50
            res, n, r2 = run_specification(
                df_work, rate_var, 'WL Drop>p50',
                sample_filter=sample_p50, quiet=True
            )
            wl_results['(8) Drop>p50'] = {'res': res, 'n': n, 'r2': r2, 'controls': f'Drop WL>{wl_p50:.0f}min'}
            print(f"   N = {n:,}, R2 = {r2:.4f}")
        except Exception as e:
            print(f"   ERROR: {e}")

        # Create summary table
        if wl_results:
            print("\n" + "="*80)
            print("WINDOW LENGTH ROBUSTNESS - SUMMARY")
            print("="*80)

            triple_var = f'omega_rank_{rate_var}'

            wl_summary_rows = []
            for spec_name, spec_data in wl_results.items():
                res = spec_data['res']
                row = {
                    'Specification': spec_name,
                    'N': spec_data['n'],
                    'R2': spec_data['r2'],
                    'Controls': spec_data['controls']
                }

                if triple_var in res.params.index:
                    coef = res.params[triple_var]
                    se = res.std_errors[triple_var]
                    pval = res.pvalues[triple_var]
                    stars = '***' if pval < 0.01 else '**' if pval < 0.05 else '*' if pval < 0.10 else ''
                    row['Triple Coef'] = f"{coef:.4f}{stars}"
                    row['Triple SE'] = f"({se:.4f})"

                wl_summary_rows.append(row)

            wl_summary_df = pd.DataFrame(wl_summary_rows)

            print("\nTriple Interaction Coefficient (omega * rank * rate):")
            print(wl_summary_df.to_string(index=False))

            # Save to CSV
            wl_output_file = output_tab / "table_wl_robustness_ma3.csv"
            wl_summary_df.to_csv(wl_output_file, index=False)
            print(f"\nWindow length robustness table saved to: {wl_output_file}")

            # Save detailed output
            wl_detail_file = output_tab / "table_wl_robustness_ma3_detailed.txt"
            with open(wl_detail_file, 'w', encoding='utf-8') as f:
                f.write("="*80 + "\n")
                f.write("WINDOW LENGTH ROBUSTNESS TABLE - DETAILED OUTPUT\n")
                f.write(f"Rate Variable: {rate_var}\n")
                f.write("="*80 + "\n\n")

                f.write(f"Window length percentiles:\n")
                f.write(f"   p50 = {wl_p50:.1f} min\n")
                f.write(f"   p75 = {wl_p75:.1f} min\n")
                f.write(f"   p90 = {wl_p90:.1f} min\n\n")

                for spec_name, spec_data in wl_results.items():
                    f.write(f"\n{'='*60}\n")
                    f.write(f"{spec_name}\n")
                    f.write(f"Controls: {spec_data['controls']}\n")
                    f.write(f"{'='*60}\n")
                    f.write(spec_data['res'].summary.as_text())
                    f.write("\n\n")

            print(f"Detailed results saved to: {wl_detail_file}")

print("\n" + "="*80)
print("WINDOW LENGTH ROBUSTNESS ANALYSIS COMPLETE")
print("="*80)




























