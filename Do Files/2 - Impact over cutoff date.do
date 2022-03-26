
* Set up
clear all
eststo clear
cd "${user}"

* Temp frame and file
tempvar tframe
tempfile tfile

* Open data
use "F:/Covid-19 Data/delay_demographic", clear

* Specification
local controls="_d* _h* _c*"
local absorb="stfips time agecat sexcat racecat"
	
* Save estimates
g beta = .
g ub = .
g lb = .
g cutoff = .
	
* Loop over outcome rows
foreach y in delay_count delay_length {
local i=0
forvalues j = -1/10{

	* Store what is needed into temp frame
	cap frame drop `tframe'
	frame put `y' insurance `controls' `absorb', into(`tframe')
	
	* Work in temp frame
	frame `tframe'{
		
		* Keep in date window
		keep if time <= td(27mar2020)+`j'*30
		sum *
	
		* Number of groups
		cap drop _total_groups
		gegen _total_groups= group(stfips agecat sexcat racecat)
		sum _total_groups, meanonly
		local _g=r(max)

		* Number of days
		cap drop _total_days
		gegen _total_days= group(time)
		sum _total_days, meanonly
		local _d = r(max)

		* Average insurance rate
		sum insurance, meanonly
		local _i = r(mean)

		* Total 
		cap drop _total
		gegen _total = sum(`y')
		sum _total, meanonly
		local _t=r(mean)

		* Regression
		reghdfe `y' insurance `controls', a(`absorb') vce(cluster stfips#agecat#sexcat#racecat)
		
		* Convert to percentage
		lincom insurance * `_g' * `_d' * (1-`_i') / `_t'
		
	}
	
	* Store regression coefficient and 95% CI
	local i=`i'+1
	replace beta = r(estimate) in `i'
	replace ub = r(ub) in `i'
	replace lb = r(lb) in `i'
	replace cutoff = td(27mar2020)+`j'*30 in `i'
	
}

* Save figure
tsset  cutoff, daily
local policy = td(27mar2020)
twoway 	line beta cutoff if !inlist(beta,.) ///
		|| rcap ub lb cutoff ///
		|| scatter beta cutoff if !inlist(beta,.) ///
		, xline(`policy', lcolor(red)) xtitle("") legend(off) 	///
		ytitle("%{&Delta} Delays from full insurance" "coverage")
graph export "Output/cutoff_`y'.pdf", replace		

}

* Exit stata
exit, clear STATA
