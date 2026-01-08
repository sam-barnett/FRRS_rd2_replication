*bootstrap python file 

python:
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

def regress(data, yvar, xvar):
    # keep permno so we can group on it
    sub = data[[yvar, xvar, "permno"]].replace([np.inf, -np.inf], np.nan).dropna()
    # within-demean
    y_w = sub[yvar] - sub.groupby("permno")[yvar].transform("mean")
    x_w = sub[xvar] - sub.groupby("permno")[xvar].transform("mean")
    # sklearn fit
    lr = LinearRegression(fit_intercept=False).fit(x_w.values.reshape(-1,1), y_w.values)
    return lr.coef_[0]

def one_bootstrap():
    # Getting sampled placebo days
    sampled_days = fomc_trimmed.groupby('fomc_id').apply(lambda x: x.sample(1), include_groups=False).reset_index(drop=True).loc[:, "daten"]
    # Keeping only placebo obs
    placebo_df = pd.merge(df, sampled_days, on='daten', how='inner')
    # Actually getting the coefficient
    coefficients_df = regress(placebo_df, "shock_hf_30min", "mp_klms_placebo")
    print(coefficients_df)
    return coefficients_df

# Load and prep dataset
df_raw = pd.read_stata("master_daily_placebo_calculation_UPDATE.dta")
df_original = df_raw.copy()

# Getting the FOMC groups
fomc_df = df_original.loc[:, ["daten", "fomc_id"]]
fomc_df = fomc_df.drop_duplicates().sort_values(by=["daten"])
fomc_df["fomc_day"] = fomc_df['fomc_id'].notnull()
fomc_df['fomc_id'] = fomc_df['fomc_id'].bfill()
fomc_df = fomc_df[fomc_df["fomc_id"].notnull()]
# Getting extra dataset that will be used for placebo calculation
fomc_trimmed = fomc_df[~fomc_df["fomc_day"]]

# Merging two datasets together
df = pd.merge(df_original.drop(columns = ["fomc_id"]), fomc_df, on='daten', how='inner')
df['mp_klms_placebo'] = df.groupby('fomc_id')['mp_klms'].transform('max')
df = df[~df["fomc_day"]].reset_index(drop = True)

# Run bootstrap loop 10,000 times
# set seed for bootstrap reproducibility
np.random.seed(1)
boot_count = 10000
results = []
for _ in range(boot_count):
    single_result = one_bootstrap()
    results.append(single_result)

# Running actual estimation
df_main = df_original[df_original["mp_klms"].notnull()]
main_coeff = regress(df_main, "shock_hf_30min", "mp_klms")

# Merging them, getting df, and exporting
results_all = [main_coeff] + results
label_all = ["Regular"] + ["Placebo"] * boot_count
export_df = pd.DataFrame({'Estimates': results_all, 'Type': label_all})
export_df.to_csv("bootstrap_placebo.csv", index = False)
end