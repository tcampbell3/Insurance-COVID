clear all
use  "Data/DTA/contiguous_counties", clear
* Storage variables
foreach v of varlist tests positive repub population  populationdensity householdsize percentlivinginpoverty percentpopulation65yrs svi ccvi pct_vax* {
	fasterxtile c_`v' = `v', nq(10)
	replace c_`v'=100 if inlist(c_`v',.)
}
g ub=.
g lb=.
g b=.

local i=1
foreach v of varlist insurance cases deathsinvolvingcovid19 deaths_confirmed deathsfromallcauses admissions pct_staffed_covid_bed pct_icu_covid_bed {
	sum `v' if inlist(treated,0), meanonly
	local pre=r(mean)
	reghdfe `v' treatment c.tests##i.c_tests  i.c_* i.metro , a(pair) vce(cluster stnum pair)
	lincom treatment/`pre'
	replace ub = r(ub) in `i'
	replace lb = r(lb) in `i'
	replace b = r(estimate) in `i'	
	local i=`i'+1
}
g n=_n if !inlist(b,.)
twoway 	rcap ub lb n, color(maroon%80) lw(thick) msize(large) || ///
		scatter b n, m(S) mc(navy)	///
		, yline(0, lp(solid) lc(gray%70)) scheme(plotplain) legend(off) xtitle("") ///
		xlabel(.5 " " 	///
				1 "Insurance" 	///
				2 `""Covid-19" "Cases""' 	///
				3 `""Covid-19" "Deaths" "(involved)""' 	///
				4 `""Covid-19" "Deaths" "(confirmed)""' 	///
				5 `""Deaths" "(all causes)""' 	///
				6 "Admissions" 	///
				7 `""% Staffed" "Beds""' 	///
				8 `""% ICU" "Beds""'	///
				8.5 " "	///
				)
graph export "Output/contiguous_counties_reduced_form.pdf", replace