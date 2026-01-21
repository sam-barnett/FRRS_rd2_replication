/*******************************************************************************
* RD3 TEMPORARY ANALYSIS FILE
* Purpose: Replicate main quarterly LP spec using 1994-2006 vs 2007-2024 divide
* Date: January 2026
*
* Key change: Replace continuous interest rate variable (l.target) with
*            post dummy (post=1 if year>=2007)
*******************************************************************************/

clear all
set more off
/*******************************************************************************
* LOCAL PROJECTION PLOTS: All 8 outcome variables
* Coefficients across horizons h=0,1,...,7 with 95% CIs
*******************************************************************************/

// Reload data for LP estimation
use "$proc_analysis/estdata_update_ptilec.dta", clear
keep if year >= 1994 & year <= 2024

// Recreate leader5 variable
cap drop leader5
gen leader5 = (ptile_consis_ind >= 0.95)

// remake post: 
cap drop post 
gen post = 0 
replace post = 1 if year >= 2007 & year <= 2021

// Recreate interaction variables
cap drop double_mp_klms_U_gk triple_mp_klms_U_gk Lileader leader_mcap
gen double_mp_klms_U_gk = c.mp_klms_U_gk#c.leader5
gen triple_mp_klms_U_gk = c.post#c.mp_klms_U_gk#c.leader5
gen Lileader = post*leader5
gen leader_mcap = leader5

// Set up for LP
local lag = 3
local type_mp "_gk"
local type ""

// Define outcome variables and their labels
local yvars "Lborrowing_cost2 Llog_assets Llog_ppe Llogrev Pcapxq Paqcq Llog_debt Lleverage"
local yvar_labels `" "Borrowing Cost" "Assets" "PPE" "Revenue" "CAPX" "Acquisitions" "Debt" "Leverage" "'

// Loop over all outcome variables
local ynum = 0
foreach yvar of local yvars {
	local ynum = `ynum' + 1
	local ylab : word `ynum' of `yvar_labels'

	// Define controls for LP (using lag of contemporaneous outcome)
	local controls l(1/`lag').`yvar'0`type' l(1/`lag').double_mp_klms_U`type_mp' l(1/`lag').triple_mp_klms_U`type_mp' l(1/`lag').leader_mcap l(1/`lag').Lileader

	// Initialize matrix for LP coefficients: rows = horizons+1, cols = 7
	// Col 1-3: double coef, upper CI, lower CI
	// Col 4-6: triple coef, upper CI, lower CI
	// Col 7: horizon
	cap matrix drop LPfill
	matrix LPfill = J(9, 7, .)

	// Set row 1 to zeros (for h=-1 baseline)
	matrix LPfill[1, 1] = 0
	matrix LPfill[1, 2] = 0
	matrix LPfill[1, 3] = 0
	matrix LPfill[1, 4] = 0
	matrix LPfill[1, 5] = 0
	matrix LPfill[1, 6] = 0
	matrix LPfill[1, 7] = 0

	// Run LP regressions for h=0 to 7
	forv ahead = 0/7 {
		cap reghdfe `yvar'`ahead'`type' double_mp_klms_U`type_mp' triple_mp_klms_U`type_mp' ///
			Lileader leader_mcap `controls' if quarter_d != ., ///
			absorb(industrytime) vce(cluster quarter_d)

		if _rc == 0 {
			// Store double interaction coefficients (MP × Leader)
			matrix LPfill[`ahead'+2, 1] = _b[double_mp_klms_U`type_mp']
			matrix LPfill[`ahead'+2, 2] = _b[double_mp_klms_U`type_mp'] + 1.96 * _se[double_mp_klms_U`type_mp']
			matrix LPfill[`ahead'+2, 3] = _b[double_mp_klms_U`type_mp'] - 1.96 * _se[double_mp_klms_U`type_mp']

			// Store triple interaction coefficients (POST × MP × Leader)
			matrix LPfill[`ahead'+2, 4] = _b[triple_mp_klms_U`type_mp']
			matrix LPfill[`ahead'+2, 5] = _b[triple_mp_klms_U`type_mp'] + 1.96 * _se[triple_mp_klms_U`type_mp']
			matrix LPfill[`ahead'+2, 6] = _b[triple_mp_klms_U`type_mp'] - 1.96 * _se[triple_mp_klms_U`type_mp']

			// Horizon counter
			matrix LPfill[`ahead'+2, 7] = `ahead' + 1
		}
	}

	// Preserve current data
	preserve

	// Convert matrix to dataset for plotting
	clear
	svmat LPfill
	rename (LPfill1 LPfill2 LPfill3 LPfill4 LPfill5 LPfill6 LPfill7) ///
		   (double_b double_u double_l triple_b triple_u triple_l horizon)

	// Plot double interaction (MP × Leader effect)
	tw (rarea double_u double_l horizon, color(blue%20)) ///
	   (line double_b horizon, lc(blue) lw(medium)), ///
	   yline(0, lc(black) lp(dash)) ///
	   ytitle("{&beta}", size(medium)) ///
	   xtitle("Quarters", size(medium)) ///
	   title("MP × Leader: `ylab'", size(medium)) ///
	   legend(off) ///
	   name(lp_double_`ynum', replace)

	// Plot triple interaction (POST × MP × Leader effect)
	tw (rarea triple_u triple_l horizon, color(red%20)) ///
	   (line triple_b horizon, lc(red) lw(medium)), ///
	   yline(0, lc(black) lp(dash)) ///
	   ytitle("{&beta}", size(medium)) ///
	   xtitle("Quarters", size(medium)) ///
	   title("POST × MP × Leader: `ylab'", size(medium)) ///
	   legend(off) ///
	   name(lp_triple_`ynum', replace)

	// Restore data for next iteration
	restore
}

// Combine all double interaction plots (4 rows x 2 cols)
graph combine lp_double_1 lp_double_2 lp_double_3 lp_double_4 ///
			  lp_double_5 lp_double_6 lp_double_7 lp_double_8, ///
	rows(4) cols(2) ///
	title("MP × Leader Effect Across Horizons", size(medium)) ///
	note("Shaded areas = 95% CIs. POST = 1 for 2007-2024.", size(small)) ///
	name(lp_all_double, replace)
graph display, xsize(8) ysize(12)

// Combine all triple interaction plots (4 rows x 2 cols)
graph combine lp_triple_1 lp_triple_2 lp_triple_3 lp_triple_4 ///
			  lp_triple_5 lp_triple_6 lp_triple_7 lp_triple_8, ///
	rows(4) cols(2) ///
	title("POST × MP × Leader Effect Across Horizons", size(medium)) ///
	note("Shaded areas = 95% CIs. POST = 1 for 2007-2024.", size(small)) ///
	name(lp_all_triple, replace)
graph display, xsize(8) ysize(12)

// Final combined plot: all 16 panels (double on left, triple on right)
graph combine lp_all_double lp_all_triple, ///
	cols(2) ///
	title("Local Projections: All Outcomes", size(medium)) ///
	note("Left: MP × Leader. Right: POST × MP × Leader. Shaded = 95% CIs.", size(small)) ///
	name(lp_all_combined, replace)
graph display, xsize(14) ysize(12)






