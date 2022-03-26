
* Set up
clear all
eststo clear
cd "${user}"

* Temp frame and file
tempvar tframe
tempfile tfile

* Open data
use "Data/DTA/contiguous_counties", clear
foreach v of varlist tests positive repub population  populationdensity householdsize percentlivinginpoverty percentpopulation65yrs svi ccvi pct_vax* {
	fasterxtile c_`v' = `v', nq(10)
	replace c_`v'=100 if inlist(c_`v',.)
}
keep pair fips county stabb treated treatment insurance c_* metro stnum

* Save estimates
g beta = .
g ub = .
g lb = .
g cutoff = .
	
* Loop over outcome rows
local i=0
forvalues j = -2/20{

	* Counts tests within date window
	cap frame drop `tframe'
	frame create `tframe'
	frame `tframe'{
		
		* Open full webscraped dataset
		use Data/DTA/full_scrape, clear 
		
		* Keep in date window
		local cutoff = td(27mar2020)+`j'*7
		keep if date <= `cutoff'
		
		* Counts tests
		gcollapse (sum) tests=testsweek, by(fipscode)
		rename fipscode fips
		
		* Save
		save `tfile', replace

	}
	
	* Merge tests
	merge m:1 fips using `tfile', update replace nogen
	
	* Estimates
	reghdfe tests  i.c_* i.metro treatment, a(pair) vce(cluster stnum pair) old
	lincom treatment 
	
	* Store regression coefficient and 95% CI
	local i=`i'+1
	replace beta = r(estimate) in `i'
	replace ub = r(ub) in `i'
	replace lb = r(lb) in `i'
	replace cutoff = `cutoff' in `i'

}

* Save figure
tsset  cutoff, daily
local policy = td(27mar2020)
twoway 	line beta cutoff if !inlist(beta,.) ///
		|| rcap ub lb cutoff ///
		|| scatter beta cutoff if !inlist(beta,.) ///
		, xline(`policy', lcolor(red)) xtitle("") legend(off) 	///
		ytitle("Impact of Medicaid expansion" "on Covid-19 tests")
graph export "Output/cutoff_tests.pdf", replace		

* Exit stata
exit, clear STATA
