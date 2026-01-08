*Falling Rates and Rising Superstars
*July 28, 2025 
*master "do all" file 

version 19
clear all 
/* ========== SET PATHS HERE ========== */
global code_folder "C:/Users/sb3357.SPI-9VS5N34/Princeton Dropbox/Sam Barnett/FRRS_rd2_replication/FRRS_code"
global code_folder "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_code"
global data_folder "C:\Users\sb3357.SPI-9VS5N34\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_data\data"
global data_folder "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_data\data\data"
/* ========== SET PATH TO YOUR COMPUTER'S R EXECUTABLE HERE ========== */
global Rexe "C:/Program Files/R/R-4.4.1/bin/Rscript.exe"

display "Code folder: $code_folder"
display "Data folder: $data_folder"
global output "$code_folder/output"
global output_fig "$output/figures"
global output_tab "$output/tables"

global rawh "$data_folder/highfreq/raw"
global proch "$data_folder/highfreq/proc"

global rawq "$data_folder/quarterly/raw"
global procq "$data_folder/quarterly/proc"

global proc_analysis "$data_folder/proc_analysis"

global bootstrap_calculation "$code_folder/src/bootstrap_calculation"
global bootstrap_data "$data_folder/bootstrap"

global import_fred_snapshot "$data_folder/import_fred_snapshot"

sysdir set PERSONAL "$code_folder/ado"
set scheme sol, perm

set fredkey "030dacac32647f169b142f30fcdab33a", permanently

*clear processed .dta, .csv data from proc_analysis, highfreq/proc, quarterly/proc, and bootstrap folder
// erase "${proch}\*.*"
// erase "${procq}\*.*"
// erase "${proc_analysis}\*.*"
// erase "$bootstrap_data/bootstrap_placebo.csv"
// erase "$bootstrap_data/master_daily_placebo_calculation_UPDATE.dta"

*clear output from all output folders 
shell del /s /q "$output\*"

*Python packages setup 
python:
import sys, subprocess
pkgs = ["numpy", "pandas", "scikit-learn", "scipy"]
subprocess.check_call([sys.executable, "-m", "pip", "install", *pkgs])
end

*get FRED and TAQ data (R scripts)
shell "$Rexe" "$code_folder\src\as_released_data_scriptFRED.R" "$rawq"
*shell "`Rexe'" "$code_folder\src\import_intraday_whole_year.R" "$rawh" /*multi-day runtime*/

*data construction
do "$code_folder/src/data_construction_KLMS.do"
cap graph close

*analysis
*(a) bootstrap: gather bootstrap estimates of baseline for placebo figure
cd "$bootstrap_calculation"
do "bootstrap_calculation.do"
cd "$code_folder"

*(b) figures/tables in main text and appendix
do "$code_folder/src/analysis_KLMS.do"
cap graph close 








