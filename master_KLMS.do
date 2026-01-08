*Falling Rates and Rising Superstars
*July 28, 2025 
*master "do all" file 

version 19
clear all 
/* ========== SET PATH TO PROJECT FOLDER ROOT HERE ========== */
global folder "C:/Users/sb3357.SPI-9VS5N34/Princeton Dropbox/Sam Barnett/FRRS_rd2_replication" 
global folder "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication"
/* ========== SET PATH TO YOUR COMPUTER'S R EXECUTABLE HERE ========== */
global Rexe "C:/Program Files/R/R-4.4.1/bin/Rscript.exe"

display "Global folder: $folder"
global output "$folder/output"
global output_fig "$output/figures"
global output_tab "$output/tables"

global rawh "$folder/data/highfreq/raw"
global proch "$folder/data/highfreq/proc"

global rawq "${folder}/data/quarterly/raw"
global procq "${folder}/data/quarterly/proc"

global proc_analysis "$folder/data/proc_analysis"

global bootstrap_calculation "$folder/src/bootstrap_calculation"

global import_fred_snapshot "$folder/data/import_fred_snapshot"

sysdir set PERSONAL "${folder}/ado"
set scheme sol, perm

set fredkey "030dacac32647f169b142f30fcdab33a", permanently

*clear processed .dta, .csv data from proc_analysis, highfreq/proc, quarterly/proc, and bootstrap folder
// erase "${proch}\*.*"
// erase "${procq}\*.*"
// erase "${proc_analysis}\*.*"
// erase "$bootstrap_calculation/bootstrap_placebo.csv"
// erase "$bootstrap_calculation/master_daily_placebo_calculation_UPDATE.dta"

*clear output from all output folders 
shell del /s /q "$output\*"

*Python packages setup 
python:
import sys, subprocess
pkgs = ["numpy", "pandas", "scikit-learn", "scipy"]
subprocess.check_call([sys.executable, "-m", "pip", "install", *pkgs])
end

*get FRED and TAQ data (R scripts)
shell "$Rexe" "$folder\src\as_released_data_scriptFRED.R" "$rawq"
*shell "`Rexe'" "$folder\src\import_intraday_whole_year.R" "$rawh" /*multi-day runtime*/

*data construction 
do "$folder/src/data_construction_KLMS.do"
cap graph close 

*analysis 
*(a) bootstrap: gather bootstrap estimates of baseline for placebo figure 
cd "$bootstrap_calculation"
do "bootstrap_calculation.do"
cd "$folder"

*(b) figures/tables in main text and appendix
do "$folder/src/analysis_KLMS.do"
cap graph close 








