
* Set up
clear all
eststo clear
cd "${user}"

* Open data
use "F:/Covid-19 Data/delay_demographic", clear

* Specification
local controls="_d* _h* _c*"
local absorb="stfips time agecat sexcat racecat"

	
* Summary statistics to convert to percentage
	
	
	* Number of groups
	cap drop _total_groups
	gegen _total_groups= group(stfips agecat sexcat racecat)
	sum _total_groups, meanonly
	local _g=r(max)
	local mean: di %10.0fc round(r(max))	
	local mean = trim("`mean'")		
	estadd local groups = "`mean'"			
	
	* Number of days
	cap drop _total_days
	gegen _total_days= group(time)
	sum _total_days, meanonly
	local _d = r(max)
	local mean: di %10.0fc round(r(max))	
	local mean = trim("`mean'")		
	estadd local days = "`mean'"			
	
	* Average insurance rate
	sum insurance, meanonly
	local _i = r(mean)
	local mean: di %10.3fc round(r(mean),.001)	
	local mean = trim("`mean'")		
	estadd local insurance = "`mean'"			

* Save estimates
g beta = .
g ub = .
g lb = .
g y = ""
g i = _n in 1/5
	
* Loop over outcome rows
local i=0
foreach y in death positive hosp delay_count {

	* Total 
	cap drop _total
	gegen _total = sum(`y')
	sum _total, meanonly
	local _t=r(mean)

	* Regression
	reghdfe `y' insurance `controls', a(`absorb') vce(cluster stfips#agecat#sexcat#racecat)
	
	* Convert to percentage
	lincom insurance * `_g' * `_d' * (1-`_i') / `_t'
	
	* Store regression coefficient and 95% CI
	local i=`i'+1
	replace beta = r(estimate) in `i'
	replace ub = r(ub) in `i'
	replace lb = r(lb) in `i'
	replace y = "`y'" in `i'
}

* Save figure
drop if inlist(beta,.)
twoway 	bar beta i, color(edkblue) barw(.5)  || ///
		rcap ub lb i, color(red%70) yline(0, lp(solid)) ///
		xlab(1 "Deaths" 2 "Cases" 3 "Hospitalizations" 4 `"  "Person-Days" "Between" "Symptom" "Onset" "and Test"  "Administration" "' ///
		,labsize(medlarge))	///
		xtitle("") legend(off) ylab(,labsize(medlarge)) ytitle("%{&Delta} Outcome from full insurance" "coverage",size(large) ) ysc(titlegap(-5)) xscale(reverse)
graph export "Output/baseline_verticle.pdf", replace		
		
twoway 	scatter delay_leng i || bar beta i, color(edkblue) barw(.5) xaxis(2) ||	///
		rcap ub lb i, color(red%70) yline(0, lp(solid)) xaxis(2)				///
		xlab(1 "Deaths" 2 "Cases" 3 "Hospitalizations" 4 `" "Person-Days Between" "Symptom Onset and" "Test Administration" "' ,labsize(medlarge) angle(rvertical) axis(2))							///
		xtitle("") legend(off) ylab(,labsize(medlarge)) 	xsc(off) ysc(reverse) ylab(, angle(-90)) xtitle("", axis(2))
graph export "Output/baseline_horizontal.pdf", replace		


* Exit stata
exit, clear STATA
