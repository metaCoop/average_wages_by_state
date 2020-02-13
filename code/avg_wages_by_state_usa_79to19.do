/*calculate wage bins and average wages of the bottom 20%, middle 60% and
* top 20% for various years */

global base R:\new_R_drive_structure\users\dcooper\Stata\average_wages_by_state\
global output ${base}output\
global logs ${base}logs\
global exdata ${output}avg_wage_by_state_usa_79_19.xlsx

cd R:\new_R_drive_structure\users\dcooper\Stata\average_wages_by_state
capture log close
log using ${logs}avg_wage_log79to19w_usa.txt, text replace
set more off
numlabel, add

clear all

load_epiextracts, begin(1979m1) end(2019m12) sample(org) ///
	keep(year wage orgwgt statefips statecensus)
	
	keep if wage > 0 & wage != .

sort year

tempfile orgdata
save `orgdata'

/*Calculate national percentiles and merge back to data*/
binipolate wage if wage > 0 & wage ~= . [pw=orgwgt], binsize(0.25) ///
 percentiles(20 80) by(year)
 
 rename wage_binned p_binned
 reshape wide p*_binned, i(year) j(percentile)
 
 rename p_binned* us_p*_binned
 
 keep year us_p*_binned
 
 tempfile uscuts
 save `uscuts'
 
 merge 1:m year using `orgdata'

 gen us_wage_cat=.
 replace us_wage_cat=1 if wage<us_p20_binned
 replace us_wage_cat=2 if us_p20_binned<=wage & wage<=us_p80_binned
 replace us_wage_cat=3 if wage>us_p80_binned
 
 drop _merge
 
 save `orgdata', replace
 
 /*Calculate state level percentiles and merge back to data*/
 
 sort year statecensus
 
 binipolate wage if wage > 0 & wage ~= . [pw=orgwgt], binsize(0.25) ///
 percentiles(20 80) by(year statecensus)
 
  rename wage_binned p_binned
 reshape wide p*_binned, i(year statecensus) j(percentile)
 
 rename p_binned* st_p*_binned
 
 keep year statecensus st_p*_binned
 
 tempfile stcuts
 save `stcuts'
 
 merge 1:m year statecensus using `orgdata'

 gen st_wage_cat=.
 replace st_wage_cat=1 if wage<st_p20_binned
 replace st_wage_cat=2 if st_p20_binned<=wage & wage<=st_p80_binned
 replace st_wage_cat=3 if wage>st_p80_binned
 
 drop _merge
 
 save `orgdata', replace
 
 /*Calculate average wage of bottom 20% nationally */
  sort year
  
  gcollapse (mean) bottom_wage=wage if us_wage_cat==1 [pw=orgwgt], /// 
	by (year)
	
  gen statecensus=0
  
  reshape wide bottom_wage, i(statecensus) j(year)
  
  tempfile usbottom
  save `usbottom'
  
  /*Calculate average wage of bottom 20% by state and append national data */
  use `orgdata'
 sort year statecensus 
 
 gcollapse (mean) bottom_wage=wage if st_wage_cat==1 [pw=orgwgt], /// 
	by (year statecensus)
	
	reshape wide bottom_wage, i(statecensus) j(year)
	
	append using `usbottom'

 export excel using ${exdata}, sheet("Bottom") ///	
	firstrow(var) sheetreplace
	
	
   /*Calculate average wage of middle 60% nationally */
 clear
 use `orgdata'
  sort year
  
  gcollapse (mean) mid_wage=wage if us_wage_cat==2 [pw=orgwgt], /// 
	by (year)
	
  gen statecensus=0
  
  reshape wide mid_wage, i(statecensus) j(year)
  
  tempfile usmiddle
  save `usmiddle'

    /*Calculate average wage of middle 60% by state */
 clear
 use `orgdata'
 
 sort year statecensus
 
 gcollapse (mean) mid_wage=wage if st_wage_cat==2 [pw=orgwgt], /// 
	by (year statecensus)
	
	reshape wide mid_wage, i(statecensus) j(year)
	
	append using `usmiddle'

 export excel using ${exdata}, sheet("Middle") ///	
	firstrow(var) sheetreplace
	
  /*Calculate average wage of top 20% nationally */
 clear
 use `orgdata'
 
 sort year
 
 gcollapse (mean) top_wage=wage if us_wage_cat==3 [pw=orgwgt], /// 
	by (year)
	
	gen statecensus=0
	
	reshape wide top_wage, i(statecensus) j(year)
	
	  tempfile ustop
		save `ustop'
		
  /*Calculate average wage of top 20% by state */
 clear
 use `orgdata'
 
 sort year statecensus
 
 gcollapse (mean) top_wage=wage if st_wage_cat==3 [pw=orgwgt], /// 
	by (year statecensus)
	
	reshape wide top_wage, i(statecensus) j(year)
	
	append using `ustop'

	 export excel using ${exdata}, sheet("Top") ///	
	firstrow(var) sheetreplace

 log close
 exit

