/*calculate wage bins and average wages of the bottom 20%, middle 60% and
* top 20% for various years */

cd R:\new_R_drive_structure\users\dcooper\Stata\average_wage_by_state
capture log close
log using "avg_wage_log.txt", text replace
set more off
numlabel, add

clear

load_epiextracts, begin(2017m1) end(2019m12) sample(org)

sort year statecensus

tempfile orgdata
save `orgdata'

binipolate wage if wage > 0 & wage ~= . [pw=orgwgt], binsize(0.25) ///
 percentiles(10 20 30 40 50 60 70 80 90) by(year statecensus)
 
 keep year statecensus p*_binned
 
 merge 1:m year statecensus using `orgdata'

 gen wagerange=.
 replace wagerange=1 if wage<p20_binned
 replace wagerange=2 if p20_binned<=wage & wage<=p80_binned
 replace wagerange=3 if wage>p80_binned
 
 save `orgdata', replace
 
 sort year statecensus 
 collapse (mean) bottom_wage=wage if wagerange==1 [pw=orgwgt], /// 
	by (year statecensus)

 tempfile bottom
 save `bottom'

 clear
 use `orgdata'
 
 collapse (mean) mid_wage=wage if wagerange==2 [pw=orgwgt], /// 
	by (year statecensus)

 tempfile middle
 save `middle'
 
 clear
 use `orgdata'
 
 collapse (mean) top_wage=wage if wagerange==1 [pw=orgwgt], /// 
	by (year statecensus)

 tempfile top
 save `top'
 
 merge 1:1 year statecensus using `middle'
 
 drop _merge
 
 merge 1:1 year statecensus using `bottom'
 
 drop _merge
 
 export excel using "avgs_17_19_byState.xlsx", firstrow replace
 
 log close
