
* Set up
clear all
eststo clear
cd "${user}"
tempvar temp


******************************
   // 1) Import CDC Counts
******************************

* Import CDC Cases
import delimited "Data\CDC Totals\case_daily_trends__united_states.csv", delimiter(comma) varnames(4) rowrange(5) clear 
frame put *, into(`temp')

* Import CDC Deaths
import delimited "Data\CDC Totals\death_daily_trends__united_states.csv", delimiter(comma) varnames(4) rowrange(5) clear 

* Merge
frlink 1:1 date, frame(`temp')
frget newcases = newcases, from(`temp')

* Format date
g time = date(date, "MDY")
format time %d
gsort time

* Save
frame drop `temp'
frame put *, into(`temp')


******************************
   // 2) Our Data Count
******************************

* Open full dataset
use "F:/Covid-19 Data/covid_cases", clear

* Count cases and deaths
gcollapse (sum) positive death, by(time)

* Fill missing dates
tsset time
tsfill

* Merge
frlink 1:1 time, frame(`temp')
frget cases_cdc = newcases deaths_cdc=newdeaths, from(`temp')

* Replace missing with zero and find totals
gsort time
foreach v of varlist *{
	replace `v' = 0 if inlist(`v',.)
	gegen `v'_total = sum(`v')
	g `v'_run = `v'
	replace `v'_run=`v'_run + `v'_run[_n-1] if !inlist(_n,1)
}


******************************
		// 3) Figures
******************************

* Time labels
sum time
local tlabel = r(max)
forvalues m = 1(3)12{
	local t: di d(1/`m'/2020)
	local tlabel = "`tlabel' `t'"
}

* Cases
tsset time
cap drop _diff
sum cases_cdc_total, meanonly
	local t1: di %20.0fc r(max)
	local t1=trim("`t1'")
sum positive_total, meanonly
	local t2: di %20.0fc r(max)
	local t2=trim("`t2'")
g _diff = (l3.cases_cdc+l2.cases_cdc+l1.cases_cdc+cases_cdc+f1.cases_cdc+f2.cases_cdc+f3.cases_cdc)/7	///
		- (l3.positive+l2.positive+l1.positive+positive+f1.positive+f2.positive+f3.positive)/7
twoway 	bar cases_cdc time, color(blue%40) || ///
		bar positive time, color(red%40) || ///
		line _diff time, sort color(black) lp(solid) xlabel(`tlabel') lw(medthick)	///
		legend(order(1 "CDC cases (total = `t1')" 2 "Surveillance cases (total = `t2')" ///
		3 "Difference in 7 day moving averages") size(medsmall) pos(11) ring(0)) xtitle("")  
graph export "Output/cdc_cases.pdf", replace

* Deaths
tsset time
cap drop _diff
sum deaths_cdc_total, meanonly
	local t1: di %20.0fc r(max)
	local t1=trim("`t1'")
sum death_total, meanonly
	local t2: di %20.0fc r(max)
	local t2=trim("`t2'")
g _diff = (l3.deaths_cdc+l2.deaths_cdc+l1.deaths_cdc+deaths_cdc+f1.deaths_cdc+f2.deaths_cdc+f3.deaths_cdc)/7	///
		- (l3.death+l2.death+l1.death+death+f1.death+f2.death+f3.death)/7
twoway 	bar deaths_cdc time, color(blue%40) || ///
		bar death time, color(red%40) || ///
		line _diff time, sort color(black) lp(solid) xlabel(`tlabel') xlab(22251, add custom labcolor(maroon)) ///
		lw(medthick) legend(order(1 "CDC deaths (total = `t1')" 2 "Surveillance deaths (total = `t2')" ///
		3 "Difference in 7 day moving averages") size(medsmall) pos(1) ring(0)) xtitle("")  ///
		xline(22251, lcol(maroon))
graph export "Output/cdc_deaths.pdf", replace

* Exit stata
exit, clear STATA
