#%% 
import numpy as np
#from multiprocessing import Pool
import pandas as pd
#import os
from sklearn.linear_model import LinearRegression
#import statsmodels.api as sm 
#import time
#from joblib import Parallel, delayed
#import matplotlib.pyplot as plt
#import concurrent.futures
#import csv
#import pdb

#%% Functions 
def regress(data, yvar, xvar):
    # keep permno so we can group on it
    sub = data[[yvar, xvar, "permno"]] \
            .replace([np.inf, -np.inf], np.nan) \
            .dropna()

    # within‐demean
    y_w = sub[yvar] - sub.groupby("permno")[yvar].transform("mean")
    x_w = sub[xvar] - sub.groupby("permno")[xvar].transform("mean")

    # sklearn fit
    lr = LinearRegression(fit_intercept=False) \
            .fit(x_w.values.reshape(-1,1), y_w.values)

    return lr.coef_[0]   # scalar slope

def one_bootstrap():
    # Getting sampled placebo days
    sampled_days = fomc_trimmed.groupby('fomc_id').apply(lambda x: x.sample(1), include_groups=False).reset_index(drop=True).loc[:, "daten"]
    # Keeping only placebo obs
    placebo_df = pd.merge(df, sampled_days, on='daten', how='inner')
    
    # Actually getting the coefficient # NOTICE: NO LONGER AN AVERAGE, BUT A FIRM FE APPROACH
    coefficients_df = regress(placebo_df, "shock_hf_30min", "mp_klms_placebo")
    # mean_iter = coefficients_df["mp_klms_placebo"].mean() #OLD ver
    # return mean_iter
    print(coefficients_df)
    return coefficients_df 



#%% Load and prep dataset 
df_raw = pd.read_stata("master_daily_placebo_calculation_UPDATE.dta")

# df_original = df_raw.dropna(subset=['shock_hf_1hour_dollar']) # we don't do this anymore in main analysis
df_original = df_raw.copy()

####### Getting the FOMC groups
fomc_df = df_original.loc[:, ["daten", "fomc_id"]]
fomc_df = fomc_df.drop_duplicates().sort_values(by=["daten"])
fomc_df["fomc_day"] = fomc_df['fomc_id'].notnull()
fomc_df['fomc_id'] = fomc_df['fomc_id'].bfill()
# Drop cases that are after our tracked FOMCs // (very end of 2019)
fomc_df = fomc_df[fomc_df["fomc_id"].notnull()]
# Getting extra dataset that will be used for placebo calculation
fomc_trimmed = fomc_df[~fomc_df["fomc_day"]]

######## Merging two datasets together
df = pd.merge(df_original.drop(columns = ["fomc_id"]), fomc_df, on='daten', how='inner')
df['mp_klms_placebo'] = df.groupby('fomc_id')['mp_klms'].transform('max')
df = df[~df["fomc_day"]].reset_index(drop = True)



#%% Run bootstrap loop 10,000 times
#set seed for bootstrap reproducibility
np.random.seed(1)
boot_count = 10000
# results = Parallel(n_jobs=-1)(delayed(one_bootstrap)() for _ in range(boot_count))
results = []
for _ in range(boot_count):
    single_result = one_bootstrap()
    results.append(single_result)

# Running actual estimation
df_main = df_original[df_original["mp_klms"].notnull()]
# coefficients_df = df_main.groupby('permno').apply(regress, "shock_hf_30min", ['mp_klms']) # OLD version -- we no longer take avg coeff
main_coeff = regress(df_main, "shock_hf_30min", "mp_klms") # NEW version -- we take firm FE coeff. Same as in Table 1. 

# Merging them, getting df, and exporting
results_all = [main_coeff] + results
label_all = ["Regular"] + ["Placebo"] * boot_count
export_df = pd.DataFrame({'Estimates': results_all, 'Type': label_all})
export_df.to_csv("bootstrap_placebo.csv", index = False)


# %%
