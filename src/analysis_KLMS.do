* analysis 

* Analysis

// A. MAKE MAIN ANALYSIS FILES 
// B. HIGH-FREQ FIGURES   
// C. HIGH-FREQ TABLES 
// D. COMPUSTAT INTRO TABLES/FIGURES (3.1)
// E. COMPUSTAT IRFS/NEWS ROBUSTNESS
// F. APPENDIX 

// A. MAKE MAIN ANALYSIS FILES: ================================================
// (a) HF "main table" data with various percentiles,
// (b) Compustat data with various percentiles  

// (a) "Main Table" Data (with some robustness measures defined)
use "${proch}/master_firm_level_24.dta", clear 
	merge m:1 daten using "$proch/master_fomc_level_24.dta", nogen keep(master matched)

	merge m:1 permno using "${procq}/mainsample_list_update", nogen keep(matched)

	*get year-firm ptile. We only ever generated ptile by period, previously. 
	bysort daten: egen rank = rank(adj_MV) 
	bysort daten: egen count = count(adj_MV) 
	gen ptile = (rank - 0.5) / count 

	*Percentile mean by firm
	egen Fptile_TEMP=mean(ptile) if unscheduled_meetings!=1, by(permno) //
	egen Fptile = mean(Fptile_TEMP), by(permno) // this new method fills in for unsched dates too--important
	gen Fdecile=int(Fptile*20)+1
	replace Fdecile = Fdecile * 5 // "percentiles" in 100s
	* "percentile by Fptile" -- consistent across FIRMS. 
	egen firmtag = tag(permno) // if !missing(Fptile) &!missing(adj_MV)
	egen rankF = rank(Fptile) if firmtag==1 
	egen countF = count(Fptile) if firmtag == 1
	gen temp_ptile_consis = (rankF-0.5)/countF // sum: 25th, median, 75th percentiles good
	bysort permno: egen ptile_consis = mean(temp_ptile_consis)
	drop temp_ptile_consis
	gen Fdecile_consis = int(ptile_consis*20)+1 
	replace Fdecile_consis = Fdecile_consis * 5 // "percentiles"	
	
	*now will do the same for within-industry percentile. 
	bysort daten ffi: egen indrank = rank(adj_MV)
	bysort daten ffi: egen indcount = count(adj_MV) 
	gen indptile = (indrank - 0.5) / indcount
	egen indFptile_TEMP = mean(indptile) if unscheduled_meetings!=1, by(permno)
	egen indFptile = mean(indFptile_TEMP), by(permno) // 
	gen indFdecile = int(indFptile*20)+1
	replace indFdecile = indFdecile*5
	*consis defn: 
	egen rank_indF = rank(indFptile) if firmtag==1
	egen count_indF = count(indFptile) if firmtag==1
	gen temp_ptile_consis_ind = (rank_indF - 0.5)/count_indF
	bysort permno: egen ptile_consis_ind = mean(temp_ptile_consis_ind) 
	drop temp_ptile_consis_ind 
	gen Fdecile_consis_ind = int(ptile_consis_ind*20)+1
	replace Fdecile_consis_ind = Fdecile_consis_ind * 5 // "percentiles"

	*save "$proch/DU_temp_FD.dta", replace 
	
	*use "$proch/DU_temp_FD.dta", clear 

	*Firm distribution test
	levelsof daten if unscheduled_meetings!=1, local(datens)
	local ctdaten = wordcount("`datens'")
	disp "`ctdaten'"
	bysort permno: egen firmcount = count(daten) if unscheduled_meetings!=1
	tab firmcount // about 20 percent of firm-dates are firms w/ all dates
	drop firmcount
	
	*Window length mean by firm
	egen Fwindowlen=mean(window_shock_hf_30min) if unscheduled_meetings!=1, by(permno)

	capture drop mp_klmspost
	capture drop WLxSHOCK
	capture drop mp_klmsFptile
	gen WLxSHOCK = window_shock_hf_30min * mp_klms_U
	*Key step: replacing Fptile with consistent definition ====================================== 
	replace Fptile = ptile_consis
	gen mp_klms_ptile = mp_klms_U * ptile 
	gen mp_klmsFptile=mp_klms_U*Fptile
	drop post*
	
	*Make post 3 times || ZLB & nonZLB definitions
	gen post=0 if year>=1994 & year<=2006
// 		replace post=1 if year>=2007 & year<=2019	
		replace post=1 if year>=2007 & year<=2024	
	gen postZLB = 0 if year>=1994 & year<=2006     
		replace postZLB=1 if (year>=2009 & year<=2015) | (year>=2020 & year<=2021)
		gen excluderZLB = 1 if !missing(postZLB) 
		replace postZLB = 0 if missing(postZLB)	// use condition above to remove 
	gen postnonZLB = 0 if year>=1994 & year<=2006
		replace postnonZLB=1 if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022)
		gen excludernonZLB = 1 if !missing(postnonZLB)
		replace postnonZLB = 0 if missing(postnonZLB) // use condition in reg to remove

	gen tempzlbtest = postZLB + postnonZLB 
	sum tempzlbtest if year >= 2007 // adds to 1 always
	
	gen Fptilepost = Fptile * post 
	gen Fptile_postZLB = Fptile * postZLB 
	gen Fptile_postnonZLB = Fptile * postnonZLB
	
	*Make postxshock 3 times
	gen mp_klmspost=mp_klms_U*post
	gen mp_klmspostZLB = mp_klms_U*postZLB 
	gen mp_klmspostnonZLB = mp_klms_U*postnonZLB 
	
	*Make postxptilexshock 3 times 
	gen mp_klmsFptilepost=mp_klms_U*Fptile*post
	gen mp_klmsFptilepostZLB=mp_klms_U*Fptile*postZLB
	gen mp_klmsFptilepostnonZLB=mp_klms_U*Fptile*postnonZLB
	
	*Triple interactions, now using ptile (time-varying)
	gen mp_klms_ptile_post=mp_klms_U*ptile*post
	gen mp_klms_ptile_postZLB=mp_klms_U*ptile*postZLB
	gen mp_klms_ptile_postnonZLB=mp_klms_U*ptile*postnonZLB
	
	label var mp_klms_U "$\omega_t$"
	label var mp_klmsFptile "$\omega_t * \bar{X}_i$"
	label var mp_klms_ptile "$\omega_t * X_{it}$" // new 4/12/25 
	
	label var post "$\text{post}$" 
	label var postZLB "$\text{post (ZLB)}$"
	label var postnonZLB "$\text{post (non-ZLB)}$"
	
	label var mp_klmspost "$\omega_t * \text{post}$"
	label var mp_klmspostZLB "$\omega_t * \text{post (ZLB)}$"
	label var mp_klmspostnonZLB "$\omega_t * \text{post (non-ZLB)}$"
	
	label var mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$"
	label var mp_klmsFptilepostZLB "$\omega_t * \bar{X}_i * \text{post (ZLB)}$"
	label var mp_klmsFptilepostnonZLB "$\omega_t * \bar{X}_i * \text{post (non-ZLB)}$"
	
	//new 4/12/25: time-varying ptile
	label var mp_klms_ptile_post "$\omega_t * X_{it} * \text{post}$"
	label var mp_klms_ptile_postZLB "$\omega_t * X_{it} * \text{post (ZLB)}$"
	label var mp_klms_ptile_postnonZLB "$\omega_t * X_{it} * \text{post (non-ZLB)}$"
	label var ptile "X_{it}"
	label var Fptilepost "X_{i} * \text{post}"
	label var Fptile_postZLB "X_{i} * \text{post (ZLB)}"
	label var Fptile_postnonZLB "X_{i} * \text{post (non-ZLB)}"
	
	label var window_shock_hf_30min "$\text{Window Length}_{it}$"
	label var WLxSHOCK "$\omega_t * \text{Window Length}_{it}$"
	
	drop zcoupon_1y diff_zcoupon_1y MP* ED* shock_ed* shock_ff* indic_GKL scaled_diff
	save "$proc_analysis/maintable_data", replace 

// (b) Compustat data with various percentiles 
use "$procq/estdata_update", clear
	rename (market_value2) (adj_MV)
	gen valid = 1 if adj_MV != .
	bysort quarter_d: egen rank = rank(adj_MV) if valid == 1 // valid doesn't matter
	bysort quarter_d: egen count = count(adj_MV) if valid == 1
	gen ptile = (rank - 0.5) / count 

	*Percentile mean by firm
	egen Fptile=mean(ptile) /*if unscheduled_meetings!=1*/, by(id) //
	gen Fdecile=int(Fptile*20)+1
	replace Fdecile = Fdecile * 5 // "percentiles" in 100s
	* "percentile by Fptile" -- consistent across FIRMS. 
	egen firmtag = tag(id) // if !missing(Fptile) &!missing(adj_MV)
	egen rankF = rank(Fptile) if firmtag==1 
	egen countF = count(Fptile) if firmtag == 1
	gen temp_ptile_consis = (rankF-0.5)/countF // sum: 25th, median, 75th percentiles good
	bysort id: egen ptile_consis = mean(temp_ptile_consis)
	drop temp_ptile_consis
	gen Fdecile_consis = int(ptile_consis*20)+1 
	replace Fdecile_consis = Fdecile_consis * 5 // "percentiles"	
	
	*now will do the same for within-industry percentile. 
	bysort quarter_d ffi: egen indrank = rank(adj_MV)
	bysort quarter_d ffi: egen indcount = count(adj_MV) 
	gen indptile = (indrank - 0.5) / indcount
	egen indFptile = mean(indptile) /*if unscheduled_meetings!=1*/, by(id)
	//egen indFptile = mean(indFptile_TEMP), by(id) // 
	gen indFdecile = int(indFptile*20)+1
	replace indFdecile = indFdecile*5
	*consis defn: 
	egen rank_indF = rank(indFptile) if firmtag==1
	egen count_indF = count(indFptile) if firmtag==1
	gen temp_ptile_consis_ind = (rank_indF - 0.5)/count_indF
	bysort id: egen ptile_consis_ind = mean(temp_ptile_consis_ind) 
	drop temp_ptile_consis_ind 
	gen Fdecile_consis_ind = int(ptile_consis_ind*20)+1
	replace Fdecile_consis_ind = Fdecile_consis_ind * 5 // "percentiles"
	
	*top 4 firms by ptile_consis_ind in each ind 
	gen neg_ptile_consis_ind = -1*ptile_consis_ind 
	bysort ffi: egen neg_leader = rank(neg_ptile_consis_ind) if firmtag==1
	gen top4temp = neg_leader <= 4 & firmtag==1
	bysort id: egen top4 = max(top4temp)
	
	*sales industry leader
	bysort quarter_d ffi: egen indrankSAL = rank(saleq)
	bysort quarter_d ffi: egen indcountSAL = count(saleq)
	gen indptileSAL = (indrankSAL - 0.5) / indcountSAL
	egen indFptileSAL = mean(indptileSAL) /*if unscheduled_meetings!=1*/, by(id)
	*consis defn:
	egen rank_indFSAL = rank(indFptileSAL) if firmtag==1
	egen count_indFSAL = count(indFptileSAL) if firmtag==1
	gen temp_ptile_consis_indSAL = (rank_indFSAL - 0.5)/count_indFSAL
	bysort id: egen ptile_consis_indSAL = mean(temp_ptile_consis_indSAL)
	drop temp_ptile_consis_indSAL 	
	
	*sic industry leader -- remember to change FEs as well.
	egen sicindustrytime = group (year quarter sic) // use for the FE 
	bysort quarter_d sic: egen indrankSIC = rank(adj_MV)
	bysort quarter_d sic: egen indcountSIC = count(adj_MV)
	gen indptileSIC = (indrankSIC - 0.5) / indcountSIC
	egen indFptileSIC = mean(indptileSIC) /*if unscheduled_meetings!=1*/, by(id)
	*consis defn:
	egen rank_indFSIC = rank(indFptileSIC) if firmtag==1
	egen count_indFSIC = count(indFptileSIC) if firmtag==1
	gen temp_ptile_consis_indSIC = (rank_indFSIC - 0.5)/count_indFSIC
	bysort id: egen ptile_consis_indSIC = mean(temp_ptile_consis_indSIC)
	drop temp_ptile_consis_indSIC
	
	egen temptag = tag(id quarter_d) 
	drop if temptag == 0 // 10 of 491,000
	xtset id quarter_d	
	
	drop neg* temptag
	*drop unneeded WRDS data 
	drop indfmt consol popsrc datafmt curcdq datacqtr datafqtr assets ceqq dlcq  ///
	cshoq dlttq dpq oiadpq ppe revtq saleq xintq aqcy capxy costat fic prccq sic ///
	actq ancq cheq cogsq dd1q lctq lltq ltq mibq niq oibdpq piq ppegtq pstkq req ///
	teqq txtq wcapq xrdq xsgaq chechy dlcchy dltisy dltry dvy exrey fiaoy fincfy ///
	ivncfy oancfy prstkccy prstkcy prstkpcy scstkcy spstkcy sstky txbcofy xrdy   ///
	xsgay cshtrq dvpspq dvpsxq mkvaltq prchq prclq adjex conml capxq aqcq        ///
    nca_assets_ratio real_sales_growth N_2digit N_5percent                       ///
	leader_mcap_today top4_mcap_today top10_mcap_today follower_mcap_today	
	save "$proc_analysis/estdata_update_ptilec.dta", replace 
	

// B. HIGH-FREQ FIGURES ========================================================

*(0) Values referenced in text that don't come from figures. 

 *Introductory statistic: fed funds averages 
use "$proch/FFtarget.dta", clear // daily target, switch to lower limit
gen year = yofd(daten)
sum target if year >= 1994 & year <= 2006, meanonly 
disp "High rate mean FFR: `r(mean)'"
sum target if year >= 2007 & year <= 2024, meanonly
disp "Low rate mean FFR: `r(mean)'"

*Statement: "remarkably similar to the decline in 5-year rate..."
*import fred DGS5, clear 
use "$import_fred_snapshot/DGS5.dta", clear
gen date = dofm(daten)
gen year = yofd(daten)
sum DGS5 if year >= 1994 & year <= 2006, meanonly 
disp "High rate mean FFR: `r(mean)'"
sum DGS5 if year >= 2007 & year <= 2024, meanonly
disp "Low rate mean FFR: `r(mean)'"

*Statement: "...the top 5% and top 10% of firms constitute approximately 66% and 78% of total market value..."
// use "$proc_analysis/DU_temp_FD.dta", clear 
use "$proc_analysis/maintable_data", clear
gen indic10 = ptile_consis >= 0.9
gen indic5 = ptile_consis >= 0.95
collapse (mean) adj_MV (first) indic5 indic10, by(permno) // average market value by firm 

preserve 
collapse (sum) adj_MV, by(indic5)
egen allMV = total(adj_MV)
replace adj_MV = adj_MV / allMV
sum adj_MV if indic5==1, meanonly 
disp "Top 5% total MV: `r(mean)'"
restore 

preserve 
collapse (sum) adj_MV, by(indic10)
egen allMV = total(adj_MV)
replace adj_MV = adj_MV / allMV
sum adj_MV if indic10==1, meanonly 
disp "Top 10% total MV: `r(mean)'"
restore 

*Statement: "... when average inflation was 2.5 percentage points."
*import fred FPCPITOTLZGUSA, clear 
use "$import_fred_snapshot/FPCPITOTLZGUSA.dta", clear
gen date = dofm(daten)
gen year = yofd(daten)
sum FPCPITOTLZGUSA if year >= 1994 & year <= 2024, meanonly 
disp "Avg inflation in sample: `r(mean)' percent"



*(1a) Basic Fig 1 redo, unscheduled. 
use "$proc_analysis/master_fomc_level_24.dta", clear 
	* (Default post definition is >=2007)
	gen myshock = mp_klms_U // CHANGE SHOCK HERE ==========
	
	*matrix for coefficients
	cap matrix drop Beta_1s
	mat Beta_1s=J(9,3,.)

	***** Getting Coefs
			eststo clear
			local ynum=0
			*RUN FOR ALL COLUMNS
			local lhs_list MP1 MP2 ED2 ED3 ED4 shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min
			local mat_list 42 84 180 270 365 730 1825 3650 10950
			
			forv i = 1/9 {
			local lhs : word `i' of `lhs_list'
			local mat : word `i' of `mat_list'
			disp "`lhs'"
			local ynum = `ynum' + 1
			
			*Define controls
			reghdfe `lhs' myshock, noabsorb vce(cluster daten) 
			
			mat Beta_1s[`ynum',1]=_b[myshock]
			mat Beta_1s[`ynum',2]=_se[myshock]
			mat Beta_1s[`ynum',3]= `mat'
			}

	clear
	svmat Beta_1s 
	rename (Beta_1s1 Beta_1s2 Beta_1s3) (coef se mat)
	gen ub = coef + 1.96 * se
	gen lb = coef - 1.96 * se
	gen log_mat = log(mat)
	
	twoway (rcap ub lb /*log_mat*/ mat, lcolor(gray) lpattern(dash)) ///
	       (scatter coef /*log_mat*/mat, mcolor(black)), ///
	       leg(off) xscale(log) xlabel(30 "30" 90 "90" 365 "365" 1095 "1095" 3650 "3650" 10950 "10950") ///
		   xtitle("Maturity length, days (log scale)") ytitle("High-frequency response of yield curve to {&omega}") ///
		   /*title("Full 1994-2024 sample, drop unscheduled") */
	graph export "${output_fig}\maindraft\fig1_rate_response_omega.pdf", replace	   

*(1b) Pre/post split, >=2007 defn of post 
use "$proc_analysis/master_fomc_level_24.dta", clear 
	* (Default post definition is >=2007)
	gen myshock = mp_klms_U // CHANGE SHOCK HERE ==========
	
		*matrix for coefficients
		cap estimates drop * 
		cap matrix drop Beta_1s
		mat Beta_1s=J(9,5,.)

		***** Getting Coefs
			eststo clear
			local ynum=0
			*RUN FOR ALL COLUMNS
			local lhs_list MP1 MP2 ED2 ED3 ED4 shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min
			local mat_list 42 84 180 270 365 730 1825 3650 10950
			
			forv i = 1/9 {
			local lhs : word `i' of `lhs_list'
			local mat : word `i' of `mat_list'
			disp "`lhs'"
			disp "`shockvar'"
			local ynum = `ynum' + 1
				
			*Run pre regression
			reghdfe `lhs' myshock if post==0, noabsorb vce(cluster daten) 
			*Store coeffs
			matrix Beta_1s[`ynum',1]=_b[myshock]
			matrix Beta_1s[`ynum',2]=_se[myshock]
			matrix Beta_1s[`ynum',3]= `mat'
			*Run post regression 
			reghdfe `lhs' myshock if post==1, noabsorb vce(cluster daten) 
			*Store coeffs
			matrix Beta_1s[`ynum',4]=_b[myshock]
			matrix Beta_1s[`ynum',5]=_se[myshock]
			}

		clear
		svmat Beta_1s 
		rename (Beta_1s1 Beta_1s2 Beta_1s3 Beta_1s4 Beta_1s5) (coef se mat coef2 se2)
		gen ub = coef + 1.96 * se
		gen lb = coef - 1.96 * se
		gen ub2 = coef2 + 1.96 * se2
		gen lb2 = coef2 - 1.96 * se2

		twoway (rcap ub lb mat, lcolor(gray) lpattern(dash)) (scatter coef mat, mcolor(black)) ///
		(rcap ub2 lb2 mat, lcolor(edkblue) lpattern(dash)) (scatter coef2 mat, mcolor(edkblue) msymbol(square)) , ///
		xscale(log) xlabel(30 "30" 90 "90" 365 "365" 1095 "1095" 3650 "3650" 10950 "10950") ///
		/*leg(off)*/ legend(order(2 "Pre-2007" 4 "Post-2007")) /// 
		xtitle("Maturity length, days (log scale)") ytitle("High-frequency response of yield curve to {&omega}") ///
		name(g1, replace) yscale(range(-0.1 0.4)) ylabel(-0.1(0.1)0.4)
// 		/// title("Split by pre-2007 and 2007 onwards (green)")
	graph export "${output_fig}\misc\fig1_rate_response_omega_splitpost.pdf", replace	
	

*(1c) Pre/post split, post is both ZLB and nonZLB. 
use "$proc_analysis/master_fomc_level_24.dta", clear 
	* (Default post definition is >=2007)
	gen myshock = mp_klms_U // CHANGE SHOCK HERE ==========
	
		*matrix for coefficients
		cap estimates drop * 
		cap matrix drop Beta_1s
		mat Beta_1s=J(9,7,.)

		***** Getting Coefs
			eststo clear
			local ynum=0
			*RUN FOR ALL COLUMNS
			local lhs_list MP1 MP2 ED2 ED3 ED4 shock_2Y_30min shock_5Y_30min shock_10Y_30min shock_30Y_30min
			local mat_list 42 84 180 270 365 730 1825 3650 10950
			
			forv i = 1/9 {
			local lhs : word `i' of `lhs_list'
			local mat : word `i' of `mat_list'
			disp "`lhs'"
			disp "`shockvar'"
			local ynum = `ynum' + 1
				
			*Run pre regression
			reghdfe `lhs' myshock if post==0, noabsorb vce(cluster daten) 
			*Store coeffs
			matrix Beta_1s[`ynum',1]=_b[myshock]
			matrix Beta_1s[`ynum',2]=_se[myshock]
			matrix Beta_1s[`ynum',3]= `mat'
			*Run post regression 
			cap drop post 
			gen post=0 if year>=1994 & year<=2006
			replace post=1  if (year>=2009 & year<=2015) | (year>=2020 & year<=2021) //only ZLB as post
			tab post	
			reghdfe `lhs' myshock if post==1, noabsorb vce(cluster daten) 
			*Store coeffs
			matrix Beta_1s[`ynum',4]=_b[myshock]
			matrix Beta_1s[`ynum',5]=_se[myshock]
			
			*Change to post non-ZLB defn 
			preserve 
			replace post = 0 
			replace post=1  if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | year>=2022 //only non-ZLB as post
			*Run post regression 
			reghdfe `lhs' myshock if post==1, noabsorb vce(cluster daten) 
			*Store coeffs
			matrix Beta_1s[`ynum',6]=_b[myshock]
			matrix Beta_1s[`ynum',7]=_se[myshock]
			restore 
			}

		clear
		svmat Beta_1s 
		rename (Beta_1s1 Beta_1s2 Beta_1s3 Beta_1s4 Beta_1s5 Beta_1s6 Beta_1s7) (coef se mat coef2 se2 coef3 se3)
		gen ub = coef + 1.96 * se
		gen lb = coef - 1.96 * se
		gen ub2 = coef2 + 1.96 * se2
		gen lb2 = coef2 - 1.96 * se2
		gen ub3 = coef3 + 1.96 * se3 
		gen lb3 = coef3 - 1.96 * se3 
		
		*NEW 6/23: JITTER THIS GRAPH 
		gen mat_pre   = mat ^ 0.995      //   -0.5% shift to the left
		gen mat_zlb   = mat             //    0 % (stays centred)
		gen mat_nonz  = mat ^ 1.005      //   +0.5% shift to the right	
		
		twoway (rcap ub lb mat_pre, lcolor(gray) lpattern(dash)) (scatter coef mat_pre, mcolor(black)) ///
		(rcap ub2 lb2 mat_zlb, lcolor(blue) lpattern(dash)) (scatter coef2 mat_zlb, mcolor(blue) msymbol(square)) ///
		(rcap ub3 lb3 mat_nonz, lcolor(eltblue) lpattern(dash)) (scatter coef3 mat_nonz, mcolor(eltblue) msymbol(square)), ///
		xscale(log) xlabel(30 "30" 90 "90" 365 "365" 1095 "1095" 3650 "3650" 10950 "10950") ///
		/*leg(off)*/ legend(order(2 "Pre-2007" 4 "Post-2007 ZLB" 6 "Post-2007 Non-ZLB") cols(3)) /// 
		xtitle("Maturity length, days (log scale)") ytitle("High-frequency response of yield curve to {&omega}") ///
		name(g2, replace) yscale(range(-0.1 0.4)) ylabel(-0.1(0.1)0.4)
// 		/// title("Split by pre-2007 and ZLB (green), non-ZLB (red)")
	graph export "${output_fig}\misc\fig1_rate_response_omega_postZLBnonZLB.pdf", replace	
	
	graph combine g1 g2, cols(2) xsize(5.375) ysize(2.6)  
	graph export "$output_fig\maindraft\fig1_rate_response_omega_combine.pdf", replace

* 2. Coefficients by year, quintile, post definition. ==========================
*(2a) using mp_klms_U: rolling 6Y 
 
	*use "$proc_analysis/DU_temp_FD.dta", clear 
	use "$proc_analysis/maintable_data", clear
	
	gen coef1=.
	gen se1=.
	egen ytag=tag(year)
	forvalues i=1994/2019 {
	areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1 & year>=`i' & year<=`i'+5 ,cluster(daten) absorb(permno)
	replace coef1=_b[mp_klms_U] if year==`i'+5
	replace se1=_se[mp_klms_U] if year==`i'+5
	}
	gen lb = coef1 - se1 
	gen ub = coef1 + se1
	graph twoway (rcap ub lb year, lcolor(gray) lpattern(dash)) (scatter coef1 year,  mcolor(black) msymbol(diamond)) if ytag==1, yline(0, lpattern(dash)) ytitle("{&beta}{subscript:1}") /*title("Rolling 6Y coeffs. using scheduled only")*/ xtitle("") legend(off) xscale(r(1995 2025)) xlabel(1995(5)2025) // nice rolling avg
	graph export "${output_fig}\maindraft\fig2_coeffs_by_year.pdf", replace	

*(2b) using mp_klms_U, split quintile coeff graph by post 
	*use "$proc_analysis/DU_temp_FD.dta", clear 
	use "$proc_analysis/maintable_data", clear
	
	gen coef3=.
	gen se3=.
	egen FpPtag=tag(Fdecile_consis post)
	
	forvalues p=0/1 {
	forvalues i=1/20 {
	areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1 & Fdecile_consis==`i'*5 & post==`p',cluster(daten) absorb(permno) 
	replace coef3=_b[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	replace se3=_se[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	}
	}	
	gen lb3 = coef3 - se3 
	gen ub3 = coef3 + se3 
	graph twoway (rcap ub3 lb3 Fdecile_consis if post==0, lcolor(red) lpattern(dash)) (scatter coef3 Fdecile_consis if post==0, mcolor(red)) ///
	(rcap ub3 lb3 Fdecile_consis if post==1, lcolor(blue) lpattern(dash)) (scatter coef3 Fdecile_consis if post==1, mcolor(blue)) ///
	(lfit coef3 Fdecile_consis if post == 0, lcolor(red)) (lfit coef3 Fdecile_consis if post == 1, lcolor(blue)) ///
	if FpPtag==1, /*title("Split percentile graph using scheduled only")*/ leg(order(2 "1994-2006" 4 "2007-2024")) /*ylabel(-0.25(0.05)0)*/ ytitle("{&beta}{subscript:1}") xtitle("Percentile")
	graph export "${output_fig}\maindraft\fig3_coeffs_by_quintile_splitpost.pdf", replace


*(3) Dollar duration figure split by pre/post. =================================
	*use "$proc_analysis/DU_temp_FD.dta", clear 
	use "$proc_analysis/maintable_data", clear	
	
	gen coef3=.
	gen se3=.
	egen FpPtag=tag(Fdecile_consis post)
	
	forvalues p=0/1 {
	forvalues i=1/20 {
	areg shock_hf_30min_dollar mp_klms_U if unscheduled_meetings!=1 & Fdecile_consis==`i'*5 & post==`p',cluster(daten) absorb(permno) 
	replace coef3=_b[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	replace se3=_se[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	}
	}	
	gen lb3 = coef3 - se3 
	gen ub3 = coef3 + se3 
	
	graph twoway (scatter coef3 Fdecile_consis if post==0 /*& Fdecile<=80*/, mcolor(red)) ///
	(scatter coef3 Fdecile_consis if post==1 /*& Fdecile<=80*/, mcolor(blue)) ///
	if FpPtag==1, title("\$ 30 min") leg(order(1 "1994-2006" 2 "2007-2024")) /*ylabel(-0.25(0.05)0)*/ ytitle("{&beta}{subscript:1}") xtitle("Percentile")
	graph export "${output_fig}\maindraft\fig4_dollarduration_by_xtile.pdf", replace


// C. HIGH-FREQ TABLES =========================================================

*(1) Main Table 
use "$proc_analysis/maintable_data", clear 		
	cap estimates drop * 
	cap eststo clear 	
	*baseline 
	areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1, cluster(daten) absorb(permno)
	eststo p0 
	estadd local FE "Firm"
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspost post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspostZLB mp_klmspostnonZLB postZLB postnonZLB if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klms_U mp_klmsFptile Fptile if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"		
	
	*
	areg shock_hf_30min mp_klmsFptilepostZLB mp_klmspostZLB postZLB mp_klmsFptilepostnonZLB mp_klmspostnonZLB postnonZLB mp_klmsFptile mp_klms_U  if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	
	esttab p*, label se 				
	
	esttab p* using "${output_tab}\maindraft\DU_ZLBnonZLB_ptileconsis.tex", label drop(_cons Fptile) se stats(N r2 FE, label("N" "R2" "FEs") fmt(%9.0fc %9.3f)) replace ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	post "$\text{post}$"  ///
	postZLB "$\text{post (ZLB)}$" ///
	postnonZLB "$\text{post (non-ZLB)}$" ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmspostZLB "$\omega_t * \text{post (ZLB)}$" ///
	mp_klmspostnonZLB "$\omega_t * \text{post (non-ZLB)}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
	mp_klmsFptilepostZLB "$\omega_t * \bar{X}_i * \text{post (ZLB)}$"  ///
	mp_klmsFptilepostnonZLB "$\omega_t * \bar{X}_i * \text{post (non-ZLB)}$" ///
    ) ///
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) nonotes //note("")
			
					
*(2) Second main table with FFR level in each period replacing period indicators, and a "dollar duration" column 
use "$proch/FFtarget", clear // import fred FEDFUNDS, clear 

gen year = yofd(daten)

	sum target if year >= 1994 & year <= 2006, meanonly 
	local premean = `r(mean)'
	sum target if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021), meanonly  
	local ZLBmean = `r(mean)'	
	sum target if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024), meanonly  
	local nonZLBmean = `r(mean)'	
	di "`premean', `ZLBmean', `nonZLBmean'"
	
	use "$proc_analysis/maintable_data", clear 
	
	cap estimates drop * 
	cap eststo clear 	
	
	gen FFR_bar = `premean' /* */ // pre- period 
	replace FFR_bar = `ZLBmean' /* */ if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021) 
	replace FFR_bar = `nonZLBmean' /* */ if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024) 
 	
	replace mp_klmspost = mp_klms_U * FFR_bar 
	replace mp_klmsFptilepost = mp_klms_U * ptile_consis * FFR_bar 

	*
	areg shock_hf_30min mp_klms_U mp_klmspost FFR_bar if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"		
	*
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U FFR_bar if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"		
	*
	gen leader_indic = (ptile_consis >= 0.95)
	gen shock_leader_FFR = mp_klms_U * leader_indic * FFR_bar 
	gen shock_leader = mp_klms_U * leader_indic
	areg shock_hf_30min_dollar shock_leader mp_klms_U shock_leader_FFR mp_klmspost FFR_bar if unscheduled_meetings!=1, cluster(daten) absorb(permno)
	eststo p3
	estadd local FE "Firm"		
	
	esttab p*, nocons se
	
	esttab p* using "${output_tab}\maindraft\DU_FFRbar.tex", label drop(_cons /*Fptile*/) se stats(N r2 FE, label("N" "R2" "FEs") fmt(%9.0fc %9.3f)) replace ///
	  varlabels( ///
    FFR_bar           "$\overline{\mathrm{FFR}}$" ///
    mp_klmspost       "$\omega_t * \overline{\mathrm{FFR}}$" ///
    mp_klmsFptilepost "$\omega_t * \bar X_i * \overline{\mathrm{FFR}}$" ///
    shock_leader_FFR  "$\omega_t * \text{Overall Leader} * \overline{\mathrm{FFR}}$" ///
    shock_leader      "$\omega_t * \text{Overall Leader}$" ///
  ) ///
	mgroups("$ R_{it}$" "$\textdollar R_{it}$" , pattern(1 0 1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			order(mp_klms_U FFR_bar mp_klmspost mp_klmsFptile mp_klmsFptilepost) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 	nonotes
			
// D. COMPUSTAT INTRO TABLES/FIGURES (3.1) =====================================

*(1) Summary Statistics 
	local type "_gk" 
	local type_mp `type'
	
	eststo clear						
	use "${procq}/estdata_update", clear
	local pp_vars leverage`type' Paqcq3`type' Pcapxq3`type'
	foreach var of local pp_vars{
		gen percentp_`var' = `var' * 100
	}

	lab var borrowing_cost2`type' "Borrowing Costs" 
	lab var percentp_leverage`type' "Leverage"
	lab var percentp_Paqcq3`type' "Acquisitions Expenditure" 
	lab var percentp_Pcapxq3`type' "Capital Acquisition Expenditure" 
	lab var debt`type' "Debt" 
	lab var assets`type' "Assets" 
	lab var ppe`type' "Property, Plant, and Equipment" 
	lab var logrev`type' "Revenue"
	lab var mp_klms`type_mp' "MP shock"

	preserve
	drop if year < 1994 | year > 2024 // changed	
	keep quarter_d mp_klms_U`type_mp'
	duplicates drop
	drop if missing(mp_klms_U`type_mp')
	estpost summarize mp_klms_U`type_mp', detail
	cap matrix drop mat1
	matrix mat1 = J(1, 6, .)
	matrix mat1[1, 1] = e(count)
	matrix mat1[1, 2] = e(mean)'
	matrix mat1[1, 3] = e(sd)'
	matrix mat1[1, 4] = e(p25)'
	matrix mat1[1, 5] = e(p50)'
	matrix mat1[1, 6] = e(p75)'
	clear
	svmat mat1
	tempfile mat1
	save `mat1'
	restore
									
	drop if year < 1994 | year > 2024 // changed
	estpost summarize borrowing_cost2`type' assets`type' ppe`type' revtq`type' percentp_Pcapxq3`type' percentp_Paqcq3`type' ///
					  debt`type' percentp_leverage`type', detail
	matrix mat1 = J(8,6,.) 
	matrix mat1[1., 1] = e(count)'
	matrix mat1[1., 2] = e(mean)'
	matrix mat1[1., 3] = e(sd)'
	matrix mat1[1., 4] = e(p25)'
	matrix mat1[1., 5] = e(p50)'
	matrix mat1[1., 6] = e(p75)'
	clear
	svmat mat1
	append using `mat1'
	mkmat *, matrix(mat_all)

	matrix rownames mat_all = "Borrowing Cost" "Assets" "Property, Plant, and Equipment" ///
                         "Revenue" "Capital Expenditure" "Acquisitions Expenditure" ///
                         "Debt" "Leverage" "MP shock"
				
	esttab matrix(mat_all, fmt(%16.0fc %16.2fc %16.2fc %16.2fc %16.2fc %16.2fc)) using "${output_tab}\maindraft\table4_sum_table_vars.tex", nomtitles  collabels("N" "Mean" "SD" "p25" "p50" "p75") /*rename(r1 "Borrowing Cost" r2 "Assets" r3 `" "Property, Plants, and Equipment" "' */ ///
	/* r4 "Revenue" r5 "Capital Expenditure" r6 "Acquisitions Expenditure" r7 "Debt" r8 "Leverage" r9 "MP shock") */ ///
	title("Summary Statistics of Main Variables\label{tab:sumvarstats}") fragment ///
	prehead(`"\centering"' `"\renewcommand{\arraystretch}{1.2}"' `"\begin{tabular}{l*{6}{c}} \\ \hline\hline"') ///
	postfoot(`"\hline \hline"' `"\end{tabular}"' ) replace nonotes

	
*(2) Response of average borrowing cost to monetary policy shocks (w)
use "${procq}/estdata_update", clear	
	local collapsed_vars
	forv l = 0/10{
		local collapsed_vars `collapsed_vars' Lborrowing_cost2`l'_gk
	}
	// keep if inrange(year,1994,2019)
	
	fcollapse (mean) `collapsed_vars', by(quarter_d)
	merge 1:1 quarter_d using "${procq}/QuarterlyFOMC_24", keep(match master) nogen
	tsset quarter_d 
	
	local controls l(1/3).Lborrowing_cost20_gk l(1/3).mp_klms_U_gk
	disp "`controls'"

	cap matrix drop LPfill 
	matrix LPfill = J(12, 4, .)
	forv ahead = 0/10 {
		reghdfe Lborrowing_cost2`ahead'_gk mp_klms_U_gk ///
			`controls' if quarter_d != ., ///
			/*absorb(`FE')*/ noabsorb vce(cluster quarter_d)
		matrix LPfill[`ahead'+2, 1] = _b[mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 2] = _b[mp_klms_U_gk] + 1.96 * _se[mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 3] = _b[mp_klms_U_gk] - 1.96 * _se[mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 4] = `ahead'+1 // counter, so the "0 ahead" regression is plotted at "1"
	}
	matrix list LPfill
		mata:		A = st_matrix("LPfill")   // copy into Mata
		mata:		A[1,] = J(1, 4, 0)        // set first row (all columns) to zero
		mata:		st_matrix("LPfill", A)    // write result back to Stata

	svmat LPfill, names(beta)
	
	rename beta4 ahead 
	gen zero = 0 
	
	tw (line beta1 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta2 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta3 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line zero ahead, lcolor(black)), ///
	xtitle("") leg(off)	
	graph export "${output_fig}\maindraft\test_avg_borrowing_cost_gk_updated.pdf", replace

	
*(3) Regress Borrowing Cost on "X"  
use  "${procq}/estdata_update", clear
	gen EA=earnings/assets
	gen lnMV=log(market_value2)

	gen rating_flag2=1 if strpos(rating,"AAA")
	replace rating_flag2=2 if strpos(rating,"AA") & !strpos(rating,"AAA")
	replace rating_flag2=3 if strpos(rating,"A") & !strpos(rating,"AA")
	replace rating_flag2=4 if strpos(rating,"BBB")
	replace rating_flag2=5 if strpos(rating,"BB") & !strpos(rating,"BBB")
	replace rating_flag2=6 if strpos(rating,"B") & !strpos(rating,"BB")
	replace rating_flag2=7 if strpos(rating,"CCC")
	replace rating_flag2=8 if strpos(rating,"CC") & !strpos(rating,"CCC")
	replace rating_flag2=9 if strpos(rating,"C") & !strpos(rating,"CC")

	* Dividing PE by 100 to make coeff look nicer 
	replace PE = PE / 100
	*** Creating GK version of all variables 
	foreach var in leader_mcap lnMV leverage PE icr dd EA rating_flag2 {
		cap gen L1_`var' = L1.`var'
		cap gen `var'_gk = weight_currq * `var' + weight_lastq * L1_`var'
	}

	lab var leader_mcap "Leader"
	lab var lnMV "log Market val"
	lab var leverage "Leverage"
	lab var PE "P/E"
	lab var icr "ICR"
	lab var dd "Distance to Default"
	lab var EA "Earnings/assets"
	lab var rating_flag2 "S\&P Ratings"

	local type "_gk"
		preserve
		gen x=.
		eststo clear
		foreach i in leader_mcap lnMV leverage PE icr dd EA rating_flag2 {
		replace x=`i'`type'
			eststo: reghdfe borrowing_cost2`type' x, absorb(quarter_d) cluster(quarter_d id)
		}
		lab var x "X"
		esttab using "${output_tab}\maindraft\BC_none`type'_alt.tex", b(a2) se(a2) label nomtitles nonumbers mlabels(none) nocons se replace compress collabels(none) nocons s( N r2, label("N" "R2") fmt( %13.0gc 3)) substitute(\_ _)  star( * 0.1 ** 0.05 *** 0.01) fragment prehead(`"\centering"' `"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"' `"\setlength{\tabcolsep}{3pt}"' `"\renewcommand{\arraystretch}{1.2}"' `"\footnotesize"' `"\begin{tabular}{l*{8}{c}}"' `"\hline"' `"  &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)}         &\multicolumn{1}{c}{(6)}         &\multicolumn{1}{c}{(7)} &\multicolumn{1}{c}{(8)}         \\  &   \multicolumn{1}{c}{Leader}         &\multicolumn{1}{c}{Market}         & \multicolumn{1}{c}{Leverage}         &      \multicolumn{1}{c}{P/E}         &      \multicolumn{1}{c}{ICR}  & \multicolumn{1}{c}{Distance to}  &\multicolumn{1}{c}{Earnings /} & \multicolumn{1}{c}{S\&P} \\  &   \multicolumn{1}{c}{}         &\multicolumn{1}{c}{Value}         & \multicolumn{1}{c}{}         &      \multicolumn{1}{c}{}         &      \multicolumn{1}{c}{}  & \multicolumn{1}{c}{Default}  &\multicolumn{1}{c}{Assets} & \multicolumn{1}{c}{Ratings} \\"' "`& & val & & & & default & Assets & Rating \\'") /*postfoot(`"\hline \hline"' `"\multicolumn{9}{l}{\footnotesize Standard errors in parentheses}\\"' `"\multicolumn{9}{l}{\footnotesize \sym{*} \(p<0.1\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)}\\"' `"\end{tabular}"')*/ postfoot(`"\hline \hline"' `"\end{tabular}"')
		restore




// E. COMPUSTAT IRFS/NEWS ROBUSTNESS

*(1) LP for all variables. 	
use "$proc_analysis/estdata_update_ptilec.dta", clear 

/*gen FFR_bar =  4.155963 // pre- period
replace FFR_bar = 0.0582192 if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021) // 0.0582192
replace FFR_bar = 2.615385 if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022) // 2.615385*/ 
	
	*Save the baseline version. 
	/* ----- LEADER AND RATE SETTINGS - RESET BLOCK ----- */
	cap drop leader5
// 	gen leader5 = (ptile_consis >= 0.95) // USE PTILE CONSIS */
	gen leader5 = (ptile_consis_ind >= 0.95) // USE PTILE CONSIS INDUSTRY */
	
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
// 	replace triple_mp_klms_U_gk = c.l.FFR_bar#c.mp_klms_U_gk#c.leader5 // USE FFR_bar
// 	replace Lileader = l.FFR_bar*leader5 // USE FFR_bar */
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leader5 // Using qtly FFR
	replace Lileader = l.target*leader5 // Using qtly FFFR
	replace leader_mcap = leader5 //
	/* ------------------------------------------------- */
	
local namelist `" "Borrowing Cost" "Assets" "Revenue" "Property, Plant, and Equipment" "Capital Expenditure" "Acquisitions" "Debt" "Leverage" "'
	local counter 0 
foreach yvar in Lborrowing_cost2 Llog_assets Llogrev Llog_ppe Pcapxq Paqcq Llog_debt Lleverage {
	local counter = `counter' + 1
	local name : word `counter' of `namelist'
	disp "`name'"

	*controls 
	local controls l(1/3).`yvar'0_gk 
	local controls `controls' l(1/3).double_mp_klms_U_gk l(1/3).triple_mp_klms_U_gk
	local controls `controls' l(1/3).Lileader l(1/3).leader_mcap // 
	disp "`controls'"

	cap matrix drop LPfill 
	matrix LPfill = J(12, 7, .)
	forv ahead = 0/10 {
		reghdfe `yvar'`ahead'_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
		matrix LPfill[`ahead'+2, 1] = _b[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 2] = _b[double_mp_klms_U_gk] + 1.96 * _se[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 3] = _b[double_mp_klms_U_gk] - 1.96 * _se[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 4] = _b[triple_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 5] = _b[triple_mp_klms_U_gk] + 1.96 * _se[triple_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 6] = _b[triple_mp_klms_U_gk] - 1.96 * _se[triple_mp_klms_U_gk]	
		matrix LPfill[`ahead'+2, 7] = `ahead'+1 // counter, so the "0 ahead" regression is plotted at "1"
	}
	matrix list LPfill
		mata:		A = st_matrix("LPfill")   // copy into Mata
		mata:		A[1,] = J(1, 7, 0)        // set first row (all columns) to zero
		mata:		st_matrix("LPfill", A)    // write result back to Stata

	cap drop beta* 
	cap drop ahead zero 
	svmat LPfill, names(beta)
	
	rename beta7 ahead 
	gen zero = 0 
	tw (line beta1 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta2 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta3 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line zero ahead, lcolor(black)), ///
	ytitle("{&beta}{subscript:ZLB}", size(large)) xtitle("") name(bzlb, replace) leg(off)
	
	tw (line beta4 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta5 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta6 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line zero ahead, lcolor(black)), ///
	ytitle("{&beta}{subscript:{&Delta}}", size(large)) xtitle("") name(bdelta, replace) leg(off)
	
	graph combine bzlb bdelta, rows(1) xsize(10) ysize(5) title("`name'", size(small)) name(`yvar'_2LP, replace)
	graph export "${output_fig}\maindraft\IRFs\samHFconsis_`yvar'_IRF_`graphname'.pdf", replace 
	
	****SAVE BZLB, BDELTA // for showing in the "robustness" checks in appendix 
	gen coeff_zlb_`yvar' = beta1 
	gen coeff_delta_`yvar' = beta4
}
	
	graph combine ///
	Lborrowing_cost2_2LP Llog_assets_2LP Llogrev_2LP Llog_ppe_2LP Pcapxq_2LP ///
	Paqcq_2LP Llog_debt_2LP Lleverage_2LP, ///
    rows(4) cols(2) imargin(0 0 0 0) graphregion(margin(zero))
	graph export "${output_fig}\maindraft\all8_IRFs_baseline.pdf", replace	

	// for showing in the "robustness" checks in appendix 
	preserve 	
	keep ahead coeff_zlb* coeff_delta*
	gen line_id = _n 
	save "$proc_analysis/LP_baseline_coeffs.dta", replace 
	restore 		
	use "$proc_analysis/LP_baseline_coeffs.dta", clear // to look at coefficients. ahead = h = 9 is 8 quarters ahead. 


*(2) Figure for Macro news
local type "_gk"
	
	* Fixing just MP type
	local type_mp `type'
	if "`type'" == "_gk_filtered"{
	local type_mp _gk_filtered
	local type _gk
	}
	
use "$proc_analysis/estdata_update_ptilec.dta", clear 
local lag=3
local h=7 // this is correct 

	/* ----- LEADER AND RATE SETTINGS - RESET BLOCK ----- */
	cap drop leader5
// 	gen leader5 = (ptile_consis >= 0.95) // USE PTILE CONSIS */
	gen leader5 = (ptile_consis_ind >= 0.95) // USE PTILE CONSIS INDUSTRY */
	
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
// 	replace triple_mp_klms_U_gk = c.l.FFR_bar#c.mp_klms_U_gk#c.leader5 // USE FFR_bar
// 	replace Lileader = l.FFR_bar*leader5 // USE FFR_bar */
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leader5 // Using qtly FFR
	replace Lileader = l.target*leader5 // Using qtly FFFR
	replace leader_mcap = leader5 //
	/* ------------------------------------------------- */
	
*remake leadertime, tripletime, double_`spec', triple_`spec'	
replace leadertime=c.leader_mcap#c.time_trend 
replace tripletime_mp_klms_U`type_mp' =c.time_trend#c.l.target#c.leader_mcap //ADDED for secular time test

foreach spec in lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1_10_fomc {
	replace double_`spec' = c.leader_mcap#c.`spec'
	replace triple_`spec' = c.l.target#c.`spec'#c.leader_mcap
}

*matrix for coefficients
mat Beta_1s=J(8,8,.)
mat Beta_2s=J(8,8,.)

local s mp_klms_U`type_mp'
***** Getting Coefs
		local mod=0
foreach spec in lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1_10_fomc time_trend regular {
		local mod=`mod'+1
		eststo clear
		local ynum=0
		*RUN FOR ALL COLUMNS
		foreach lhs in Lborrowing_cost2 Llog_assets Llog_ppe Llogrev Pcapxq Paqcq Llog_debt Lleverage{
		local ynum=`ynum' + 1
		local s mp_klms_U`type_mp'
		if "`spec'" == "regular"{
		local controls 
		}
		else if "`spec'" != "time_trend"{
		local controls l(0/`lag').double_`spec' l(0/`lag').triple_`spec'
		} 
		else{
		local controls l(0/`lag').leadertime l(0/`lag').tripletime_`s'
		}
	
		*Define controls
		local controls `controls' l(1/`lag').`lhs'0`type' l(1/`lag').double_`s' l(1/`lag').triple_`s' l(1/`lag').leader_mcap l(1/`lag').Lileader
		local X `lhs'`h'`type'
		reghdfe `X' double_`s' triple_`s' leader_mcap Lileader `controls' if quarter_d!=. , absorb(industrytime) vce(cluster quarter_d) 
		
		*save coeffs for plot
		if "`spec'" == "regular"{
		mat Beta_1s[`ynum',7]=_b[double_mp_klms_U`type_mp']
		mat Beta_1s[`ynum',8]=_se[double_mp_klms_U`type_mp']
		mat Beta_2s[`ynum',7]=_b[triple_mp_klms_U`type_mp']
		mat Beta_2s[`ynum',8]=_se[triple_mp_klms_U`type_mp']
		}
		else{
		mat Beta_1s[`ynum',`mod']=_b[double_mp_klms_U`type_mp']
		mat Beta_2s[`ynum',`mod']=_b[triple_mp_klms_U`type_mp']
		}
		}
}


******** Beta ZLB
clear
svmat Beta_1s 
rename (Beta_1s1 Beta_1s2 Beta_1s3 Beta_1s4 Beta_1s5 Beta_1s6) (lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1 time_trend)
rename (Beta_1s7 Beta_1s8) (baseline SE)

gen original_order = _n
gsort -original_order
gen model=sum(1)


foreach i in lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1 time_trend baseline SE{
	replace `i'=`i'*10 if model!=8
}
gen bl_l=baseline-1.96*SE
gen bl_u=baseline+1.96*SE

tw (scatter model baseline, mc(black) mfc(black) ms(C)) (rcap bl_u bl_l model, horizontal lc(black)) (scatter model lrgdp_surprise, mc(red)) (scatter model lag_bbk, mc(blue)) ///
(scatter model ret_sp500, mc(green)) (scatter model ret_pcommodity, mc(gold)) (scatter model pc1, mc(purple)) (scatter model time_trend, mc(brown)), legend(order(2 "Baseline 95% CI" 1 "Baseline" 3 "RGDP Surprise" 4 "BBK" 5 "SP500" 6 "Commodity Index" 7 "PC1" 8 "Time Trend") cols(3)) xline(0) name(doubleint, replace) ylabel(1 "Leverage" 2 "Debt" 3 "Acq Expenditure" 4 "Capt Expenditure" 5 "Revenue" 6 "PPE" 7 "Assets" 8 "Borrowing Cost" ,labsize(*1)) ytitle("Outcome variable (Y)", size(large)) xtitle("{&beta}{subscript:ZLB}", size(large)) title("") yscale(titlegap(*20)) xlabel(,labsize(*1.5))
graph export "${output_fig}\maindraft\news_controls_All_double`type'_alt.pdf", replace

******** Beta Delta
clear
svmat Beta_2s 
rename (Beta_2s1 Beta_2s2 Beta_2s3 Beta_2s4 Beta_2s5 Beta_2s6) (lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1 time_trend)
rename (Beta_2s7 Beta_2s8) (baseline SE)


gen original_order = _n
gsort -original_order
gen model=sum(1)

foreach i in lrgdp_surprise lag_bbk ret_sp500 ret_pcommodity pc1 time_trend baseline SE{
	replace `i'=`i'*10 if model!=8
}
gen bl_l=baseline-1.96*SE
gen bl_u=baseline+1.96*SE

tw (scatter model baseline, mc(black) mfc(black) ms(C)) (rcap bl_u bl_l model, horizontal lc(black)) (scatter model lrgdp_surprise, mc(red)) (scatter model lag_bbk, mc(blue)) ///
(scatter model ret_sp500, mc(green)) (scatter model ret_pcommodity, mc(gold)) (scatter model pc1, mc(purple)) (scatter model time_trend, mc(brown)), legend(order(2 "Baseline 95% CI" 1 "Baseline" 3 "RGDP Surprise" 4 "BBK" 5 "SP500" 6 "Commodity Index" 7 "pc1" 8 "Time Trend") cols(3)) xline(0) name(tripleint, replace) ylabel(1 "Leverage" 2 "Debt" 3 "Acq Expenditure" 4 "Capt Expenditure" 5 "Revenue" 6 "PPE" 7 "Assets" 8 "Borrowing Cost" ,labsize(*1)) ytitle("", size(large)) xtitle("{&beta}{subscript:{&Delta}}", size(large)) title("") yscale(titlegap(*20)) xlabel(,labsize(*1.5))
graph export "${output_fig}\misc\news_controls_All_triple`type'.pdf", replace

grc1leg doubleint tripleint, cols(2) legendfrom(doubleint)
graph display, xsize(7) ysize(4)
graph export "${output_fig}\maindraft\news_controls_All`type_mp'_alt.pdf", replace 



*(3) Controlling for firm-level attributes
local type "_gk"
local type_mp `type'

use "$proc_analysis/estdata_update_ptilec.dta", clear 

	/* ----- LEADER AND RATE SETTINGS - RESET BLOCK ----- */
	cap drop leader5
// 	gen leader5 = (ptile_consis >= 0.95) // USE PTILE CONSIS */
	gen leader5 = (ptile_consis_ind >= 0.95) // USE PTILE CONSIS INDUSTRY */
	
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
// 	replace triple_mp_klms_U_gk = c.l.FFR_bar#c.mp_klms_U_gk#c.leader5 // USE FFR_bar
// 	replace Lileader = l.FFR_bar*leader5 // USE FFR_bar */
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leader5 // Using qtly FFR
	replace Lileader = l.target*leader5 // Using qtly FFFR
	replace leader_mcap = leader5 //
	/* ------------------------------------------------- */

**generating the factor X controls
foreach c in b_mkt icr BM PE dd leverage{
	foreach i in mp_klms_U`type_mp'{
		gen `c'_double_`i'=c.`c'#c.`i'
		gen `c'_triple_`i'=c.l.target#c.`i'#c.`c'
	}
	gen `c'_Lileader=l.target*`c'
}

local lag=3
local h = 7

// change coeffs
lab var Lborrowing_cost27`type' "BC"
lab var Llog_debt7`type' "Debt"
lab var Lleverage7`type' "Leverage"
lab var Llog_assets7`type' "Assets"
lab var Llog_ppe7`type' "PPE"
lab var Paqcq7`type' "Acq"
lab var Pcapxq7`type' "CAPX"

tokenize `"`c(ALPHA)'"'

local b_mktname "Market Beta"
local icrname "interest coverage ratio"
local BMname "Book/Market"
local PEname "Price/Earnings"
local leveragename "Leverage"
local ddname "Distance to Default"

local mod=0

*matrix for coefficients
// mat Beta_1s=J(8,8,.)
// mat Beta_2s=J(8,8,.)
mat Beta_1s=J(8,7,.)
mat Beta_2s=J(8,7,.)



foreach c in b_mkt icr BM /*PE*/ leverage dd {
		local mod=`mod'+1
		eststo clear
		local ynum=0
		*RUN FOR ALL COLUMNS
		foreach lhs in Lborrowing_cost2 Llog_assets Llog_ppe Llogrev Pcapxq Paqcq Llog_debt Lleverage {
			local ynum=`ynum'+1
			*Define controlz
			local controls l(1/`lag').`lhs'0`type' l(1/`lag').double_mp_klms_U`type_mp' l(1/`lag').triple_mp_klms_U`type_mp' l(1/`lag').leader_mcap l(1/`lag').Lileader
			display "`controls'"
			local X `lhs'`h'`type'
				
			*RUN regressions
			eststo: reghdfe `X' double_mp_klms_U`type_mp' triple_mp_klms_U`type_mp' leader_mcap Lileader l(0/`lag').`c'_double_mp_klms_U`type_mp' l(0/`lag').`c'_triple_mp_klms_U`type_mp' l(0/`lag').`c' l(0/`lag').`c'_Lileader `controls' , absorb(industrytime) vce(cluster quarter_d) 
			*save coeffs for plot
			mat Beta_1s[`ynum',`mod']=_b[double_mp_klms_U`type_mp']
			mat Beta_2s[`ynum',`mod']=_b[triple_mp_klms_U`type_mp']
				
		}	
}

local ynum=0
foreach lhs in Lborrowing_cost2 Llog_assets Llog_ppe Llogrev Pcapxq Paqcq Llog_debt Lleverage{
		local ynum=`ynum'+1
		*Define controlz
		local controls l(1/`lag').`lhs'0`type' l(1/`lag').double_mp_klms_U`type_mp' l(1/`lag').triple_mp_klms_U`type_mp' l(1/`lag').leader_mcap l(1/`lag').Lileader

		local X `lhs'`h'`type'
		
		*RUN regressions
		reghdfe `X' double_mp_klms_U`type_mp' triple_mp_klms_U`type_mp' leader_mcap Lileader `controls' , absorb(industrytime) vce(cluster quarter_d) 
// 		mat Beta_1s[`ynum',7]=_b[double_mp_klms_U`type_mp']
// 		mat Beta_1s[`ynum',8]=_se[double_mp_klms_U`type_mp']
// 		mat Beta_2s[`ynum',7]=_b[triple_mp_klms_U`type_mp']
// 		mat Beta_2s[`ynum',8]=_se[triple_mp_klms_U`type_mp']
		mat Beta_1s[`ynum',6]=_b[double_mp_klms_U`type_mp']
		mat Beta_1s[`ynum',7]=_se[double_mp_klms_U`type_mp']
		mat Beta_2s[`ynum',6]=_b[triple_mp_klms_U`type_mp']
		mat Beta_2s[`ynum',7]=_se[triple_mp_klms_U`type_mp']
}
clear
svmat Beta_1s 
// rename (Beta_1s1 Beta_1s2 Beta_1s3 Beta_1s4 Beta_1s5 Beta_1s6) (b_mkt icr BM PE leverage dd)
// rename (Beta_1s7 Beta_1s8) (baseline SE)
rename (Beta_1s1 Beta_1s2 Beta_1s3 Beta_1s4 Beta_1s5) (b_mkt icr BM leverage dd)
rename (Beta_1s6 Beta_1s7) (baseline SE)

gen original_order = _n
gsort -original_order
gen model=sum(1)

foreach i in b_mkt icr BM /*PE*/ leverage dd baseline SE{
	replace `i'=`i'*10 if model!=8
}
gen bl_l=baseline-1.96*SE
gen bl_u=baseline+1.96*SE

tw (scatter model baseline, mc(black) mfc(black) ms(C)) (rcap bl_u bl_l model, horizontal lc(black)) (scatter model b_mkt, mc(red)) (scatter model BM, mc(green) msymbol(X) msize(large)) (scatter model leverage, mc(purple) msymbol(Oh)) (scatter model icr, mc(blue) msymbol(triangle)) /*(scatter model PE, mc(gold))*/, legend(order(2 "Baseline 95% CI" 1 "Baseline" 3 "Market Beta" 4 "Book/Market" 5 "Leverage" 6 "Interest Coverage Ratio" /*7 "P/E"*/) cols(3)) xline(0) name(doubleint, replace) ylabel(1 "Leverage" 2 "Debt" 3 "Acq Expenditure" 4 "Capt Expenditure" 5 "Revenue" 6 "PPE" 7 "Assets" 8 "Borrowing Cost" ,labsize(*1)) ytitle("Outcome variable (Y)", size(large)) xtitle("{&beta}{subscript:ZLB}", size(large)) title("") yscale(titlegap(*20)) xlabel(,labsize(*1.5))
graph export "${output_fig}\misc\controls_All_double`type'_alt.pdf", replace

clear
svmat Beta_2s 
// rename (Beta_2s1 Beta_2s2 Beta_2s3 Beta_2s4 Beta_2s5 Beta_2s6) (b_mkt icr BM PE leverage dd)
// rename (Beta_2s7 Beta_2s8) (baseline SE)
rename (Beta_2s1 Beta_2s2 Beta_2s3 Beta_2s4 Beta_2s5) (b_mkt icr BM /*PE*/ leverage dd)
rename (Beta_2s6 Beta_2s7) (baseline SE)

gen original_order = _n
gsort -original_order
gen model=sum(1)

foreach i in b_mkt icr BM /*PE*/ leverage dd baseline SE{
	replace `i'=10*`i' if model!=8
}
gen bl_l=baseline-1.96*SE
gen bl_u=baseline+1.96*SE


tw (scatter model baseline, mc(black) mfc(black) ms(C)) (rcap bl_u bl_l model, horizontal lc(black)) (scatter model b_mkt, mc(red)) (scatter model BM, mc(green) msymbol(X) msize(large)) (scatter model leverage, mc(purple) msymbol(Oh)) (scatter model icr, mc(blue) msymbol(triangle)) /*(scatter model PE, mc(gold))*/, legend(order(2 "Baseline 95% CI" 1 "Baseline" 3 "Market Beta" 4 "Book/Market" 5 "Leverage" 6 "Interest Coverage Ratio" /*6 "P/E"*/) cols(3)) xline(0) name(tripleint, replace) ylabel(1 "Leverage" 2 "Debt" 3 "Acq Expenditure" 4 "Capt Expenditure" 5 "Revenue" 6 "PPE" 7 "Assets" 8 "Borrowing Cost" ,labsize(*1)) ytitle("Outcome variable") ytitle("", size(large)) xtitle("{&beta}{subscript:{&Delta}}", size(large)) title("") yscale(titlegap(*20)) xlabel(,labsize(*1.5))
graph export "${output_fig}\misc\controls_All_triple`type'_alt.pdf", replace

grc1leg doubleint tripleint, cols(2) legendfrom(doubleint)
graph display, xsize(7) ysize(4)
graph export "${output_fig}\maindraft\controls_All`type_mp'_alt.pdf", replace 		





// F. APPENDIX 


*(1) Placebo Duration 
import delimited "$folder/bootstrap_calculation/bootstrap_placebo.csv", clear
su estimates if type == "Regular"
local reg_baseline  = r(mean)
di "`reg_baseline'"
drop if type == "Regular"

* Creating auxiliary files for histogram
local x_pos = `reg_baseline' + 0.025
local scale xscale(range(-0.91 0.3)) xlabel(-.9(.1).3) yscale(range(0 8.5)) ylabel(0(1)8.5) ///
text(7.9 -0.745 "Baseline Estimate", place(e) size(small)) ///
text(7.9 -.13 "Placebo FOMC days", place(e) size(small)) text(7.5 -0.05 "Estimates", place(e) size(small)) legend(off)
* Creating variables just for the arrow
gen x1 = `reg_baseline'
gen y1 = 7.6
gen x2 = `reg_baseline'
gen y2 = 0

* Creating histogram
tw (hist estimates, percent lcolor(gray) fcolor(gray*0.25)) (pcarrow y1 x1 y2 x2 if _n == 1, lcolor(red) mcolor(red)), xtitle("`=ustrunescape("\u03B2\u0302")'") ytitle("Density") title("") ///
`scale'  plotregion(margin(0))
graph export "${output_fig}\appendix\placebo_duration.pdf", replace


*(2) LPs Robustness Figures
cap program drop LP8x 
program define LP8x 
args graphname FE

local namelist `" "Borrowing Cost" "Assets" "Revenue" "Property, Plant, and Equipment" "Capital Expenditure" "Acquisitions" "Debt" "Leverage" "'
	local counter 0 
foreach yvar in Lborrowing_cost2 Llog_assets Llogrev Llog_ppe Pcapxq Paqcq Llog_debt Lleverage {
	local counter = `counter' + 1
	local name : word `counter' of `namelist'
	disp "`name'"

	*grab baseline coeffs to plot together 
	preserve 
	use "$proc_analysis/LP_baseline_coeffs.dta", clear
	keep line_id coeff_zlb_`yvar' coeff_delta_`yvar' 
	tempfile baseline_betas
	save `baseline_betas', replace 
	restore 
	
	*controls
	xtset id quarter_d
	local controls l(1/3).`yvar'0_gk 
	local controls `controls' l(1/3).double_mp_klms_U_gk l(1/3).triple_mp_klms_U_gk
	local controls `controls' l(1/3).Lileader l(1/3).leader_mcap // 
	disp "`controls'"

	cap matrix drop LPfill 
	matrix LPfill = J(12, 7, .)
	forv ahead = 0/10 {
		reghdfe `yvar'`ahead'_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(`FE') vce(cluster quarter_d)
		matrix LPfill[`ahead'+2, 1] = _b[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 2] = _b[double_mp_klms_U_gk] + 1.96 * _se[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 3] = _b[double_mp_klms_U_gk] - 1.96 * _se[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 4] = _b[triple_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 5] = _b[triple_mp_klms_U_gk] + 1.96 * _se[triple_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 6] = _b[triple_mp_klms_U_gk] - 1.96 * _se[triple_mp_klms_U_gk]	
		matrix LPfill[`ahead'+2, 7] = `ahead'+1 // counter, so the "0 ahead" regression is plotted at "1"
	}
	matrix list LPfill
		mata:		A = st_matrix("LPfill")   // copy into Mata
		mata:		A[1,] = J(1, 7, 0)        // set first row (all columns) to zero
		mata:		st_matrix("LPfill", A)    // write result back to Stata

	svmat LPfill, names(beta)
	
	rename beta7 ahead 
	gen zero = 0 
	
	gen line_id = _n 
	merge 1:1 line_id using `baseline_betas', keep(master matched) nogen 
	
	tw (line beta1 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta2 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta3 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line coeff_zlb_`yvar' ahead, lcolor(orange) lpattern(solid) lwidth(thin)) ///
	(line zero ahead, lcolor(black)), ///
	ytitle("{&beta}{subscript:ZLB}", size(large)) xtitle("") name(bzlb, replace) leg(off)
	
	tw (line beta4 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta5 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta6 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line coeff_delta_`yvar' ahead, lcolor(orange) lpattern(solid) lwidth(thin)) ///	
	(line zero ahead, lcolor(black)), ///
	ytitle("{&beta}{subscript:{&Delta}}", size(large)) xtitle("") name(bdelta, replace) leg(off)
	
	graph combine bzlb bdelta, rows(1) xsize(10) ysize(5) title("`name'", size(small)) name(`yvar'_2LP, replace)
	graph export "${output_fig}\appendix\IRFs\samHFconsis_`yvar'_IRF_`graphname'.pdf", replace 
	
	*cleanup 
	drop beta* 
	drop ahead 
	drop zero 
	drop coeff_zlb* coeff_delta*	
	drop line_id
}
	
	graph combine ///
	Lborrowing_cost2_2LP Llog_assets_2LP Llogrev_2LP Llog_ppe_2LP Pcapxq_2LP ///
	Paqcq_2LP Llog_debt_2LP Lleverage_2LP, ///
    rows(4) cols(2) imargin(0 0 0 0) graphregion(margin(zero))
	graph export "${output_fig}\appendix\appendix_all8_IRFs_`graphname'.pdf", replace
end 

*Load data
use "$proch/FFtarget", clear // import fred FEDFUNDS, clear 
gen year = yofd(daten)
	sum target if year >= 1994 & year <= 2006, meanonly 
	local premean = `r(mean)'
	sum target if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021), meanonly  // 0.0582192
	local ZLBmean = `r(mean)'	
	sum target if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024) , meanonly  // 2.615385
	local nonZLBmean = `r(mean)'	
	di "`premean', `ZLBmean', `nonZLBmean'"

use "$proc_analysis/estdata_update_ptilec.dta", clear 
egen mtarget = mean(target), by(year) 
gen FFR_bar = `premean' /**/ // pre- period
replace FFR_bar = `ZLBmean' /**/ if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021) 
replace FFR_bar = `nonZLBmean' /**/ if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022) 
	/* ----- LEADER AND RATE SETTINGS - RESET BLOCK ----- */
	xtset id quarter_d	
	cap drop leader5
// 	gen leader5 = (ptile_consis >= 0.95) // USE PTILE CONSIS */
	gen leader5 = (ptile_consis_ind >= 0.95) // USE PTILE CONSIS INDUSTRY */
	
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
	replace triple_mp_klms_U_gk = c.l.FFR_bar#c.mp_klms_U_gk#c.leader5 // USE FFR_bar
	replace Lileader = l.FFR_bar*leader5 // USE FFR_bar */
// 	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leader5 // Using qtly FFR
// 	replace Lileader = l.target*leader5 // Using qtly FFFR
	replace leader_mcap = leader5 //
	/* ------------------------------------------------- */

LP8x "IND5_FFRBAR" industrytime


*(3) LP Robustness figures: wide window ^ use the above code 

*Load data
use "$proc_analysis/estdata_update_ptilec.dta", clear 
	/* ----- LEADER AND RATE SETTINGS - RESET BLOCK ----- */
	xtset id quarter_d	
	cap drop leader5
// 	gen leader5 = (ptile_consis >= 0.95) // USE PTILE CONSIS */
	gen leader5 = (ptile_consis_ind >= 0.95) // USE PTILE CONSIS INDUSTRY */
	
	*New: replace mp_klms_U_gk with mp_klms_U1h_gk, the equivalent 1h shock
	replace mp_klms_U_gk = mp_klms_U1h_gk // 
	
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
// 	replace triple_mp_klms_U_gk = c.l.FFR_bar#c.mp_klms_U_gk#c.leader5 // USE FFR_bar
// 	replace Lileader = l.FFR_bar*leader5 // USE FFR_bar */
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leader5 // Using qtly FFR
	replace Lileader = l.target*leader5 // Using qtly FFFR
	replace leader_mcap = leader5 //
	/* ------------------------------------------------- */

LP8x "IND5_WIDESHOCK" industrytime






*(4) Leader defns figure 
****LP robustness to alternate definitions. 
use "$proc_analysis/estdata_update_ptilec.dta", clear 
egen mtarget = mean(target), by(year) 
/*gen FFR_bar =  4.155963 // pre- period
replace FFR_bar = 0.0582192 if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021) // 0.0582192
replace FFR_bar = 2.615385 if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022) // 2.615385 */
	
matrix rob8_bzlb = J(8, 11, .)
matrix rob8_bdelta = J(8, 11, .)

	local counter 0 	
foreach yvar in Lleverage Llog_debt Paqcq Pcapxq Llogrev Llog_ppe Llog_assets Lborrowing_cost2 {
	local counter = `counter' + 1
	
	local controls l(1/3).`yvar'0_gk 
	local controls `controls' l(1/3).double_mp_klms_U_gk l(1/3).triple_mp_klms_U_gk
	local controls `controls' l(1/3).Lileader l(1/3).leader_mcap // 
	disp "`controls'"
	
	*Define Baseline 
	cap drop leaderdef
	gen leaderdef = (ptile_consis_ind >= 0.95) 
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 	
	
	*beta ZLB 
	matrix rob8_bzlb[`counter', 1] = `counter'
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 2] = _b[double_mp_klms_U_gk]	
	matrix rob8_bzlb[`counter', 3] = _b[double_mp_klms_U_gk]	- 1.96 * _se[double_mp_klms_U_gk]
	matrix rob8_bzlb[`counter', 4] = _b[double_mp_klms_U_gk]	+ 1.96 * _se[double_mp_klms_U_gk]
	
	*beta Delta 
	matrix rob8_bdelta[`counter', 1] = `counter'
	matrix rob8_bdelta[`counter', 2] = _b[triple_mp_klms_U_gk]	
	matrix rob8_bdelta[`counter', 3] = _b[triple_mp_klms_U_gk]	- 1.96 * _se[triple_mp_klms_U_gk]
	matrix rob8_bdelta[`counter', 4] = _b[triple_mp_klms_U_gk]	+ 1.96 * _se[triple_mp_klms_U_gk]
	
	**** Robustness ****
	*leader top5 by ptile_consis -- non-industry
	cap drop leaderdef
	gen leaderdef = (ptile_consis >= 0.95) 
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 5] = _b[double_mp_klms_U_gk]	
	matrix rob8_bdelta[`counter', 5] = _b[triple_mp_klms_U_gk]		
	
	*leader top5 by indptile -- time varying industry percentile 
	cap drop leaderdef
	gen leaderdef = (indptile >= 0.95) // note that this will be time-varying too
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 6] = _b[double_mp_klms_U_gk]	
	matrix rob8_bdelta[`counter', 6] = _b[triple_mp_klms_U_gk]			
	
	*top four firms by ind (consis ver) 
	cap drop leaderdef
	gen leaderdef = top4 
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 7] = _b[double_mp_klms_U_gk]	
	matrix rob8_bdelta[`counter', 7] = _b[triple_mp_klms_U_gk]		
	
	*leader top10 by ptile_consis_ind
	cap drop leaderdef
	gen leaderdef = (ptile_consis_ind >= 0.90) 
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 8] = _b[double_mp_klms_U_gk]
	matrix rob8_bdelta[`counter', 8] = _b[triple_mp_klms_U_gk]		
	
	* ptile_consis_ind directly -- continuous measure, not indicator 
	cap drop leaderdef
	gen leaderdef = ptile_consis_ind 
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 9] = _b[double_mp_klms_U_gk]
	matrix rob8_bdelta[`counter', 9] = _b[triple_mp_klms_U_gk]			
	
	* top5 by consis sales 
	cap drop leaderdef
	gen leaderdef = (ptile_consis_indSAL >= 0.95)  
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 10] = _b[double_mp_klms_U_gk]
	matrix rob8_bdelta[`counter', 10] = _b[triple_mp_klms_U_gk]			
	
	* top5 by ptile consis SIC  // change FEs to sicindustrytime
	cap drop leaderdef
	gen leaderdef = (ptile_consis_indSIC >= 0.95)  
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leaderdef
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leaderdef 
	replace Lileader = l.target*leaderdef 
	replace leader_mcap = leaderdef 
	reghdfe `yvar'8_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(sicindustrytime) vce(cluster quarter_d)
	matrix rob8_bzlb[`counter', 11] = _b[double_mp_klms_U_gk]
	matrix rob8_bdelta[`counter', 11] = _b[triple_mp_klms_U_gk]				
}

// will graph betazlb on model, betadelta on model
cap drop betazlb* 
cap drop betadelta* 
cap drop bzlb* 
cap drop bdelta*
cap drop model

svmat rob8_bzlb, names(betazlb)
svmat rob8_bdelta, names(betadelta)
rename betazlb1 model 
*rescale what will become borrowingcost coeffs and baseline SEs
forv i = 2/11 {
	replace betazlb`i' = betazlb`i' * 0.1 if model == 8 
	replace betadelta`i' = betadelta`i' * 0.1 if model == 8 
}

rename (betazlb2 betazlb3 betazlb4) (betazlb betazlb_lb betazlb_ub)
rename (betazlb5 betazlb6 betazlb7 betazlb8 betazlb9 betazlb10 betazlb11) ///
	(bzlb_nonind bzlb_timvar bzlb_topfour bzlb_t10 bzlb_continuous bzlb_sales bzlb_sic)

rename (betadelta2 betadelta3 betadelta4) (betadelta betadelta_lb betadelta_ub) 
rename (betadelta5 betadelta6 betadelta7 betadelta8 betadelta9 betadelta10 betadelta11) ///
	(bdelta_nonind bdelta_timvar bdelta_topfour bdelta_t10 bdelta_continuous bdelta_sales bdelta_sic)
	
*Graphing -- TRY TO GET ORANGE CROSS ON TOP 
tw ///
    (scatter model betazlb, mc(black) mfc(black) ms(C)) ///
	(rcap betazlb_lb betazlb_ub model, horizontal lc(black)) ///	
	(scatter model bzlb_nonind, mc(yellow)) ///
	(scatter model bzlb_timvar, mc(red)) ///
	(scatter model bzlb_topfour, mc(blue)) ///
	(scatter model bzlb_t10, mc(green)) ///
	(scatter model bzlb_continuous, mc(gold)) ///
	(scatter model bzlb_sales, mc(orange)) /// 	
	(scatter model bzlb_sic, mc(purple)),   ///
    name(doubleint, replace)                                    ///
    ylabel(1 "Leverage"   2 "Debt"         3 "Acq Expenditure"  ///
           4 "Capt Expenditure" 5 "Revenue"     6 "PPE"          ///
           7 "Assets"      8 "Borrowing Cost",                   ///
           labsize(*1))                                          ///
    ytitle("Outcome variable (Y)", size(large))                 ///
    xtitle("{&beta}{subscript:ZLB}", size(large))          ///
    title("")                                                   ///
    yscale(titlegap(*20))                                       ///
	xline(0) ///
	legend(order(1 "Baseline" 2 "Baseline 95% CI" 3 "Non-Industry" 4 "Time-Varying" 5 "Top Four" 6 "Top 10%" 7 "Continuous" 8 "Sales Top 5%" 9 "SIC Top 5%" )) ///
    xlabel(, labsize(*1.5))
	
tw ///
    (scatter model betadelta, mc(black) mfc(black) ms(C)) ///
	(rcap betadelta_lb betadelta_ub model, horizontal lc(black)) ///	
	(scatter model bdelta_nonind, mc(yellow)) ///
	(scatter model bdelta_timvar, mc(red)) ///
	(scatter model bdelta_topfour, mc(blue)) ///
	(scatter model bdelta_t10, mc(green)) ///
	(scatter model bdelta_continuous, mc(gold)) ///
	(scatter model bdelta_sales, mc(orange)) /// 	
	(scatter model bdelta_sic, mc(purple)),   ///
    name(tripleint, replace)                                    ///
    ylabel(1 "Leverage"   2 "Debt"         3 "Acq Expenditure"  ///
           4 "Capt Expenditure" 5 "Revenue"     6 "PPE"          ///
           7 "Assets"      8 "Borrowing Cost",                   ///
           labsize(*1))                                          ///
    ytitle("")                 ///
    xtitle("{&beta}{subscript:{&Delta}}", size(large))          ///
    title("")                                                   ///
    yscale(titlegap(*20))                                       ///
	xline(0) ///
	leg(off) ///
    xlabel(, labsize(*1.5))	
	
grc1leg doubleint tripleint, cols(2) legendfrom(doubleint) xsize(7) ysize(4) imargin(0 0 0 0) graphregion(margin(zero))
graph export "${output_fig}\appendix\rob8ahead_all.pdf", replace 







*(5) LP (in levels version) for all variables. 	See data construction: the equivalent is "F`yvar'`ahead'_gk".
cap program drop LP8x_lvls_version
program define LP8x_lvls_version 
args graphname FE 

local namelist `" "Borrowing Cost" "Assets" "Revenue" "Debt" "Property, Plant, and Equipment" "Leverage" "'
	local counter 0 
foreach yvar in borrowing_cost2 log_assets logrev log_debt log_ppe leverage {
	local counter = `counter' + 1
	local name : word `counter' of `namelist'
	disp "`name'"

	*grab baseline coeffs to plot together 
	preserve 
	use "$proc_analysis/LP_baseline_coeffs.dta", clear
	keep line_id coeff_zlb_L`yvar' coeff_delta_L`yvar' 
	tempfile baseline_betas
	save `baseline_betas', replace 
	restore 
	
	*controls
	xtset id quarter_d
	local controls l(1/3).F`yvar'0_gk 
	local controls `controls' l(1/3).double_mp_klms_U_gk l(1/3).triple_mp_klms_U_gk
	local controls `controls' l(1/3).Lileader l(1/3).leader_mcap // 
	disp "`controls'"

	cap matrix drop LPfill 
	matrix LPfill = J(12, 7, .)
	forv ahead = 0/10 {
		reghdfe F`yvar'`ahead'_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(`FE') vce(cluster quarter_d)
		matrix LPfill[`ahead'+2, 1] = _b[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 2] = _b[double_mp_klms_U_gk] + 1.96 * _se[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 3] = _b[double_mp_klms_U_gk] - 1.96 * _se[double_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 4] = _b[triple_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 5] = _b[triple_mp_klms_U_gk] + 1.96 * _se[triple_mp_klms_U_gk]
		matrix LPfill[`ahead'+2, 6] = _b[triple_mp_klms_U_gk] - 1.96 * _se[triple_mp_klms_U_gk]	
		matrix LPfill[`ahead'+2, 7] = `ahead'+1 // counter, so the "0 ahead" regression is plotted at "1"
	}
	matrix list LPfill
		mata:		A = st_matrix("LPfill")   // copy into Mata
		mata:		A[1,] = J(1, 7, 0)        // set first row (all columns) to zero
		mata:		st_matrix("LPfill", A)    // write result back to Stata

	svmat LPfill, names(beta)
	
	rename beta7 ahead 
	gen zero = 0 
	
	gen line_id = _n 
	merge 1:1 line_id using `baseline_betas', keep(master matched) nogen 
	
	tw (line beta1 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta2 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta3 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line coeff_zlb_L`yvar' ahead, lcolor(orange) lpattern(solid) lwidth(thin)) ///
	(line zero ahead, lcolor(black)), ///
	ytitle("{&beta}{subscript:ZLB}", size(large)) xtitle("") name(bzlb, replace) leg(off)
	
	tw (line beta4 ahead, lcolor(edkblue) lpattern(solid) lwidth(thick)) ///
	(line beta5 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line beta6 ahead, lcolor(edkblue ) lpattern(dash) lwidth(thick)) ///
	(line coeff_delta_L`yvar' ahead, lcolor(orange) lpattern(solid) lwidth(thin)) ///	
	(line zero ahead, lcolor(black)), ///
	ytitle("{&beta}{subscript:{&Delta}}", size(large)) xtitle("") name(bdelta, replace) leg(off)
	
	graph combine bzlb bdelta, rows(1) xsize(10) ysize(5) title("`name'", size(small)) name(F`yvar'_2LP, replace)
	graph export "${output_fig}\appendix\IRFs\samHFconsis_`yvar'_IRF_`graphname'.pdf", replace 
	
	*cleanup 
	drop beta* 
	drop ahead 
	drop zero 
	drop coeff_zlb* coeff_delta*	
	drop line_id
}
	
	graph combine ///
	Fborrowing_cost2_2LP Flog_assets_2LP Flogrev_2LP ///
	Flog_debt_2LP Flog_ppe_2LP Fleverage_2LP, ///
    rows(3) cols(2) imargin(0 0 0 0) graphregion(margin(zero))
	graph export "${output_fig}\appendix\appendix_all8_IRFs_`graphname'_lvls.pdf", replace
end 

use "$proc_analysis/estdata_update_ptilec.dta", clear 
	
	*Save the baseline version. 
	/* ----- LEADER AND RATE SETTINGS - RESET BLOCK ----- */
	cap drop leader5
// 	gen leader5 = (ptile_consis >= 0.95) // USE PTILE CONSIS */
	gen leader5 = (ptile_consis_ind >= 0.95) // USE PTILE CONSIS INDUSTRY */
	
	replace double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
// 	replace triple_mp_klms_U_gk = c.l.FFR_bar#c.mp_klms_U_gk#c.leader5 // USE FFR_bar
// 	replace Lileader = l.FFR_bar*leader5 // USE FFR_bar */
	replace triple_mp_klms_U_gk = c.l.target#c.mp_klms_U_gk#c.leader5 // Using qtly FFR
	replace Lileader = l.target*leader5 // Using qtly FFFR
	replace leader_mcap = leader5 //
	/* ------------------------------------------------- */
LP8x_lvls_version "FFRbaseline" industrytime





*(6) Window length controls, robustness.
use "$proc_analysis/maintable_data", clear 	
	
	cap estimates drop * 
	cap eststo clear 	
	
	*Baseline main result
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	estadd local notes "Baseline"
	estadd local percentile_cutoff 
	
	*Window control
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_30min WLxSHOCK if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"	
	estadd local notes "Window Control"	

	/*--------------------------*/
	gen WLxPOST = window_shock_hf_30min * post 
	gen WLxFPTILE = window_shock_hf_30min * Fptile
	gen WLxTRIPLE = window_shock_hf_30min * mp_klmsFptilepost
	/*--------------------------*/	
	
	*Window control
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_30min WLxSHOCK WLxPOST if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	estadd local notes "Window Control"		
	
	*Window control
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_30min WLxSHOCK WLxPOST WLxFPTILE if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Window Control"		
	
	*Window control
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_30min WLxSHOCK WLxPOST WLxFPTILE WLxTRIPLE if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	estadd local notes "Window Control"		
	
	*90th percentile window length
	sum window_shock_hf_30min, d
	local p90 = r(p90)
	disp "90th percentile (it): `p90'"
	gen overp90 = window_shock_hf_30min > `p90'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p6
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90"	
	estadd local percentile_cutoff `p90'	
	
	esttab p* using "${output_tab}\appendix\DU_ZLBnonZLB_ptileconsis_WL907550.tex", label drop(_cons) se stats(N r2 FE notes, label("N" "R2" "FEs" "Notes" "WL Cutoff (min)") fmt(%9.0fc %9.3f)) replace ///
	order(mp_klms_U mp_klmspost post mp_klmsFptile mp_klmsFptilepost window_shock_hf_30min WLxSHOCK) ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	post "$\text{post}$"  ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
	window_shock_hf_30min "$\text{window}_{it}$" ///
	WLxSHOCK "$\text{window}_{it} * \omega_t$" ///
	WLxPOST "$\text{window}_{it} * \text{post}$" ///
	WLxFPTILE "$\text{window}_{it} * \bar{X}_i$" ///
	WLxTRIPLE "$\text{window}_{it} * (\omega_t * \bar{X}_i * \text{post}$)" ///	
    ) ///		
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 	nonotes	
	




*(7) Neutral rate table 

/*
ssc install erepost // if needed
*/
capture program drop KLMSalterations // Keelan
program define KLMSalterations, eclass
mat mc = e(b)
mat vc = e(V)
*get rownumbers of coefficients
local r = rownumb(vc, "double_")
local p = colnumb(vc, "triple_")
local q = rownumb(vc, "`1'")
*caluclate neutral rate and SE using delta method

local a=vc[`r',`r']
local b=vc[`p',`p']
local c=vc[`r', `p']

mat NR=-mc[1,`r']/mc[1,`p']
mat list NR

matrix sigma=(`a',`c' \ `c',`b')

mat delta_g=(-1/mc[1,`p'], mc[1,`r']/mc[1,`p']^2)
mat var_g=delta_g*sigma*delta_g'
di "Rate at which effect is zero="NR[1,1]
di "SE of neutral rate=" sqrt(var_g[1,1])

matrix mc[1,`q']=NR[1,1]
matrix vc[`q', `q']=var_g[1,1]
ereturn repost b=mc
ereturn repost V=vc

end

*Grab neutral rate from table 2 (FFRbar)
use "$proch/FFtarget", clear // import fred FEDFUNDS, clear 
gen year = yofd(daten)
	sum target if year >= 1994 & year <= 2006, meanonly 
	local premean = `r(mean)'
	sum target if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021), meanonly  // 0.0582192
	local ZLBmean = `r(mean)'	
	sum target if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024), meanonly  // 2.615385
	local nonZLBmean = `r(mean)'	
	di "`premean', `ZLBmean', `nonZLBmean'"
	
	use "$proc_analysis/maintable_data", clear 
	
	cap estimates drop * 
	cap eststo clear 	
	
	gen FFR_bar = `premean' /* */ // pre- period 
	replace FFR_bar = `ZLBmean' /* */ if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021) 
	replace FFR_bar = `nonZLBmean' /* */ if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024) 
 	
	replace mp_klmspost = mp_klms_U * FFR_bar 
	replace mp_klmsFptilepost = mp_klms_U * ptile_consis * FFR_bar 

	* COL 2 
	rename (mp_klms_U mp_klmsFptilepost mp_klmsFptile) (Lileader triple_HF double_HF) // for table formatting and  only 
	areg shock_hf_30min triple_HF double_HF mp_klmspost /**/ /*Fptilepost*/ /**/ Lileader FFR_bar if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	KLMSalterations Lileader // stores eta estimate in w_t's spot 
	local NR_HF = _b[Lileader]
	local seNR_HF = _se[Lileader]	
	disp "Neutral Rate:`NR_HF', SE of NR: `seNR_HF'"
	eststo e0
	sleep 2000
	

*SETTINGS [1] [2] [3] [4]
*[1] Horizons ahead 
local horizons_ahead 7 // "7 is h=8"
*[2] Dataset 
local dataset "proc_analysis/estdata_update_ptilec"  
local stripdataset = subinstr("`dataset'", "/", "_", .)
disp "`stripdataset'"

use "$`dataset'", clear
xtset id quarter_d 

*[3] Clustering 
gen nocluster = _n // clustering by _n is the same as vce(robust) 
local cluster quarter_d // nocluster // either nocluster, quarter_d, etc TEMP // =========================================

*[4] Any changes to the dataset (variable defns, etc)
replace leader_mcap = (ptile_consis_ind >= 0.95) /**/
xtset id quarter_d
/*----------*/
replace Lileader = leader_mcap * target 
replace double_mp_klms_U_gk = mp_klms_U_gk * leader_mcap
replace triple_mp_klms_U_gk = mp_klms_U_gk * leader_mcap * l.target

label var Lileader "$\hat{\eta}$"
label var Lborrowing_cost2`horizons_ahead'_gk "Borrowing Cost"
label var Llog_assets`horizons_ahead'_gk "Assets"
label var Llogrev`horizons_ahead'_gk "Revenue"
label var Llog_ppe`horizons_ahead'_gk "PPE"
label var Pcapxq`horizons_ahead'_gk "CAPX"
label var Paqcq`horizons_ahead'_gk "Acquisitions"
label var Llog_debt`horizons_ahead'_gk "Debt"
label var Lleverage`horizons_ahead'_gk "Leverage"
gen shock_hf_30min = 1 // for labelling
label var shock_hf_30min "$ R_{it}$"
tempfile nrdata 
save `nrdata'

*Panel A: NR by LHS variable 
local mod 0
// cap estimates drop * 
local mylist Lborrowing_cost2 Llog_assets Llogrev Llog_ppe Pcapxq Paqcq Llog_debt Lleverage
	foreach yvar of local mylist {
		local mod = `mod'+1
			
		local controls l(1/3).`yvar'0_gk 
		local controls `controls' l(1/3).double_mp_klms_U_gk l(1/3).triple_mp_klms_U_gk
		local controls `controls' l(1/3).Lileader l(1/3).leader_mcap 
		disp "`controls'"
		reghdfe `yvar'`horizons_ahead'_gk double_mp_klms_U_gk triple_mp_klms_U_gk ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)
			
		KLMSalterations Lileader // stores NR estimate into leader dummy's spot
		local NR_`yvar' = _b[Lileader]
		local seNR_`yvar' = _se[Lileader]
		
		disp "Neutral Rate:`NR_`yvar'', SE of NR: `seNR_`yvar''"
		eststo e`mod'
	}
local hdisp = `horizons_ahead' + 1	


esttab e* using "${output_tab}\appendix\test5_`stripdataset'`horizons_ahead'.tex", nocons se keep(Lileader) replace ///
    label b(a2) se(a2) s(N, label("N") fmt(%13.0gc)) nomtitles nonumbers mlabels(none) collabels(none) compress ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    posthead( ///
    `"\hline"'  `"\multicolumn{10}{c}{Estimates of the Neutral Rate}\\\hline"' ///
    `"  &\multicolumn{1}{c}{(1)} &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         &\multicolumn{1}{c}{(4)} &\multicolumn{1}{c}{(5)}         &\multicolumn{1}{c}{(6)}         &\multicolumn{1}{c}{(7)} &\multicolumn{1}{c}{(8)}  &\multicolumn{1}{c}{(9)}           \\"' ///
    `"  &   \multicolumn{1}{c}{$ R_{it}$}         &\multicolumn{1}{c}{Borrowing}         & \multicolumn{1}{c}{Assets}         &      \multicolumn{1}{c}{Revenue}         &      \multicolumn{1}{c}{PPE}  & \multicolumn{1}{c}{CAPX}  &\multicolumn{1}{c}{Acquisitions} & \multicolumn{1}{c}{Debt} & \multicolumn{1}{c}{Leverage} \\"' ///
    `"  &   \multicolumn{1}{c}{}         &\multicolumn{1}{c}{Cost}         & \multicolumn{1}{c}{}         &      \multicolumn{1}{c}{}         &      \multicolumn{1}{c}{}  & \multicolumn{1}{c}{}  &\multicolumn{1}{c}{} & \multicolumn{1}{c}{} \\"' ///
    `"\hline"' ///
    ) ///
    substitute(\_ _) nonotes
 
*(8) Main table but use industry Ptile
use "$proc_analysis/maintable_data", clear 	
	replace Fptile = ptile_consis_ind
	replace mp_klmsFptile = mp_klms_U * ptile_consis_ind
	replace mp_klmsFptilepost = mp_klms_U * ptile_consis_ind * post 
	
	cap estimates drop * 
	cap eststo clear 	
	
	*
	areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1, cluster(daten) absorb(permno)
	eststo p0 
	estadd local FE "Firm"
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspost post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspostZLB mp_klmspostnonZLB postZLB postnonZLB if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"		

	*
	areg shock_hf_30min mp_klms_U mp_klmsFptile Fptile if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klmsFptilepostZLB mp_klmspostZLB postZLB mp_klmsFptilepostnonZLB mp_klmspostnonZLB postnonZLB mp_klmsFptile mp_klms_U  if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	
	esttab p* using "${output_tab}\appendix\DU_ZLBnonZLB_ptileconsisIND.tex", label drop(_cons Fptile) se stats(N r2 FE, label("N" "R2" "FEs") fmt(%9.0fc %9.3f)) replace ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	post "$\text{post}$"  ///
	postZLB "$\text{post (ZLB)}$" ///
	postnonZLB "$\text{post (non-ZLB)}$" ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmspostZLB "$\omega_t * \text{post (ZLB)}$" ///
	mp_klmspostnonZLB "$\omega_t * \text{post (non-ZLB)}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
	mp_klmsFptilepostZLB "$\omega_t * \bar{X}_i * \text{post (ZLB)}$"  ///
	mp_klmsFptilepostnonZLB "$\omega_t * \bar{X}_i * \text{post (non-ZLB)}$" ///
    ) ///	
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) nonotes

 









