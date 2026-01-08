* Data Construction file -> analysis_KLMS

timer on 1 

* A. Base Files ================================================================
**(0) Updated list of FOMC announcements. 
use "${rawh}/manual/fomc_times_2024_temp.dta", clear 
	gen double daten_ms = daten * 24 * 60 * 60 * 1000
	gen double time_fomc_ms = time_fomc 
	gen double datetime = daten_ms + time_fomc_ms
	drop time_fomc_ms daten_ms
	format datetime %tc
	save "${proch}/fomc_times_2024.dta", replace  

	*Make a dates-only dataset to feed into R WRDS query. 
	use "${proch}/fomc_times_2024.dta", clear 
	keep daten time_fomc fomc_id hour minute
	gen date = string(daten, "%tdCCYY-NN-DD")
	rename (hour minute) (hour_fomc minute_fomc)
	save "${proch}/FTIMES.dta", replace // ======================================

** (1) Policy rates: Fed Target, Zero coupon: uses https://www.federalreserve.gov/data/yield-curve-tables/feds200628.csv
*First: fed funds rate 
*import fred DFEDTAR DFEDTARL, clear // FF target, FF target range lower limit 
use "$import_fred_snapshot/DFEDTAR_DFEDTARL.dta", clear
	replace DFEDTAR = DFEDTARL if missing(DFEDTAR)
	drop DFEDTARL 
	rename DFEDTAR target 
	save "$proch/FFtarget.dta", replace 

import delimited using "${rawh}/orig/FRB/feds200628.csv", clear  
	rename v1 date 
	rename v69 sveny01
	drop in 1/8
	keep date sveny01
	gen daten = date(date, "YMD")
	format daten %td
	rename sveny01 zcoupon_1y
	sort daten 
	drop if zcoupon_1y == "NA"
	destring zcoupon_1y, replace
	gen t = _n
	tsset t
	gen diff_zcoupon_1y = d.zcoupon_1y
	drop t
	save "${proch}/zero_coupon_daily.dta", replace // ===========================
	
** (2) CPI updated. 
*import fred CPIAUCSL, clear
use "$import_fred_snapshot/CPIAUCSL.dta", clear
	rename CPIAUCSL cpi
	gen month = mofd(daten)
	drop daten datestr
	* Normalizing so 2019/12 is 1 || now it's 2015 Dec dollars to be consistent with Quarterly. 
	su cpi if month == 671
	replace cpi = cpi/r(mean) 
	save "$proch/cpifred.dta", replace // merged in next section. 	

** (3) CRSP for Market Value = Price * Shares Outstanding 
use "$rawh/WRDS/CRSP_Stocks_Daily_all", clear // original dataset 
	rename *, lower
	drop if year(date)<1980

	replace prc = -prc if prc<0 // 10,642,331/74,602,901, or 14.2 percent 
	*identifier
	egen temp = tag(permno date)
	drop if temp == 0 // 17,733 dropped
	drop temp
	*keep what we need
	keep permno date /*permco accomp siccd naics*/ prc /*divamt vol*/ cfacpr cfacshr shrout
		drop if year(date) >= 2021 // since we got >=2021 in the new data 
	tempfile CRSP_pre2020
	save `CRSP_pre2020'
	
	/*
	CRSP Panel Data.
https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/annual-update/stock-security-files/daily-stock-file/
	Choose date range
	permno
	search entire database
	select shrout prc naics cfacpr cfacshr
	
	The following matrix of database linking from WRDS is very helpful (!):
	// https://wrds-www.wharton.upenn.edu/pages/wrds-research/database-linking-matrix/
	*/
use "${rawh}/WRDS/CRSP_Stocks_Daily_2124_update", clear 
	rename *, lower
	drop naics cusip
	replace prc = -prc if prc<0 // 218,715/9,335,070, or 2.3 percent 
	*identifier
	egen temp = tag(permno date)
	drop if temp == 0 // none 
	drop temp
	append using `CRSP_pre2020'
	rename date daten 
	save "${proch}/CRSP_allstocks.dta", replace // ==============================
	
	*Make "price-correction" dataset, used for company-level stocks 
	*keep permno daten cfacpr 
	gen month = mofd(daten)
	merge m:1 month using "$proch/cpifred.dta"
	drop _merge 
	drop if missing(permno) | missing(daten)
	*make adjusted market value 
	gen MV = prc*shrout/1000
	bys permno (daten): gen prev_MV = MV[_n - 1]
	gen adj_MV = MV/cpi
	gen adj_prev_MV = prev_MV/cpi	
	keep permno daten cfacpr /*and*/ month MV prev_MV adj_MV adj_prev_MV
	save "$proch/CRSP_price_correction_new.dta", replace // =====================

** (4) MP1, MP2, ED2, ED3, ED4. ** ED2, 3, 4 good for dates < Jan 2022. From then on will use SOFR per FRB paper. 
* (a) ED Futures 2019-2021; (b) FF futures 2019-2024; (c) SOFR futures 2022-2024. 
*The data comes from TickWrite. FF, ED, and SR3 futures. The date in the name of the data refers to expiration month/year. Get all months for FF and H,M,U,Z for ED. 
*Time based bars, Granularity 1 minutes, Skip empty intevals, include all sessions. 
*https://s3-us-west-2.amazonaws.com/tick-data-s3/pdf/TickWrite7_Manual.pdf

/* ED futures go out up to 10Y
https://www.cmegroup.com/education/files/eurodollar-futures-foundational-concepts.pdf
FF futures go out up to 3Y
https://www.cmegroup.com/education/courses/introduction-to-fed-fund-futures.html */ 

*Main shock data: Use GSS (2021) dataset. 
import excel "$rawh/orig/gurkaynak2021/GSSrawdata.xlsx", clear firstrow
	drop if year < 1994
	rename Date daten 
	destring MP1 MP2 ED2 ED3 ED4, replace

	drop if inlist(daten, 17861, 17867)
	pca MP1 MP2 ED2 ED3 ED4
	predict mp_shock_klms, score
	keep daten MP1 MP2 ED2 ED3 ED4 mp_shock_klms 
	save "${proch}/mpshocks_18.dta", replace // =================================

// SIMPLE DIFF WINDOW PROGRAM FOR RETURN 
cap program drop diff_window
program define diff_window, rclass
args variable window

if "`window'" == "30min"{
	local lower_min -10
	local upper_min 20
}
else if "`window'" == "1hour" {
	local lower_min -15
	local upper_min 45
}

keep if daten == daten_fomc
gen hour_trade = hh(timen)
gen diff_min = Clockdiff(time_fomc, timen, "minute")
gen fomc_diff = -1 if diff_min < `lower_min' 
replace fomc_diff = 1 if diff_min >= `upper_min'  
drop if missing(fomc_diff)

	isid fomc_id fomc_diff timen // ============================================
gsort fomc_id fomc_diff timen /*id*/ //, stable // STABLE ADDED 5/14
// save "${proch}/eurodollar_test.dta", replace
// use "${proch}/eurodollar_test.dta", clear
by fomc_id fomc_diff: gen last_obs = 1 if _n == _N
by fomc_id fomc_diff: gen first_obs = 1 if _n == 1
keep if ((last_obs == 1) & (fomc_diff == -1)) | ((first_obs == 1) & (fomc_diff == 1))
gsort daten timen /*id*/ //, stable // STABLE ADDED 5/14

gen price = 100 - close
by daten: gen shock_`variable'_`window' = price - price[_n-1]
by daten: gen MPshockWL_`variable'_`window' = timen - timen[_n-1]
end



	*Make a "calendar" dataset for accurately computing distance to end of month. 
	clear
	local start = td("01jan1994")
	local end = td("31dec2026")
	local ndays = `end' - `start' + 1
	disp `ndays'
	set obs `ndays'
	gen daten = `start' + _n - 1
	format daten %td // calendar daily dates
	save "$proch/calendar.dta", replace 
	
	gen exp_quarter = qofd(daten) // to merge with exp_quarter in ED/SOFR file. 
	gen year = year(daten)
	gen month = month(daten)
	gen firstday = mdy(month, 1, year)
	gen dayofwk = dow(firstday + 7)
	gen offset = mod(3 - dayofwk, 7)
	gen firstwed = firstday + offset 
	gen thirdwed = firstday + offset + 14 // this is 2 days AFTER ED expiration date -- none of the Monday holidays for Bank of England conflict 
		format thirdwed %td
	gen contract_exp = thirdwed - 1 /*2*/ // contract expirations, needed in SOFR calculations. Tuesday before 3rd Wed
		format contract_exp %td
	keep if inlist(month, 3, 6, 9, 12)
	keep exp_quarter thirdwed contract_exp
	gen sofr = 1
	duplicates drop 
	save "$proch/thirdwed_byq", replace  

// FOMC DATES LIST 
***** Adapting FOMC dates so we know what was the next scheduled meeting every time
use "${proch}/fomc_times_2024.dta", clear
	gen year = year(daten)
	keep if Unscheduled == 0
	gen next_scheduled_meeting = daten[_n + 1]
// 	replace next_scheduled_meeting = td(19mar2024) if missing(next) // HARDCODED, may need to change. // LEGACY VER 
    replace next_scheduled_meeting = td(29jan2025) if missing(next) // HARDCODED, may need to change. // CORRECT VER
	
	keep daten next_scheduled_meeting
	joinby daten using "${proch}/fomc_times_2024.dta", unmatched(both)
	gen year = year(daten)
	drop if year < 1994
	sort daten
	drop _merge
	replace next = next[_n-1] if missing(next)
	format next %td

	*** Get months that we need to merge. If last seven days, substitute to next month (this is for FF futures)
	gen current_month = mofd(daten)
	* NEW 
	merge 1:1 daten using "$proch/calendar", nogen 
	gen monthn = month(daten)
	gen yearn = year(daten)
	bysort monthn yearn (daten): gen numdays_temp = day(daten) if _n == _N 
	bysort monthn yearn: egen numdays = mean(numdays_temp)
	drop monthn yearn numdays_temp 
	gsort daten 
	drop if missing(fomc_id) // get rid of all the non FOMC dates merged in with calendar dataset 

	gen day_diff_current = 30 /*numdays*/ - day(daten)
	gen tag_current = 1 if day_diff_current <=7
	replace current_month = current_month + 1 if tag_current == 1
	gen next_fomc_month = mofd(next_scheduled_meeting)
	gen day_next = day(next_scheduled_meeting)
	gen day_diff_next = 30 /*numdays*/ - day(next_scheduled_meeting)
	gen tag_next = 1 if day_diff_next <=7
	replace next_fomc_month = next_fomc_month + 1 if tag_next == 1
	keep daten time_fomc hour minute current_month day_diff_current tag_current next_fomc_month day_diff_next tag_next fomc_id day_next /*numdays*/ 
	save "${proch}/fomc_hour_futures_ff.dta", replace

***Load Eurodollar futures: For 30min need for FOMC Dates 2019-2022, since we have GSS before that. 
*But, the year is indexing the contract expiration, so to get eg ED4 we need to go 2Y out for some Qtrs. 
*Historical all the way back to '95 is for 1h shocks and for backtesting. 


*** Loading pre 2000 years NEW 5/13
local yearlist
forv year = 95/99{
	local yearlist `yearlist' "`year'"
}
* Loading 2000-2009
forv year = 0/9{
	local yearlist `yearlist' "0`year'"
}
*Loading 2010-onwards
forv year = 10/24{
	local yearlist `yearlist' "`year'"
}


*** Creating master eurodollar file
foreach year in `yearlist'{
disp `year'
foreach month in H M U Z{
import delimited "${rawh}/TickWrite/Eurodollars_FF_updated/ED`month'`year'.csv", clear
	gen daten = daily(date, "MDY")
	egen contract_exp = max(daten)
	gen exp_quarter = qofd(contract_exp)
	gen timen = clock(time, "hm")
	gen hour = hh(timen)
	gen minute = mm(timen)
	gen sofr = 0 
	// rename (hour minute timen) (hour_trade minute_trade timen_trade)
	if ("`month'" == "H") & (`year' == 95){
		save "${proch}/eurodollar_futures_14_24.dta", replace
	}
	else{
		append using "${proch}/eurodollar_futures_14_24.dta"
		sleep 800 // helps with read-only errors 
		save "${proch}/eurodollar_futures_14_24.dta", replace
	}
	}
	}
	
*add sofrs 
* Based on this paper, use SOFR from Jan 2022 onward. https://www.federalreserve.gov/econres/feds/files/2024034pap.pdf
foreach year in /*21*/ 22 23 24 25 26 { 
disp `year'
	local qcount 0
foreach month in H M U Z{
	local qcount = `qcount' + 1 
import delimited "$rawh/TickWrite/SOFR_all/SR3`month'`year'all.csv", clear
	gen daten = daily(date, "MDY")
	gen sofr = 1
// 	egen contract_exp = max(daten) // this logic doesn't work here for all contracts, because some expirations haven't occurred yet  
	gen year = 2000 + `year'
	gen quarter = `qcount'
	gen exp_quarter = yq(year, quarter) +1 /* !! */ // This corrects an error inside Tickwrite -- expiration quarter is off by 1. Can look at raw data
	drop year quarter 
	merge m:1 exp_quarter using "$proch/thirdwed_byq", keep(matched) nogen // this gets us contract_exp 
	gen timen = clock(time, "hm")
	replace timen = timen + msofseconds(60*60) // SOFR is in Central but ED is in ET by default. 
	gen hour = hh(timen)
	gen minute = mm(timen)
		append using "${proch}/eurodollar_futures_14_24.dta"
		sleep 800 // helps with read-only errors 
		save "${proch}/eurodollar_futures_14_24.dta", replace
	}
	}
	
	/* *check isid
	forv i = 236/252 {
		disp "quarter : `i'"
		levelsof contract_exp if exp_quarter == `i' & sofr == 0 
	} */
	
	*** Getting contract expiration dates
	use "${proch}/eurodollar_futures_14_24.dta", clear
		gsort daten timen //
		// gen id = _n // ==== key to sort on this later for reproducibility; allows sort by time within FOMC date ====
		save "${proch}/eurodollar_futures_14_24.dta", replace 
	keep exp_quarter contract_exp sofr 
	duplicates drop
	gsort sofr contract_exp 
	save "${proch}/eurodollar_expiration_dates_14_24.dta", replace

	***** Getting the actual quarters we need to merge
	forv q = 1/4{
	if `q' == 1 {
	use "${proch}/fomc_hour_futures_ff.dta", clear
	gen sofr = 1 if daten >= td(01jan2022)
	replace sofr = 0 if sofr == . 
	}
	else{
	use "${proch}/fomc_hour_bonds_eurodollar_14_24.dta", clear
	}
	gen exp_quarter = qofd(daten) + `q'
	merge m:1 exp_quarter sofr using "${proch}/eurodollar_expiration_dates_14_24.dta", keep(matched) nogen
	gen diff_days_`q' = contract_exp - daten
	replace exp_quarter = exp_quarter + 1 if diff_days_`q' <= (30*3*`q') 
	rename exp_quarter quarter_`q'_ahead
	keep daten hour minute fomc_id quarter* sofr time 
	save "${proch}/fomc_hour_bonds_eurodollar_14_24.dta", replace
	sleep 800
	}
	replace quarter_2 = quarter_2 + 1 if quarter_1 == quarter_2
	replace quarter_3 = quarter_3 + 1 if quarter_2 == quarter_3 // I think this was mistake earlier, "replace quarter 3  =quarter_2 +1"
	replace quarter_4 = quarter_4 + 1 if quarter_3 == quarter_4
	//gen actual_quarter = qofd(daten)
	save "${proch}/fomc_hour_bonds_eurodollar_14_24.dta", replace

	***** For each q ahead, merge this dataset with eurodollar
	*30MIN VERSION 
	local m 1
	forv q = 1/4{
	disp "`m'"
	use "${proch}/fomc_hour_bonds_eurodollar_14_24.dta", clear
	keep daten hour minute fomc_id quarter_`q'_ahead time_fomc sofr
		keep if daten >= td(01jan1995) //NEW
	rename quarter_`q'_ahead exp_quarter
	rename daten daten_fomc
	joinby exp_quarter sofr using "${proch}/eurodollar_futures_14_24.dta" 
		drop if yofd(daten) >= 2022 & sofr == 0 
		drop if yofd(daten) < 2022 & sofr == 1
		drop if yofd(contract_exp) >= 2023 & sofr == 0 // don't need these ED contracts, drop just in case 
	*** Looping over windows
// 	foreach window in "30min" /*"1hour" "daily"*/ {
		preserve
		local adj_q = `q' + 1
		diff_window "ed`adj_q'" "30min"
		keep if shock != . 
		keep shock_ed`adj_q' MPshockWL_ fomc_id
		if `m' == 1 {
			save "${proch}/eurodollar_shock_final_14_24.dta", replace
			local m =  `m' + 1
		}
		else {
			merge 1:1 fomc_id using "${proch}/eurodollar_shock_final_14_24.dta", nogen
			save "${proch}/eurodollar_shock_final_14_24.dta", replace
			local m =  `m' + 1
		}
		restore
// 	}
	}
	
	*1HOUR VERSION 
	local m 1
	forv q = 1/4{
	disp "`m'"
	use "${proch}/fomc_hour_bonds_eurodollar_14_24.dta", clear
	keep daten hour minute fomc_id quarter_`q'_ahead time_fomc sofr
		keep if daten >= td(01jan1995) // NEW
	rename quarter_`q'_ahead exp_quarter
	rename daten daten_fomc
	joinby exp_quarter sofr using "${proch}/eurodollar_futures_14_24.dta"
		drop if yofd(daten) >= 2022 & sofr == 0 
		drop if yofd(daten) < 2022 & sofr == 1
		drop if yofd(contract_exp) >= 2023 & sofr == 0 // don't need these ED contracts, drop just in case 
	*** Looping over windows
// 	foreach window in "30min" /*"1hour" "daily"*/ {
		preserve
		local adj_q = `q' + 1
		diff_window "ed`adj_q'" "1hour" // "`window'"
		keep if shock != . 
		keep shock_ed`adj_q' MPshockWL_ fomc_id
		if `m' == 1 {
			save "${proch}/eurodollar_hourshock_final_14_24.dta", replace
			local m =  `m' + 1
		}
		else {
			merge 1:1 fomc_id using "${proch}/eurodollar_hourshock_final_14_24.dta", nogen
			save "${proch}/eurodollar_hourshock_final_14_24.dta", replace
			local m =  `m' + 1
		}
		restore
	}	
	
	*Backtesting against GSS data 
	use "${proch}/mpshocks_18.dta", clear 
	gen fomc_id = _n 
	tempfile GSS 
	save `GSS'
	use "${proch}/eurodollar_shock_final_14_24.dta", clear 
	merge 1:1 fomc_id using `GSS', keep(matched) nogen 
	tw (scatter ED2 shock_ed2_30min) (line ED2 ED2)
	tw (scatter ED3 shock_ed3_30min) (line ED3 ED3)	
	tw (scatter ED4 shock_ed4_30min) (line ED4 ED4)	
	corr(ED2 shock_ed2_30min)
	corr(ED3 shock_ed3_30min)
	corr(ED4 shock_ed4_30min)
	graph close 
		
	
*LEGACY FEDFUNDS -- for 1hour \omega_t
import delimited "${rawh}\TickWrite\fedfunds_cme_highfreq\unzipped\main_ff.csv", stringcols(_all) clear
compress
*keep v1 v2 v4 v7 v10
rename (v1 v2 v4 v7 v10) (date_str time_str type exp_month_str close_str)
split close_str, p(.)
sleep 1000
gen digit_temp = strlen(close_str1)
destring close_str, gen(close)
sleep 1000
replace close = close / (10^(digit_temp - 2))
drop close_str* digit_temp
gen daten = date(date_str, "YMD")
gen timen = clock(time_str,"hms")
* Adding an hour to "timen" to change timezone from central to eastern
replace timen = timen + msofseconds(60*60)
gen hour = hh(timen)
gen minute = mm(timen)
gen exp_year = substr(exp_month_str, 1,2)
destring exp_year, replace
gen exp_month_original = exp_month_str
replace exp_month_str = substr(exp_month_str, 1,2) + "-"+ substr(exp_month_str, 3,.)
gen exp_month = monthly(exp_month_str, "20YM") if exp_year <= 22
replace exp_month = monthly(exp_month_str, "19YM") if exp_year > 90
* There are some missing expiration months. Doesn't seem to be important for results
drop if missing(exp_month)
keep daten timen close hour minute exp_month
	gen tempid = _n // data is stacked according to time
bys daten hour minute timen (tempid): keep if _n == _N
rename (hour minute /*timen*/) (hour_trade minute_trade /*timen_trade*/)
format daten %td
drop if yofd(daten) == 2019
save "${proch}/ff_clean.dta", replace	
	
	
*NEW UPDATE METHOD 
foreach year in 19 20 21 22 23 24 25 {
disp `year'
local monthcounter 0 
foreach month in F G H J K M N Q U V X Z {
local monthcounter = `monthcounter'+1
import delimited using "$rawh/TickWrite/FF_futures_dataupdate/FF`month'`year'_UPDATE.csv", clear 
	gen daten = date(date, "MDY")
	*(remember time zone change)
	gen double timen = clock(time, "hm") + 3600000
	format timen %tcHH:MM
	gen monthn = mofd(daten)
	format monthn %tm	
	
	gen calmonth = `monthcounter' 
	gen calyear = 2000 + `year'
	gen exp_month = ym(calyear, calmonth)
	
	if "`year'" == "19" & "`month'" == "F" { 
		save "$proch/FF_futures_alltrd_19_24", replace 
	}
	else {
		append using "$proch/FF_futures_alltrd_19_24" 
		sleep 1000 // helps with read-only errors 
		save "$proch/FF_futures_alltrd_19_24", replace 
	}
	}
	}

	use "${proch}/ff_clean.dta", clear // older data 
	format timen %tcHH:MM
	gen monthn = mofd(daten)
	format monthn %tm
	drop hour_trade minute_trade 
	tempfile FF_LEG 
	save `FF_LEG'
	
	use "$proch/FF_futures_alltrd_19_24", clear
	keep daten timen close exp_month 
	append using `FF_LEG'
	
		// gen id = _n // ==== key for sorting by time within FOMC date for reproducibility ====
	save "$proch/FF_futures_alltrd_95_24", replace
	

	
	*Calculating price differences 
	*MP1 30m
	use "${proch}/fomc_hour_futures_ff.dta", clear
	rename current_month exp_month
	rename daten daten_fomc 
	joinby exp_month using "$proch/FF_futures_alltrd_95_24" // "$proch/FF_futures_alltrd_19_24" 
	
	preserve
	diff_window "ff1" "30min"
	gen original_shock_mp1_30min = shock_ff1_30min
	keep if shock != .
	gen adj_factor = 30 /*numdays*/ / day_diff_current if missing(tag_current)
	replace adj_factor = 1 if tag_current == 1 // "unscaled change" (GSS 2005)
	replace shock = shock * adj_factor
	keep shock fomc_id daten original
	save "${proch}/FF_new_shock.dta", replace
	restore

	*MP2 30m 
	use "${proch}/fomc_hour_futures_ff.dta", clear
	rename next_fomc_month exp_month
	rename daten daten_fomc 
	joinby exp_month using "$proch/FF_futures_alltrd_95_24" // "$proch/FF_futures_alltrd_19_24" 
	
	preserve
	diff_window "mp2" "30min"
	keep if shock != .
	gen original_shock_mp2_30min = shock_mp2_30min
	merge 1:1 fomc_id using "${proch}/FF_new_shock.dta", nogen
	gen adj_factor = 30 /*numdays*/ / day_diff_next if missing(tag_next)
	replace adj_factor = 1 if tag_next == 1
	gen adj_factor_2 = day_next / 30 /*numdays*/ 
	replace adj_factor_2 = 0 if tag_next == 1
	gen shock_ff2_30min = adj_factor * (shock_mp2_30min - (adj_factor_2 * shock_ff1_30min))
	keep fomc_id original_shock_mp2_30min shock_ff2_30min original_shock_mp1_30min shock_ff1_30min daten_fomc
	save "${proch}/FF_new_shock.dta", replace 
	restore	
	
	*new ---------------------------------
	*MP1 1hour
	use "${proch}/fomc_hour_futures_ff.dta", clear
	rename current_month exp_month
	rename daten daten_fomc 
	joinby exp_month using "$proch/FF_futures_alltrd_95_24" // "$proch/FF_futures_alltrd_19_24" 
	
	preserve
	diff_window "ff1" "1hour"
	gen original_shock_mp1_1hour = shock_ff1_1hour
	keep if shock != .
	gen adj_factor = 30 /*numdays*/ / day_diff_current if missing(tag_current)
	replace adj_factor = 1 if tag_current == 1 // "unscaled change" (GSS 2005)
	replace shock = shock * adj_factor
	keep shock fomc_id daten original
	save "${proch}/FF_new_hourshock.dta", replace
	restore

	*MP2 1hour 
	use "${proch}/fomc_hour_futures_ff.dta", clear
	rename next_fomc_month exp_month
	rename daten daten_fomc 
	joinby exp_month using "$proch/FF_futures_alltrd_95_24" // "$proch/FF_futures_alltrd_19_24" 
	
	preserve
	diff_window "mp2" "1hour"
	keep if shock != .
	gen original_shock_mp2_1hour = shock_mp2_1hour
	merge 1:1 fomc_id using "${proch}/FF_new_hourshock.dta", nogen
	gen adj_factor = 30 /*numdays*/ / day_diff_next if missing(tag_next)
	replace adj_factor = 1 if tag_next == 1
	gen adj_factor_2 = day_next / 30 /*numdays*/ 
	replace adj_factor_2 = 0 if tag_next == 1
	gen shock_ff2_1hour = adj_factor * (shock_mp2_1hour - (adj_factor_2 * shock_ff1_1hour))
	keep fomc_id original_shock_mp2_1hour shock_ff2_1hour original_shock_mp1_1hour shock_ff1_1hour daten_fomc
	save "${proch}/FF_new_hourshock.dta", replace 
	restore	
	*new --------------------------------------
	
	*Backtesting against GSS data 
	use "${proch}/mpshocks_18.dta", clear 
	gen fomc_id = _n 
	tempfile GSS 
	save `GSS'
	use "${proch}/FF_new_shock.dta", clear 
	merge 1:1 fomc_id using `GSS', keep(matched) nogen	
	corr(shock_ff1_30min MP1) 
	corr(shock_ff2_30min MP2)
	
	corr(shock_ff1_30min MP1) if yofd(daten_fomc) >= 2019
	corr(shock_ff2_30min MP2) if yofd(daten_fomc) >= 2019

	* These correlations all seem a little low, but see this paper 
	* https://www.federalreserve.gov/econres/feds/files/2024011r1pap.pdf

	use "${proch}/eurodollar_shock_final_14_24.dta", clear 
	merge 1:1 fomc_id using "${proch}/FF_new_shock.dta", nogen 
	merge 1:1 fomc_id using "${proch}/eurodollar_hourshock_final_14_24.dta", nogen 
	merge 1:1 fomc_id using "${proch}/FF_new_hourshock.dta", nogen 	
	*rename daten_fomc daten 
	/* Key final step: SOFR correction for post 2022. Order matters in replace commands. 
	Per the Fed article, 
	"While Eurodollar futures were based on expected interest rates over three months 
	after the settlement date, SOFR futures are based on interest rates over the three months before. 
	As Figure 1 shows, both the first-outstanding Eurodollar future and the second-outstanding SOFR future 
	are called the q + 1 contract. Because the CME named both Eurodollar and SOFR
	futures based on the quarter of their interest rate exposure, they can be matched based on
	their contract names. Alternatively, one can match the nth-outstanding SOFR contract with
	the (n − 1)st-outstanding Eurodollar contract." */
	replace shock_ed2_30min = shock_ed3_30min if daten >= td(01jan2022)
	replace shock_ed3_30min = shock_ed4_30min if daten >= td(01jan2022)
	replace shock_ed4_30min = shock_ed5_30min if daten >= td(01jan2022)	
	
	replace shock_ed2_1hour = shock_ed3_1hour if daten >= td(01jan2022) 
	replace shock_ed3_1hour = shock_ed4_1hour if daten >= td(01jan2022)
	replace shock_ed4_1hour = shock_ed5_1hour if daten >= td(01jan2022)	 
	drop original*
	
	drop if missing(daten)
	gsort daten 
	format daten %td
	gen indic_GKL = daten <= td(19jun2019) // NEW, for merging with GKL
	// drop if daten <= td(19jun2019) // for merging with GKL
	rename daten_fomc daten
	save "${proch}/MP_shocks_19_24", replace  // ================================


** (5) Treasury data (Govpx) on long term yields. Data ends Mar 2024. 
* Old method of getting the data no longer accessible (Bobray email), now need to download date-by-date.  
* https://dss2.princeton.edu/govpx/2024/03/20240320/

*Get 2020, '21, '22, '23, '24 data into years. 
*We have datasets by date; loop over FOMC dates. 
use "${proch}/FTIMES.dta", clear 
replace date = subinstr(date, "-", "", .)
gen year = substr(date, 1, 4)
destring year, replace 
keep if year >= 2021
gen month = substr(date, 6, 2)
destring month, replace 
drop if (year == 2024 & daten >= td(01apr2024)) | (year == 2025)
forv year = 2021/2024 {
    
preserve
keep if year == `year'
levelsof date, local(dates)
	
local counter 1
foreach dt of local dates {
import delimited "$rawh/WRDS/us_treasury_govpx/`dt'-GOVPX_NEX_UST_0_0.csv", clear 
		save "$rawh/WRDS/us_treasury_govpx/`dt'-GOVPX_NEX_UST_0_0.dta", replace 
		use "$rawh/WRDS/us_treasury_govpx/`dt'-GOVPX_NEX_UST_0_0.dta", clear 
			if "`dt'" == "20220126" {
				tostring maturitydate, replace 
			}
		if `counter' > 1 {
			append using "${proch}/`year'_HF_Treasury.dta"
		}
		sleep 800 // helps with read-only errors 
		save "${proch}/`year'_HF_Treasury.dta", replace 
		local ++counter
	}
	restore
	} 
	
	*Split by maturity // currently, this drops "when issued" trades which make up like 1%
	forv year = 2021/2024 {
	use "${proch}/`year'_HF_Treasury.dta", clear
		foreach matlen in 2 5 10 30 {
			preserve 
			keep if record == "`matlen'_YEAR"
			gen date = substr(timestamp, 1, 10)
			gen hour = substr(timestamp, 12, 2)
			gen minute = substr(timestamp, 15, 2)
			destring hour minute, replace
			rename (indicativeaskyield indicativebidyield) (indayld indbyld)
			keep date hour minute indayld indbyld
			export delimited "$rawh/WRDS/us_treasury_govpx/tbills_highfreq/`year'hig_freq_`matlen'Y.csv", replace 
			restore 
		}
	}	

*** Loading data post 2009
local iter = 0
foreach mat in 2Y 5Y 10Y 30Y{
forval year = 2009/2024 {
import delimited "$rawh/WRDS/us_treasury_govpx/tbills_highfreq/`year'hig_freq_`mat'.csv", clear
	gen mat = "`mat'"
	gen daten = date(date, "YMD")
	merge m:1 daten using "$proch/FTIMES.dta", nogen keep(matched)
	if `iter' > 0 {
		append using "${proch}/bond_highfreq_post_200924.dta"
	}
	sleep 800 // helps with read-only errors 
	save "${proch}/bond_highfreq_post_200924.dta", replace
	local iter = `iter' + 1
	
	}
	}

	use "${proch}/bond_highfreq_post_200924.dta", clear
	gen prc = (indbid + indask) / 2
	gen yield = (indbyld + indayld) / 2
	drop if yield == 0

	keep yield daten hour minute /*keep_day*/ fomc_id /*date matdate diff*/ mat hour_fomc minute_fomc /*prc coupon*/ cusip
	tostring hour_fomc minute_fomc, replace
	gen time_fomc = hour_fomc + ":" + minute_fomc
	gen timen_fomc = clock(time_fomc, "hm")
	drop time_fomc
	save "${proch}/bond_highfreq_post_2009_final24.dta", replace

*** Loading data pre 2009
local iter = 0
foreach mat in /*6M*/ 2Y 5Y 10Y 30Y{
forval year = 1994/2008 {
import delimited "$rawh/WRDS/us_treasury_govpx/tbills_highfreq/`year'hig_freq_`mat'.csv", clear
	gen mat = "`mat'"
	cap gen daten = date(date, "YMD")
	cap merge m:1 daten using "${proch}/FTIMES.dta", nogen keep(matched)
	if `iter' > 0 {
		append using "${proch}/bond_highfreq_pre_200924.dta", force
	}
	sleep 800 // helps with read-only errors 
	save "${proch}/bond_highfreq_pre_200924.dta", replace
	local iter = `iter' + 1
	sleep 800
	}
	}
	
	*prochcessing pre 2009
	use "${proch}/bond_highfreq_pre_200924.dta", clear
	gen prc = (indbid + indask) / 2
	replace prc = ltprc if missing(prc)
	gen yield = (indbyld + indayld) / 2
	replace yield = ltyld if missing(yield)
	drop if yield == 0
	keep yield daten hour minute /*keep_day*/ fomc_id /*date matdate diff*/ mat hour_fomc minute_fomc /*prc coupon*/ cusip
	tostring hour_fomc minute_fomc, replace
	gen time_fomc = hour_fomc + ":" + minute_fomc
	gen timen_fomc = clock(time_fomc, "hm")
	drop time_fomc
	save "${proch}/bond_highfreq_pre_2009_final24.dta", replace

	***** Merging both datasets and calculating price diff
	foreach mat in /*6M*/ 2Y 5Y 10Y 30Y {
	use "${proch}/bond_highfreq_post_2009_final24.dta", clear
	append using "${proch}/bond_highfreq_pre_2009_final24.dta"
	keep if mat == "`mat'"
	drop if hour < 9 | hour >= 17
	replace minute = floor(minute/5) * 5
	tostring hour minute, gen(hour_str minute_str)
	gen time_trade = hour_str + ":" + minute_str
	gen timen_trade = clock(time_trade, "hm")
	collapse (median) yield, by(daten hour minute timen_trade /*keep_day*/ fomc_id timen_fomc)
	gen id = _n // shouldn't matter here because of (median) but to be safe
	gsort fomc_id /*keep_day*/ daten hour minute id  // stable (id) added 6/2
	preserve
	keep if hour == 16 & minute == 55
	keep daten yield
	sleep 800 // helps with read-only errors 
	save "${proch}/bond_check_`mat'24.dta", replace
	restore
	gsort daten hour minute id // stable (id) added 6/2
	gen diff = yield - yield[_n - 1] if fomc_id == fomc_id[_n-1]
	gen tagpos = 1 if diff > 0.1
	gen tagneg = 1 if diff < -0.1
	by daten: egen checkpos = max(tagpos) 
	by daten: egen checkneg = max(tagneg) 
	gen check = checkpos * checkneg
	replace diff = . if check == 1 & abs(diff) > 0.1
	drop check* tag*
	gen quarter = qofd(daten)
	***** Picking up shocks to do robustness table
	*** 30 min window (-10 to +20, such as in NS and "tight" GSS)
	preserve
// 	keep if keep_day == 0
	gen diff_min = Clockdiff(timen_fomc, timen_trade, "minute")
	drop if missing(timen_fomc) | missing(yield)
	gen fomc_diff = -1 if diff_min < -10
	replace fomc_diff = 1 if diff_min >= 20
	drop if missing(fomc_diff)
	gsort fomc_id fomc_diff hour minute id // stable (id) added 6/2
	by fomc_id fomc_diff: gen last_obs = 1 if _n == _N
	by fomc_id fomc_diff: gen first_obs = 1 if _n == 1
	keep if ((last_obs == 1) & (fomc_diff == -1)) | ((first_obs == 1) & (fomc_diff == 1))
	gsort daten hour minute id // stable (id) added 6/2
	by daten: gen shock_`mat'_30min = yield - yield[_n-1]
	keep if (first_obs == 1) & (fomc_diff == 1)
	keep quarter shock daten
	sleep 800 // helps with read-only errors 
	save "${proch}/`mat'_shocks24.dta", replace
	restore
	*** 60 min window
	preserve
// 	keep if keep_day == 0
	gen diff_min = Clockdiff(timen_fomc, timen_trade, "minute")
	drop if missing(timen_fomc) | missing(yield)
	gen fomc_diff = -1 if diff_min < -15
	replace fomc_diff = 1 if diff_min >= 45
	drop if missing(fomc_diff)
	gsort fomc_id fomc_diff hour minute id // stable (id) added 6/2
	by fomc_id fomc_diff: gen last_obs = 1 if _n == _N
	by fomc_id fomc_diff: gen first_obs = 1 if _n == 1
	keep if ((last_obs == 1) & (fomc_diff == -1)) | ((first_obs == 1) & (fomc_diff == 1))
	gsort daten hour minute id // stable (id) added 6/2
	by daten: gen shock_`mat'_1hour = yield - yield[_n-1]
	keep if shock != .
	keep quarter shock daten
		disp "here0!"
	merge 1:1 daten using "${proch}/`mat'_shocks24.dta", nogen
		disp "here1!"
	sleep 800 // helps with read-only errors 
	save "${proch}/`mat'_shocks24.dta", replace
	restore
}

	**** Collapsing all shocks in a single file
	use "${proch}/10y_shocks24.dta", clear
	merge 1:1 daten quarter using "${proch}/30y_shocks24.dta", nogen
	merge 1:1 daten quarter using "${proch}/5y_shocks24.dta", nogen
	merge 1:1 daten quarter using "${proch}/2y_shocks24.dta", nogen
// 	merge 1:1 daten quarter using "${temp}/6m_shocks.dta", nogen
	gen date_daily = daten
	save "${proch}/yield_shocks24.dta", replace // ==============================
	

** (6) Company level stock data. 
* Documentation: This data is pulled from WRDS using the R code "import_Trades_intraday_using_WRDS"

*First, get old crosswalk for TAQ data. 
// https://wrds-www.wharton.upenn.edu/pages/get-data/linking-suite-wrds/taq-crsp-link/
import delimited "$rawh/WRDS/monthly_taq_permno_cw_v2.csv", clear 
tostring date, replace
gen daten = date(date, "YMD")
gen month = mofd(daten)
gen year = year(daten)
keep if year <= 2003
*** Checking which obs has lower score and namedis
bys permno month: egen min_score = min(score)
bys permno month: egen min_namedis = min(namedis)
keep if score == min_score & namedis == min_namedis
duplicates tag permno month, gen(tag) 
drop if tag > 0
drop tag
save "${proch}/monthly_taq_permno_cw_trim.dta", replace

*For placebo days, we need all business days 
use "${proch}/zero_coupon_daily.dta", clear 
merge 1:1 daten using "$proch/FTIMES", keep(master matched) nogen
keep if yofd(daten) >= 1994 & yofd(daten) <= 2024 // our sample period 
gen FOMC_day = 1 if fomc_id != .
keep daten FOMC_day time_fomc fomc_id
* Gen mock time (the unit of time is millisec)
replace time_fomc = 14*1000*60*60 if missing(time_fomc)
save "$proch/fomc_placebo_days_2024", replace 


cap program drop shock_window_taq 
program define shock_window_taq, rclass
args window
* Setting the correct windows
if "`window'" == "30min"{
	local lower_min -10
	local upper_min 20
}
else if "`window'" == "1hour"{
	local lower_min -15
	local upper_min 45
}
else if "`window'" == "daily"{
	local lower_min -15
	local upper_min 45
}

if inlist("`window'", "30min", "1hour"){
	gen fomc_diff = -1 if diff_min < `lower_min'
	replace fomc_diff = 1 if diff_min >= `upper_min'
	drop if missing(fomc_diff)

	gsort permno daten fomc_diff time_trade id //, stable 
	by permno daten fomc_diff: gen last_obs = 1 if _n == _N
	by permno daten fomc_diff: gen first_obs = 1 if _n == 1
	keep if ((last_obs == 1) & (fomc_diff == -1)) | ((first_obs == 1) & (fomc_diff == 1))

}
* In daily, you get the first and last obs of the day, given it's outside of the window
else if "`window'" == "daily" {
		gen fomc_diff = -1 if diff_min < `lower_min'
		replace fomc_diff = 1 if diff_min >= `upper_min'
		drop if missing(fomc_diff)

		gsort permno daten fomc_diff time_trade id //, stable 
		by permno daten fomc_diff: gen last_obs = 1 if _n == _N
		by permno daten fomc_diff: gen first_obs = 1 if _n == 1
		keep if ((first_obs == 1) & (fomc_diff == -1)) | ((last_obs == 1) & (fomc_diff == 1))		
}

gsort permno daten time_trade id //, stable
by permno daten: gen shock_hf = log(Padj) - log(Padj[_n - 1])
by permno daten: gen diff_min_hf = diff_min - diff_min[_n - 1]
bys permno daten (time_fomc): drop if _n != _N
keep permno shock_hf diff_min_hf daten 
end 

*Get permno crsp crosswalk 
use "${rawh}/WRDS/permno_crsp_cw_2024.dta", clear 
// https://wrds-www.wharton.upenn.edu/pages/get-data/linking-suite-wrds/daily-taq-crsp-link/
	rename (DATE SYM_ROOT SYM_SUFFIX PERMNO CUSIP) (daten sym_root sym_suffix permno cusip)
	gen cw_id = _n 
	tempfile CW24 
	save `CW24'

*** Merging the CSVs with relevant datasets and cleaning data
local iter = 0
forval year = 1994/2024 {

	disp "* ========== Loading HF Stocks for year `year' ========== *"
*use "${proch}/taq_dta/`year'_5min_stocks.dta", clear
	if `year' <= 2003 {
	import delimited "$rawh/WRDS/Intraday stocks/Stocks Last Trade/comp_`year'.csv", clear
	}
	else {
	import delimited "$rawh/WRDS/Intraday stocks/Stocks Last Trade/`year'_5min_stocks.csv", clear
	}

	if `year' >= 2020 {
	*drop minute // still one bar every 5 min
	rename bar_5min minute // new 6/2/2025
	}
	
	tostring date, force replace
	cap tostring cond, replace
	gen daten = date(date, "YMD")
	gen month = mofd(daten) 	
		gen id = _n // needed for reprod in sort 
	merge m:1 daten using "${proch}/fomc_placebo_days_2024.dta", keep(matched) 
// 	merge m:1 daten using "${proch}/fomc_times_2024.dta", keep(matched) // WE ACTUALLY NEED EVERY BUSINESS DAY, FOR PLACEBO EST
	sleep 1000 // seems to crash here a lot 
	if `year' <= 2003 {
		merge m:1 month symbol using "${proch}/monthly_taq_permno_cw_trim.dta", keep(matched) nogen
	gen cw_id = _n // reprod
	}
	else if `year' >= 2004 {
		joinby daten sym_root sym_suffix using `CW24' // new crosswalk 
	}
	*** Dropping invalid observations
	drop if (hour <=8) | (hour == 9 & minute == 0) | (hour >=16)
	keep permno hour minute daten price time_fomc id cw_id /*FOMC_day*/
	*** Merging price correction
	merge m:1 daten permno using "${proch}/CRSP_price_correction_new.dta", nogen keep(matched)
	gen Padj = price / cfacpr
	gsort permno daten hour minute id cw_id //, stable // new May // to be safe
	by permno: gen logret = log(Padj) - log(Padj[_n - 1])
	by permno: gen diff_days = daten - daten[_n - 1]
	drop if diff_days > 7
	drop if missing(logret)
	* Creating a flag and dropping observations if they had two swings of more than 50% in the same month
	gen neg_logret = 1 if logret < -0.5
	gen pos_logret = 1 if logret > 0.5
	/*gen month = month(daten)*/
	bys permno month: egen neg_logret_month = max(neg_logret)
	bys permno month: egen pos_logret_month = max(pos_logret)
	by permno month: gen filter_logret_month = 1 if neg_logret_month == 1 & pos_logret_month == 1
	replace logret = . if filter_logret_month == 1 & abs(logret) > 0.5
	keep permno minute hour Padj time_fomc /*FOMC_day*/ id cw_id daten
	gen time_trade = minute * 1000 * 60 + hour * 1000 * 60 *60
	gen diff_min = Clockdiff(time_fomc, time_trade, "minute")
	preserve
	shock_window_taq "30min"
	rename (shock_hf diff_min_hf) (shock_hf_30min window_shock_hf_30min)
	tempfile shock_30min
	save `shock_30min'
	restore
	preserve
	shock_window_taq "1hour"
	rename (shock_hf diff_min_hf) (shock_hf_1hour window_shock_hf_1hour)
	tempfile shock_1hour
	save `shock_1hour'
	restore
	shock_window_taq "daily"
	rename (shock_hf diff_min_hf) (shock_hf_daily window_shock_hf_daily)
	merge 1:1 daten permno using `shock_30min', nogen keepusing(shock_hf_30min window_shock_hf_30min)
	merge 1:1 daten permno using `shock_1hour', nogen keepusing(shock_hf_1hour window_shock_hf_1hour)
	if `iter' > 0 {
		append using "${proch}/temp_stock_fomc_level24.dta"
	}
	sleep 800 
	save "${proch}/temp_stock_fomc_level24.dta", replace // =====================
	local iter = `iter' + 1
	}
	
	
* B. Merging base files to create full FOMC-level and firm-level data  =========
** (1) FOMC-level dataset 
/* Need: 
use "${temp}/master_daily_no_stocks_trim.dta", clear // daily dataset, no stocks
	keep daten /*mp_klmslong30* mp_klms_U* */ MP1 MP2 ED2 ED3 ED4 scaled_diff_zcoupon_1y ///
	shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min unscheduled_meetings 
*/

use "${proch}/fomc_times_2024.dta", clear 
merge 1:1 daten using "${proch}/zero_coupon_daily.dta", nogen keep(master matched)
merge 1:1 daten using "${proch}/mpshocks_18.dta", nogen keep(master matched) // gurkaynak 
merge 1:1 daten using "${proch}/MP_shocks_19_24", nogen keep(master matched)
merge 1:1 daten using "${proch}/yield_shocks24.dta", nogen keep(master matched) 
merge 1:1 daten using "$proch/FFtarget.dta", nogen keep(master matched)
codebook daten // 261 

*filling in our shocks post-2019
replace MP1 = shock_ff1_30min if missing(MP1)
replace MP2 = shock_ff2_30min if missing(MP2)
replace ED2 = shock_ed2_30min if missing(ED2)
replace ED3 = shock_ed3_30min if missing(ED3)
replace ED4 = shock_ed4_30min if missing(ED4)

*processing into our format
rename Unscheduled unscheduled_meetings
gen scaled_diff_zcoupon_1y = diff_zcoupon_1y * 10 

*PCA and TS variables 
preserve 
drop if unscheduled_meetings==1 // KEY STEP =====
pca MP1 MP2 ED2 ED3 ED4 
predict mp_klms_U mp_klms_UPCA2, score

pca MP1 MP2 ED2 ED3 ED4 shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min 
predict mp_klmslong30 mp_klmslong30_PCA2, score

pca shock_ff1_1hour shock_ff2_1hour shock_ed2_1hour shock_ed3_1hour shock_ed4_1hour 
predict mp_klms_U1h

keep daten mp_klms_U mp_klms_UPCA2 mp_klmslong30 mp_klmslong30_PCA2 mp_klms_U1h
tempfile tempPCA 
save `tempPCA'
restore 

merge 1:1 daten using `tempPCA', nogen 

pca MP1 MP2 ED2 ED3 ED4 
predict mp_klms, score 
	
*Scaling the shock to 10bp movement in 1Y zero-coupon
foreach var in mp_klms_U mp_klms_UPCA2 mp_klmslong30 mp_klmslong30_PCA2 mp_klms mp_klms_U1h {
	reg scaled_diff_zcoupon_1y `var', r 
	mat scale_`var' = e(b) 
	replace `var' = `var' * scale_`var'[1, 1]
}

gen year = year(daten)
gen post=year>2006
replace post = 0 if year <= 2006 
gen postZLB = 0 if year>=1994 & year<=2006     
	replace postZLB=1 if (year>=2009 & year<=2015) | (year>=2020 & year<=2021)
	replace postZLB = 0 if missing(postZLB)	
gen postnonZLB = 0 if year>=1994 & year<=2006
	replace postnonZLB=1 if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022)
	replace postnonZLB = 0 if missing(postnonZLB) 

drop if year == 2025 
save "$proch/master_fomc_level_24.dta", replace 
save "$proc_analysis/master_fomc_level_24.dta", replace


** (2) Firm level dataset 
/* firm shocks; need to make adj_MV and dollar duration 
*/

use "${proch}/fomc_times_2024.dta", clear
merge 1:m daten using "${proch}/CRSP_allstocks.dta", nogen keep(master matched)  // shrout prc 
drop if missing(permno) 
isid daten permno
merge 1:1 daten permno using "$proch/CRSP_price_correction_new.dta", nogen keep(master matched) // cpi cfacpr 
merge 1:1 daten permno using "${proch}/temp_stock_fomc_level24.dta", nogen keep(master matched)

*making firm-level variables 
// gen MV = prc*shrout/1000
// bys permno (daten): gen prev_MV = MV[_n - 1]
// gen adj_MV = MV/cpi
// gen adj_prev_MV = prev_MV/cpi
	
gen shock_hf_30min_dollar = shock_hf_30min * adj_prev_MV	
replace shock_hf_30min = shock_hf_30min * 100	
replace shock_hf_1hour = shock_hf_1hour * 100
save "${proch}/master_firm_level_24.dta", replace 


*C. Data needed for quarterly dataset used to estimate LPs =====================
	
**(0) Append new quarterly compustat data. 

*Main quarterly datasets: 
*https://wrds-www.wharton.upenn.edu/pages/get-data/center-research-security-prices-crsp/annual-update/crspcompustat-merged/fundamentals-quarterly/
*Variables: prccq cshoq xintq dlcq dlttq atq ppentq revtq dpq oiadpq ceqq capxy aqcy , saleq
*ID variables: gvkey liid permno lpermco datafqtr datadate datacqtr fic sic 
use  "${rawq}/WRDS/CCM_Fundamentals_all", clear 
	rename GVKEY LIID LPERMNO LPERMCO, lower
	destring gvkey, replace 
	drop liid 
	drop if year(datadate) == 2020
	tempfile old_CCMF
	save `old_CCMF'

// import delimited using "$raw/ccm_fundamentals_qtly_20_24.csv", clear 
// use "$raw/ccm_fundamentals_qtlyraw_20_24.dta", clear 
import delimited using "$rawq/WRDS/ccm_fundamentals_quarterly_raw_20_24", clear 
	rename datadate olddate 
	gen datadate = date(olddate, "YMD") 
	drop olddate 
	tostring sic, replace 
	append using `old_CCMF'

	gen quarter_d =quarterly(datacqtr, "YQ")
	format quarter_d %tq
	rename (fyearq fqtr) (year quarter)
	save "$procq/CCM_Fundamentals_update24.dta", replace // =====================

	
** (1) FOMC shocks aggregated to quarterly level. 
use "$proch/master_fomc_level_24.dta", clear 

	*aggregating shocks
	preserve
	drop if year(daten) < 1994 // 0 deleted 
	gen quarter_d = qofd(daten)
	keep daten mp_klms mp_klms_U mp_klms_UPCA2 mp_klmslong30 mp_klmslong30_PCA2 ///
		shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min mp_klms_U1h quarter_d 
	gen mp_klms_original = mp_klms_U // change here, since mp_klms_U is our new default
	rangestat (sum) mp_klms mp_klms_U mp_klms_UPCA2 mp_klmslong30 mp_klmslong30_PCA2 ///
	shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min mp_klms_U1h, int(daten -90 0)
	keep if (dow(daten) > 0) & (dow(daten) < 6)

	collapse (mean)  ///
	mp_klms_gk = mp_klms_sum ///
	mp_klms_U_gk = mp_klms_U_sum ///
	mp_klms_UPCA2_gk = mp_klms_UPCA2_sum ///
	mp_klmslong30_gk = mp_klmslong30_sum ///
	mp_klmslong30_PCA2_gk = mp_klmslong30_PCA2_sum ///
	shock_2Y_30min_gk = shock_2Y_30min_sum /// 
	shock_5Y_30min_gk = shock_5Y_30min_sum /// 
	shock_10Y_30min_gk = shock_10Y_30min_sum /// 
	shock_30Y_30min_gk = shock_30Y_30min_sum /// 
	mp_klms_U1h_gk = mp_klms_U1h_sum ///
	(sum) mp_klms_original ///
	, by(quarter_d)
	save "${procq}/mpshock_gk_adjusted_24.dta", replace
	restore

	*collapse to quarterly
	gen quarter_d = qofd(daten)
	tsset daten

	collapse ///
	(sum) *30min mp_klms mp_klms_U mp_klms_UPCA2 mp_klmslong30 mp_klmslong30_PCA2 diff_zcoupon_1y ///
	(count) Cmp_klms=mp_klms Cmp_klms_U=mp_klms_U Cmp_klms_UPCA2=mp_klms_UPCA2 Cmp_klmslong30=mp_klmslong30 Cmp_klmslong30_PCA2=mp_klmslong30_PCA2 ///
	(lastnm) target year post postZLB postnonZLB ///
	, by(quarter_d)

	foreach var of varlist mp_klms mp_klms_U mp_klms_UPCA2 mp_klmslong30 mp_klmslong30_PCA2{
	replace `var'=. if C`var'==0
	}
	drop C*

	drop if quarter_d<112  //dropping pre-1988 quarters

	merge 1:1 quarter_d using "${procq}/mpshock_gk_adjusted_24.dta", keep(master match) nogen

	sort quarter_d
	save "${procq}/QuarterlyFOMC_24", replace // ================================

** (2) dd is "distance to default"
* first process data, export to csv, calculate measure using matlab "distance_to_default.m" in same folder as this do-file  
* dataset is A.3 from above (CRSP_Stocks_All adjusted), combined with Treas rate and quarterly compustat data. 

*Get treasury rate date to merge 
*import fred DGS1, clear	
use "$import_fred_snapshot/DGS1.dta", clear
	drop datestr
	rename daten date 
	rename DGS1 treasury_rate 
	tempfile treasury
	save `treasury'

*Get quarterly compustat data for debt 
use "$procq/CCM_Fundamentals_update24.dta", clear // updated compustat quarterly data 
	rename lpermno permno 
	gen debt = dlcq+ dlttq 
	keep permno gvkey quarter_d debt 
	egen temp = tag(permno quarter_d)
	drop if temp==0 
	drop temp 
	compress 
	tempfile compustat_debt 
	save `compustat_debt'

*Get CRSP and merge the three datasets 
use "${proch}/CRSP_allstocks.dta", clear 
	rename daten date 
	drop cfacpr cfacshr 
	gen quarter_d = qofd(date) 
	compress
	merge m:1 permno quarter_d using `compustat_debt', keep(master matched) nogen
	gen market_value = prc*shrout/1000
	keep permno date market_value debt
	// duplicates drop

	isid permno date // yes, implying duplicates drop above is unneccessary
	*drop firms where you never have Compustat Financials:
	bysort permno (date): gen aux=!missing(debt)
	bysort permno (date): egen aux2=total(aux)
	drop if aux2==0
	drop aux aux2

	*merge with treasury
	merge m:1 date using `treasury', nogen
	*Identify last day in quarter
	gen q=qofd(date)
	gsort date
	fcollapse (last) x=date, by(q) merge
	gen lastdate=0
	replace lastdate=1 if x==date
	replace debt=. if lastdate!=1
	drop x q lastdate

	gen day 	= day(date)
	gen month 	= month(date)
	gen year	= year(date)

	*convert treasury rates to daily returns (actually, only need to div e by 100 - need yearly rate)
	replace treasury_rate=treasury_rate/100
	replace treasury_rate=(1+treasury_rate)^(1/365) - 1
	drop if missing(permno)

	*drop negative debt values 
	drop if debt<0 & !missing(debt)

	*fill in missing debt values 
	gen debt2=debt

	*only extrapolate backward for 40 trading days 
	foreach if of numlist 1/40{
	 bysort permno (date): replace debt2 = debt2[_n+1] if missing(debt2) & !missing(debt2[_n+1])
	}
	*then do forward interpolation:
	bysort permno (date): replace debt2 = debt2[_n-1] if missing(debt2) & !missing(debt2[_n-1])
	*then do more backward (do unlimited - but in practice loop over debt not debt2 so will never use more than 250 days prior [worry with unlimited backward extrapolation would be 10years of extrapolation --> never happens])
	gen aux =-date
	bysort permno (aux): replace debt2 = debt2[_n-1] if missing(debt2) & !missing(debt2[_n-1])
	drop aux

	drop if permno==76492
	export delimited using "${procq}/DDdata.csv", delimiter(tab) replace

*Two versions of the DD algorithm. Python pushes Stata to its limit but is faster by 5x.
*There's also a Matlab code in the same code folder as this do-file.
*Formula: this AER 2012. *https://mfm.uchicago.edu/wp-content/uploads/2020/07/Gilchrist_Zakrajsek_Credit-Spreads-and-Business-Cycle-Fluctuations-UPDATED.pdf
*------------------------------------------------------------------------------*
local dd_filepath `"$procq/DDdata.csv"'
di "`dd_filepath'"
local dd_filepath_out `"$procq/DDdata_withdd.csv"'
di "`dd_filepath_out'"

python:
import numpy as np
# Suppress floating warnings; produce Inf or NaN rather than raise warnings
np.seterr(divide='ignore', over='ignore', invalid='ignore', under='ignore')

import pandas as pd
import time 
from scipy.stats import norm

def distance_to_default(filename, filename_out):
    """
    Python equivalent of the MATLAB function distance_to_default.m
    Loads a tab-delimited CSV, iterates over 'permno' blocks, performs
    the Gilchrist-Zakrajsek iterative procedure, and overwrites the input file.
    """
    # 1. Load the CSV (like MATLAB's readtable)
    DDdata = pd.read_csv(filename, sep='\t')
    print("Columns found:", DDdata.columns)
	
    # 2. Setup iteration parameters
    tol = 1e-6  # tolerance
    T = 250     # one-year horizon (250 trading days)

    # 3. Add a 'logequity' column
    DDdata['logequity'] = np.log(DDdata['market_value'])

    # 4. Identify unique permno values
    ids = DDdata['permno'].unique()

    # We'll collect results in a list of row dicts, to convert into a DataFrame later
    output_rows = []

    # 5. Loop over each permno block
    for perm in ids:
        time.sleep(0.05)
        print(perm)
        # Subset data for this firm
        data_firm = DDdata[DDdata['permno'] == perm].copy().reset_index(drop=True)
        I = data_firm.shape[0]

        # 6. Loop over each observation in this firm's data
        for i in range(I):
            # Equivalent to "if ~isnan(data.debt(i)) && i>250" in MATLAB
            if not pd.isna(data_firm.loc[i, 'debt']) and i >= 250:
                # Extract the last 251 rows (i-250 through i)
                aux = data_firm.iloc[i-250 : i+1].copy()

                # 7. Gather needed values
                debt = aux['debt2'].values
                debt0 = aux['debt'].iloc[250]
                equity = aux['market_value'].values
                equity0 = aux['market_value'].iloc[250]
                v = equity + debt
                r = aux['treasury_rate'].iloc[250]

                # In MATLAB: sigma_e = std(aux.logequity(2:251) - aux.logequity(1:250))
				# Be very careful about Matlab -> python indexing, because python is 0-indexed and exclusive end range
                sigma_e = np.std(
                    aux['logequity'].iloc[1:251].values
                  - aux['logequity'].iloc[0:250].values
                )
                sigma_v = sigma_e * (debt0 / (debt0 + equity0))

                dist_ = 1000
                iteration_count = 0
                inf_encountered = False  # Flag to detect infinite delta1

                # 8. Iterate until convergence
                while dist_ > tol:
                    iteration_count += 1

                    # Compute delta1
                    delta1 = (np.log(v / debt) + (r + 0.5*sigma_v**2)*T) / (sigma_v**2 * np.sqrt(T))

                    # If any infinite or NaN in delta1, bail from the while loop
                    if np.isinf(delta1).any() or np.isnan(delta1).any():
                        inf_encountered = True
                        break

                    # Proceed with normal iteration steps
                    delta2 = delta1 - sigma_v * np.sqrt(T)
                    cdf1 = norm.cdf(delta1)
                    cdf2 = norm.cdf(delta2)
                    # Avoid dividing by zero
                    cdf1_safe = np.where(cdf1 == 0, 1e-15, cdf1)

                    # Update v
                    v = (equity + np.exp(-r * T) * debt * cdf2) / cdf1_safe

                    # Recompute sigma_v
                    if len(v) >= 251:
                        sigma_v1 = np.std(np.diff(np.log(v[:251])))
                    else:
                        sigma_v1 = np.nan

                    dist_ = abs(sigma_v1 - sigma_v)
                    sigma_v = sigma_v1

                    # If it doesn't converge in 10k steps, forcibly stop
                    if iteration_count > 10000:
                        dist_ = 0
                        sigma_v1 = np.nan

                # 9. Check if we encountered Inf or NaN in delta1
                if inf_encountered:
                    # We skip normal dd calc, store dd=Inf, and go to next i
                    dd = np.inf
                    row_251 = aux.iloc[250].to_dict()
                    row_251['dd'] = dd
                    output_rows.append(row_251)
                    continue

                # If we didn't bail out, proceed with normal dd calculation
                if not np.isnan(sigma_v1):
                    mu_v = np.mean(np.diff(np.log(v[:251])))
                    dd = ((np.log(v[250] / debt0)
                           + mu_v
                           - 0.5 * sigma_v**2 * T)
                          / (sigma_v * np.sqrt(T)))
                else:
                    dd = np.nan

                # Store the final row + dd
                row_251 = aux.iloc[250].to_dict()
                row_251['dd'] = dd
                output_rows.append(row_251)

    # 10. Convert to DataFrame & save results
    output_df = pd.DataFrame(output_rows)
    output_df.to_csv(filename_out, index=False)

# Now call it with your Stata macro path
distance_to_default(r"`dd_filepath'", r"`dd_filepath_out'")

end
*-------------------------------------------------------------------------------


*Get DD in quarterly format . 
	import delimited "$procq/DDdata_withdd.csv", clear 
	// get dd 
	gen dd_flag=.
	replace dd_flag=1 if dd=="inf"
	replace dd="" if dd=="inf"
	replace dd="" if dd=="NaN"
	destring dd, replace

	// some overview of dd
	su dd, d
	preserve
	collapse (median) dd, by(year)
	line dd year
	restore

	// drop one duplicates
	duplicates tag permno date, gen(aux)
	drop if aux>0
	drop aux
	// convert datadate string into long date:
	drop logequity
	// gen date:
	gen date2 = date(date, "DMY")
	format date2 %td
	drop date year month day
	rename date2 datadate
	save "$procq/DDfinal_quarterly", replace // =================================

	
	

	
* -- Bauer Swanson news PCA shock reconstruction 
** (3) Bcom: comes from Bloomberg Terminal, "Bloomberg total commodity price index (Bloomberg ticker BCOM Index)"
import excel "$rawq/Bloomberg/BCOMAG_94_24.xlsx", firstrow clear // BCOMAG index in Bloomberg, NOW QUARTERLY DATA. 
	rename (Date Close) (daten bcomag)
	keep daten bcomag 
	gen quarter = qofd(daten)
	tempfile bcomag 
	save `bcomag'

import excel "$rawq/Bloomberg/BCOM_94_24.xlsx", firstrow clear 
	rename (Date Close) (daten bcom) 
	keep daten bcom
	gen quarter = qofd(daten)
	merge m:1 quarter using `bcomag', nogen 
	count if missing(bcom) | missing(bcomag) // 0 
	gen log_bcom = log(bcom)
	gen log_bcomag = log(bcomag)
	save "$procq/newdailyshocks", replace 
	sleep 800 
	
** (4) SP500: TickWrite in library, daily (close) price of index 
import delimited "$rawq/TickWrite/SPall_daily.csv", clear 
	rename (close) (sp500)
	gen daten = date(date, "MDY")
	drop date
	gen log_SP500 = log(sp500)
	keep daten log_SP500
	merge 1:1 daten using "$procq/newdailyshocks", nogen 
	save "$procq/newdailyshocks", replace 
	sleep 800 

** (5) Slope yield curve 	
*import fred T10Y3M, clear // slope of Treasury yield curve, daily	
use "$import_fred_snapshot/T10Y3M.dta", clear
	gsort daten
	replace T10Y3M = T10Y3M[_n - 1] if missing(T10Y3M)
	merge 1:1 daten using "$procq/newdailyshocks", nogen 
	save "$procq/newdailyshocks", replace 
	sleep 800 

** (6) Payroll, unemployment, core CPI surprise 
*for these we need "money market services" survey data.
*this is no longer available at Princeton, so we needed to get last 5 years through Refinitiv in library -> search up each variable and 
*click the blue highlighted data values in the table under Reuters forecasts, then export to excel. 
*(make sure excel has the plugin for refinitiv under File -> Options)

import excel "$rawq/refinitiv_reuters/refinitiv_reuters_coreCPI_polls20_25.xlsx", clear
	keep A C 
	drop in 1/9 
	rename (A C) (datestr corecpi_expec)
	gen date = date(datestr, "MDY")
	gen year = year(date)
	gen month = month(date)
	destring corecpi_expec, replace
	drop datestr 
	tempfile corecpi 
	save `corecpi'

import excel "$rawq/refinitiv_reuters/refinitiv_reuters_UNEMP_polls20_25.xlsx", clear
	keep A C 
	drop in 1/9 
	rename (A C) (datestr unemp_expec)
	gen date = date(datestr, "MDY")
	gen year = year(date)
	gen month = month(date)
	destring unemp_expec, replace 
	drop datestr 
	tempfile unemp 
	save `unemp'	

import excel "$rawq/refinitiv_reuters/refinitiv_reuters_nfpayroll_polls20_25.xlsx", clear
	keep A C 
	drop in 1/9 
	rename (A C) (datestr payroll_expec)
	gen date = date(datestr, "MDY")
	gen year = year(date)
	gen month = month(date)
	destring payroll_expec, replace 
	drop datestr 
	merge 1:1 date using `corecpi', nogen 
	merge 1:1 date using `unemp', nogen 
	
	keep if year >= 2023 // we have data through 2022 via MMS data below)
	replace payroll_expec = payroll_expec/1000 // consistent with previous and Bauer/Swanson approach. 
	tempfile payroll_corecpi_unemp
	save `payroll_corecpi_unemp'		

*** Cleaning MMS data [accessed through Global Insight, now unavailable at Princeton]
import excel "${rawq}/Global_Insight/MMS Data.xlsx", clear
	gen id = _n
	drop if id <= 4
	rename(A B C D E F) (date_str unemp_expec payroll_expec cpi corecpi_expec rgdp_expec)
	destring *_expec, replace
	replace date_str = subinstr(date_str, "-", "",.)
	replace date_str = lower(date_str) 
	gen date = date(date_str, "M19Y") if id <= 244
	replace date = date(date_str, "M20Y") if missing(date)
	drop id date_str
	gen month = month(date)
	gen year = year(date)
	order year month

	drop if missing(date)
	append using `payroll_corecpi_unemp'	
	rename date daten 
	format daten %td 
	save "$procq/MMS_reuters_expectations.dta", replace 

*Load expectations data and merge one by one with "as released" FRED data; again, this comes from as_released.R
	*Payroll 	
	use "$procq/MMS_reuters_expectations.dta", clear 
	keep year month payroll_expec
	tempfile payroll_expec
	save `payroll_expec'

import delimited "$rawq/payroll_asreleased.csv", clear 
	rename (year_pred month_pred) (year month)
	merge 1:1 year month using `payroll_expec', nogen keep(matched)
	drop year month
	rename observed_value payroll_actual
	gen payroll_surprise = payroll_actual - payroll_expec
	replace payroll_surprise = payroll_surprise / 1000
	gen daten = date(release_date, "YMD")
	drop release_date
	merge 1:1 daten using "$procq/newdailyshocks", nogen 
	save "${procq}/newdailyshocks.dta", replace
	sleep 800

	*Unemp 
	use "$procq/MMS_reuters_expectations.dta", clear 
	keep year month unemp_expec
	gsort year month 
	replace unemp_expec = unemp_expec[_n-1] if missing(unemp_expec)
	tempfile unemp_expec
	save `unemp_expec'	

import delimited "$rawq/unemp_asreleased.csv", clear 	
	rename (year_pred month_pred) (year month)
	merge 1:1 year month using `unemp_expec', nogen keep(matched)
	drop year month
	rename observed_value unemp_actual
	gen unemp_surprise = unemp_actual - unemp_expec
	gen daten = date(release_date, "YMD")
	drop release_date
	merge 1:1 daten using "${procq}/newdailyshocks.dta", nogen
	*generate month, year, quarter to get variables in other date scheds
	gen year=year(daten)
	gen month=mofd(daten)
	format month %tm
// 	gen quarter=qofd(daten)
// 	format quarter %tq
	save "${procq}/newdailyshocks.dta", replace
	sleep 800
	
	*Core CPI 
	use "$procq/MMS_reuters_expectations.dta", clear 
	keep year month corecpi_expec
	gsort year month 
	replace corecpi_expec = corecpi_expec[_n-1] if year == 2014 & month == 12
	count if missing(year) // 0 
	tempfile corecpi_expec
	save `corecpi_expec'	

import delimited "$rawq/cpi_asreleased.csv", clear 
	rename (year_pred month_pred) (year month)
	* Changing missing value from ALFRED
	replace observed_value = "0.1" if observed_value == "NA"
	merge 1:1 year month using `corecpi_expec', keep(matched) nogen
	drop year month
	rename observed_value corecpi_actual
	destring corecpi_actual, replace
	gen corecpi_surprise = corecpi_actual - corecpi_expec
	gen daten = date(release_date, "YMD")
	gen month = mofd(daten)
	drop release_date
	rename corecpi_expec corecpi_expec_day
	drop daten 
	merge 1:m month using "${procq}/newdailyshocks.dta", nogen
	save "${procq}/newdailyshocks.dta", replace
	sleep 800

** (7) Blue Chip GDP Forecasts, for rgdp_surprise: Accessible through Haver Analytics in Library. 
* Process: follow the process at this link closely: https://libguides.princeton.edu/ld.php?content_id=17176779

* Getting first two (or three) business days of month; these are the days on which bluechip was released 
use "$import_fred_snapshot/T10Y3M.dta", clear
	gen month_index = mofd(daten)
	bys month_index (daten): gen business_day = _n
	gen year = year(daten)
	keep if (business_day == 3 & year <= 2000) | (business_day == 2 & year >= 2001)
	keep daten month_index
	save "${procq}/bchip_days.dta", replace

* Getting Real GDP surprise
*Expectations: new data 
import excel "$rawq/Haver/bluechipQQannrgdp22_24.xlsx", firstrow clear 
	rename Q1122QDisaggregate_All Q11985Q
	replace Q11985Q = substr(Q11985Q, 1, 2) + "/20" + substr(Q11985Q, 4, 2)
	tostring AAAN*, replace 

	*get excel_last variable; last day of quarter
	gen quarter = real(substr(Q11985Q, 2, 1))
	gen year = real(substr(Q11985Q, 4, 4))
		drop if year <= 2022 & quarter <= 3 // we need to grab Q4 2022
	gen qdate_ahead = yq(year, quarter) + 1
	format qdate_ahead %tq
	gen excel_last = dofq(qdate_ahead) - 1
	format excel_last %td
	drop quarter year qdate_ahead
	tempfile NEWBC
	save `NEWBC'

*Expectations: old data 
import excel "${rawq}/Haver/bchip_series_qoq.xlsx", firstrow sheet("Real GDP") clear
	drop if excel_last == td(31dec2022) // we overwrite this row because it's incomplete 
	append using `NEWBC'

	drop if excel_last == .
	gen quarter_F=qofd(excel_last)
	format quarter_F %tq
	rename AAAN*BLUECHIP BC*
	destring _all, replace
	reshape long BC, i(quarter_F) j(survey) string
	gen year=substr(survey,1,2)
	gen month=substr(survey,3,2)
	destring year month, replace
	replace year=year+2000 if year<50
	replace year=year+1900 if year>=50 & year<2000
	drop if BC == .
	gen mdate = ym(year, month)
	gen quarter_survey = qofd(dofm(mdate))
	keep year month BC quarter_F quarter_survey
	rename BC rgdp_expec

	* For GDP we exceptionally look only at the forecast for previous quarter
	keep if quarter_F == (quarter_survey - 1)
		tab year 
	rename quarter_F quarter_forecast
	keep year quarter_forecast month rgdp_expec
	tempfile bchip_rgdp
	save `bchip_rgdp'

* Loading actual GDP value as provided on the date (from "wayback machine" FRED page)
* these come from an R file in this code folder (as_released.R), which queries archival FRED "ALFRED"
import delimited "$rawq/gdp_asreleased.csv", clear
	rename (year_pred month_pred) (year month)
	gen quarter_forecast = qofd(dofm(ym(year, month)))
	*
	sort quarter_forecast
	keep release_date observed_value quarter_forecast
	merge 1:m quarter_forecast using `bchip_rgdp', nogen keep(matched)
	* Need to do that bc GDP data is not released every month
	gen daten = date(release_date, "YMD")
	gen mo_release = month(daten)
	keep if month == mo_release
	drop month year
	rename observed_value rgdp_actual
	gen rgdp_surprise = rgdp_actual - rgdp_expec
	keep daten rgdp_surprise rgdp_actual rgdp_expec
	merge 1:1 daten using "${procq}/newdailyshocks.dta", nogen
	save "${procq}/newdailyshocks.dta", replace
	sleep 800

** (8) BBK: monthly "Brave-Butters-Kelley RGDP", found here https://fred.stlouisfed.org/series/BBKMGDP
import delimited "$rawq/FRED/fred_bbk_90_25.csv", clear 
	gen daten = date(observation_date, "YMD")
	gen year = yofd(daten) 
	gen month  =mofd(daten) 
	sort month 
	rename bbkmgdp bbk 
	gen lag_bbk = bbk[_n-1]
	keep lag_bbk month 
	merge 1:m month using "${procq}/newdailyshocks.dta", nogen
	save "${procq}/newdailyshocks.dta", replace
	sleep 800

** (9) Core CPI expec, monthly variable 
	use "$procq/MMS_reuters_expectations.dta", clear 
	keep year month corecpi_expec
	gsort year month 
	replace corecpi_expec = corecpi_expec[_n-1] if year == 2014 & month == 12
	count if missing(year) // 0 
	rename month oldmonth 
	gen month = ym(year, oldmonth)
	drop year oldmonth 
	merge 1:m month using "${procq}/newdailyshocks.dta", nogen
		drop if missing(daten) // core cpi goes before bcom 
	save "${procq}/newdailyshocks.dta", replace
	sleep 800
	
** (10) core CPI actual change over time (Bauer/Swanson variable, 6mo change)
*import fred CPILFESL, clear // core cpi , m
use "$import_fred_snapshot/CPILFESL.dta", clear
	rename CPILFESL cpix 
	gen month = mofd(daten)
	gen log_cpi = log(cpix)
	gsort daten 
	gen change_6_mo_corecpi = ((log_cpi[_n-2] - log_cpi[_n-8]) - (log_cpi[_n-8] - log_cpi[_n-14])) * 200
	keep month change_6_mo_corecpi
	merge 1:m month using "${procq}/newdailyshocks.dta", nogen
		drop if missing(daten) // same again 
	save "${procq}/newdailyshocks.dta", replace
	sleep 800
	
	*Final processing of news shocks: inter-FOMC "news"
	use "${proch}/fomc_times_2024.dta", clear 
	keep daten
	sort daten
	gen FOMCdate=_n
	merge 1:1 daten using "${procq}/newdailyshocks.dta", nogen
	save "${procq}/newdailyshockstemp.dta", replace // OK that not everything merges at this stage. 
	
	format daten %td
	format month %tm
	format quarter %tq
	keep if year>=1994 & year<=2024
	order daten year quarter month
	
	*constructing news shocks from day after previous fomc to day before current fomc day
	isid daten
	gsort -daten
	gen FOMCinterval=FOMCdate
	replace FOMCinterval=FOMCinterval[_n-1] if FOMCinterval==. & FOMCinterval[_n-1]!=.
	replace FOMCinterval=. if FOMCdate!=.
	sort daten
	gen ret_sp500 = log_SP500 - log_SP500[_n-1]
	gen ret_pcommodity = (log_bcom - 0.4*log_bcomag) - (log_bcom[_n-1] - 0.4*log_bcomag[_n-1])
	gen diff_slope_yield = T10Y3M - T10Y3M[_n-1]
	sort daten
	gen FOMCcycle=FOMCdate
	replace FOMCcycle=FOMCinterval if FOMCcycle==.

	foreach var of varlist ret_sp500 ret_pcommodity diff_slope_yield rgdp_surprise corecpi_surprise unemp_surprise payroll_surprise  {
	sort FOMCinterval daten
	by FOMCinterval: egen fomc_`var' = sum(`var')
	replace fomc_`var'=. if FOMCinterval==.
	sort FOMCcycle daten
	replace fomc_`var'=fomc_`var'[_n-1] if FOMCinterval==.
	}

	order daten year quarter month FOMC* 
	keep if FOMCdate!=.
	sort daten
	tsset FOMCdate
		gen lrgdp_surprise = L.rgdp_surprise
	
	pca fomc_unemp_surprise fomc_payroll_surprise fomc_rgdp_surprise ///
	lag_bbk change_6_mo_corecpi corecpi_expec ///
	fomc_corecpi_surprise fomc_ret_sp500 fomc_diff_slope_yield ///
	fomc_ret_pcommodity
	predict pc1_10_fomc pc2_10_fomc pc3_10_fomc pc4_10_fomc pc5_10_fomc ///
	pc6_10_fomc pc7_10_fomc pc8_10_fomc pc9_10_fomc pc10_10_fomc
	rename quarter quarter_d 
	collapse (sum) pc*fomc lrgdp_surprise ret_sp500 ret_pcommodity diff_slope_yield rgdp_surprise corecpi_surprise unemp_surprise payroll_surprise lag_bbk, by(quarter_d)	
	save "$procq/PCA_News_newdailyshocks", replace // ===========================
	keep quarter_d pc1_10_fomc pc2_10_fomc pc3_10_fomc pc4_10_fomc pc5_10_fomc ///
	pc6_10_fomc pc7_10_fomc pc8_10_fomc pc9_10_fomc pc10_10_fomc
	save "$procq/PCA_News_justpcs", replace 
	

*D. Final processing and aggregation of quarterly dataset ("estdata") ========== 

** (1) Compustat quarterly fundamentals data processing to "analysis file": 
	
*We need to get revenue from here first
*https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/fundamentals-quarterly/
*just get variables we keep below 
use "$rawq/WRDS/compustat_revenue_80_25.dta", clear 
	keep gvkey datafqtr datadate datacqtr revtq 
	destring gvkey, replace 
	rename revtq revtq_supplemented
	tempfile cREV
	save `cREV'
	
*CPI from fred 	
*import fred CPALTT01USQ661S, clear
use "$import_fred_snapshot/CPALTT01USQ661S.dta", clear
	rename CPALTT01USQ661S cpi
	gen quarter_d = qofd(daten)
	drop datestr daten
	replace cpi = cpi/100 
	tempfile cpi
	save `cpi'	
	
	use "$procq/CCM_Fundamentals_update24.dta", clear // processed dataset from section C.0
	merge m:1 gvkey datafqtr datadate datacqtr using `cREV', nogen keep(master matched)	
	merge m:1 quarter_d using `cpi', keep(match) nogen
	replace revtq = revtq_supplemented if missing(revtq)
	drop revtq_supplemented
	
	*drop finance, pub administration
	drop if sic>="6000" & sic<"7000"
	drop if sic>="9000" & sic<="9799" 
	*drop firms incorporated outside US
	drop if fic!="USA"

	*get Fama French industry codes 
	replace sic = "." if sic == ""
	destring sic, replace 
	ffind sic, newvar(ffi) type(49)
	tostring sic, replace 

	* ==== processing according to old procedure, use same order. ==== * 
	// Carryover: 
	//some firms change their fiscal year during the sample creating a handful of artificial duplicates, we just drop all of these
	duplicates tag gvkey quarter_d, gen(aux)
	drop if aux>0
	drop aux  
	duplicates tag datadate gvkey, g(t) 
	drop if t>0
	drop t
	egen maxdate = max(datadate)
	local maxd = maxdate[1]
	disp "`maxd'"


	egen id = group(gvkey) 
	xtset id quarter_d 

	*Market value, earnings  	
	gen market_value2=prccq*cshoq	
	gen earnings = dpq+oiadpq // operating income + depreciation/amortization
		
	bysort gvkey: egen N=count(gvkey)
	keep if N>=10
	drop N 

	*quarterly flows for capx and acquisitions
	foreach i in capx aqc {
			bysort gvkey year (quarter): gen `i'q=`i'y if quarter==1
			sort id quarter_d
			replace `i'q=D1.`i'y if quarter>1
	}

	*forming LP variables 
	replace ppentq = (F1.ppentq+L1.ppentq)/2 if missing(ppentq) & !missing(L1.ppentq) & !missing(F1.ppentq) 

	gen leverage = (dlcq+dlttq)/atq
		*btw, here are some drop conditions in the original data construction -- which do we need? 
		drop if leverage>10 & !missing(leverage) // NEED. Same order as orig constr
		gen nca_assets_ratio = (actq-lctq)/atq
		gen real_sales_growth =(saleq/L1.saleq)*(L1.cpi/cpi)-1
		drop if !missing(nca_assets_ratio) & (nca_assets_ratio>10 | nca_assets_ratio<-10) // important for capx, acquisitions? yes
		drop if (real_sales_growth>1 | real_sales_growth<-1) & !missing(real_sales_growth) // important for capx, acquisitions? yes
		winsor2 leverage, cuts(.5 99.5) replace
			
	replace atq = (F1.atq+L1.atq)/2 if missing(atq) & !missing(L1.atq) & !missing(F1.atq)

	*generate leader and follower based on todays vars
		preserve
		drop if missing(market_value2)
		keep id quarter_d ffi market_value2
		bysort quarter_d ffi: gen N_2digit=_N
		bysort quarter_d ffi: gen N_5percent= round(N_2digit*.95)
		bysort quarter_d ffi (market_value2): gen leader_mcap_today=(_n>=N_5percent)
		bysort quarter_d ffi (market_value2): gen top4_mcap_today=(_n>=N_2digit-4)
		bysort quarter_d ffi (market_value2): gen top10_mcap_today=(_n>=N_2digit-10)
		gen follower_mcap_today = 1-leader_mcap_today
		save "${procq}/06_leader_market_value2_2024.dta", replace
		restore	

	merge 1:1 id quarter_d using "${procq}/06_leader_market_value2_2024.dta", keep(master matched) nogen
	gen leader_mcap = L1.leader_mcap_today
	gen follower_mcap = L1.follower_mcap_today
	gen top4_mcap = L1.top4_mcap_today
	gen top10_mcap = L1.top10_mcap_today

	*ICR
	gen icr=earnings/xintq
	winsor2 icr, cuts(10 90) replace trim
	foreach i of numlist 1/12{
		gen icr_lag`i' = L`i'.icr
	}
	gen rowno = _n 
	sort id quarter_d rowno //, stable // stable Jun 2
	drop rowno
	gen icr_mean = (L1.icr+L2.icr+L3.icr)/3
	egen icr_median=rowmedian(icr_lag1-icr_lag12)

	*borrowing cost 
	gen borrowing_cost2 = xintq/(dlcq+dlttq)
	winsor2 borrowing_cost2, cuts(0 95) by(year) replace trim
	replace borrowing_cost2=. 	if borrowing_cost2<0
	// annualize and convert to percentages
	replace borrowing_cost2=borrowing_cost2*400
		
	*debt	
	gen debt=dlcq+dlttq // this debt var also used in *(13) for distance to default calc
	gen log_debt = log(debt)
	xtset id quarter_d

	*distance to default is above, merge it later. 

	*assets
	rename atq assets 
	gen log_assets=log(assets)

	*ppe 
	rename ppentq ppe 
	gen log_ppe = log(ppe)

	*revenue 
	gen logrev = log(revtq)

	*aqcq capxq: forwarding the cash flows
	foreach y in aqcq capxq { 
	gen temp=0
	forv l=0/10{
			replace temp=temp+F`l'.`y'
			gen P`y'`l'=(temp/l.assets)
		}
		drop temp
	}

	*Forwarding other variables
	forv l=0/10{
		foreach y in borrowing_cost2 log_debt leverage log_ppe log_assets logrev { 
			gen L`y'`l'=(F`l'.`y'-L1.`y')
			gen F`y'`l'=(F`l'.`y')
		}
	}

	*BM and PE 
	gen BM= 100*ceqq/market_value2
	gen PE= market_value2/earnings
	*clean PE as it has crazy values
	replace PE=. if PE<0 
	su PE, d
	winsor2 PE, cuts(0 95) replace

	*Make interaction terms wrt shock variables. 
	merge m:1 quarter_d using "$procq/QuarterlyFOMC_24", keep(master matched) nogen
	merge m:1 quarter_d using "$procq/PCA_News_newdailyshocks", keep(master matched) nogen	

	xtset id quarter_d
	gen time_trend = quarter_d - 140

	foreach i in mp_klms mp_klms_U ///
				 mp_klms_gk mp_klms_U_gk ///
				 shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min ///
				 shock_2Y_30min_gk shock_5Y_30min_gk shock_10Y_30min_gk shock_30Y_30min_gk ///
				 lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1_10_fomc ///
				 {
		gen double_`i'=c.leader_mcap#c.`i'
		gen triple_`i'=c.l.target#c.`i'#c.leader_mcap
			*new: interactions with postZLB, postnonZLB 
			gen triple_pZLB_`i' = c.l.postZLB#c.`i'#c.leader_mcap
			gen triple_pnZLB_`i' = c.l.postnonZLB#c.`i'#c.leader_mcap
		* Time robustness
		**** In previous versions we had misplaced MYP2 instead of target
		gen tripletime_`i'=c.time_trend#c.l.target#c.leader_mcap //ADDED for secular time test

		*label
		lab var double_`i' "\(\epsilon^{`i'}\)x Top 5 Percent=1"
		lab var triple_`i' "\(\epsilon^{`i'}\) x Top 5 Percent=1 x lagged \(FFR\) "
	}
	gen Lileader=l.target*leader_mcap
		*new: interactions with postZLB, postnonZLB 
		gen LpostZLBleader = l.postZLB*leader_mcap
		gen LpostnonZLBleader = l.postnonZLB*leader_mcap
		gen tripletime_postZLB = c.time_trend#c.l.postZLB#c.leader_mcap
		gen tripletime_postnonZLB = c.time_trend#c.l.postnonZLB#c.leader_mcap 
		
	*generating "gertler/karadi" weights (these are applied to the LP LHS variables, but NOT the interaction terms above; should check correctness)
	preserve 
	use "$proch/master_fomc_level_24.dta", clear // FOMC level shock data
	keep daten mp_klms_U
	gen quarter_d = qofd(daten)
	* Getting overall count in last 90 days
	rangestat (count) mp_count_all=mp_klms_U, int(daten -90 0)
	* Getting count on quarter up-to-date
	rangestat (count) mp_count_currq=mp_klms_U, int(daten -90 0) by(quarter_d)
	gen mp_count_lastq = mp_count_all - mp_count_currq
	gen weight_currq = mp_count_currq / mp_count_all
	gen weight_lastq = mp_count_lastq / mp_count_all
	keep if (dow(daten) > 0) & (dow(daten) < 6)
	collapse (mean) weight_currq weight_lastq, by(quarter_d)
	save "$procq/gkweights_94_24", replace 
	restore 	

	merge m:1 quarter_d using "$procq/gkweights_94_24", nogen 
	*weighting LHS variables
	xtset id quarter_d
	foreach var of varlist *borrowing_cost2* /*returns**/ *log_assets* *log_ppe* *logrev* Pcapxq* Paqcq* *log_debt* *leverage* debt assets ppe revtq {
		gen L1_`var' = L1.`var'
		gen `var'_gk = weight_currq * `var' + weight_lastq * L1_`var'
	}
	rename lpermno permno 
	tempfile QTLY1 
	save `QTLY1' 
	save "$procq/temptodelete", replace 
	
** (2) Beta suite: https://wrds-www.wharton.upenn.edu/pages/get-data/beta-suite-wrds/beta-suite-by-wrds/
*Choose date range, PERMNO, search entire database, daily, default windows (?), market model, regular return, PERMNO Date Ticker -> Submit

*Original data, '80-2019
use "${rawq}/WRDS/CRSP_Betaj", clear
	rename PERMNO DATE RET TICKER, lower
	keep permno date b_mkt
	rename date daten 
	tempfile BETAJ
	save `BETAJ', replace

import delimited "$rawq/WRDS/b_mkt_20_24.csv", clear 
	keep permno date b_mkt 
	gen daten = date(date, "YMD")
	drop date
	append using `BETAJ'
// 	drop if daten < td(01jan1994)
	gen quarter_d = qofd(daten)
	fcollapse (lastnm) b_mkt, by(permno quarter_d)
	merge 1:m quarter_d permno using "$procq/temptodelete" // `QTLY1'
	drop if _merge==1
	drop _merge
	
** (3) Bring back in DD at this stage; also add SP ratings 
	preserve 
	*S&P ratings
	use "${rawq}/WRDS/SPRatings2.dta", clear // discountined 2017
	keep gvkey datadate splticrm 
	destring gvkey, replace // this is new, so saving to /proc
	rename splticrm rating
	drop if missing(rating)
	save "${procq}/SPRatings2_postDESTR.dta", replace	// we used to merge on datadate, but new data has only ratingdate
	
	*New Standard & Poors ratings data. 
	*https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/capital-iq/sp-credit-ratings/security-ratings/
	*Codebook for the new SPRatings data. The data in the link above is "Option 3." 
	*https://wrds-www.wharton.upenn.edu/documents/1849/WRDS_Credit_Rating_Data_Overview.pdf?alg[…]id=document_1849_2&algolia-index-name=main_search_index
	*Before, we were using "Option 1." That can be found at this link: 
	*https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/ratings/
	use "$rawq/WRDS/SPcredit_entity_rat_17_24", clear 
	drop if ratingdate <= td(28feb2017)
	keep if ratingtype == "STDLONG" & !missing(gvkey) // following codebook for new SPRatings data
	drop if ratingsymbol == "NR"
	duplicates drop 
		egen idtag = tag(gvkey ratingdate)
		egen id = group(gvkey ratingdate)
		bysort id: egen idmean = mean(idtag)
		drop if idmean != 1 // these have multiple ratings per date that are not NR. 
		isid ratingdate gvkey // yes 
	gen quarter_d = qofd(ratingdate)
	gsort gvkey ratingdate // gvkey ratingdate uniquely id
	collapse (lastnm) ratingsymbol, by(gvkey quarter_d) // get last rating each quarter	
	destring gvkey, replace 
	save "$procq/SPcredit_entity_clean", replace 
	restore 
	
	merge m:1 permno datadate using "$procq/DDfinal_quarterly", keep(master matched) nogen 
	merge 1:1 datadate gvkey using "${procq}/SPRatings2_postDESTR.dta", keep(master matched) nogen // same as previously 
	merge 1:1 gvkey quarter_d using "$procq/SPcredit_entity_clean", keep(master matched) nogen 
	replace rating = ratingsymbol if missing(rating) // update ratings thru 2024, this data is very sparse however
	
	keep if year >= 1992 & year <= 2024 // 1992 start matches estdata old version
	drop if missing(permno) 
	drop if missing(quarter_d) // 90
	gen leadertime=c.leader_mcap#c.time_trend 
	egen industrytime = group(year quarter ffi)
	xtset id quarter_d
	
	save "$procq/estdata_update", replace // ====================================
	
	*Get list of firms in quarterly data, and their industry 
	use "$procq/estdata_update", clear 
	keep permno ffi 
	duplicates drop 
	egen duptag = tag(permno)
	drop if duptag == 0 // ffi changes 
	save "$procq/mainsample_list_update.dta", replace 

// MISC. 

*(1) Placebo duration dataset update. 
	use "$proch/master_fomc_level_24.dta", clear // for \omega_t 
	keep daten fomc_id mp_klms_U 
	rename mp_klms_U mp_klms // for the Placebo code 
	drop if missing(mp_klms) // since we have some missing -- the unsched meetings
	tempfile shokplacebo 
	save `shokplacebo'

	use "${proch}/temp_stock_fomc_level24.dta", clear // all days FOMC	
	keep daten permno shock_hf_30min 
	replace shock_hf_30min = shock_hf_30min * 100 
	merge m:1 daten using `shokplacebo', nogen keep(master matched)
	merge m:1 permno using "$procq/mainsample_list_update.dta", nogen keep(matched) // main sample consistent w HF
	gsort permno
	format daten %td
	save "$bootstrap_data/master_daily_placebo_calculation_UPDATE.dta", replace
	// can see that there are the same # of firms in the above data as in "maintable_data"	using: 
	// codebook permno if !missing(mp_klms) & !missing(shock_hf_30min)

timer off 1 
timer list 1 
// ========================================================================== //
/* END DATA CONSTRUCTION */ 
// ===========================================================================//
	
	