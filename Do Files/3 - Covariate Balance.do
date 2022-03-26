ereturn clear

* generate open variables
use  "Data/DTA/contiguous_counties", clear

* local controls
local controls = "test positive repub population  populationdensity householdsize percentlivinginpoverty percentpopulation65yrs svi ccvi pct_vax* metro"

* Pretreatment only
keep `controls' fips treated pair stabb

* label controls
label var test "Number of Covid-19 tests administered (100,000's)"
label var positive "Positive test rate"
label var repub "Presidential republican vote share in 2016"
label var population "Population (100,000's)"
label var populationdensity "Population density (100's)"
label var householdsize "Household size"
label var percentlivinginpoverty "\% Living in poverty"
label var percentpopulation65yrs "\% Under age 65"
label var svi "CDC Social Vulnerability Index (SVI)"
label var ccvi "COVID-19 Community Vulnerability Index (CCVI)"
label var pct_vax "Percent vaccinated"
label var pct_vax65 "Percent vaccinated over age 65"
label var metro "NCHS Urban/Rural Classification"

* Format large variables
replace test = test / 100000
replace population = population / 100000
replace populationdensity = populationdensity / 100

* Joint F-test (and individual t-tests) frame
preserve
	g stack=0
	g name=""
	tempfile temp
	tempvar tframe
	local i=1
	foreach v of varlist `controls'{
		cap frame drop `tframe'
		frame put `v' treated stack name fips pai stabb, into(`tframe')
		frame `tframe'{
			keep if inlist(stack,0)
			rename `v' control
			replace stack=`i'
			replace name="`v'"
			local i = `i'+1
			save `temp', replace
		}
		append using `temp'
	}
	drop if inlist(stack,0)
	keep control stack name treated fips pair stabb
	cap frame drop `tframe'
	frame put *, into(`tframe')
restore

* table
frame `tframe': reghdfe control c.treated#stack, a(stack)  vce(cluster stabb pair)
local ftest=e(F)
local df1=e(df_a)
local df2=e(df_r)
estpost sum `controls' if treated==1
eststo est1
estadd scalar ftest = `ftest'

estpost sum `controls'  if treated==0
eststo est2
estadd scalar ftest = `ftest'

esttab est1 est2 using "Output/cov_balance.tex", scalars("N Observations" "ftest \$ F_{`df1',\; `df2'}\$") main(mean "%4.2f") aux(sd "%4.2f") nostar unstack noobs nonote label  nogaps nonotes mtitles("Treated" "Control") replace substitute( )

* Exit stata
exit, clear STATA