<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/katex.min.css">
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


# Codebook 

In cases where data is not clear from context (e.g., FRED series), a codebook is provided below. 

## GovPX
The following is a codebook for the new-format GovPx data on Treasury yields. 

Field Name | Col |	Example Value	| Supported Value(s) |	Description
| ----------- | ----------- | ----------- | ----------- | ----------- |
Timestamp |	A|	2019-03-20T09:08:32.461-04:00	| yyyy-mm-ddThh:mm:ss.sss|	Date & Time of update
Producer	|B|	US_GOVPX|	US_GOVPX|	GovPX| US Treasury source|
Record|	C|	10_YEAR	1_MONTH, 2_MONTH, 3_MONTH, 4_MONTH, 6_MONTH, 1_YEAR, 2_YEAR, 3_YEAR, 5_YEAR, 7_YEAR, 10_YEAR, 20_YEAR, 30_YEAR, 1_MONTH_WI, 2_MONTH_WI, 3_MONTH_WI, 4_MONTH_WI, 6_MONTH_WI, 1_YEAR_WI, 2_YEAR_WI, 3_YEAR_WI, 5_YEAR_WI, 7_YEAR_WI, 10_YEAR_WI, 20_YEAR_WI, 30_YEAR_WI, 1MO_ROLL, 2MO_ROLL, 3MO_ROLL, 4MO_ROLL, 6MO_ROLL, 12M_ROLL, 2_YR_ROLL, 3_YR_ROLL, 5_YR_ROLL, 7_YR_ROLL, 10_YR_ROLL, 20_YR_ROLL, 30_YR_ROLL  | (CUSIPs for most issues)|	Instrument name / tenor
Ask|	D|	100.1641	|decimal|	Ask price
AskType|	E|	17|	numeric|	Instrument identifier
AskYield|	F|	3.03	|decimal|	Ask yield (%)
Bid	|G|	100.1016|	decimal|	Bid price
BidType|	H|	16|	numeric|	Instrument identifier
BidYield|	I|	2.265	|decimal|	Bid yield (%)|
BidYieldChg|	J|	9128286B1|	int64|	Security identifier
CashAskPrice|	K|	100.1328|	decimal|	Cash-settled ask price
CashBidPrice|	L|	-0.03125|	decimal|	Cash-settled bid price
CashMidPrice|	M|	100.0090779	|decimal|	Mid price (cash market)
Change|	N|	2.613|	decimal	|Price change
Coupon|	O|	2.265|	decimal	|Stated coupon (%)
CUSIP|	P|	9128286B1	|alphanumeric|	Security identifier
Description|	Q	|1MO_04/30|	alphanumeric	|Issue description
DollarFlow|	R|	-1804	|numeric|	Net signed trade size (dollar-flow)
High|	S|	0.011|	decimal	|Intraday high price
ICAPVOL|	T|	24309|	int64|	Total on-broker volume
IndicativeAskPrice	|U|	100.1640625|	decimal|	Indicative ask price
IndicativeAskYield	|V|	2.403	|decimal|	Indicative ask yield
IndicativeBidPrice|	W|	100.1015625|	decimal	|Indicative bid price
IndicativeBidYield|	X|	2.4	|decimal|	Indicative bid yield
IssueDate|	Y|	20190215|	yyyymmdd	|Date of issuance
Last|	Z|	99.76563|	decimal	|Last trade price
LastHitorTake	|AA |	H	|H;T	|Last trade aggressor side
LastYield|	AB|	2.36|	decimal	|Last trade yield
Low|	AC|	99.89063|	decimal|	Intraday low price
MaturityDate|	AD|	20290215|	yyyymmdd|	Date of maturity
Mid|	AE|	100.1328|	decimal	|Mid price
MidChg|	AF|	-0.03125|	decimal	|Mid-price change
MidSnapChg|	AG|	0.8817	|decimal	|Mid-price change vs. prior day
MidYield|	AH	|2.6095|	decimal	|Mid yield (%)
MidYldSnapChg|	AI|	0.011|	decimal	|Mid-yield change vs. prior day
Open|	AJ	|100.1563|	decimal	|First price of day
SettlementDate	|AK|	20190320	|yyyymmdd|	Settlement date
ShortDescription|	AL|	10Y|	1M, 2M, 3M, 4M, 6M, 1Y, 2Y, 3Y, 5Y, 7Y, 10Y, 20Y, 30Y, 1MW, 2MW, 3MW, 4MW, 6MW, 1YW, 2YW, 3YW, 5YW, 7YW, 10YW, 20YW, 30YW, I, P, 5t, 10t, 20t, 30t|	Human-readable tenor code
TreasuryType|	AM|	151	|150 (off-the-run), 151 (active), 152 (OTR bills), 153 (active bills), 154 (WI), 157 (TIPS)|	Type of Treasury
VoiceAskPrice |	AN|	99.765625|	decimal|	Voice ask price (if available)
VoiceAskSize|	AO|	5|	int64|	Voice ask size
VoiceAskYield|	AP|	2.37|	decimal	|Voice ask yield
VoiceBidPrice|	AQ|	99.76171875|	decimal|	Voice bid price
VoiceBidSize|	AR|	5|	int64|	Voice bid size
VoiceBidYield|	AS|	2.4|	decimal	|Voice bid yield
VoiceTradeSize|	AT|	5|	decimal	|Voice-executed trade size
VWAP|	AU|	99.76171875|	decimal |	VWAP (full day)
VWAP*|	AV|	99.76171875|	decimal	|VWAP for [time range]
VWAY	|BE|	99.76171875|	decimal|	VWAP calculated in yield space
VWAY*|	BF|	99.76171875|	decimal|	VWAY for [time range]


## WRDS 

#### CRSP Stock/Security Files
Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
PERMNO       |   double | %8.0g     |PERMNO (firm identifier)
date|            long    |%td        |Names Date
NAICS|           str8|    %8s|      North American Industry Classification System
CUSIP|           str8|    %8s|                   CUSIP
PRC|             double|  %12.0g|    Price or Bid/Ask Average
SHROUT|          double|  %12.0g|    Shares Outstanding
CFACPR|          double|  %12.0g|    Cumulative Factor to Adjust Prices
CFACSHR|         double|  %12.0g|    Cumulative Factor to Adjust Shares/Vol


#### TAQ/CRSP Old Crosswalk 
- For context: There is not a one-to-one mapping between "permno" and security symbol. WRDS provides a "many-to-many" match in the crosswalk with variables measuring the "closeness" of the match. 
  
Variable Name | Label
| ----------- | ----------- |
permno      | Firm identifier in CRSP 
symbol      | Security/stock symbol 
fdate       | unused
namedis     | Measure of distance between characters in "permno" name and "symbol" name 
cusip       | CUSIP (id)
name        | unused
comnam      | unused
date        | End-of-month date
cusip_full  | unused
score       | Lower score is "higher match" according to following criteria. 0: BEST match: using (cusip, cusip dates and company names) or (exchange ticker, company names and 6-digit cusip). 1: Cusips and cusip dates match but company names do not match. 2: Cusips and company names match but cusip dates do not match. 3: Cusips match but cusip dates and company names do not match. 4: Exch tickers and 6-digit cusips match but company names do not match. 5: Exch tickers and company names match but 6-digit cusips do not match. 6: Exch tickers match but company names and 6-digit cusips do not match


#### TAQ/CRSP New Crosswalk 
Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
DATE   |         long|    %td|                   Date
SYM_ROOT|        str6|    %6s|                   Security symbol root
SYM_SUFFIX|      str10|   %10s|                  Security symbol suffix
PERMNO|          double|  %8.0g|                 PERMNO
CUSIP|           str8|    %8s|                   CUSIP


#### Compustat Quarterly Fundamentals, Compustat Revenue 
Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
GVKEY       |    str6|    %6s|                   Standard and Poor's Identifier
LIID|            str4|    %4s|                   Security-level Identifier
LPERMNO|         double|  %12.0g|                Historical CRSP PERMNO Link to COMPUSTAT Record
LPERMCO|         double|  %12.0g|                Historical CRSP PERMCO Link to COMPUSTAT Record
datadate|        long|    %td|                   Data Date
fyearq|          double|  %6.0g|                 Fiscal Year
fqtr|            double|  %4.0g|                 Fiscal Quarter
fyr|             double  |%4.0g|                 Fiscal Year-end Month
indfmt|          str12   |%12s|                  Industry Format
consol|          str2|    %2s|                   Level of Consolidation - Company Interim Descriptor
popsrc|          str2|    %2s|                   Population Source
datafmt|         str12|   %12s|                  Data Format
curcdq|          str4|    %4s|                   ISO Currency Code
datacqtr|        str6|    %6s|                   Calendar Data Year and Quarter
datafqtr|        str6|    %6s|                   Fiscal Data Year and Quarter
actq|            double|  %18.0g|                Current Assets - Total
ancq|            double  |%18.0g|                Non-Current Assets - Total
atq|             double  |%18.0g|                Assets - Total
ceqq|            double|  %18.0g|                Common/Ordinary Equity - Total
cheq|            double|  %18.0g|                Cash and Short-Term Investments
cogsq|           double|  %18.0g|                Cost of Goods Sold
cshoq|           double|  %18.0g|                Common Shares Outstanding
dd1q |            double|  %18.0g|                Long-Term Debt Due in One Year
dlcq|            double|  %18.0g|                Debt in Current Liabilities
dlttq|double|%18.0g|Long-Term Debt - Total
dpq|double|%18.0g|Depreciation and Amortization - Total
lctq|double|%18.0g|Current Liabilities - Total
lltq|double|%18.0g|Long-Term Liabilities (Total)
ltq|double|%18.0g|Liabilities - Total
mibq|double|%18.0g|Noncontrolling Interest - Redeemable - Balance Sheet
niq|double|%18.0g|Net Income (Loss)
oiadpq|double|%18.0g|Operating Income After Depreciation - Quarterly
oibdpq|double|%18.0g|Operating Income Before Depreciation - Quarterly
piq|double|%18.0g|Pretax Income
ppegtq|double|%18.0g|Property, Plant and Equipment - Total (Gross) - Quarterly
ppentq|double|%18.0g|Property Plant and Equipment - Total (Net)
pstkq|double|%18.0g|Preferred/Preference Stock (Capital) - Total
req|double|%18.0g|Retained Earnings
saleq|double|%18.0g|Sales/Turnover (Net)
teqq|double|%18.0g|Stockholders Equity - Total
txtq|double|%18.0g|Income Taxes - Total
wcapq|double|%18.0g|Working Capital (Balance Sheet)
xintq|double|%18.0g|Interest and Related Expense- Total
xrdq|double|%18.0g|Research and Development Expense
xsgaq|double|%18.0g|Selling, General and Administrative Expenses
aqcy|double|%18.0g|Acquisitions
capxy|double|%18.0g|Capital Expenditures
chechy|double|%18.0g|Cash and Cash Equivalents - Increase (Decrease)
dlcchy|double|%18.0g|Changes in Current Debt
dltisy|double|%18.0g|Long-Term Debt - Issuance
dltry|double|%18.0g|Long-Term Debt - Reduction
dvy|double|%18.0g|Cash Dividends
exrey|double|%18.0g|Exchange Rate Effect
fiaoy|double|%18.0g|Financing Activities - Other
fincfy|double|%18.0g|Financing Activities - Net Cash Flow
ivncfy|double|%18.0g|Investing Activities - Net Cash Flow
oancfy|double|%18.0g|Operating Activities - Net Cash Flow
prstkccy|double|%18.0g|Purchase of Common Stock (Cash Flow)
prstkcy|double|%18.0g|Purchase of Common and Preferred Stock
prstkpcy|double|%18.0g|Purchase of Preferred/Preference Stock (Cash Flow)
scstkcy|double|%18.0g|Sale of Common Stock (Cash Flow)
spstkcy|double|%18.0g|Sale of Preferred/Preference Stock (Cash Flow)
sstky|double|%18.0g|Sale of Common and Preferred Stock
txbcofy|double|%18.0g|Excess Tax Benefit of Stock Options - Cash Flow Financing
xrdy|double|%18.0g|Research and Development Expense
xsgay|double|%18.0g|Selling, General and Administrative Expenses
costat|str2|%2s|Active/Inactive Status Marker
fic|str4|%4s|Current ISO Country Code - Incorporation
cshtrq|double|%18.0g|Common Shares Traded - Quarter
dvpspq|double|%18.0g|Dividends per Share - Pay Date - Quarter
dvpsxq|double|%18.0g|Div per Share - Exdate - Quarter
mkvaltq|double|%18.0g|Market Value - Total
prccq|double|%18.0g|Price Close - Quarter
prchq|double|%18.0g|Price High - Quarter
prclq|double|%18.0g|Price Low - Quarter
adjex|double|%18.0g|Cumulative Adjustment Factor by Ex-Date
conml|str100|%100s|Company Legal Name
loc|str4|%4s|Current ISO Country Code - Headquarters
naics|str6|%6s|North American Industry Classification Code
sic|str4|%4s|Standard Industry


#### CRSP Beta Suite 
- From a WRDS guide available at https://wrds-www.wharton.upenn.edu/documents/1582/WRDS_Beta_Suite_Documentation_3T4EcS7.pdf. 

###### Overview  
WRDS Beta Suite is a web-based tool that lets researchers estimate securities’ factor loadings (betas) quickly and flexibly, with rolling regressions at daily, weekly, or monthly frequency. 

###### Methodology  

###### Frequency of study  
Choose one of three return frequencies: 

- **Daily**  (used)
- Weekly
- Monthly  

###### Risk models  

| Model | Specification (summary) |
|-------|-------------------------|
| **CAPM / Market model** | $R_{i,t}-R_{f,t}=\alpha_i+\beta_i\,(R_{m,t}-R_{f,t})+\varepsilon_{i,t}$ |

Where 
  - $R_{i, t}$ is firm $i$'s stock return in period $t$
  - $R_{f,t}$ is the risk-free rate in period $t$
  - $R_{m,t}$ is Fama-French Excess Return on the Market during period $t$

### Estimation & minimum window  
Users pick the **estimation window** length (e.g., 60 months at monthly frequency) and the **minimum window** of valid observations required for a regression to be kept (e.g., 36 months). 


## References    
- Sharpe, W. F. (1964), *Capital Asset Prices: A Theory of Market Equilibrium under Conditions of Risk*, *J. Finance* 19, 425-442. 


Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
PERMNO        |  double|  %8.0g|                 PERMNO
DATE|            long|    %td|                   Date of Observation
n|               double|  %12.0g|                Number of Observations used to compute Beta
RET|             double|  %10.0g|                Returns
b_mkt|           double|  %8.0g|                 Est. beta (see above)
alpha|           double  |%8.0g|                 Est. alpha (not used)
ivol|            double  |%10.0g|                Idiosyncratic Risk (not used)
tvol|            double  |%10.0g                |Total Volatility (not used)
R2|              double|  %10.0g|                R-Squared (not used)
exret|           double  |%10.0g|                Excess Return from Risk Model (not used)
TICKER|          str8    |%8s|                   Ticker Symbol (not used)


#### S&P Ratings (Old) 

Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
gvkey|str6|%6s|Global Company Key
splticrm|str10|%10s|S&P Domestic Long Term Issuer Credit Rating
spsdrm|str10|%10s|S&P Subordinated Debt Rating
spsticrm|str10|%10s|S&P Domestic Short Term Issuer Credit Rating
datadate|long|%td|Data Date
add1|str66|%66s|Address Line 1
add2|str66|%66s|Address Line 2
add3|str66|%66s|Address Line 3
add4|str66|%66s|Address Line 4
addzip|str20|%20s|Postal Code
busdesc|str2000|%2000s|S&P Business Description
cik|str10|%10s|CIK Number
city|str100|%100s|City
conml|str100|%100s|Company Legal Name
county|str100|%100s|County Code
dlrsn|str8|%8s|Research Co Reason for Deletion
ein|str10|%10s|Employer Identification Number
fax|str20|%20s|Fax Number
fic|str4|%4s|Current ISO Country Code - Incorporation
fyrc|double|%4.0g|Current Fiscal Year End Month
ggroup|str4|%4s|GIC Groups
gind|str6|%6s|GIC Industries
gsector|str2|%2s|GIC Sectors
gsubind|str8|%8s|GIC Sub-Industries
idbflag|str2|%2s|International, Domestic, Both Indicator
incorp|str8|%8s|Current State/Province of Incorporation Code
loc|str4|%4s|Current ISO Country Code - Headquarters
naics|str6|%6s|North American Industry Classification Code
phone|str20|%20s|Phone Number
prican|str8|%8s|Current Primary Issue Tag - Canada
prirow|str8|%8s|Primary Issue Tag - Rest of World
priusa|str8|%8s|Current Primary Issue Tag - US
sic|str4|%4s|Standard Industry Classification Code
spcindcd|double|%6.0g|S&P Industry Sector Code
spcseccd|double|%6.0g|S&P Economic Sector Code
spcsrc|str4|%4s|S&P Quality Ranking - Current
state|str8|%8s|State/Province
stko|double|%4.0g|Stock Ownership Code
weburl|str60|%60s|Web URL
dldte|long|%td|Research Company Deletion Date
ipodate|long|%td|Company Initial Public Offering Date
conm|str58|%58s|Company Name
tic|str8|%8s|Ticker Symbol
cusip|str10|%10s|CUSIP

#### S&P Ratings (New)


Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
gvkey     |      str6|    %-9s|                  GVKEY
ratingdate|      long|    %td|                   Rating Date (ratingdate)
entity_id|       str6|    %-9s|                  CIQ Ratings Entity ID (entity_id)
entname    |     str111|  %-9s|                  Entity Name (entname)
ratingtypecode|  str10|   %-9s|                  Type of Rating (ratingtypecode)
ratingsymbol|    str7    |%-9s|                  Rating (ratingsymbol)


## Analysis Files 

#### (1) master_fomc_level_24

Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
daten|float|%td..|Date
hour|float|%10.0g|Hour
minute|float|%10.0g|Minute
time_fomc|float|%9.0g| FOMC meeting time 
unscheduled_meetings|float|%9.0g| Unscheduled meeting indicator 
fomc_id|float|%9.0g| FOMC # in dataset 
datetime|double|%tc| Stata datetime
date|strL|%9s| String date 
zcoupon_1y|double|%10.0g| 1Y Zero-Coupon, FRB
diff_zcoupon_1y|float|%9.0g| Daily change in 1Y-Zero Coupon 
MP1|double|%10.0g|MP1 (See Nakamura and Steinsson (2018), Appendix A)
MP2|double|%10.0g|MP2 (See Nakamura and Steinsson (2018), Appendix A)
ED2|double|%10.0g|ED2 (See Nakamura and Steinsson (2018), Appendix A)
ED3|double|%10.0g|ED3 (See Nakamura and Steinsson (2018), Appendix A)
ED4|double|%10.0g|ED4 (See Nakamura and Steinsson (2018), Appendix A)
mp_shock_klms|float|%9.0g| Unscaled PCA policy shock 
shock_[futures or Treasury][quarters ahead]_[window length] | float | %90g | Shock for ED/Treasury prices for the N-quarters ahead contract (if applicable) and length of window used to compute price change at each date 
MPshockWL[futures][quarters ahead]_[window length]|float|%9.0g|Length of window used to compute price change at each date 
indic_GKL|float|%9.0g|Indicator for data coming from Gürkaynak et al. (2022)
quarter|float|%9.0g| Stata quarterly date
date_daily|float|%9.0g|Daily date 
datestr|str10|%-10s|String date 
target|float|%9.0g|Federal Funds Target Rate from DFEDTAR and DFEDTARL 
scaled_diff_~1y|float|%9.0g|diff_zcoupon_1y x 10
mp_klms_U|float|%9.0g| Main policy shock variable; PCA performed on scheduled dates only 
mp_klms_UPCA2|float|%9.0g|Scores for component 2 from above 
mp_klmslong30|float|%9.0g|Alternative, "longer" policy shock including all the Treasury shocks in the PCA as well
mp_klmslong30~2|float|%9.0g|Scores for component 2 from above
mp_klms_U1h|float|%9.0g|Same as mp_klms_U, but uses 1-hour window
mp_klms|float|%9.0g|Same as mp_klms_U, but using all dates (including unscheduled meetings)
year|float|%9.0g| year 
post|float|%9.0g| Indicator for year $\geq$ 2007
postZLB|float|%9.0g| Indicator for ZLB years (see paper)
postnonZLB|float|%9.0g|Indicator for nonZLB post-2007 years (see paper)

#### (2) maintable_data

Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
daten|double|%td..|Date
hour|float|%10.0g|Hour
minute|float|%10.0g|Minute
time_fomc|float|%9.0g| FOMC time 
Unscheduled|float|%9.0g| Unscheduled FOMC meeting indicator
fomc_id|float|%9.0g|FOMC # in dataset
datetime|double|%tc|Stata datetime
permno|double|%8.0g|PERMNO id
prc|double|%12.0g|Price or Bid/Ask Average
shrout|double|%12.0g|Shares Outstanding
cfacpr|double|%12.0g|Cumulative Factor to Adjust Prices
cfacshr|double|%12.0g|Cumulative Factor to Adjust Shares/Vol
month|float|%9.0g| Stata month
cpi|float|%9.0g|Consumer Price Index for All Urban Consumers: All Items in U.S. City Average
shock_hf_daily|float|%9.0g|TAQ-derived one-day stock return 
window_shock_hf_daily~y|float|%9.0g|Length of one-day window used to compute shock_hf_daily, in minutes
shock_hf_30min|float|%9.0g|TAQ-derived 30-min HF stock return
window_shock_hf_30min|float|%9.0g|Length of window used to compute shock_hf_30min, in minutes
shock_hf_1hour|float|%9.0g|TAQ-derived 1-hour HF stock return
window_shock_hf_1hour|float|%9.0g|Length of window used to compute shock_hf_1hour, in minutes
MV|float|%9.0g| Market value: prc*shrout/1000
prev_MV|float|%9.0g|Previous day's market value
adj_MV|float|%9.0g|MV/cpi
adj_prev_MV|float|%9.0g|prev_MV/cpi
shock_hf_30min_dollar|float|%9.0g| shock_hf_30min in 2015 dollars 
unscheduled_meetings|float|%9.0g|Unscheduled FOMC date indicator
date|strL|%9s|String date 
mp_shock_klms|float|%9.0g|Unscaled PCA policy shock
quarter|float|%9.0g|Stata quarterly date 
shock_[maturity]_[window length]|float|%9.0g|Shock for Treasury yields and length of window used to compute price change at each date
date_daily|float|%9.0g|Daily date
datestr|str10|%-10s|String date
target|float|%9.0g|Federal Funds Target Rate from DFEDTAR and DFEDTARL
mp_klms_U|float|%9.0g|Main policy shock variable; PCA performed on scheduled dates only, $\omega_t$
mp_klms_UPCA2|float|%9.0g|Scores for component 2 from above 
mp_klmslong30|float|%9.0g| 	Alternative, “longer” policy shock including all the Treasury shocks in the PCA as well
mp_klmslong30_PCA2|float|%9.0g| 	Scores for component 2 from above
mp_klms_U1h|float|%9.0g| 	Same as mp_klms_U, but uses 1-hour window
mp_klms|float|%9.0g|Same as mp_klms_U, but using all dates (including unscheduled meetings)
year|float|%9.0g|Year
ffi|float|%40.0g|ffi|Fama-French industry code (49 industries)
duptag|byte|%8.0g|tag(permno)
rank|float|%9.0g|rank of (adj_MV) by daten
count|float|%9.0g|count of (adj_MV) by daten 
ptile|float|%9.0g| $X_{it}$ (MV percentile)
Fptile_TEMP|float|%9.0g|Intermediate for Fptile
Fptile|float|%9.0g|Average FOMC-date ptile for a firm i; overwritten to equal ptile_consis, rank from 0-1 by this variable 
Fdecile|float|%9.0g|Ventile by Fptile 
firmtag|byte|%8.0g|tag(permno)
rankF|float|%9.0g|rank of (Fptile)
countF|float|%9.0g|count of (Fptile)
ptile_consis|float|%9.0g|0-1 percentile of Fptile; "normalizes" to uniform dist of $\bar{X}_i$ over firms
Fdecile_consis|float|%9.0g|Ventile by ptile_consis
indrank|float|%9.0g|rank of (adj_MV) by daten ffi
indcount|float|%9.0g|count of (adj_MV) by daten ffi 
indptile|float|%9.0g|ptile by above
indFptile_TEMP|float|%9.0g|placeholder in computation of indFptile
indFptile|float|%9.0g|Within-industry percentile 
indFdecile|float|%9.0g|Ventile by within-industry percentile 
rank_indF|float|%9.0g|rank of (indFptile)
count_indF|float|%9.0g|count of indFptile
ptile_consis_ind|float|%9.0g|0-1 percentile of indFptile (i.e., normalized to uniform)
Fdecile_consis_ind|float|%9.0g| Ventile by ptile_consis_ind
Fwindowlen|float|%9.0g|Average firm window length 
WLxSHOCK|float|%9.0g|$\omega_t * \text{Window Length}_{it}$; i.e., surprise MP shock times Length of window used to compute shock_hf_30min, in minutes
mp_klms_ptile|float|%9.0g|$\omega_t * X_{it}$ interaction term (unused)
mp_klmsFptile|float|%9.0g|$\omega_t * \bar{X}_i$ interaction term: shock times consistent (normalized) firm percentile 
post|float|%9.0g|$\text{post}$ Year $\geq$ 2007 indicator 
postZLB|float|%9.0g|$\text{post (ZLB)}$ Post-ZLB indicator 
excluderZLB|float|%9.0g|Indicator for !missing(postZLB) for running ZLB, non-ZLB separately (unused)
postnonZLB|float|%9.0g|$\text{post (non-ZLB)}$ Post-nonZLB indicator 
excludernonZLB|float|%9.0g| Indicator for !missing(postnonZLB) for running ZLB, non-ZLB separately (unused) 
tempzlbtest|float|%9.0g| ZLB+nonZLB indicators (should sum to 1)
Fptilepost|float|%9.0g|$X_{i} * \text{post}$ interaction between consistent firm Ptile and post 
Fptile_postZLB|float|%9.0g|$X_{i} * \text{post (ZLB)}$ interaction 
Fptile_postno~B|float|%9.0g|$X_{i} * \text{post (non-ZLB)}$ interaction 
mp_klmspost|float|%9.0g|$\omega_t * \text{post}$ interaction 
mp_klmspostZLB|float|%9.0g|$\omega_t * \text{post (ZLB)}$ interaction
mp_klmspostnonZLB|float|%9.0g|$\omega_t * \text{post (non-ZLB)}$ interaction
mp_klmsFptilepost|float|%9.0g|$\omega_t * \bar{X}_i * \text{post}$ interaction
mp_klmsFptilepostZLB|float|%9.0g|$\omega_t * \bar{X}_i * \text{post (ZLB)}$ interaction
mp_klmsFptilepostnonZLB|float|%9.0g|$\omega_t * \bar{X}_i * \text{post (non-ZLB)}$ interaction
mp_klms_ptilepost|float|%9.0g|$\omega_t * X_{it} * \text{post}$ interaction
mp_klms_ptile_postZLB|float|%9.0g|$\omega_t * X_{it} * \text{post (ZLB)}$ interaction
mp_klms_ptile_postnonZLB|float|%9.0g|$\omega_t * X_{it} * \text{post (non-ZLB)}$ interaction

#### (3) estdata_update_ptilec 

Variable Name | Type | Format |	Label
| ----------- | ----------- | ----------- | ----------- |
permno|double|%8.0g|PERMNO (identifier)
quarter_d|float|%9.0g|Quarterly date 
b_mkt|double|%9.0g|Last nonmissing (lastnm) b_mkt from WRDS Beta Suite (see above)
gvkey|long|%12.0g|GVKEY (identifier)
liid|byte|%8.0g|LIID (identifier)
lpermco|double|%12.0g|LPERMCO (identifier)
year|double|%8.0g|Year
quarter|double|%8.0g|Quarterly date
loc|str4|%4s|Current ISO Country Code - Headquarters
naics|str6|%6s|North American Industry Classification Code
cpi|float|%9.0g|Consumer Price Indices (CPIs, HICPs), COICOP 1999: Consumer Price Index: Tot..
ffi|float|%40.0g|ffi|Fama-French industry code (49 industries)
maxdate|float|%9.0g|Max date from quarterly data 
id|float|%9.0g|group(gvkey)
adj_MV|float|%9.0g|CRSP  
earnings|float|%9.0g|dpq+oiadpq; operating income + depreciation/amortization
leader_mcap|float|%9.0g|1st quarterly lag of indicator for top 5% by market value in industry
follower_mcap|float|%9.0g|1-leader_mcap
top4_mcap|float|%9.0g|Top four firms by market value (first lag) in industry
top10_mcap|float|%9.0g|Top ten firms by market value (first lag) in industry 
icr|float|%9.0g|icr (interest coverage ratio)
icr_lag[n]|float|%9.0g|nth lag of icr
icr_mean|float|%9.0g|(L1.icr+L2.icr+L3.icr)/3
icr_median|float|%9.0g|median of lags 1-12 of icr
borrowing_cost2|float|%9.0g|xintq/(dlcq+dlttq), i.e., Interest and Related Expense- Total / (Debt in Current Liabilities + Long-term debt, Total)
debt|float|%9.0g|dlcq+dlttq, i.e., Debt in Current Liabilities + Long-term debt, Total
log_debt|float|%9.0g|log debt
log_assets|float|%9.0g|log assets (atq)
log_ppe|float|%9.0g|log PPE (ppentq)
logrev|float|%9.0g|log revenue (revtq)
Paqcq[h]/Pcapxq[h]|float|%9.0g|Cum. sum of acquisitions from $t=0$ to $t=h$ divided by $t-1$ value of assets 
L[variable][q]|float|%9.0g|q-th lag of [variable], q can be 0
F[variable][q]|float|%9.0g|q-th ahead value of [variable], q can be 0
ceqq|float|%9.0g|Common/Ordinary Equity - Total
prccq|float|%9.0g|Price Close - Quarter
cshoq|float|%9.0g|Common Shares Outstanding
BM|float|%9.0g|Book-market := 100*ceqq/market_value2
PE|float|%9.0g|Price-earnings: market_value2/earnings 
shock*, MPshockWL*|double|%9.0g|quarterly sum of variables as defined in codebook for (2), maintable_data.dta
mp_klms*|double|%9.0g|quarterly sum of variables as defined in codebook for (2), maintable_data.dta
diff_zcoupon_1y|double|%9.0g|quarterly sum of diff_zcoupon_1y as defined in codebook for (2), maintable_data.dta 
target|float|%9.0g|last nonmissing value (lastnm) of Fed Funds Target (from DFEDTAR/DFEDTARL) in the quarter
post|float|%9.0g|last nonmissing post indicator (lastnm) as defined in codebook for (2), maintable_data.dta
postZLB|float|%9.0g|(lastnm) postZLB as defined in codebook for (2), maintable_data.dta
postnonZLB|float|%9.0g|(lastnm) postnonZLB as defined in codebook for (2), maintable_data.dta
mp_*gk, shock_[maturity]_gk|double|%10.0g|Weighted average of policy surprise PCA shocks, Treasury yield shocks according to Ottonello and Winberry (2020). 
pc[n]_10_fomc|double|%9.0g|Scores from component [n] of PCA shock of all 10 Bauer and Swanson (2023) key variables, including intra-FOMC date summed: (1) unemployment surprises; (2) payroll surprises; (3) real GDP surprises; (4) core CPI surprises; (5) S&P 500 returns; (6) changes in slope of Treasury yield curve; (7) daily return on pcommodity (see ret_pcommodity below), and the FOMC-date values of lag_bbk (one-day lagged value of Blue-Butters-Kelley index), change_6_mo_corecpi := ((log CPIXt−2 − log CPIXt−8) − (log CPIXt−8 − log CPIXt−14)) * 200m, and core CPI expectations from MMS/Reuters
lrgdp_surprise|double|%9.0g|1-FOMC date lagged value of: as-released GDP (ALFRED) minus expectations (MMS, Reuters), summed over each quarter
ret_sp500|double|%9.0g|change in daily S&P 500 at each FOMC date, summed over the quarter
ret_pcommodity|double|%9.0g|daily difference in log(BCOM) + 0.4 * log(BCOMAG), summed over the quarter
diff_slope_yield|double|%9.0g|daily difference in T10Y3M (slope of Treasury yield curve, FRED) summed over the quarter
rgdp_surprise|double|%9.0g|as-released GDP (fred) - expectations (MMS, Reuters), summed over each quarter
corecpi_surprise|double|%9.0g|Actual as-released core CPI from ALFRED (archival FRED) minus expectations (MMS, Reuters) summed over the quarter
unemp_surprise|double|%9.0g|Actual as-released unemployment from ALFRED (archival FRED) minus expectations (MMS, Reuters) summed over the quarter
payroll_surprise|double|%9.0g|(sum) Actual as-released payroll from ALFRED (archival FRED) minus expectations (MMS, Reuters) summed over the quarter
lag_bbk|double|%9.0g| one-day lagged value of Blue-Butters-Kelley index, summed over the quarter
time_trend|float|%9.0g| Stata quarterly date minus 140 
double_[shock][_gk]|float|%9.0g|Aggregated MP shock (e.g., mp_klms, mp_klms_U, mp_klms_U_gk, shock_2Y_30min) times leader (top 5% of industry by mkt cap). "_U" indicates that the shock uses only scheduled meetings; "_gk" means the shocks are aggregated at the quarterly level following the Ottonello and Winberry (2020) procedure rather than simple average
triple_[shock][_gk]|float|%9.0g|Triple interaction of aggregated MP shock (e.g., mp_klms, mp_klms_U, mp_klms_U_gk, shock_2Y_30min) times leader (top 5% of industry by mkt cap) times the quarterly lag of the Federal Funds target (DFEDTAR/DFEDTARL); "_U" indicates that the shock uses only scheduled meetings; "_gk" means the shocks are aggregated at the quarterly level following the Ottonello and Winberry (2020) procedure rather than simple average
triple_pZLB_[shock][_gk]|float|%9.0g|Triple interaction of aggregated MP shock (e.g., mp_klms, mp_klms_U, mp_klms_U_gk, shock_2Y_30min) times leader (top 5% of industry by mkt cap) times the quarterly lag of indicator for post-ZLB; "_U" indicates that the shock uses only scheduled meetings; "_gk" means the shocks are aggregated at the quarterly level following the Ottonello and Winberry (2020) procedure rather than simple average
triple_pnZLB_[shock][_gk]|float|%9.0g|Triple interaction of aggregated MP shock (e.g., mp_klms, mp_klms_U, mp_klms_U_gk, shock_2Y_30min) times leader (top 5% of industry by mkt cap) times the quarterly lag of indicator for post-non-ZLB; "_U" indicates that the shock uses only scheduled meetings; "_gk" means the shocks are aggregated at the quarterly level following the Ottonello and Winberry (2020) procedure rather than simple average
tripletime_[shock][_gk]|float|%9.0g|time_trend times leader (top 5% of industry by mkt cap) times shock 
tripletime_mp_klms_U|float|%9.0g|Triple interaction of time_trend times leader (top 5% of industry by mkt cap) times the quarterly lag of FF target (DFEDTAR/DFEDTARL)
Lileader|float|%9.0g|1-quarter lag of FF target (DFEDTAR/DFEDTARL) times leader (top 5% of industry by mkt cap)
LpostZLBleader|float|%9.0g|lagged indicator of post-ZLB times leader (top 5% of industry by mkt cap)  
LpostnonZLBleader|float|%9.0g|lagged indicator of post-non-ZLB times leader (top 5% of industry by mkt cap)  
tripletime_postZLB|float|%9.0g| time_trend times lagged indicator of post-ZLB times leader (top 5% of industry by mkt cap)  
tripletime_postnonZLB|float|%9.0g| time_trend times lagged indicator of post-non-ZLB times leader (top 5% of industry by mkt cap)  
weight_currq|float|%9.0g|Share of meetings that happened in current quarter of those that happened in last 90 days 
weight_lastq|float|%9.0g|Share of meetings that happened in previous quarter of those that happened in last 90 days
[LHS variable]_gk|float|%9.0g|Current-quarter [LHS variable] * weight currq + last-quarter [LHS variable] * weight_lastq
L1_[LHS variable]|float|%9.0g|First quarterly lag [LHS variable]
market_value|float|%9.0g|prc*shrout/1000 (from CRSP, not Quarterly fundamentals data)
treasury_rate|float|%9.0g|FRED DGS1, 1Y Treasury 
leverage  |  float |  %9.0g |  (dlcq+dlttq)/atq; i.e., debt in current liabilities plus total long-term debt over total assets
debt2|float|%9.0g|Debt placeholder used for interpolation
dd|double|%10.0g|Distance to default calculated using Gilchrist and Zakrajšek (2012) procedure 
dd_flag|float|%9.0g|DD = "inf" flag 
rating|str10|%10s|S&P Domestic Long Term Issuer Credit Rating (from pre-2017 database)
ratingsymbol|str7|%-9s|S&P Rating (from post-2017 database)
leadertime|float|%9.0g|time_trend times leader (top 5% of industry by mkt cap)
industrytime|float|%9.0g|group(year quarter ffi) -- fixed effect 
valid|float|%9.0g|Not missing adjusted MV (for percentile ranking variable)
rank|float|%9.0g|rank of (adj_MV) by quarter_d
count|float|%9.0g|count of (adj_MV) by quarter_d
ptile|float|%9.0g|percentile rank of firm by adj_MV within quarter
Fptile|float|%9.0g|firm-average percentile 
Fdecile|float|%9.0g|Ventile by Fptile 
firmtag|byte|%8.0g|tag(id) -- indicator for first instance of each firm id 
rankF|float|%9.0g|rank of (Fptile)
countF|float|%9.0g|count of Fptile 
ptile_consis|float|%9.0g|Percentile by Fptile; i.e., Fptile normalized to uniform distribution over firms 
Fdecile_consis|float|%9.0g|Ventile by ptile_consis
indrank|float|%9.0g|rank of (adj_MV) by quarter_d ffi (i.e., within-industry rank by quarter)
indcount|float|%9.0g|count of (adj_MV) by quarter_d ffi
indptile|float|%9.0g|within-industry percentile by adj_MV within quarter 
indFptile|float|%9.0g|average of a firm's within-industry percentile by adj_MV within quarter 
indFdecile|float|%9.0g|Ventile by indFptile
rank_indF|float|%9.0g|rank of (indFptile)
count_indF|float|%9.0g|count of (indFptile)
ptile_consis_ind|float|%9.0g|rank by indFptile; i.e., indFptile normalized to uniform distribution over firms
Fdecile_consis_ind|float|%9.0g|Ventile by ptile_consis_ind
neg_ptile_consis_ind|float|%9.0g|-1 * ptile_consis_ind
neg_leader|float|%9.0g|rank of (neg_ptile_consis_ind) by ffi
top4temp|float|%9.0g|top four firms by ptile_consis_ind within an industry (intermediate variable, not filled in for all dates)
top4|float|%9.0g|top four firms by ptile_consis_ind within an industry
*SAL|float|%9.0g|Using "saleq" (measure of sales), follows same pattern as above (e.g., ptile, indptile, Fptile, indFptile)
*SIC|float|%9.0g|rank of (adj_MV) by quarter_d sic
sicindustrytime|float|%9.0g|group(year quarter sic)
temptag|byte|%8.0g|tag(id quarter_d) -- indicator for first instance of each firm id / quarter_d pair 

#### (4) LP_baseline_coeffs
- Contains coefficients for $h = 1, ..., 11$ from estimation of $\Delta y_{i,j,t+h-1}=\alpha_{j,t}^{h}+\beta_{ZLB}^{h}(\omega_t*L_{i,j,t-1}) +\beta_{\Delta}^{h}(\omega_t*L_{i,j,t-1}*FFR_{t-1})+\delta'_{h}z_{i,j,t}+\sum_{\ell=1}^{3}\Gamma'_{h}\theta_{i,j,t-\ell}+\epsilon_{i,j,t+h-1}$ for each dependent variable, using estdata_update_ptilec.dta. 

## References 
Bauer, M. D., and Swanson, E. T. (2023), A Reassessment of Monetary Policy Surprises and High-Frequency Identification. NBER Macroeconomics Annual 2023 37:, 87-155. https://doi.org/10.1086/723574

Gilchrist, S., and Zakrajšek, E. (2012), Credit Spreads and Business Cycle Fluctuations. American Economic Review 102 (4): 1692–1720. DOI: 10.1257/aer.102.4.1692

Ottonello, P. and Winberry, T. (2020), Financial Heterogeneity and the Investment Channel of Monetary Policy. Econometrica, 88: 2473-2502. https://doi.org/10.3982/ECTA15949

