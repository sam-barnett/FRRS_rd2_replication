/*******************************************************************************
* RD3 TEMPORARY DATA CONSTRUCTION FILE
* Purpose: Documentation for RD3 pre/post-2008 analysis
* Date: January 2026
*
* NOTE: The main quarterly dataset already contains the POST variable we need.
*       This file documents the key variable definition for RD3 analysis.
*******************************************************************************/

/*******************************************************************************
* KEY VARIABLE: POST DUMMY
*
* The POST variable is already created in data_construction_KLMS.do:
*   gen post = year > 2006
*   replace post = 0 if year <= 2006
*
* This creates:
*   post = 0 for years 1994-2006 (PRE period)
*   post = 1 for years 2007-2024 (POST period)
*
* RATIONALE FOR 2007 SPLIT:
* - 2007 marks beginning of Financial Crisis
* - Beginning of extended low interest rate environment
* - Clear structural break in interest rate regime
* - Addresses referee concerns about ad-hoc period definitions
*******************************************************************************/

/*******************************************************************************
* COMPARISON TO ORIGINAL SPECIFICATION:
*
* Original (RD2) specification used continuous interest rate:
*   triple = l.target × mp × leader
*   Lileader = l.target × leader
*
* New (RD3) specification uses POST dummy:
*   triple = post × mp × leader
*   Lileader = post × leader
*
* ADVANTAGES:
* 1. Clean pre/post split (not ad-hoc)
* 2. Avoids issues with recent high nominal rates post-COVID
* 3. Tests whether differential effects exist in crisis/ZLB era
* 4. Addresses Referee 4's concern about rate definition
* 5. More robust to specification changes
*******************************************************************************/

/*******************************************************************************
* NO ADDITIONAL DATA CONSTRUCTION NEEDED
*
* The quarterly dataset already contains:
* - post variable (1994-2006 vs 2007-2024)
* - All outcome variables (borrowing_cost, assets, PPE, revenue, etc.)
* - Leader definitions (leader5 = top 5% by market cap)
* - Monetary policy shocks (mp_klms_U_gk)
* - Control variables (b_mkt, icr, BM, leverage, dd)
* - Industry×time fixed effects (industrytime)
*
* Simply load the existing quarterly dataset for analysis:
*   use "${folder}/dta_repo/quarterly_KLMS.dta", clear
*******************************************************************************/
