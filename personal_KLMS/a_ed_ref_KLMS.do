*a_ed_ref_KLMS
*!!!!!!!!!! First, run paths in master_KLMS in root folder. !!!!!!!!!!

global testoverleaf "C:\Users\illge\Princeton Dropbox\Sam Barnett\Apps\Overleaf\Longer maturity shock, post x ptile, post x firmcontrol, 2.5.2025"

*dtop 
*global testoverleaf "C:\Users\sb3357.SPI-9VS5N34\Princeton Dropbox\Sam Barnett\Apps\Overleaf\Longer maturity shock, post x ptile, post x firmcontrol, 2.5.2025"

*all 
global ed_ref_raw "$folder/personal_KLMS/ed_ref_raw"
global ed_ref_proc "$folder/personal_KLMS/ed_ref_proc"

* Code for responses to editor letter, referee letters. 

// G. MAIN EDITOR LETTER 
// H. R1 LETTER 
// I. R2 LETTER 
// J. R3 LETTER 

*G. Editor letter  =============================================================


*ABOVE THICK LINE USE UPDATED DATA, EVERYTHING ELSE IS BAUER/SWANSON, S&P, ETC

/*
*(1) Old version window length table. 
use "$proc_analysis/maintable_data", clear 	
	
	cap estimates drop * 
	cap eststo clear 	
	
	label var window_shock_hf_30min "$\text{Window Length}_{it}$"
	label var WLxSHOCK "$\text{Window Length}_{it} * \omega_t$"
	
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
	
	*90th percentile window length
	sum window_shock_hf_30min, d
	local p90 = r(p90)
	disp "90th percentile (it): `p90'"
	gen overp90 = window_shock_hf_30min > `p90'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90"	
	estadd local percentile_cutoff `p90'
	
	*75th percentile window length
	sum window_shock_hf_30min, d
	local p75 = r(p75)
	disp "75th percentile (it): `p75'"
	gen overp75 = window_shock_hf_30min > `p75'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp75!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p75"	
	estadd local percentile_cutoff	`p75'		
	
	
	*50th percentile window length
	sum window_shock_hf_30min, d
	local p50 = r(p50)
	disp "50th percentile (it): `p50'"
	gen overp50 = window_shock_hf_30min > `p50'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp50!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p50"	
	estadd local percentile_cutoff	`p50'		
	
	esttab p*, label se 
	
	esttab p* using "${output_tab}\appendix\DU_ZLBnonZLB_ptileconsis_WL907550.tex", label drop(_cons window_shock_hf_30min WLxSHOCK) se stats(N r2 FE notes percentile_cutoff, label("N" "R2" "FEs" "Notes" "WL Cutoff (min)") fmt(%9.0fc %9.3f)) replace ///
	order(mp_klms_U mp_klmspost post mp_klmsFptile mp_klmsFptilepost window_shock_hf_30min WLxSHOCK) ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	post "$\text{post}$"  ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
    ) ///		
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 	nonotes
*/			
			
*(2) Full sample: unscheduled, scheduled 
	*use "$proc_analysis/DU_temp_FD.dta", clear 
	use "$proc_analysis/maintable_data.dta", clear 
	
	cap estimates drop * 
	cap eststo clear 
	
	label var mp_klms "$\omega_t$" // Note that this table uses mp_klms, since the point is to compare with unsched.

	*(b)
	areg shock_hf_30min /*mp_klms*/ mp_klms_U if unscheduled_meetings!=1 ,cluster(daten) absorb(permno) // same as above , s.e. doesn't change either
	eststo p2 
	estadd local unscheduled "No"
	estadd local FE "Firm"
	*(c)
	tab unscheduled_meetings //1.8% of obs in regression 
	
	replace mp_klms_U = mp_klms // use full-sample version for full-sample regression
	
	areg shock_hf_30min mp_klms_U ,cluster(daten) absorb(permno) // but these 1.8% obs increase s.e. by about 50% 
	eststo p3 
	estadd local unscheduled "Yes"
	estadd local FE "Firm"
	
	esttab p* using "${output_tab}\rd2_reports\DU_unscheduled_x_firmFE.tex", label nocons se stats(N r2 unscheduled FE, label("N" "R2" "Unscheduled" "FEs") fmt(%9.0fc %9.3f)) replace ///
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) nomtitles substitute(\_ _)  star( * 0.10 ** 0.05 *** 0.010) nonotes
// addnotes("$\omega_t$ does not drop unscheduled for this table.") ///

*(3) Summary stats for the shock in pre, postZLB, postnonZLB 
	use "$proc_analysis/maintable_data.dta", clear 
	
    keep if post==0 | postZLB==1 | postnonZLB==1
    keep mp_klms_U post postZLB postnonZLB
	duplicates drop 
	
	gen period = "1994-2006" 
	replace period = "Post (ZLB)" if postZLB ==1
	replace period = "Post (Non-ZLB)" if postnonZLB ==1
	bysort period: summarize mp_klms_U, d  // for reporting directly 
	
*box plot for the variable mp_klms_U by period
    graph box mp_klms_U, over(period) ///
        title("Box Plot of mp_klms_U by Period") ///
        ytitle("mp_klms_U") ///
        legend(off) ///
        graphregion(color(white)) ///
        scheme(s1color)
		
*vertical density plots
    twoway (kdensity mp_klms_U if post==0) ///
           (kdensity mp_klms_U if postZLB==1) ///
           (kdensity mp_klms_U if postnonZLB==1), ///
        title("Density Plot of Policy Shock by Period") ///
        ytitle("Density") ///
        xtitle("{&omega}{subscript:t}") ///
        legend(label(1 "1994-2006") label(2 "Post-ZLB") label(3 "Post-Non-ZLB")) ///
        graphregion(color(white)) ///
        scheme(s1color)
	graph export "$output_fig/rd2_reports/density_w.pdf", replace  

*(4) Version of main table that breaks up the result by + shocks and - shocks 
use "$proc_analysis/maintable_data", clear 	

	gen indic_raise = mp_klms_U >= 0 // new 

	foreach var in mp_klms_U mp_klmspost mp_klmsFptile mp_klmsFptilepost mp_klmspostZLB mp_klmspostnonZLB mp_klmsFptilepostZLB mp_klmsFptilepostnonZLB {
		cap drop i_`var'
		gen i_`var' = indic_raise * `var'
	}
	
	cap estimates drop * 
	cap eststo clear 	
	*baseline 
	areg shock_hf_30min mp_klms_U i_mp_klms_U indic_raise if unscheduled_meetings!=1, cluster(daten) absorb(permno)
	eststo p0 
	estadd local FE "Firm"
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspost ///
	i_mp_klms_U i_mp_klmspost post indic_raise if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspostZLB mp_klmspostnonZLB postZLB postnonZLB ///
	i_mp_klms_U i_mp_klmspostZLB i_mp_klmspostnonZLB indic_raise ///
	if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"		

	*
	areg shock_hf_30min mp_klms_U mp_klmsFptile Fptile ///
	i_mp_klms_U i_mp_klmsFptile indic_raise if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post ///
	i_mp_klmsFptilepost i_mp_klmsFptile i_mp_klmspost /**/ /*Fptilepost*/ /**/ i_mp_klms_U indic_raise ///
	if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	

	*
	areg shock_hf_30min mp_klmsFptilepostZLB mp_klmspostZLB postZLB mp_klmsFptilepostnonZLB mp_klmspostnonZLB postnonZLB mp_klmsFptile mp_klms_U ///
	i_mp_klmsFptilepostZLB i_mp_klmspostZLB i_mp_klmsFptilepostnonZLB i_mp_klmspostnonZLB i_mp_klmsFptile i_mp_klms_U indic_raise ///
	if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	
	esttab p*, label se 				
	
	esttab p* using "${output_tab}\rd2_reports\DU_ZLBnonZLB_ptileconsis_iplusminus.tex", label drop(_cons Fptile) se stats(N r2 FE, label("N" "R2" "FEs") fmt(%9.0fc %9.3f)) replace ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmspost "$\omega_t * \text{post}$" ///	
	post "$\text{post}$"  ///
	mp_klmspostZLB "$\omega_t * \text{post (ZLB)}$" ///
	mp_klmspostnonZLB "$\omega_t * \text{post (non-ZLB)}$" ///
	postZLB "$\text{post (ZLB)}$" ///
	postnonZLB "$\text{post (non-ZLB)}$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
	mp_klmsFptilepostZLB "$\omega_t * \bar{X}_i * \text{post (ZLB)}$"  ///
	mp_klmsFptilepostnonZLB "$\omega_t * \bar{X}_i * \text{post (non-ZLB)}$" ///
	i_mp_klms_U "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t)$" ///
	i_mp_klmspost "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \text{post})$" ///
	i_mp_klmsFptile "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \bar{X}_i)$" ///
	i_mp_klmsFptilepost "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \bar{X}_i * \text{post})$" ///
	i_mp_klmspostZLB "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \text{post (ZLB)})$" ///
	i_mp_klmspostnonZLB "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \text{post (non-ZLB)})$" ///
	i_mp_klmsFptilepostZLB "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \bar{X}_i * \text{post (ZLB)})$" ///
	i_mp_klmsFptilepostnonZLB "$\mathrm{1}_{\omega_t \geq 0} \times (\omega_t * \bar{X}_i * \text{post (non-ZLB)})$" ///
	indic_raise "$\mathrm{1}_{\omega_t \geq 0}$" ///
    ) ///
	order(mp_klms_U mp_klmspost post mp_klmspostZLB mp_klmspostnonZLB postZLB postnonZLB mp_klmsFptile mp_klmsFptilepost mp_klmsFptilepostZLB mp_klmsFptilepostnonZLB i_*) ///
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) nonotes

*(5) Ernest response table; for returns data, see C:\Users\illge\Downloads\Non-Clean full version FallingRates code
*() Try collapse first and then reg, main spec // a la previous approaches. 
	cap estimates drop * 
	cap eststo clear 	
use "$proc_analysis/maintable_data", clear 
collapse (mean) shock_hf_30min mp_klms_U mp_klms unscheduled, by(daten)
reg shock_hf_30min mp_klms_U, r	
reg shock_hf_30min mp_klms, r
tw (scatter shock_hf_30min mp_klms_U) (lfit shock_hf_30min mp_klms_U), leg(off) ytitle("HF Return (mean)") xtitle("MP Shock (mean)")

use "$proc_analysis/maintable_data", clear 
collapse (mean) shock_hf_30min mp_klms_U mp_klms [aw=adj_MV], by(daten)
reg shock_hf_30min mp_klms_U, r	
reg shock_hf_30min mp_klms, r
tw (scatter shock_hf_30min mp_klms_U) (lfit shock_hf_30min mp_klms_U), leg(off) ytitle("Wtd HF Return (mean)") xtitle("MP Shock (mean)")
			

*() Ernest's question Jul 3 
//(i) Run high-frequence SandP return on FOMC shock, 
//(ii) Run average of our firm-level return at each FOMC on FOMC shock, and 
//(iii) repeat (i) and (ii) but limit to NS dates.

cap estimates drop * 
cap eststo clear 

use "$proc_analysis/maintable_data", clear 
areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1, cluster(daten) absorb(permno) // main spec from paper
eststo p1 	
estadd local dates "All Sched."
estadd local FE "Firm"

	
*(a) ALL DATES	
/* *(i)	
use "$folder/returns_data_Jul2024/SPIndex_return.dta", clear 
keep daten SPIndex_return 		
replace SPIndex_return = SPIndex_return*100	
drop if yofd(daten) < 1994
merge 1:1 daten using "$proch/master_fomc_level_24.dta", keep(master matched) nogen

reg SPIndex_return mp_klms_U, r
eststo p2
estadd local dates "All Sched." */


*(ii) 
use "$proc_analysis/maintable_data", clear 
keep daten adj_MV shock_hf_30min mp_klms_U mp_klms

preserve // unweighted
collapse (mean) shock_hf_30min mp_klms_U mp_klms, by(daten)
reg shock_hf_30min mp_klms_U, r
eststo p3
estadd local dates "All Sched." 	
restore 


/*
preserve // weighted
collapse (mean) shock_hf_30min mp_klms_U mp_klms [aw=adj_MV], by(daten)
reg shock_hf_30min mp_klms_U, r
eststo p4
estadd local dates "All Sched."
restore 


*(b) NAKAMURA STEINSSON DATES 	
use "$folder/returns_data_Jul2024/ns_replication_data.dta", clear
	rename date_daily daten
	keep daten Dlsp500 FOMCused path_intra_wide
	* Double checking NS regressions
	reg Dlsp500 path_intra_wide  if FOMCused==1, r
	keep if !missing(Dlsp500) & !missing(path_intra_wide) &  FOMCused==1
	keep daten 
	merge 1:1 daten using "$proch/master_fomc_level_24.dta", keep(matched) nogen
	tempfile nsdates 
	save `nsdates'

*(i)	
use "$folder/returns_data_Jul2024/SPIndex_return.dta", clear 
keep daten SPIndex_return 		
replace SPIndex_return = SPIndex_return*100		
drop if yofd(daten) < 1994
merge 1:1 daten using "$proch/master_fomc_level_24.dta", keep(master matched) nogen
merge 1:1 daten using `nsdates', keep(matched) nogen // ========== n/s dates

reg SPIndex_return mp_klms_U, r
eststo p5
estadd local dates "N/S (2018) Sample"

*(ii) 
use "$proc_analysis/maintable_data", clear 
keep daten adj_MV shock_hf_30min mp_klms_U mp_klms
preserve // unweighted
collapse (mean) shock_hf_30min mp_klms_U mp_klms, by(daten)
merge 1:1 daten using `nsdates', keep(matched) nogen // ========== n/s dates
reg shock_hf_30min mp_klms_U, r
eststo p6
estadd local dates "N/S (2018) Sample"
restore 

preserve // weighted
collapse (mean) shock_hf_30min mp_klms_U mp_klms [aw=adj_MV], by(daten)
merge 1:1 daten using `nsdates', keep(matched) nogen // ========== n/s dates
reg shock_hf_30min mp_klms_U, r
eststo p7
estadd local dates "N/S (2018) Sample"
restore 
*/

*(v) Daily returns 
use "$folder/returns_data_Jul2024/SPdaily.dta", clear
rename change_log_price Dl_sp500ret 
replace Dl_sp500ret = Dl_sp500ret* 100
rename date daten 
keep daten Dl_sp500ret
merge 1:1 daten using "$proch/master_fomc_level_24.dta", keep(matched) nogen
reg Dl_sp500ret mp_klms_U, r
eststo p8
estadd local dates "All Sched."

/*
*(vi) daily returns with N/S sample only 
merge 1:1 daten using `nsdates', keep(matched) nogen // ========== n/s dates
reg Dl_sp500ret mp_klms_U, r
eststo p9
estadd local dates "N/S (2018) Sample"
*/

label var mp_klms_U "$\omega_t$"

esttab p* using "${output_tab}\rd2_reports\aggreg_response_all.tex", ///
label drop(_cons) se ///
stats(N r2 FE dates, label("N" "R2" "FEs" "Dates") fmt(%9.0fc %9.3f)) replace ///
nocons ///
mgroups("$ R_{it}$" /*"$\text{SP500 (30m)}$"*/ "$\bar{R}_t$" /*"$\bar{R}_t \text{(MV-wtd.)}$" "$\text{SP500 (30m)}$" "$\bar{R}_t$" "$\bar{R}_t \text{(MV-wtd.)}$"*/ "$\text{SP500 (24h)}$", ///
 pattern(1 1 /*1 1 1 1 1*/ 1 /*0*/) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) nonotes
			

			
			
	*(6) Atif's two section table, average period FFR result for 1994-2019 then 1994-2024  
	use "$proch/FFtarget", clear // import fred FEDFUNDS, clear 

	*[1] 1994-2019
	gen year = yofd(daten)
	keep if year <= 2019 // ===========================================================
	sum target if year >= 1994 & year <= 2006, meanonly 
	local premean = `r(mean)'
	sum target if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021), meanonly  // 0.0582192
	local ZLBmean = `r(mean)'	
	sum target if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024), meanonly  // 2.615385
	local nonZLBmean = `r(mean)'	
	di "`premean', `ZLBmean', `nonZLBmean'"
	
	use "$proc_analysis/maintable_data", clear 
	
	keep if year <= 2019 // ===========================================================
	
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
	
	*[2] 1994-2024
	preserve // ==========
	use "$proch/FFtarget", clear // import fred FEDFUNDS, clear 	
	
	gen year = yofd(daten)	
// 	keep if year <= 2019 // ===========================================================

	sum target if year >= 1994 & year <= 2006, meanonly 
	local premean = `r(mean)'
	sum target if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021), meanonly  // 0.0582192
	local ZLBmean = `r(mean)'	
	sum target if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024), meanonly  // 2.615385
	local nonZLBmean = `r(mean)'	
	di "`premean', `ZLBmean', `nonZLBmean'"
	
	restore // ==========
	
	use "$proc_analysis/maintable_data", clear 
// 	keep if year <= 2019 // ===========================================================
	
	*cap estimates drop * 
	*cap eststo clear 	
	
	gen FFR_bar = `premean' /* */ // pre- period 
	replace FFR_bar = `ZLBmean' /* */ if (year >= 2009 & year <= 2015) | (year >= 2020 & year <= 2021) 
	replace FFR_bar = `nonZLBmean' /* */ if (year>=2007 & year<=2008) | (year>=2016 & year<=2019) | (year>=2022 & year <= 2024) 
 	
	replace mp_klmspost = mp_klms_U * FFR_bar 
	replace mp_klmsFptilepost = mp_klms_U * ptile_consis * FFR_bar 

	*
	areg shock_hf_30min mp_klms_U mp_klmspost FFR_bar if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"		
	*
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U FFR_bar if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"		
	*
	gen leader_indic = (ptile_consis >= 0.95)
	gen shock_leader_FFR = mp_klms_U * leader_indic * FFR_bar 
	gen shock_leader = mp_klms_U * leader_indic
	areg shock_hf_30min_dollar shock_leader mp_klms_U shock_leader_FFR mp_klmspost FFR_bar if unscheduled_meetings!=1, cluster(daten) absorb(permno)
	eststo p6
	estadd local FE "Firm"			
	
	esttab p* using "${output_tab}\rd2_reports\tab2_improvement_94_24.tex", label drop(_cons /*Fptile*/) se stats(N r2 FE, label("N" "R2" "FEs") fmt(%9.0fc %9.3f)) replace ///
	  varlabels( ///
    FFR_bar           "$\overline{\mathrm{FFR}}$" ///
    mp_klmspost       "$\omega_t * \overline{\mathrm{FFR}}$" ///
    mp_klmsFptilepost "$\omega_t * \bar X_i * \overline{\mathrm{FFR}}$" ///
    shock_leader_FFR  "$\omega_t * \text{Overall Leader} * \overline{\mathrm{FFR}}$" ///
    shock_leader      "$\omega_t * \text{Overall Leader}$" ///
  ) ///
  prehead(`"{"' `"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"' `"\begin{tabular}{l*{6}{c}} \\ \hline\hline & \multicolumn{3}{c}{$\fbox{\text{Years 1994-2019}}$} & \multicolumn{3}{c}{$\fbox{\text{Years 1994-2024}}$} \\"') ///
	mgroups("$ R_{it}$" "$\textdollar R_{it}$" "$ R_{it}$" "$\textdollar R_{it}$" , pattern(1 0 1 1 0 1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			order(mp_klms_U FFR_bar mp_klmspost mp_klmsFptile mp_klmsFptilepost) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 	nonotes		
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
// =============================================================================
*() Motivational figure: Why weight? The firm size distribution changes substantially when shifting the window-length window. 
	use "$proc_analysis/maintable_data", clear 	
    keep Fptile Fdecile_consis window_shock_hf_30min permno daten mp_klms_U shock_hf_30min
	
	sum window_shock_hf_30min, d 
	local p90 = r(p90)
	local p75 = r(p75)
	
	*drop not in reg sample 
	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	keep if indic_reg == 1
	count // 795,059	
	
	gen id = _n 
	expand 3
	bysort id: gen category = _n 
	
	*cat 1: 0 - 90
	drop if category == 1 & (window_shock_hf_30min >= `p90')
	count if category == 1
	
	*cat 2: 0 - 75
	drop if category == 2 & (window_shock_hf_30min >= `p75')
	count if category == 2	
	
*vertical density plots
	gen F100 = int(Fptile*100)+1
	bysort category F100: egen dens = count(id)
	egen ttag = tag(F100 category)
    twoway  ///
		   (/*kdensity*/ /*Fptile*/ connected dens F100 if category==1, msize(tiny)) ///
           (/*kdensity*/ /*Fptile*/ connected dens F100 if category==2, msize(tiny)) ///
           (/*kdensity*/ /*Fptile*/ connected dens F100 if category==3, msize(tiny)) ///
		   if ttag==1, ///
        /*title("Density Plot of Firm Size by WL Range")*/ ///
        ytitle("Count") ///
        xtitle("X{subscript:i}") ///
        legend(label(1 "0-90th Percentile") label(2 "0-75th Percentile") label(3 "Full Sample") ) ///
        graphregion(color(white)) ///
        scheme(s1color) ///
		yline(0, lpattern(dash) lcolor(black))
	graph export "${output_fig}\misc\firmsizewindowlength.pdf", replace	
// =============================================================================

// =============================================================================
*() New window robustness table 
use "$proc_analysis/maintable_data", clear 	
	
	cap estimates drop * 
	cap eststo clear 	
	
	label var window_shock_hf_30min "$\text{Window Length}_{it}$"
	label var WLxSHOCK "$\text{Window Length}_{it} * \omega_t$"
	
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
	
	*1hr shock // pretty good 
// 	replace mp_klms_U = mp_klms_U1h
// 	replace mp_klmsFptilepost = mp_klms_U * Fptile * post 
// 	replace mp_klmsFptile = mp_klms_U * Fptile
// 	replace mp_klmspost = mp_klms_U * post 
	areg shock_hf_1hour mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post /*window_shock_hf_30min WLxSHOCK*/ if unscheduled_meetings!=1, cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	estadd local notes "1h Shock"	
	
	*1hr shock, WC // pretty good 
	gen store1 = WLxSHOCK
	replace WLxSHOCK = mp_klms_U * window_shock_hf_1hour
	areg shock_hf_1hour mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_1hour WLxSHOCK if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "1h, Window Control"		
	replace WLxSHOCK = store1
	
	*() Keep only shorter 0-90
	preserve 

	sum window_shock_hf_30min, d 
	local p90 = r(p90)
	gen overp90 = window_shock_hf_30min >= `p90'	
	
	keep if overp90!=1
	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	bysort Fdecile_consis: egen num_decile = count(indic_reg)
	gen w = 1/num_decile

	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p6
	estadd local FE "Firm"	
	estadd local notes "Drop WL $\geq$ p90"	
	estadd local percentile_cutoff	`p90'	
	restore 	
	
	
	*() Keep only shorter 0-75
	preserve 

	sum window_shock_hf_30min, d 
	local p75 = r(p75)
	gen overp90 = window_shock_hf_30min >= `p75'	
	
	keep if overp90!=1
	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	bysort Fdecile_consis: egen num_decile = count(indic_reg)
	gen w = 1/num_decile

	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p7
	estadd local FE "Firm"	
	estadd local notes "Drop WL $\geq$ p75"	
	estadd local percentile_cutoff	`p75'	
	restore 
	
	*Baseline main result, wtd 
	preserve 	
	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	bysort Fdecile_consis: egen num_decile = count(indic_reg)
	gen w = 1/num_decile	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p8
	estadd local FE "Firm"	
	estadd local notes "Baseline, Wtd"
	restore 	
	
	esttab p* using "${output_tab}\misc\DU_ZLBnonZLB_ptileconsis_WLalt9075.tex", label drop(_cons window_shock_hf_30min WLxSHOCK) se stats(N r2 FE notes percentile_cutoff, label("N" "R2" "FEs" "Notes" "WL Cutoff (min)") fmt(%9.0fc %9.3f)) replace ///
	order(mp_klms_U mp_klmspost post mp_klmsFptile mp_klmsFptilepost window_shock_hf_30min WLxSHOCK) ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	post "$\text{post}$"  ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
    ) ///		
	mgroups("$ R_{it}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) nonotes
// =============================================================================		

	
// =============================================================================
*() Figure version of robustness 

	use "$proc_analysis/maintable_data.dta", clear 
	
	gen coef3=.
	gen se3=.
	egen FpPtag=tag(Fdecile_consis post)
	
	forvalues p=0/1 {
	forvalues i=1/20 {
	areg shock_hf_30min mp_klms_U WLxSHOCK if unscheduled_meetings!=1 & Fdecile_consis==`i'*5 & post==`p',cluster(daten) absorb(permno) 
	replace coef3=_b[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	replace se3=_se[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	}
	}	
	gen lb3 = coef3 - se3 
	gen ub3 = coef3 + se3 
	graph twoway (rcap ub3 lb3 Fdecile_consis if post==0, lcolor(red) lpattern(dash)) (scatter coef3 Fdecile_consis if post==0, mcolor(red)) ///
	(rcap ub3 lb3 Fdecile_consis if post==1, lcolor(edkblue) lpattern(dash)) (scatter coef3 Fdecile_consis if post==1, mcolor(edkblue)) ///
	(lfit coef3 Fdecile_consis if post == 0, lcolor(red)) (lfit coef3 Fdecile_consis if post == 1, lcolor(edkblue)) ///
	if FpPtag==1, /*title("Split percentile graph using scheduled only")*/ leg(order(2 "1994-2006" 4 "2007-2024")) /*ylabel(-0.25(0.05)0)*/ ytitle("D{subscript:t, q, p}") xtitle("Percentile") name("g1", replace)

	
*Only ZLB
	use "$proc_analysis/maintable_data.dta", clear 
	
	gen coef3=.
	gen se3=.
	
	replace post = . if postnonZLB==1 // only keep ZLB for post
	egen FpPtag=tag(Fdecile_consis post)
	
	forvalues p=0/1 {
	forvalues i=1/20 {
	areg shock_hf_30min mp_klms_U WLxSHOCK if unscheduled_meetings!=1 & Fdecile_consis==`i'*5 & post==`p',cluster(daten) absorb(permno) 
	replace coef3=_b[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	replace se3=_se[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	}
	}	
	gen lb3 = coef3 - se3 
	gen ub3 = coef3 + se3 
	graph twoway /// 
	(rcap ub3 lb3 Fdecile_consis if post==0, lcolor(red) lpattern(dash)) (scatter coef3 Fdecile_consis if post==0, mcolor(red)) ///
	(rcap ub3 lb3 Fdecile_consis if post==1, lcolor(blue) lpattern(dash)) (scatter coef3 Fdecile_consis if post==1, mcolor(blue)) ///
	(lfit coef3 Fdecile_consis if post == 0, lcolor(red)) (lfit coef3 Fdecile_consis if post == 1, lcolor(blue)) ///
	if FpPtag==1, /*title("Split percentile graph using scheduled only")*/ leg(order(2 "1994-2006" 4 "Post-2007 (ZLB)")) /*ylabel(-0.25(0.05)0)*/ ytitle("D{subscript:t, q, p}") xtitle("Percentile") name("g2", replace)		
	
	
*Only nonZLB
	use "$proc_analysis/maintable_data.dta", clear 
	
	gen coef3=.
	gen se3=.
	
	replace post = . if postZLB==1 // only nonZLB	
	egen FpPtag=tag(Fdecile_consis post)
	
	forvalues p=0/1 {
	forvalues i=1/20 {
	areg shock_hf_30min mp_klms_U WLxSHOCK if unscheduled_meetings!=1 & Fdecile_consis==`i'*5 & post==`p',cluster(daten) absorb(permno) 
	replace coef3=_b[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	replace se3=_se[mp_klms_U] if Fdecile_consis==`i'*5 & post==`p'
	}
	}	
	gen lb3 = coef3 - se3 
	gen ub3 = coef3 + se3 
	graph twoway (rcap ub3 lb3 Fdecile_consis if post==0, lcolor(red) lpattern(dash)) (scatter coef3 Fdecile_consis if post==0, mcolor(red)) ///
	(rcap ub3 lb3 Fdecile_consis if post==1, lcolor(eltblue) lpattern(dash)) (scatter coef3 Fdecile_consis if post==1, mcolor(eltblue)) ///
	(lfit coef3 Fdecile_consis if post == 0, lcolor(red)) (lfit coef3 Fdecile_consis if post == 1, lcolor(eltblue)) ///
	if FpPtag==1, /*title("Split percentile graph using scheduled only")*/ leg(order(2 "1994-2006" 4 "Post-2007 (Non-ZLB)")) /*ylabel(-0.25(0.05)0)*/ ytitle("D{subscript:t, q, p}") xtitle("Percentile") name("g3", replace)
	
	graph combine g1 g2 g3, cols(3) xsize(10) ysize(5)
	graph export "${output_fig}\misc\triple_WL_robustness.pdf", replace		
// =============================================================================	
	

			

			
			
*() Bauer/Swanson data. 
import excel "${ed_ref_raw}/FOMC_Bauer_Swanson.xlsx", sheet("FOMC Announcements") firstrow clear
	*clean data
	gen year = year(Date)
	rename Date date
	drop in 170 // post-9/11, MPS is NA
	replace SP500emini = "." if SP500emini == "NA"
	destring MPS MPS_ORTH SP500emini, replace 
	drop if missing(date)
	drop if year(date) < 1994
	save "$ed_ref_proc/FOMC_Bauer_Swanson_proc.dta", replace 

*() Scatterplot of R3 regression. 
import excel "${ed_ref_raw}/pre-and-post-ZLB-factors-extended.xlsx", firstrow clear  
// downloaded here: https://sites.socsci.uci.edu/~swanson2/papers/pre-and-post-ZLB-factors-extended.xlsx
	rename EstimatedFactors ffrate_factor
	rename B date
	rename D fguide_factor 
	rename E lsap_factor 
	rename F minus_lsap_factor
	drop in 1
	drop if missing(date)

	replace date = trim(date)
	replace date = "0" + date if substr(date, 2, 1) == "/"
	replace date = substr(date, 1, 3) + "0" + substr(date, 4, 6) if strlen(date) == 9
	gen datefix = date(date, "MDY")
	drop date 
	rename datefix date
	format date %td 

	gen year = year(date)
	drop if year < 1994
	merge 1:1 date using "$ed_ref_proc/FOMC_Bauer_Swanson_proc.dta", nogen

	drop if missing(ffrate_factor)
	destring ffrate_factor, replace

	reghdfe SP500 ffrate_factor if year>=1994 & year <= 2000, noabsorb vce(cluster date)
	eststo p1 

	twoway (scatter SP500 ffrate_factor if year>=1994 & year <= 2000, mcolor(black)) ///
		   (lfit SP500 ffrate_factor if year>=1994 & year <= 2000), ///
		   legend(off) ///
		   name(g1, replace) /// 
		   /*title("1994-2000")*/ ///
		   xlabel(, labsize(small)) ylabel(, labsize(small)) ///
		   xtitle("Fed Funds Rate Factor") ytitle("SP500") ///
		   yscale(range(-2, 2)) ///
		   xscale(range(-3 1.5))

	reghdfe SP500 ffrate_factor if year>=2013 & year <= 2019, noabsorb vce(cluster date)
	matrix b = e(b)
	local intercept = b[1,2]
	local slope = b[1,1]
	eststo p2 

	twoway (scatter SP500 ffrate_factor if year>=2013 & year <= 2019, mcolor(black)) ///
		   (function y = `intercept' + `slope'*x, range(-1.5 1.5) lcolor(red) lwidth(medium)), ///
		   legend(off) ///
		   name(g2, replace) ///
		   /*title("2013-2019")*/ ///
		   xlabel(, labsize(small)) ylabel(, labsize(small)) ///
		   xtitle("Fed Funds Rate Factor") ytitle("SP500") ///
		   yscale(range(-2, 2)) ///
		   xscale(range(-3 1.5)) ///
		   xlabel(-3(1)1)

	graph combine g1 g2, col(2)	 
	graph export "$output_fig/rd2_reports/scatter_R3P11.pdf", replace
	
	*"Interest of completeness": correct the returns to switch to SP500 emini, and run regression
	replace SP500 = SP500emini if date >= td(01sep1997)
	reghdfe SP500 ffrate_factor if year>=1994 & year <= 2000, noabsorb vce(cluster date)	
	local beta = _b[ffrate_factor]
	local se = _se[ffrate_factor]
	di "Corrected returns, early period: `beta', (`se')"
	reghdfe SP500 ffrate_factor if year>=2013 & year <= 2019, noabsorb vce(cluster date)	
	local beta = _b[ffrate_factor]
	local se = _se[ffrate_factor]
	di "Corrected returns, late period: `beta', (`se')"	
	
*what is ff factor 	
import excel "$ed_ref_raw/pre-and-post-ZLB-factors-extended.xlsx", firstrow clear  	
drop B 
drop in 1 
destring *, replace 
drop if missing(Estimated)
gen date = _n 
tw line Estimated /*D E*/ date, ytitle("FF Factor")
tw line D /*E*/ date, ytitle("Forw Guidance Factor")
tw line E date, ytitle("LSAP Factor")



* () Unscheduled/scheduled rolling coeffs response graph. 
use "${ed_ref_proc}/FOMC_Bauer_Swanson_proc.dta", clear

capture program drop graph_rolling_coeff_se_split
program define graph_rolling_coeff_se_split
	syntax varlist(min=2) [if] [in], TITLE(string) 

	local y : word 1 of `varlist'
	local x : word 2 of `varlist'

	**Make graph: rolling 5y coefficients.
	*empty coefficient matrix
	matrix years_empty = J(22, 7, .)
	forvalues i = 1/22 {
		matrix years_empty[`i', 1] = 1998 + `i' - 1
	}

	*fill years_empty with coeffs and SE bounds from: reg `y' `x'
	forvalues i = 0/21 {
		reghdfe `y' `x' if year >= 1994 + `i' & year <= 1998 + `i', noabsorb vce(cluster date)
		di "`=1998+`i''"
		matrix years_empty[`i'+1, 2] = _b[`x'] //* 0.1
        matrix years_empty[`i'+1, 3] = _b[`x'] /* * 0.1*/ + /*0.675 **/ _se[`x'] // * 0.1  // Upper bound
        matrix years_empty[`i'+1, 4] = _b[`x'] /* * 0.1*/ - /*0.675 **/ _se[`x'] // * 0.1  // Lower bound
	}
	
	*same thing for reg `b' `a'
	drop if Unscheduled == 1
	forvalues i = 0/21 {
		reghdfe `y' `x' if year >= 1994 + `i' & year <= 1998 + `i', noabsorb vce(cluster date)
		di "`=1998+`i''"
		matrix years_empty[`i'+1, 5] = _b[`x'] //* 0.1
        matrix years_empty[`i'+1, 6] = _b[`x'] /* * 0.1*/ + /*0.675 **/ _se[`x'] //* 0.1  // Upper bound
        matrix years_empty[`i'+1, 7] = _b[`x'] /* * 0.1*/ - /*0.675 **/ _se[`x'] //* 0.1  // Lower bound
	}
	
	matrix list years_empty

	//test: run same row 2 & 17 regs outside of loop, see if same coeffs 
	reghdfe `y' `x' if year >= 1995 & year <= 1999, noabsorb vce(cluster date)
	reghdfe `y' `x' if year >= 2010 & year <= 2014, noabsorb vce(cluster date)

	*graph the resulting 5-year rolling estimates over time
	clear
	svmat years_empty, names(c)
	rename c1 end_year
	rename c2 fiveyr_rolling_coefficient
	rename c3 ub 
	rename c4 lb 
	rename c5 fy_rolling
	rename c6 u
	rename c7 l
	tw (rcap u l end_year, lcolor(green) lpattern(dash)) (scatter fy_rolling end_year, mcolor(green) msymbol(diamond) msize(small)) (rcap ub lb end_year, lcolor(gray) lpattern(dash)) (scatter fiveyr_rolling_coefficient end_year, mcolor(black) msymbol(diamond) msize(small)), yline(0, lpattern(dash)) ytitle(/*"D{subscript:t}"*/"{&beta}{subscript:1}", size(large)) xtitle(year) legend(off) title("Duration Rolling Window")  /* ///
    text(-1.3 1999 "Drop Unsched. FOMCs: Apr94, Oct98, Jan01, Apr01, Aug07, Aug07, Jan08, Mar08, Oct08, Oct19" , placement(ne) size(small) color(green)) */
end

graph_rolling_coeff_se_split SP500 MPS, title("5Y Rolling Coeffs: Green Drops Unscheduled")
graph export "$output_fig/rd2_reports/r3split_schedunsched_final.pdf", replace 
						

			
			
		
		
		
		
		
		
		
			
// ============================================================================		
// Not in any letters, responses 
*Trying more granular Table 2
					
*(2) Second main table with FFR level in each period replacing period indicators, and a "dollar duration" column 
local windowlen 1

use "$proch/FFtarget", clear 
gen year = yofd(daten)
	gen temp5 = (year)/`windowlen'
	gen year5 = round(temp5, 1)
		sum year5 ,d
	collapse (mean) FFR_bar=target, by(year5)	
	tempfile ff
	save `ff'

	use "$proc_analysis/maintable_data", clear 
	
	cap estimates drop * 
	cap eststo clear 	
	
	gen temp5 = (year)/`windowlen'
	gen year5 = round(temp5, 1)
		sum year5 ,d
	merge m:1 year5 using `ff', keep(master matched) nogen
	
	/*TEMP*/ replace FFR_bar = target // ====================
		
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
	
	esttab p* using "$testoverleaf\DU_FFRbar_grantarget.tex", label drop(_cons /*Fptile*/) se stats(N r2 FE, label("N" "R2" "FEs") fmt(%9.0fc %9.3f)) replace ///
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
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 	
				
	
	
/*
*Analysis Data: SP \ {KLMS} sample 		
*() mean_t of share fin_t = % SP500 dropped from KLMS that are fin.  
*ALSO drops dates missing shock_hf_30min, since those are dropped from the regression. 
*Already drops missing ffi. 

// use "${temp}/temp_stock_fomc_level.dta", clear
// merge 1:1 daten permno using "${temp}/daily_stocks.dta", keep(master matched) nogen // for FFI 

* Loading CPI
import fred CPIAUCSL, clear
rename CPIAUCSL cpi
gen month = mofd(daten)
drop daten datestr
* Normalizing so 2019/12 is 1
su cpi if month == 719
replace cpi = cpi/r(mean) 
tempfile cpi
save `cpi'

use "${proc}/FOMC_Bauer_Swanson_proc.dta", clear // for Bauer Swanson fomc dates 
// 	gen month = mofd(date)
// 	format month %tm
// 	keep month 
	rename date daten
	keep daten
	duplicates drop 
	tempfile BSdates 
	save `BSdates'	

use "${temp}/daily_stocks.dta", clear 
gen month = mofd(daten)
merge m:1 month using `cpi', nogen
merge m:1 daten using `BSdates', keep(matched) nogen
keep permno ffi month daten MV cpi 
gen adj_MV = MV / cpi 
drop MV cpi 
duplicates drop 

egen ffi_mode = mode(ffi)
egen temptag = tag(permno month)
sort permno month, stable
egen temptag_mean = mean(temptag), by(permno month)
drop if temptag_mean != 1 // drop firm-months that change FFI

merge 1:1 month permno using "${temp}/sp500_constituents_cleaned.dta", nogen // not matched from using: 357/156,000
drop if missing(sp500_const)
save "${temp}/SP_const_mv.dta", replace // =====



use "${temp}/master_daily_fomc_days.dta", clear // old main data 
	drop if missing(shock_hf_30min)  // since won't be included in regressions
	qui keep permno daten 
	qui duplicates drop
	qui tempfile temp 
	qui save `temp'
	
	
	use "${temp}/SP_const_mv.dta", clear	
	*Only constituent months with FOMC dates 
	qui merge m:1 daten using `BSdates'
	keep if _merge == 3 // now only FOMC date months
	drop _merge 
	
	*Merge that with the list of firms in the sample; then keep if in sp500consts \ {sample} 
	qui merge 1:m permno daten using `temp'
	keep if _merge == 1 // key "diff" step
	
	qui gen daydate = dofm(month)
	qui gen year = year(daydate)
	qui gen monthi = month(daydate)
	save "${temp}/SP_diff_klms_sample.dta", replace //the actual SP \ KLMS sample 
	keep permno month ffi adj_MV
	duplicates drop 
	tempfile msample 
	save `msample'
	
	use "${temp}/master_daily_fomc_days.dta", clear 
	keep daten mp_klms 
	duplicates drop 
	tempfile FOMC_temp 
	save `FOMC_temp'

use "${temp}/temp_stock_fomc_level.dta", clear
	gen month = mofd(daten)
	merge m:1 month permno using `msample' /*, keep(matched)*/ 
	keep if _merge == 3 // not matched doesn't have returns 
	drop _merge
	merge m:1 daten using `FOMC_temp', keep(matched) nogen
	gen year = yofd(daten)
	*last step: x 100 units of shock_hf_30min to be consistent with all other data
	replace shock_hf_30min = shock_hf_30min * 100
	save "$temp/SP_diff_klms_returns", replace // w/ returns 
	
use "$temp/SP_diff_klms_returns", clear 
isid daten permno

*() 9-column table with  cols (2) (3) (4) of main table two times: 
* i) show different window lengths without control, (ii) remove observations where window length is too large
use "$proc/maintable_data", clear 	
	
	cap estimates drop * 
	cap eststo clear 	
	
// 	/* !! replace block FOR NOW----*/  
// 	gen sto1 = mp_klms_U 
// 	gen sto2 = mp_klmspost
// 	gen sto3 = mp_klmsFptile
// 	gen sto4 = mp_klmsFptilepost
// 	replace mp_klms_U = mp_klms_U1h
// 	replace mp_klmspost = mp_klms_U * post 
// 	replace mp_klmsFptile = mp_klms_U * Fptile
// 	replace mp_klmsFptilepost=mp_klms_U*Fptile*post
// 	/* ------------- */
	
	*(i)
	*c1 
	areg shock_hf_1hour mp_klms_U mp_klmspost post if unscheduled_meetings!=1, cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	estadd local notes "Hour"

	*c2
	areg shock_hf_1hour mp_klms_U mp_klmsFptile Fptile if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"	
	estadd local notes "Hour"	
	
	*c3
	areg shock_hf_1hour mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	estadd local notes "Hour"	
	
// 	/* replace block */
// 	replace mp_klms_U = sto1
// 	replace mp_klmspost = sto2
// 	replace mp_klmsFptile = sto3
// 	replace mp_klmsFptilepost=sto4
// 	/* ------------- */
	
	*(ii)
	*90th percentile window length
	sum window_shock_hf_30min, d
	local p90 = r(p90)
	disp "`p90'"
	gen overp90 = window_shock_hf_30min > `p90'
		
	*c1 
	areg shock_hf_30min mp_klms_U mp_klmspost post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90"

	*c2
	areg shock_hf_30min mp_klms_U mp_klmsFptile Fptile if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90"
	
	*c3
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p6
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90"
	
	*(iii) Firm window length
	sum Fwindowlen, d	
	local p90f = r(p90)
	disp "`p90f'"
	cap drop overp90
	gen overp90 = Fwindowlen > `p90f'	
	
	*c1 
	areg shock_hf_30min mp_klms_U mp_klmspost post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p7
	estadd local FE "Firm"	
	estadd local notes "Drop Firm $>$ p90"

	*c2
	areg shock_hf_30min mp_klms_U mp_klmsFptile Fptile if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p8
	estadd local FE "Firm"	
	estadd local notes "Drop Firm $>$ p90"
	
	*c3
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1, cluster(daten) absorb(permno) 
	eststo p9
	estadd local FE "Firm"	
	estadd local notes "Drop Firm $>$ p90"
	
	esttab p*, label se 				
	
	esttab p* using "${output_tab}\misc\DU_ZLBnonZLB_ptileconsis_WLmisc.tex", label drop(_cons Fptile) se stats(N r2 FE notes, label("N" "R2" "FEs" "Notes") fmt(%9.0fc %9.3f)) replace ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	post "$\text{post}$"  ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
    ) ///		
	mgroups("$\Delta \text{MV}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 

			
*() New simpler window length table. 
use "$proc/maintable_data", clear 	
	
	cap estimates drop * 
	cap eststo clear 	
	
	label var window_shock_hf_30min "$\text{Window Length}_{it}$"
	label var WLxSHOCK "$\text{Window Length}_{it} * \omega_t$"
	
	*Baseline main result
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	estadd local notes "Baseline"
	
	*Window control
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_30min WLxSHOCK if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
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
	
	*Firm 90th percentile window length
	sum Fwindowlen, d	
	local p90f = r(p90)
	disp "90th percentile mean(i): `p90f'"
	cap drop overp90
	gen overp90 = Fwindowlen > `p90f'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1, cluster(daten) absorb(permno) 
	eststo p9
	estadd local FE "Firm"	
	estadd local notes "Drop Firm $>$ p90"
	
	esttab p*, label se 
	
	esttab p* using "${output_tab}\misc\DU_ZLBnonZLB_ptileconsis_WL.tex", label drop(_cons window_shock_hf_30min WLxSHOCK) se stats(N r2 FE notes, label("N" "R2" "FEs" "Notes") fmt(%9.0fc %9.3f)) replace ///
	order(mp_klms_U mp_klmspost post mp_klmsFptile mp_klmsFptilepost window_shock_hf_30min WLxSHOCK) ///
	varlabels( ///
	mp_klms_U "$\omega_t$" ///
	mp_klmsFptile "$\omega_t * \bar{X}_i$" ///
	mp_klms_ptile "$\omega_t * X_{it}$"  ///
	post "$\text{post}$"  ///
	mp_klmspost "$\omega_t * \text{post}$" ///
	mp_klmsFptilepost "$\omega_t * \bar{X}_i * \text{post}$" ///
    ) ///		
	mgroups("$\Delta \text{MV}$" , pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) ///
			span erepeat(\cmidrule(lr){@span})) ///
			nomtitles substitute(\_ _) star( * 0.10 ** 0.05 *** 0.010) 	
*/			
	
	
/*	
*Five results. 
/* 
(1) merge with percentile, reg Pcoeff_30min on temp22 = post * ptile, post, ptile
(2a) SP500 Duration Bauer/Swanson MPS, Keep Unscheduled
(2b) SP500 Duration Bauer/Swanson MPS, Drop Unscheduled
(2c) Average Firm Duration (KLMS)
(3) spdiffklms Average Firm Duration Bauer/Swanson MPS, Drop Unscheduled
*/

*********** Program to create coefs [i.e., function in original draft]
*** Difference: this one uses intraday return (same window as NS)
cap program drop coeff_estimator_hf
program define coeff_estimator_hf, rclass
args yrlist outcome_vars minobs rest alt_shock dataset 




clear
gen bogus=.
tempfile tempcfs
save `tempcfs', replace

*** Setting outcome vars
local shock mp_klms
if "`alt_shock'" != "mp_klms" {
	local shock `alt_shock'
}

disp "`shock'"
disp "`alt_shock'"

foreach num of local yrlist {

	tokenize "`num'"
	local year_beg "`1'"
	local year_end "`2'"
	*** First step: creating base file with the MVs
	use "${temp}/`dataset'.dta", clear
	`rest'
	gen y`year_end'=1 if year<=`year_end' & year >=(`year_beg')
	keep if y`year_end'==1
	egen temp1=count(daten), by(permno)
	*keeping firms that face at least 50 FOMC shocks in a period
	keep if temp1>=`minobs'
	* Creating variables that are constant across period
	preserve
	collapse (mean) temp1, by(permno) // temp1 is placeholder, goal is to get permnos
	/*bys permno: egen P_ffi=mode(ffi), maxmode	*/
	/* * Get cumulative asset growth change
	collapse (mean) P_mv=MV P_ebitda_t=ebitda P_saleq_t=saleq (firstnm) P_ffi, by(permno)
	gen lmv=log(P_mv) */
	gen P_year_cat = "`num'" 
	gen end_year=`year_end' 
	gen minobs=`minobs'
	tempfile base
	save `base'
	restore
	
	*** Second step: forloop to create the coeffs
	preserve
	display "**** Loop Year = `num' ****"
	levelsof permno, local(pfirm) 
	foreach outcome in `outcome_vars' {
	cap drop P_coeff P_se
	gen P_coeff=.
	gen P_se=.
	 foreach l of local pfirm {
	 	di "`l'"
		qui reghdfe shock_hf_`outcome' `shock' if permno == `l', noabsorb vce(cluster daten) 
		qui replace P_coeff=_b[`shock'] if permno == `l'
		qui replace P_se=_se[`shock'] if permno == `l'
	}
	rename P_coeff Pcoeff_`outcome'`t'
	rename P_se Pse_`outcome'`t'
	}
	egen Ptag=tag(permno)
	keep if Ptag==1
	keep permno Pcoeff* Pse*
	merge 1:1 permno using `base', nogen
	save `base', replace
	restore
	
	use `base', clear
	append using `tempcfs'
	cap drop bogus
	save `tempcfs', replace
}
end

*(1)
coeff_estimator_hf `" "1994 2008" "2009 2019" "1994 2000" "2013 2019" "' "30min" ///
50 "drop if missing(shock_hf_1hour_dollar)" "mp_klms" "master_daily_fomc_days"
tempfile coeff_hf_atif_REFS
save `coeff_hf_atif_REFS', replace 

/*save "$proc/coeff_hf_atif_REFS.dta", replace*/ // identical to old but faster to run

use "$proc_analysis/DU_temp_FD", clear 
preserve 
gen P_year_cat = "1994 2000" if year >= 1994 & year <= 2000 
replace P_year_cat = "2013 2019" if year >= 2013 & year <= 2019 
drop if missing(P_year_cat)
collapse (mean) ptile, by(permno P_year_cat)
tempfile shortpd 
save `shortpd'
restore 
gen P_year_cat = "1994 2008" if year >= 1994 & year <= 2008 
replace P_year_cat = "2009 2019" if year >= 2009 & year <= 2019 
drop if missing(P_year_cat)
collapse (mean) ptile, by(permno P_year_cat)
append using `shortpd'

merge 1:1 permno P_year_cat using `coeff_hf_atif_REFS' /*"$proc/coeff_hf_atif_REFS.dta"*/, keep(matched)

*long pds [The regression in the Stata screenshot] 
preserve
keep if P_year_cat == "1994 2008" | P_year_cat == "2009 2019"
gen post = P_year_cat == "2009 2019"
gen temp22 = ptile * post

reghdfe Pcoeff_30min post ptile temp22, absorb(permno) vce(cluster permno) // ! 
restore 

*short pds 
preserve 
keep if P_year_cat == "1994 2000" | P_year_cat == "2013 2019"
gen post = P_year_cat ==  "2013 2019"
gen temp22 = ptile * post

reghdfe Pcoeff_30min post ptile temp22, absorb(permno) vce(cluster permno) // !
restore 

**** Three-panel table. 
*(2a) 
cap estimates drop * 
cap eststo clear 

cap program drop pval_adder 
program define pval_adder 
args xvar 
	
scalar tv   = _b[`xvar']/_se[`xvar']
scalar pscalar = 1 - ttail(e(df_r), tv)
matrix pval = J(1,1, pscalar)
matrix colnames pval = `xvar'
estadd matrix pval
end


use "$proc/FOMC_Bauer_Swanson_proc.dta", clear 
replace MPS = MPS*10 // for scaling in line with KLMS 

gen P_year_cat = "1994 2008" if year >= 1994 & year <= 2008 
replace P_year_cat = "2009 2019" if year >= 2009 & year <= 2019 
/*1*/ reg SP500 MPS if P_year_cat == "1994 2008", r
pval_adder MPS 
eststo p1
/*2*/ reg SP500 MPS if P_year_cat == "2009 2019", r
pval_adder MPS 
eststo p2
	gen post = P_year_cat == "2009 2019"
	gen MPSpost = MPS * post 
	gen temp1 = MPS 
	replace MPS = MPSpost // MPS now interaction term 
/*3*/ reg SP500 temp1 post MPS, r
pval_adder MPS 
eststo p3
	replace MPS = temp1 // back to normal 
	
drop P_year_cat post MPSpost temp1
gen P_year_cat = "1994 2000" if year >= 1994 & year <= 2000 
replace P_year_cat = "2013 2019" if year >= 2013 & year <= 2019 
drop if missing(P_year_cat)
/*4*/ reg SP500 MPS if P_year_cat == "1994 2000", r
pval_adder MPS 
eststo p4
/*5*/ reg SP500 MPS if P_year_cat == "2013 2019", r
pval_adder MPS 
eststo p5
	gen post = P_year_cat == "2013 2019"
	gen MPSpost = MPS * post 
	gen temp1 = MPS 
	replace MPS = MPSpost // MPS now interaction term 
/*6*/ reg SP500 temp1 post MPS, r	
pval_adder MPS 
eststo p6

label var MPS "$\hat{D}$"
esttab p* using "$output_tab\rd2_reports\old_panel_BauSwa.tex", ///
se label drop(temp1 post _cons) nonumbers starlevels( * 0.10 ** 0.05 *** 0.010) ///
       cells(b(fmt(2) star pvalue(pval)) se(fmt(2) par pattern(1 1 0 1 1 0)) & pval(fmt(3) par([ ]) pattern(0 0 1 0 0 1))) ///
       nomtitles fragment replace collabels(none) stats(N, labels("N") fmt(%9.0f)) ///
prehead(`"\centering"' `"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"' `"\begin{tabular}{l*{3}{c}@{\hspace{2cm}}*{3}{c}} \hline\hline &\multicolumn{1}{c}{\textbf{High Rate}}&\multicolumn{1}{c}{\textbf{Low Rate}}&\multicolumn{1}{@{\hspace{-1.5cm}}c}{\textbf{Difference}}&\multicolumn{1}{c}{\textbf{High Rate}}&\multicolumn{1}{c}{\textbf{Low Rate}}&\multicolumn{1}{c}{\textbf{Difference}} \\\ &\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{@{\hspace{-1.5cm}}c}{\textbf{}}&\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{c}{\textbf{}} \\\ &\multicolumn{1}{c}{1994-2008}&\multicolumn{1}{c}{2009-2019}&\multicolumn{1}{@{\hspace{-1.5cm}}c}{}&\multicolumn{1}{c}{1994-2000}&\multicolumn{1}{c}{2013-2019}&\multicolumn{1}{c}{} \\"') ///
posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Bauer/Swanson SP500 on MPS}} \\\\[-1ex]")	   

*(2b)
cap estimates drop * 
cap eststo clear 

use "$proc/FOMC_Bauer_Swanson_proc.dta", clear 
replace MPS = MPS*10 // for scaling in line with KLMS 
drop if Unscheduled == 1

gen P_year_cat = "1994 2008" if year >= 1994 & year <= 2008 
replace P_year_cat = "2009 2019" if year >= 2009 & year <= 2019 
/*1*/ reg SP500 MPS if P_year_cat == "1994 2008", r
pval_adder MPS 
eststo p1
/*2*/ reg SP500 MPS if P_year_cat == "2009 2019", r
pval_adder MPS 
eststo p2
	gen post = P_year_cat == "2009 2019"
	gen MPSpost = MPS * post 
	gen temp1 = MPS 
	replace MPS = MPSpost // MPS now interaction term 
/*3*/ reg SP500 temp1 post MPS, r
pval_adder MPS 
eststo p3
	replace MPS = temp1 // back to normal 
	
drop P_year_cat post MPSpost temp1
gen P_year_cat = "1994 2000" if year >= 1994 & year <= 2000 
replace P_year_cat = "2013 2019" if year >= 2013 & year <= 2019 
drop if missing(P_year_cat)
/*4*/ reg SP500 MPS if P_year_cat == "1994 2000", r
pval_adder MPS 
eststo p4
/*5*/ reg SP500 MPS if P_year_cat == "2013 2019", r
pval_adder MPS 
eststo p5
	gen post = P_year_cat == "2013 2019"
	gen MPSpost = MPS * post 
	gen temp1 = MPS 
	replace MPS = MPSpost // MPS now interaction term 
/*6*/ reg SP500 temp1 post MPS, r	
pval_adder MPS 
eststo p6

label var MPS "$\hat{D}$"
esttab p* using "$output_tab\rd2_reports\old_panel_BauSwa.tex", ///
se label drop(temp1 post _cons) nonumbers starlevels( * 0.10 ** 0.05 *** 0.010) ///
       cells(b(fmt(2) star pvalue(pval)) se(fmt(2) par pattern(1 1 0 1 1 0)) & pval(fmt(3) par([ ]) pattern(0 0 1 0 0 1))) ///
       nomtitles fragment append collabels(none) stats(N, labels("N") fmt(%9.0f)) wrap posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Bauer/Swanson SP500 on MPS, Drop Unsched.}} \\\\[-1ex]")

*(2c)
cap estimates drop * 
cap eststo clear 

cap program drop btstrp_adder 
program define btstrp_adder 
args xvar SEname Pname  
	
matrix ses = `SEname'
matrix colnames ses = `xvar'
estadd matrix ses
matrix pval = `Pname'
matrix colnames pval = `xvar'
estadd matrix pval
end

cap program drop bootstrap_extract_complex
program define bootstrap_extract_complex, rclass
args var P_year_cat type dataset 
preserve

use "`dataset'", clear

keep if outcome == "`var'" & P_year_cat == "`P_year_cat'" & type == "`type'"
mean value
restore
end

*se long pd
local oldmain_btstrp_data "${temp_original}/bootstrap_se_minobs50.dta"
bootstrap_extract_complex "shock_hf_30min" "1994 2008" "se" "`oldmain_btstrp_data'"
matrix SE9408 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2009 2019" "se" "`oldmain_btstrp_data'"
matrix SE0919 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2008" "se" "`oldmain_btstrp_data'"
matrix SE9408_diff = e(b)[1, 1]
*pval long pd 
bootstrap_extract_complex "shock_hf_30min" "1994 2008" "pval" "`oldmain_btstrp_data'"
matrix P9408 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2009 2019" "pval" "`oldmain_btstrp_data'"
matrix P0919 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2008" "pval" "`oldmain_btstrp_data'"
matrix P9408_diff = e(b)[1, 1]

*se long pd
bootstrap_extract_complex "shock_hf_30min" "1994 2000" "se" "`oldmain_btstrp_data'"
matrix SE9400 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2013 2019" "se" "`oldmain_btstrp_data'"
matrix SE1319 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2000" "se" "`oldmain_btstrp_data'"
matrix SE9400_diff = e(b)[1, 1]
*pval long pd 
bootstrap_extract_complex "shock_hf_30min" "1994 2000" "pval" "`oldmain_btstrp_data'"
matrix P9400 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2013 2019" "pval" "`oldmain_btstrp_data'"
matrix P1319 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2000" "pval" "`oldmain_btstrp_data'"
matrix P9400_diff = e(b)[1, 1]


use "$proc/coeff_hf_atif_REFS.dta", clear 
gen post = 1 
/*1*/ reg Pcoeff_30min post if P_year_cat == "1994 2008", nocons r 
btstrp_adder post SE9408 P9408
eststo p1
/*2*/ reg Pcoeff_30min post if P_year_cat == "2009 2019", nocons r
btstrp_adder post SE0919 P0919
eststo p2
keep if P_year_cat == "1994 2008" |  P_year_cat == "2009 2019"
replace post = P_year_cat == "2009 2019"
/*3*/ reg Pcoeff_30min post,  r
btstrp_adder post SE9408_diff P9408_diff
eststo p3

use "$proc/coeff_hf_atif_REFS.dta", clear 
gen post = 1 
/*4*/ reg Pcoeff_30min post if P_year_cat == "1994 2000", nocons r 
btstrp_adder post SE9400 P9400
eststo p4
/*5*/ reg Pcoeff_30min post if P_year_cat == "2013 2019", nocons r
btstrp_adder post SE1319 P1319
eststo p5
keep if P_year_cat == "1994 2000" |  P_year_cat == "2013 2019"
replace post = P_year_cat == "2013 2019"
/*6*/ reg Pcoeff_30min post, r
btstrp_adder post SE9400_diff P9400_diff
eststo p6

label var post "$\hat{D}$"

*old
esttab p* using "$output_tab\rd2_reports\old_panel_BauSwa.tex", ///
se label drop(_cons) nonumbers starlevels( * 0.10 ** 0.05 *** 0.010) ///
       cells(b(fmt(2) star pvalue(pval)) ses(fmt(2) par pattern(1 1 0 1 1 0)) & pval(fmt(3) par([ ]) pattern(0 0 1 0 0 1))) ///
       nomtitles fragment append collabels(none) stats(N, labels("N") fmt(%9.0f)) wrap posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel C: KLMS Average Duration}} \\\\[-1ex]") ///
postfoot("\hline \hline \multicolumn{7}{l}{\footnotesize Standard errors in parentheses; P-values in square brackets}\\\multicolumn{7}{l}{\footnotesize \sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)}\\ \end{tabular}")	   

*(3) "spdiffklms" results
****One-panel table with the average duration here 	
*get coeffs 
coeff_estimator_hf `" "1994 2008" "2009 2019" "1994 2000" "2013 2019" "' "30min" ///
50 "" "mp_klms" "SP_diff_klms_returns"
save "$proc/coeff_hf_atif_REFS_SPdiffKLMS.dta", replace // identical to old but faster to run

//for bootstrap, run bootstrap_duration_cluster_spdiffklms at  
// round2_response\bootstrap_calculation_new\bootstrap_duration_cluster_pys, then 
// boostrap_aggregator_sep2024_specs at round2_response\bootstrap_calculation_new

*Panel table
*se long pd
cap matrix drop SE* P*
local spdklms_btstrp_data "$original_folder\temp\bootstrap_se_minobs50_spdiffklms.dta"
bootstrap_extract_complex "shock_hf_30min" "1994 2008" "se" "`spdklms_btstrp_data'"
matrix SE9408 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2009 2019" "se" "`spdklms_btstrp_data'"
matrix SE0919 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2008" "se" "`spdklms_btstrp_data'"
matrix SE9408_diff = e(b)[1, 1]
*pval long pd 
bootstrap_extract_complex "shock_hf_30min" "1994 2008" "pval" "`spdklms_btstrp_data'"
matrix P9408 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2009 2019" "pval" "`spdklms_btstrp_data'"
matrix P0919 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2008" "pval" "`spdklms_btstrp_data'"
matrix P9408_diff = e(b)[1, 1]

*se long pd
bootstrap_extract_complex "shock_hf_30min" "1994 2000" "se" "`spdklms_btstrp_data'"
matrix SE9400 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2013 2019" "se" "`spdklms_btstrp_data'"
matrix SE1319 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2000" "se" "`spdklms_btstrp_data'"
matrix SE9400_diff = e(b)[1, 1]
*pval long pd 
bootstrap_extract_complex "shock_hf_30min" "1994 2000" "pval" "`spdklms_btstrp_data'"
matrix P9400 = e(b)[1, 1]
bootstrap_extract_complex "shock_hf_30min" "2013 2019" "pval" "`spdklms_btstrp_data'"
matrix P1319 = e(b)[1, 1]
bootstrap_extract_complex "diff_shock_hf_30min" "1994 2000" "pval" "`spdklms_btstrp_data'"
matrix P9400_diff = e(b)[1, 1]

cap estimates drop *
cap eststo clear 
use "$proc/coeff_hf_atif_REFS_SPdiffKLMS.dta", clear 
gen post = 1 
/*1*/ reg Pcoeff_30min post if P_year_cat == "1994 2008", nocons r 
btstrp_adder post SE9408 P9408
eststo p1
/*2*/ reg Pcoeff_30min post if P_year_cat == "2009 2019", nocons r
btstrp_adder post SE0919 P0919
eststo p2
keep if P_year_cat == "1994 2008" |  P_year_cat == "2009 2019"
replace post = P_year_cat == "2009 2019"
/*3*/ reg Pcoeff_30min post,  r
btstrp_adder post SE9408_diff P9408_diff
eststo p3

use "$proc/coeff_hf_atif_REFS_SPdiffKLMS.dta", clear  
gen post = 1 
/*4*/ reg Pcoeff_30min post if P_year_cat == "1994 2000", nocons r 
btstrp_adder post SE9400 P9400
eststo p4
/*5*/ reg Pcoeff_30min post if P_year_cat == "2013 2019", nocons r
btstrp_adder post SE1319 P1319
eststo p5
keep if P_year_cat == "1994 2000" |  P_year_cat == "2013 2019"
replace post = P_year_cat == "2013 2019"
/*6*/ reg Pcoeff_30min post, r
btstrp_adder post SE9400_diff P9400_diff
eststo p6

label var post "$\hat{D}$"
esttab p*, se label

esttab p* using "$output_tab\rd2_reports\spdiff_klms_panel.tex", ///
se label drop(_cons) nonumbers starlevels( * 0.10 ** 0.05 *** 0.010) ///
       cells(b(fmt(2) star pvalue(pval)) ses(fmt(2) par pattern(1 1 0 1 1 0)) & pval(fmt(3) par([ ]) pattern(0 0 1 0 0 1))) ///
       nomtitles collabels(none) stats(N, labels("N") fmt(%9.0f)) fragment replace ///
prehead(`"\centering"' `"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"' `"\begin{tabular}{l*{3}{c}@{\hspace{2cm}}*{3}{c}} \hline\hline &\multicolumn{1}{c}{\textbf{High Rate}}&\multicolumn{1}{c}{\textbf{Low Rate}}&\multicolumn{1}{@{\hspace{-1.5cm}}c}{\textbf{Difference}}&\multicolumn{1}{c}{\textbf{High Rate}}&\multicolumn{1}{c}{\textbf{Low Rate}}&\multicolumn{1}{c}{\textbf{Difference}} \\\ &\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{@{\hspace{-1.5cm}}c}{\textbf{}}&\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{c}{\textbf{Period}}&\multicolumn{1}{c}{\textbf{}} \\\ &\multicolumn{1}{c}{1994-2008}&\multicolumn{1}{c}{2009-2019}&\multicolumn{1}{@{\hspace{-1.5cm}}c}{}&\multicolumn{1}{c}{1994-2000}&\multicolumn{1}{c}{2013-2019}&\multicolumn{1}{c}{} \\"') ///
posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: SP500 minus KLMS Avg HF Duration on Bau/Swa MPS}} \\\\[-1ex]")	///
postfoot("\hline \hline \multicolumn{7}{l}{\footnotesize Standard errors in parentheses; P-values in square brackets}\\\multicolumn{7}{l}{\footnotesize \sym{*} \(p<0.10\), \sym{**} \(p<0.05\), \sym{***} \(p<0.01\)}\\ \end{tabular}")	   

*/



	
/*
use "${temp}/SP_diff_klms_sample.dta", clear 
drop if missing(ffi)

gen indic_fin = ffi == 45 | ffi == 46 | ffi == 47 | ffi == 48
bysort daydate: egen date_prop_fin = mean(indic_fin)

keep daydate date_prop_fin 
duplicates drop 
summarize date_prop_fin

format daydate %td
tw (line date_prop_fin daydate), title("Prop. Financial Firms: SP500 diff. KLMS")	
graph export "$output_fig/rd2_reports/finshare_spdiffklms__over_time.pdf", replace 	
*/

	

	
	
/* Trash ================			
			
			
	/*
	*()		Try main table with weights -- Looks very good. 
	use "$proc_analysis/maintable_data", clear 

		*Try main result with weights 
		gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
		bysort Fdecile_consis: egen num_decile = count(indic_reg)
		gen w = 1/num_decile	

	cap estimates drop * 
	cap eststo clear 	
	*baseline 
	areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1 [aw=w], cluster(daten) absorb(permno)
	eststo p0 
	estadd local FE "Firm"
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspost post if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klms_U mp_klmspostZLB mp_klmspostnonZLB postZLB postnonZLB if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klms_U mp_klmsFptile Fptile if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	
	*
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 [aw=w], cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"		
	
	*
	areg shock_hf_30min mp_klmsFptilepostZLB mp_klmspostZLB postZLB mp_klmsFptilepostnonZLB mp_klmspostnonZLB postnonZLB mp_klmsFptile mp_klms_U  if unscheduled_meetings!=1 [aw=w],cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	
	esttab p*, label se 	
	*/ 	
		
		
		
				
*/* Better window length table: Needs to be interacted throughout. 

*(1) New simpler window length table. FINAL
use "$proc_analysis/maintable_data", clear 	
	
	cap estimates drop * 
	cap eststo clear 	
	
	label var window_shock_hf_30min "$\text{Window Length}_{it}$"
	label var WLxSHOCK "$\text{Window Length}_{it} * \omega_t$"
	
	*making every variable interacted with WLxSHOCK too 
	foreach var in mp_klmsFptilepost mp_klmsFptile mp_klmspost {
		gen INT`var' = window_shock_hf_30min * `var'
	}
	
	*Baseline main result
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p1
	estadd local FE "Firm"	
	estadd local notes "Baseline"
	estadd local percentile_cutoff 
	
	*Window control
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post window_shock_hf_30min WLxSHOCK INT* if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p2
	estadd local FE "Firm"	
	estadd local notes "Window Control"	
	
	*ZLB nonZLB 
	*making every variable interacted with WLxSHOCK too 
	foreach var in mp_klmsFptilepostZLB mp_klmspostZLB mp_klmsFptilepostnonZLB mp_klmspostnonZLB {
		gen INT`var' = window_shock_hf_30min * `var'
	}	
	areg shock_hf_30min mp_klmsFptilepostZLB mp_klmspostZLB postZLB mp_klmsFptilepostnonZLB mp_klmspostnonZLB postnonZLB mp_klmsFptile mp_klms_U ///
	Fptile_postZLB Fptile_postnonZLB INTmp_klmsFptilepostZLB INTmp_klmspostZLB INTmp_klmsFptilepostnonZLB INTmp_klmspostnonZLB ///
	if unscheduled_meetings!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"		
	
	*90th percentile window length
	sum window_shock_hf_30min, d
	local p90 = r(p90)
	disp "90th percentile (it): `p90'"
	gen overp90 = window_shock_hf_30min > `p90'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p3
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90"	
	estadd local percentile_cutoff `p90'
	
	*75th percentile window length
	sum window_shock_hf_30min, d
	local p75 = r(p75)
	disp "75th percentile (it): `p75'"
	gen overp75 = window_shock_hf_30min > `p75'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp75!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p75"	
	estadd local percentile_cutoff	`p75'		
	
	
	*50th percentile window length
	sum window_shock_hf_30min, d
	local p50 = r(p50)
	disp "50th percentile (it): `p50'"
	gen overp50 = window_shock_hf_30min > `p50'	
	
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp50!=1,cluster(daten) absorb(permno) 
	eststo p5
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p50"	
	estadd local percentile_cutoff	`p50'		
	
	esttab p*, label se drop(INT*)
*/ 

	/*
	*() NOW NO WEIGHTING -- COMPARE [Drop above p90]
	preserve 
	sum window_shock_hf_30min, d
	local p90 = r(p90)
	disp "90th percentile (it): `p90'"
	gen overp90 = window_shock_hf_30min > `p90'	

	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	bysort Fdecile_consis: egen num_decile = count(indic_reg)
	gen w = 1/num_decile
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p90, wtd"	
	estadd local percentile_cutoff	`p90'	
	restore 

	*() NOW NO WEIGHTING -- COMPARE [Drop above p80]
	preserve 
	pctile pc = window_shock_hf_30min, nq(10)
	local p80 = pc[8]
	disp "80th percentile (it): `p80'"
	gen overp90 = window_shock_hf_30min > `p80'	

	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	bysort Fdecile_consis: egen num_decile = count(indic_reg)
	gen w = 1/num_decile
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90!=1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p80, wtd"	
	estadd local percentile_cutoff	`p80'	
	restore 	
	
	*() NOW NO WEIGHTING -- COMPARE // Keep only middle half of shocks 
	preserve 
	sum window_shock_hf_30min, d
	local p25 = r(p25)
	gen overp90 = window_shock_hf_30min > `p25'	
	local p75 = r(p75) 
	gen underp = window_shock_hf_30min < `p75'		

	gen indic_reg = !missing(mp_klms_U) & !missing(shock_hf_30min)
	bysort Fdecile_consis: egen num_decile = count(indic_reg)
	gen w = 1/num_decile
	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90==1 & underp==1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p50, wtd"	
	estadd local percentile_cutoff	`p50'	
	restore 		
	
	*()  NOW NO WEIGHTING -- COMPARE // Keep only longer half of shocks  
	preserve 
	sum window_shock_hf_30min, d
	local p50 = r(p50)
	disp "50th percentile (it): `p50'"
	gen overp90 = window_shock_hf_30min > `p50'	

	areg shock_hf_30min mp_klmsFptilepost mp_klmsFptile mp_klmspost /**/ /*Fptilepost*/ /**/ mp_klms_U post if unscheduled_meetings!=1 & overp90==1,cluster(daten) absorb(permno) 
	eststo p4
	estadd local FE "Firm"	
	estadd local notes "Drop WL $>$ p50, wtd"	
	estadd local percentile_cutoff	`p50'	
	restore 		
	*/	
		
		
		
	Try stuff: rolling window 
	
	
	local roll_length_true 2
	local rollnum = `roll_length_true' - 1
	use "$proc_analysis/DU_temp_FD.dta", clear 

	gen coef1=.
	gen se1=.
	egen ytag=tag(year)
		local endyear = 2024 - `rollnum'
	forvalues i=1994/`endyear' {
	areg shock_hf_30min mp_klms_U if unscheduled_meetings!=1 & year>=`i' & year<=`i'+`rollnum' ,cluster(daten) absorb(permno)
	replace coef1=_b[mp_klms_U] if year==`i'+`rollnum'
	replace se1=_se[mp_klms_U] if year==`i'+`rollnum'
	}
	gen lb = coef1 - se1 
	gen ub = coef1 + se1
	graph twoway (rcap ub lb year, lcolor(gray) lpattern(dash)) (scatter coef1 year,  mcolor(black) msymbol(diamond)) if ytag==1, yline(0, lpattern(dash)) ytitle("D{subscript:t}") title("Rolling `roll_length_true'Y coeffs. using scheduled only") xtitle("") legend(off) xscale(r(1995 2025)) xlabel(1995(5)2025) // nice rolling avg	
		
		
		
		
		