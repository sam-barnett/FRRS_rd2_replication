<style>
/* body {
  font-size: 12px;
  margin: 32px;
  padding: 24px;
} */
table, th, td {
  font-size: 12px; /* Set a smaller font size specifically for tables */
}
</style> 





# Overview
This folder contains the code and non-proprietary data for the paper "Falling Rates and Rising Superstars" by Thomas Kroen, Ernest Liu, Atif Mian, and Amir Sufi. The code reproduces the results, figures, and tables presented in the paper.


The code in this replication package constructs a high-frequency FOMC date-level monetary policy shock file, a high-frequency firm-FOMC date file, and a firm-quarter file. The primary data sources are: 
- Trade and Quote (TAQ) data on stock prices at 5-minute intervals
- Futures prices data used to compute a monetary policy shock
- Quarterly data on firm fundamentals from Compustat 

Two main files, data_construction_KLMS.do and analysis_KLMS.do, run all of the code to generate the data and results for the figures and tables in the paper and its appendix. The replicator should expect the code to run for about 8-16 hours.

The replication package is organized into two main folders: FRRS_code (containing all code and ado files) and FRRS_data (containing all data). The high-frequency and quarterly data processing are largely separate from one another. The data is thus organized as follows. There is a high-frequency folder containing a raw and a processed subfolder and a quarterly folder with the same structure. There is a "proc_analysis" folder which contains only the datasets used in directly producing the tables and figures. import_fred_snapshot contains FRED data collected using Stata's "import fred" command on July 31, 2025. Lastly, there is a separate "bootstrap_calculation" subfolder in src that stores the scripts needed to run the bootstrap for Figure A.1. 

# Data Availability and Provenance Statements 

## Statement about Rights
- I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.
- I certify that the author(s) of the manuscript have documented permission to redistribute/publish the data contained within this replication package. Appropriate permissions are documented in the LICENSE.txt file.

## License for Data

Creative Commons Attribution 4.0 (CC-BY-4.0), except for all data in: highfreq\raw\TickWrite, highfreq\raw\WRDS, 	quarterly\raw\Bloomberg, quarterly\raw\TickWrite, quarterly\raw\refinitiv_reuters, quarterly\raw\Global_Insight, quarterly\raw\Haver, and quarterly\raw\WRDS, which are proprietary and therefore excluded from this license.

## Summary of Availability
- Some data cannot be made publicly available.
- Confidential data used in this paper and not provided as part of the public replication package will be preserved for at least 5 years after publication, in accordance with journal policies.

## Details on each Data Source
All data listed below is provided in the FRRS_data folder. The * symbol indicates data to which the authors no longer have access.

| Data.Name  | Data.Files | Location | Provided | Citation
| ---------- | ---------- | -------- | -------- | -------- |
| FOMC Dates & Times    | fomc_times_2024_temp.dta    | highfreq/raw/manual  | Yes  |    |
| FRED Policy Rates | DFEDTAR.dta, DFEDTARL.dta | import_fred_snapshot | Yes | FRB (2025a, 2025b) |
| Zero-Coupon Rate | feds200628.csv | highfreq\raw\orig\FRB | Yes | Gürkaynak et al. (2007)  |
| FRED CPI | CPIAUCSL.dta | import_fred_snapshot | Yes | U.S. Bureau of Labor Statistics (2025c) |
| Gürkaynak et al. shocks | GSSrawdata.xlsx | highfreq\raw\orig\gurkaynak2021 | Yes | Gürkaynak et al. (2022) |
| Eurodollar Futures 1995- | ED[quarter][year].csv (ignore FF) | highfreq\raw\TickWrite\Eurodollars_FF_updated | No | TickWrite LLC. (1995-2025) |
| SOFR Futures 2022- | SR3[quarter][year]all.csv | highfreq\raw\TickWrite\SOFR_all | No | TickWrite LLC. (1995-2025) |
| Fed Funds Futures 1995-2019 | main_ff.csv | \highfreq\raw\TickWrite\fedfunds_cme_highfreq\unzipped | No | TickWrite LLC. (1995-2025) |
| Fed Funds Futures 2019- | FF[month][year]_UPDATE.csv | highfreq\raw\TickWrite\FF_futures_dataupdate | No | TickWrite LLC. (1995-2025) |
| 5-minute stock prices | [year]_5min_stocks.csv | highfreq\raw\WRDS\Intraday stocks\Stocks Last Trade (pulled using import_intraday_whole_year.R) | No | NYSE Trade and Quote (1994-2024) |
| Intraday Long-Term Yields (Old Format)* | [year]hig_freq_[maturity].csv | highfreq\raw\WRDS\us_treasury_govpx\tbills_highfreq | No | GovPX, Inc. (1991-2024) |
| Intraday Long-Term Yields (New Format) | [Stata-format FOMC date]-GOVPX_NEX_UST_0_0.csv | highfreq\raw\WRDS\us_treasury_govpx | No | GovPX, Inc. (1991-2024) |
| CRSP Stock/Security Files, 2021-2024 | CRSP_Stocks_Daily_2124_update.dta | highfreq\raw\WRDS | No | CRSP (1960-2024) |
| CRSP Stock/Security Files, 1960-2020 | CRSP_Stocks_Daily_all.dta | highfreq\raw\WRDS | No | CRSP (1960-2024) |
| TAQ-CRSP "Old" Crosswalk, 1993-2014 | monthly_taq_permno_cw_v2.csv | highfreq\raw\WRDS | No | WRDS (1993-2014) |
| TAQ-CRSP "New" Crosswalk, 2003-2024 | permno_crsp_cw_2024.dta | highfreq\raw\WRDS | No | WRDS (2003-2024) |
| Compustat Quarterly Firm Fundamentals, 1961-2020 | CCM_fundamentals_all.dta | quarterly\raw\WRDS | No | Standard and Poor's (1961-2024) |
| Compustat Quarterly Firm Fundamentals, 2020-2024 | ccm_fundamentals_quarterly_raw_20_24.csv | quarterly\raw\WRDS | No | Standard and Poor's (1961-2024) |
| Bloomberg Agriculture Subindex | BCOMAG_94_24.xlsx  | quarterly\raw\Bloomberg | No | Bloomberg L.P. (2025a) |
| Bloomberg Commodity Index  | BCOM_94_24.xlsx | quarterly\raw\Bloomberg | No | Bloomberg L.P. (2025b)  |
| S&P 500 Daily Closing Prices | SPall_daily.csv |  quarterly\raw\TickWrite | No | TickWrite LLC. (1995-2025) |
| FRED Slope of Treasury Yield Curve | T10Y3M.dta | import_fred_snapshot | Yes | FRB St. Louis (2025) |
| Refinitiv/Reuters Unemployment, Payroll, Core CPI Forecasts | refinitiv_reuters_[variable]_polls20_25.xlsx  | quarterly\raw\refinitiv_reuters | No | LSEG (2025) |
| Global Insight / Money Market Services Expectations* | MMS Data.xlsx |  quarterly\raw\Global_Insight | No | IHS Global Insight (2022) |
| As-released FRED data on Unemployment, Payroll, etc. | [variable]_asreleased.csv | quarterly\raw (pulled using as_released_data_scriptFRED.R) | Yes | U.S. Bureau of Economic Analysis (2025), U.S. Bureau of Labor Statistics (2025a, 2025b) |
| FRED Release Dates | release_dates_[releaseID]_[variable].xlsx | quarterly\raw\FRED | Yes | U.S. Bureau of Economic Analysis (2025), U.S. Bureau of Labor Statistics (2025a, 2025b) |
| Blue Chip Real GDP Forecasts (New) 2022-2024 | bluechipQQannrgdp22_24.xlsx  | quarterly\raw\Haver | No | Haver (2025), Wolters Kluwer (2025) |
| Blue Chip Real GDP Forecasts (Old) 1985-2022 | bchip_series_qoq.xlsx  | quarterly\raw\Haver | No | Haver (2025), Wolters Kluwer (2025) |
| FRED Brave-Butters Kelley RGDP Index | fred_bbk_90_25.csv | quarterly\raw\FRED | Yes | Indiana University (2025) |
| FRED Core CPI Change | CPILFESL.dta | import_fred_snapshot | Yes | U.S. Bureau of Labor Statistics (2025d) |
| Compustat Revenue 1980-2025 | compustat_revenue_80_25.dta | quarterly\raw\WRDS | No | Standard and Poor's (1961-2024) |
| FRED CPI (OECD) | CPALTT01USQ661S.dta | import_fred_snapshot | Yes | OECD (2025) |
| CRSP "Beta Suite" 1980-2019 | CRSP_Betaj.dta | quarterly\raw\WRDS | No | WRDS (1980-2024) |
| CRSP "Beta Suite" 2020-2024 | b_mkt_20_24.csv | quarterly\raw\WRDS | No | WRDS (1980-2024) |
| S&P Ratings Data (Old), 1984-2017 | SPRatings2.dta | quarterly\raw\WRDS | No | Standard & Poor’s, (1984-2017) |
| S&P Ratings Data (New), 2017-2024 | SPcredit_entity_rat_17_24.dta | quarterly\raw\WRDS | No | Standard & Poor’s, (2017-2024) |
| FRED Yield on U.S. Treasury Securities at 5-Year Constant Maturity | DGS5.dta | import_fred_snapshot | Yes | FRB (2025c) |
| FRED Annual Inflation | FPCPITOTLZGUSA.dta | import_fred_snapshot | Yes | World Bank (2025) |


**How each data source was accessed:**
  
 - FOMC dates and times were manually entered from https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm. 
 - The Fed's target rate, and all other FRED series in the "import_fred_snapshot" subfolder, was pulled from FRED using the "import FRED" command in Stata. For all FRED datasets, the name of the .dta file corresponds with the series name. 
 - The zero-coupon rate was downloaded from the Federal Reserve Board at https://www.federalreserve.gov/data/yield-curve-tables/feds200628.csv. 
 - The monetary policy shocks from Gürkaynak et al. (2022) can be found in the replication package at https://onlinelibrary.wiley.com/doi/10.1111/jofi.13163. We use the only variables MP1, MP2, ED2, ED3, and ED4 from February 1994 through June 2019. For details on how these variables were constructed, see Appendix A of Nakamura and Steinsson (2018). 
 - Eurodollar Futures were downloaded on TickWrite 7 on computers located in Firestone Library in Princeton. For all futures data from TickWrite, the name of each dataset refers to the expiration quarter and year.  The settings in TickWrite used to download the data were: Time based bars, Granularity 1 minutes, Skip empty intervals, Include all sessions, All contracts, Start Date Jan 1995. For more information on TickWrite see the user guide at https://s3-us-west-2.amazonaws.com/tick-data-s3/pdf/TickWrite7_Manual.pdf. For information about purchasing data from Tick Data, see https://www.tickdata.com/data-delivery/tickweb. 
 - SOFR Futures were downloaded via the same procedure, but with no start date or end date selected (since the data is only available from 2018). Note that there is an error in the expiration quarter for these contracts which is manually corrected in the data construction code; this can be confirmed by checking the raw data. 
 - Fed Funds Futures for 1995-2019 were collected as tick-based bars and bound manually into a single comma separated values file in Excel. This data is used only for backtesting the methodology used to compute MP1 and MP2 with the values from Gürkaynak et al. (2022) for dates up through 2018, for which we use MP1 and MP2 from Gürkaynak et al. (2022) directly. 
 - Fed Funds Futures 2019-present were collected using the same methodology as Eurodollar Futures, selecting Jan 01, 2019 as the start date. 
 - 5-minute stock prices were collected from WRDS using its native querying capabilities in R. For more information see https://wrds-www.wharton.upenn.edu/pages/about/3-ways-use-wrds/ (requires a WRDS account to view all documentation). The procedure is documented in the .R file which pulls the raw data, import_intraday_whole_year.R in the root folder. Data for 1994-2019 was collected in October 2023; data for 2020-2024 was collected in June 2025. For information about accessing WRDS data, see https://wrds-www.wharton.upenn.edu/pages/about/wrds-faqs/. 
 - Intraday Long-Term Yields through 2020 were collected from GovPX on Princeton University servers. The original format the data was collected in is no longer available at Princeton, but the data is available in a directory for individual dates at https://dss2.princeton.edu/govpx/ (Princeton login required). Intraday Long-Term Yields from 2021 onward (New Format) were manually downloaded for each FOMC date. To learn more about purchasing GovPX data, visit https://www.cmegroup.com/market-data/browse/files/govpx-us-treasury-fact-sheet.pdf.  
 - CRSP Stock/Security files for 1960-2020 and 2021-2024 were collected from https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/annual-update/stock-security-files/daily-stock-file/. After selecting the date range, "permno" as identifier, and "search entire database", select the following variables: shrout, prc, naics, cfacpr, cfacshr. (The following table explaining how to link databases in WRDS may be helpful in understanding the various identifiers: https://wrds-www.wharton.upenn.edu/pages/wrds-research/database-linking-matrix/.)
 - There are two crosswalks on WRDS corresponding to the Trade and Quote data (5-minute stock prices) that enable merging with CRSP data. The first covers 1993-2014 and is available at https://wrds-www.wharton.upenn.edu/pages/get-data/linking-suite-wrds/taq-crsp-link/. The second covers 2003-2024 and is available at https://wrds-www.wharton.upenn.edu/pages/get-data/linking-suite-wrds/daily-taq-crsp-link/. 
 - The Compustat firm fundamentals, used primarily to build  the dependent variables in the local projection specifactions in the papers, can be found at https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/annual-update/crspcompustat-merged/fundamentals-quarterly/. Choose "search entire database" and select the following variables: prccq, cshoq, xintq, dlcq, dlttq, atq, ppentq, revtq, dpq, oiadpq, ceqq, capxy, aqcy, saleq, gvkey, liid, permno, lpermco, datafqtr, datadate, datacqtr, fic, sic. There are many other options on the page; leave these defaults unchanged. 
 - The Bloomberg commodity price indices were downloaded from a Bloomberg Terminal in Firestone Library in Princeton. Choose the BCOM index for the total commodity price index and the BCOMAG index for the agriculture subindex. For more information on accessing Bloomberg data, see https://www.bloomberg.com/professional/solution/bloomberg-terminal/. 
 - S&P 500 daily closing prices were collected from TickWrite 7 from the Indices tab. Choose daily bars from 1990-present. 
 - Unemployment, payroll, and core CPI forecasts were collected from Refinitiv/Reuters and Money Market Services through Global Insight. Data from Global Insight is no longer provided through Princeton Library and is inaccessible to the authors. The Refinitiv/Reuters data used to update the forecast series was accessed on computers in Firestone Library at princeton. Search up each variable and click the blue highlighted data values in the table under "Reuters forecasts," then export the data to an Excel. (The replicator may need to ensure Excel has the Refinitiv plugin enabled under File -> Options.) For more information about accessing Refinitiv/Reuters data, visit https://www.lseg.com/en/data-analytics/refinitiv?. 
 - As-released FRED data on the above three variables and GDP is collected using ALFRED: https://alfred.stlouisfed.org/. The R code that pulls this data is as_released_data_scriptFRED.R in the root folder. 
- Release dates for the archival FRED data above can be found at https://alfred.stlouisfed.org/release/downloaddates?rid=10 (CPI), https://alfred.stlouisfed.org/release/downloaddates?rid=50 (Payroll and Unemployment), and https://alfred.stlouisfed.org/release/downloaddates?rid=53 (GDP). 
- Blue Chip Real GDP Forecasts for 1985-2022 and 2022-2024 were accessed through Haver Analytics on computers in Firestone Library at Princeton. For downloading the data through the Haver interface, it is recommended that replicators follow the procedure documented at https://libguides.princeton.edu/ld.php?content_id=17176779 closely and carefully. For more information about accessing Haver data, visit https://www.haver.com/. 
- FRED's Brave-Butters-Kelley (BBK) real GDP index can be found at https://fred.stlouisfed.org/series/BBKMGDP. 
- Compustat revenue data can be found at https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/fundamentals-quarterly/. Proceed as above, selecting the variables gvkey, datafqtr, datadate, datacqtr, and revtq.  
- The "Beta Suite by WRDS" data can be found at https://wrds-www.wharton.upenn.edu/pages/get-data/beta-suite-wrds/beta-suite-by-wrds/. After choosing the date range and selecting "permno" as identifier, enabling "search entire database", leaving the frequency selection parameter as "Daily (trading days)", leaving the default estimation and minimum windows, selecting "Market Model" under "Step 4: Risk Model," leaving "Step 5: Return Type" as "Regular Return", and choosing "PERMNO, Date of Observation, Returns, and Ticker" as variables, submit the query. 
- The Standard & Poor's Ratings data pre-2017 can be found at the following link: https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/ratings/. The updated ratings data through 2024 can be found at https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/capital-iq/sp-credit-ratings/security-ratings/. The following guide explains the different S&P ratings data at WRDS: https://wrds-www.wharton.upenn.edu/documents/1849/WRDS_Credit_Rating_Data_Overview.pdf?alg[…]id=document_1849_2&algolia-index-name=main_search_index. We use "Option 1: Company S&P Credit Ratings" until they are no longer available in 2017, at which point we switch to "Option 3: Capital IQ S&P Credit Ratings", listed as the "current flagship credit rating data on WRDS." 

## Variable Descriptions
- See the file CODEBOOK.pdf for a codebook of variables. 
- All WRDS data is also documented at the links provided in the tab "Variable Descriptions." 

# Dataset list (for analysis)
The below datasets used in creating the tables and figures in the paper are included in FRRS_data\data\proc_analysis. 

| Data file  | Source | Notes | Provided | 
| ---------- | ---------- | -------- | -------- | 
| master_fomc_level_24.dta    |  Fed Funds Futures, Eurodollar Futures, Treasury Yields, FOMC Dates & Times, FRED Policy Rates, Zero-Coupon Rate, Gürkaynak et al. shocks  | Various policy shocks: Fed Funds, Eurodollars, Treasury Yields, PCA shocks of the above   | Yes  |
| maintable_data.dta | master_fomc_level_24.dta, TAQ/CRSP Stock Data, CPI | Main high-frequency panel dataset with stock returns and high-frequency shocks | No | 
| estdata_update_ptilec.dta | master_fomc_level_24.dta, Compustat, Bloomberg Indices, S&P 500,  FRED Yield Slope/Historical Releases/OECD CPI, Refinitiv/Reuters, Haver Blue Chip, Global Insight/Money Market Survey, FRED BBK, CRSP "Beta Suite", S&P Ratings  | Quarterly panel used for estimating LPs | No | 
| LP_baseline_coeffs.dta | analysis do-file | Coefficients from estimating main local projection specification (for plotting in robustness checks) | Yes | 

# Computational requirements

## Software Requirements
- Stata packages are in the "ado" subfolder (users do not need to ssc install these).
- R, with packages fredr, readxl, tidyverse, RPostgres, DBI, and data.table. Running R_load_packages.R in the root folder installs these six packages automatically. These packages can also be manually installed by the replicator using install.packages("[packagename]"), e.g. in R or Rstudio. 
- Python with packages numpy, pandas, scikit-learn, and scipy installed in the Python environment to which Stata's Python integration points. These packages are **installed automatically** by master_KLMS.do in the code block titled "Python packages setup," which installs the four necessary packages into the correct directory, provided Python is installed. The user can also comment out this section and manually ensure the correct packages are installed. 


## Controlled Randomness 
- Line 48 of bootstrap_calculation\bootstrap_calculation.do sets the seed for the bootstrap that creates the histogram of baseline estimates in Appendix Figure A.1.
## Memory, Runtime, Storage Requirements
- With all confidential files included, the replication package is approximately 200 GB. The code requires around 25 GB of additional free SSD storage to store large tempfiles created during the data construction process. 
#### Summary 
Approximate time needed to reproduce the analyses on a standard (CURRENT YEAR) desktop machine:
- 8-24 hours 

If reproducing the part of the code that pulls R data:
- 14+ days 

#### Details 
The code was last run on a 4-core Intel-based laptop running Windows 11 with 50 GB of free space. The versions of software used were StataNow 19.5, R 4.4.1, and Python 3.12. 

# Description of programs/code
## License for Code 
The code is licensed under a MIT license. See LICENSE.txt in the root folder for details.

# Instructions to Replicators
## Details
- Install necessary packages for R as described in the "Software Requirements" section (e.g., by running the file R_load_packages.R).
- Open master_KLMS.do in the FRRS_code folder. Change the following paths:
  - The path to the code folder on your computer (lines 8-9)
  - The path to the data folder on your computer (lines 10-11)
  - The path to your computer's R executable (line 13)
  - (Optional) Comment out line 59, which pulls the raw 5-minute stock data from WRDS
- Run master_KLMS.do. 

Because of the computationally-intensive nature of the file "import_intraday_whole_year.R", it may be desirable to run it in a dedicated IDE such as Rstudio. 

# List of tables/figures and programs

Tables and figures require confidential data unless otherwise specified.

Figure/Table # | Program  |	Line Number | Output file |	Note
| ----------- | ----------- | ----------- | ----------- | ----------- |
Table 1 	| analysis_KLMS.do 	|  540 | DU_ZLBnonZLB_ptileconsis.tex | 	 
Table 2 	| analysis_KLMS.do 	| 597  | DU_FFRbar.tex | 	 
Table 3 	| analysis_KLMS.do 	| 656  | table4_sum_table_vars.tex | 	 
Table A.1 | analysis_KLMS.do  | 767  | BC_none_gk_alt.tex |
Table A.2 	| analysis_KLMS.do 	| 1684  | DU_ZLBnonZLB_ptileconsis_WL907550.tex | 	 
Table A.3 	| analysis_KLMS.do 	| 1906  | DU_ZLBnonZLB_ptileconsisIND.tex | 	 
Table A.4 	| analysis_KLMS.do 	|1762  | test5_proc_analysis_estdata_update_ptilec7.tex | 	  
Figure 1 	| analysis_KLMS.do 	| 292  | fig1_rate_response_omega.pdf | 	 Requires only master_fomc_level_24.dta, provided in data\proc_analysis. 
Figure 2 	| analysis_KLMS.do 	| 336  | fig1_rate_response_omega_combine.pdf | 	 Requires only master_fomc_level_24.dta, provided in data\proc_analysis. 
Figure 3 	| analysis_KLMS.do 	| 472  | fig2_coeffs_by_year.pdf | 	 
Figure 4 	| analysis_KLMS.do 	| 490  | fig3_coeffs_by_quintile_splitpost.pdf, fig4_dollarduration_by_xtile.pdf | 	 
Figure 5 	| analysis_KLMS.do 	| 723  | test_avg_borrowing_cost_gk_updated.pdf | 	 
Figure 6 	| analysis_KLMS.do 	| 816  | all8_IRFs_baseline.pdf | 	 
Figure 7 	| analysis_KLMS.do 	| 910  | news_controls_All_double_gk_alt.pdf | 	 
Figure 8 	| analysis_KLMS.do 	| 1039  | controls_All_gk_alt.pdf.pdf | 	 
Figure A.1 	| analysis_KLMS.do, bootstrap_calculation\bootstrap_calculation.do 	| 1190, 1 (resp.)  | placebo_duration.pdf |  
Figure A.2 	| analysis_KLMS.do 	| 1214, 1300  | appendix_all8_IRFs_IND5_FFRBAR.pdf | 	 
Figure A.3 	| analysis_KLMS.do 	| 1214, 1333  | appendix_all8_IRFs_IND5_WIDESHOCK.pdf | 	 
Figure A.4 	| analysis_KLMS.do 	| 1361  | rob8ahead_all.pdf | 	
Figure A.5 	| analysis_KLMS.do 	| 1577  | appendix_all8_IRFs_FFRbaseline_lvls.pdf | 	 
# References 

Bloomberg L.P., 2025a. Bloomberg Agricultural Commodity Price Index [BCOMAG Index],
retrieved from Bloomberg Terminal, March 18, 2025.

Bloomberg L.P., 2025b. Bloomberg Total Commodity Price Index [BCOM Index], retrieved
from Bloomberg Terminal, March 17, 2025.

Board of Governors of the Federal Reserve System, 2025a. Federal Funds Target Rate
[DFEDTAR], retrieved from FRED, Federal Reserve Bank of St. Louis;
https://fred.stlouisfed.org/series/DFEDTAR, July 31, 2025.

Board of Governors of the Federal Reserve System, 2025b. Federal Funds Target Range - Lower Limit [DFEDTARL], retrieved from FRED, Federal Reserve Bank of St. Louis;
https://fred.stlouisfed.org/series/DFEDTARL, July 31, 2025.

Board of Governors of the Federal Reserve System, 2025c. Market Yield on U.S. Treasury Securities at 5-Year Constant Maturity, Quoted on an Investment Basis [DGS5], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/DGS5, July 31, 2025.

Center for Research in Security Prices (CRSP), University of Chicago Booth School of Business, (1960-2024). CRSP Stock/Security Files. Wharton Research Data Services (WRDS). https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/annual-update/stock-security-files/daily-stock-file/

Federal Reserve Bank of St. Louis, 2025. 10-Year Treasury Constant Maturity Minus 3-
Month Treasury Constant Maturity [T10Y3M], retrieved from FRED, Federal Reserve Bank
of St. Louis; https://fred.stlouisfed.org/series/T10Y3M, July 31, 2025.

GovPX, Inc., (1991-2024). GovPX U.S. Treasury Securities Intraday Data.

Gürkaynak, R., Karasoy-Can, H.G. and Lee, S.S. (2022), Stock Market's Assessment of Monetary Policy Transmission: The Cash Flow Effect. The Journal of Finance, 77: 2375-2421.

Gürkaynak, R., Sack, B. and Wright, J.H. (2007), The U.S. Treasury. Yield Curve: 1961 to the Present. Journal of Monetary Economics, vol 54, pp2291-2304.

Haver Analytics, 2025. Blue Chip Economic Indicators and Blue Chip Financial Forecasts, Real GDP Forecasts for the United States [Blue Chip GDP Forecasts], retrieved from Haver Analytics database July 31, 2025.

IHS Global Insight, 2022. “MMS Survey Medians and As Reported Data (MMSAMER),” formerly
available at https://wrds-www.wharton.upenn.edu/pages/about/data-vendors/ihs-global-insight/.

Indiana University, 2025. Indiana Business Research Center, Brave-Butters-Kelley Real Gross Domestic Product [BBKMGDP], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/BBKMGDP, July 31, 2025

LSEG Data and Analytics, 2025. "Economic Indicator Polls." https://www.lseg.com/en/data-analytics/refinitiv, accessed March 18, 2025.

Nakamura, E. and Steinsson, J. (2018), High-Frequency Identification of Monetary Non-
Neutrality: The Information Effect. The Quarterly Journal of Economics, 133 (3), 1283–1330.

NYSE Trade and Quote, (1994-2024). NYSE TAQ. Wharton Research Data Services (WRDS). https://wrds-www.wharton.upenn.edu/pages/about/data-vendors/nyse-trade-and-quote-taq/ 

Organization for Economic Co-operation and Development, 2025. Consumer Price Indices (CPIs, HICPs), COICOP 1999: Consumer Price Index: Total for United States [CPALTT01USQ661S], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/CPALTT01USQ661S, July 31, 2025.

Standard and Poor's, (1961-2024). Compustat Quarterly Firm Fundamentals. Wharton Research Data Services (WRDS). https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/fundamentals-quarterly/

Standard & Poor's, (1984-2017). Compustat Daily Updates - Ratings. Wharton Research Data Services (WRDS). https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/ratings/

Standard & Poor's, (2017-2024). Security Ratings. Wharton Research Data Services (WRDS). https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/capital-iq/sp-credit-ratings/security-ratings/

TickWrite LLC, (1995-2025). TickWrite Historical Futures and Indices Data.

U.S. Bureau of Economic Analysis, 2025. Real Gross Domestic Product [GDPC1], retrieved
from ALFRED (Archival Federal Reserve Economic Data), Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/GDPC1,
July 31, 2025.

U.S. Bureau of Labor Statistics, 2025a. All Employees, Total Nonfarm [PAYEMS], retrieved
from ALFRED (Archival Federal Reserve Economic Data), Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/PAYEMS,
July 31, 2025.

U.S. Bureau of Labor Statistics, 2025b. Unemployment Rate [UNRATE], retrieved from
ALFRED (Archival Federal Reserve Economic Data), Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/UNRATE, July 31, 2025.

U.S. Bureau of Labor Statistics, 2025c. Consumer Price Index for All Urban Consumers: All
Items in U.S. City Average [CPIAUCSL], retrieved from FRED, Federal Reserve Bank of St.
Louis; https://fred.stlouisfed.org/series/CPIAUCSL, July 31, 2025.

U.S. Bureau of Labor Statistics, 2025d. Consumer Price Index for All Urban Consumers: All
Items Less Food and Energy in U.S. City Average [CPILFESL], retrieved from ALFRED (Archival Federal Reserve Economic Data), Federal
Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/CPILFESL, July 31, 2025.

Wharton Research Data Services (WRDS), (1993-2014). TAQ CRSP Link. https://wrds-www.wharton.upenn.edu/pages/get-data/linking-suite-wrds/taq-crsp-link/

Wharton Research Data Services (WRDS), (2003-2024). Daily TAQ CRSP Link Suite. https://wrds-www.wharton.upenn.edu/pages/get-data/linking-suite-wrds/daily-taq-crsp-link/

Wharton Research Data Services (WRDS), (1980-2024). Beta Suite by WRDS. https://wrds-www.wharton.upenn.edu/pages/get-data/beta-suite-wrds/beta-suite-by-wrds/

Wolters Kluwer, 2025. “Blue Chip Financial Forecasts.” Monthly newsletter available at
https://www.wolterskluwer.com/en/solutions/vitallaw-law-firms/blue-chip

World Bank, 2025. Inflation, consumer prices for the United States [FPCPITOTLZGUSA], retrieved from FRED, Federal Reserve Bank of St. Louis; https://fred.stlouisfed.org/series/FPCPITOTLZGUSA, July 31, 2025.

