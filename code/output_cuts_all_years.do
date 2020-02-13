/*calculate wage bins and average wages of the bottom 20%, middle 60% and
* top 20% for various years */

global base R:\new_R_drive_structure\users\dcooper\Stata\average_wages_by_state\
global output ${base}output\
global logs ${base}logs\
global exdata ${output}cuts79_19w95.xlsx

cd R:\new_R_drive_structure\users\dcooper\Stata\average_wages_by_state
capture log close
log using ${logs}cuts79_19w95.txt, text replace
set more off
numlabel, add

clear all

load_epiextracts, begin(1979m1) end(2019m12) sample(org) ///
	keep(year wage orgwgt statefips statecensus)
	
	keep if wage > 0 & wage != .

sort year

tempfile orgdata
save `orgdata'

/*Calculate national percentiles*/
binipolate wage if wage > 0 & wage ~= . [pw=orgwgt], binsize(0.25) ///
 percentiles(10 20 30 40 50 60 70 80 90 95) by(year)
 
 rename wage_binned p_binned
 reshape wide p*_binned, i(year) j(percentile)
 
 rename p_binned* us_p*_binned
 
 keep year us_p*_binned
 
 tempfile uscuts
 save `uscuts'
  
 /*Calculate state level percentiles*/
 use `orgdata'
 sort year statecensus
 
 binipolate wage if wage > 0 & wage ~= . [pw=orgwgt], binsize(0.25) ///
 percentiles(10 20 30 40 50 60 70 80 90 95) by(year statecensus)
 
  rename wage_binned p_binned
 reshape wide p*_binned, i(year statecensus) j(percentile)
 
 rename p_binned* st_p*_binned
 
 keep year statecensus st_p*_binned
 
 tempfile stcuts
 save `stcuts'
 
append using `uscuts'
 
 export excel using ${exdata}, sheet("Cuts") ///	
firstrow(var) sheetreplace

 log close
 exit

