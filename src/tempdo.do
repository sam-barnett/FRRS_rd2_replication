do "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_code\src\setup_paths.do"

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
	
	/* twoway (rcap ub lb log_mat mat, lcolor(gray) lpattern(dash))  */


	twoway (rcap ub lb /*log_mat*/ mat, lcolor(gray) lpattern(dash)) ///
	       (scatter coef /*log_mat*/mat, mcolor(black)), ///
	       leg(off) xscale(log) xlabel(30 "30" 90 "90" 365 "365" 1095 "1095" 3650 "3650" 10950 "10950") ///
		   xtitle("Maturity length, days (log scale)") ytitle("High-frequency response of yield curve to {&omega}") ///
		   title("Full 1994-2024 sample, drop unscheduled")