do "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_code\src\setup_paths.do"

*(2a) using mp_klms_U: rolling 6Y

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
	graph twoway (rcap ub lb year, lcolor(gray) lpattern(dash)) (scatter coef1 year,  mcolor(black) msymbol(diamond)) if ytag==1, yline(0, lpattern(dash)) ytitle("{&beta}{subscript:1}") /*title("Rolling 6Y coeffs. using scheduled only")*/ xtitle("") legend(off) xscale(r(1995 2025)) xlabel(1995(5)2025)
