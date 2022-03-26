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
foreach v of varlist cases admissions deaths_confirmed {
	
	* Totals
	sum insurance, meanonly
	local I = r(mean)
	unique fips
	local G = r(unique)
	sum t_`v', meanonly
	cap drop dummy
	gegen dummy=total(`v')
	sum dummy, meanonly
	local sumY=r(mean)
	if inlist("`v'","pct_staffed_covid_bed","pct_icu_covid_bed"){
		local G=1
		local sumY=1
	}

	reghdfe `v' c.tests##i.c_tests i.c_* i.metro (insurance=treatment), a(pair) vce(cluster stnum pair) old
	lincom insurance  * (1-`I') * `G' / `sumY'
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
				1 "Cases" 	///
				2 "Hospitalizations" 	///
				3 `""Deaths" "(confirmed)""' 	///
				3.5 " "	///
				)
graph export "Output/contiguous_counties_2sls_verticle.pdf", replace