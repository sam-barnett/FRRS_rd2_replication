do "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_code\src\setup_paths.do"

*(3) Dollar duration figure split by pre/post. =================================
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

	graph twoway (scatter coef3 Fdecile_consis if post==0, mcolor(red)) ///
	(scatter coef3 Fdecile_consis if post==1, mcolor(blue)) ///
	if FpPtag==1, title("\$ 30 min") leg(order(1 "1994-2006" 2 "2007-2024")) ytitle("{&beta}{subscript:1}") xtitle("Percentile")

	