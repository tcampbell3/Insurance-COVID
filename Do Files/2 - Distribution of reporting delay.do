
* Set up
clear all
eststo clear
cd "${user}"
tempvar temp

* Open full dataset
use "F:/Covid-19 Data/covid_cases", clear

* Difference between minimum(symptom, test) - report for nonmissing
g report_delay = max(cdc_report_dt-min(onset_dt, pos_spec_dt),0) if !inlist(cdc_report_dt,.)&(!inlist(onset_dt,.)|!inlist(pos_spec_dt,.))
drop if inlist(report_delay,.)
keep report_delay

* Count cases by delay in reporting
g count=1
gcollapse (sum) count, by(report_delay)

* 95% coverage
gegen total = total(count)
g running = sum(count)
g cum = running/total
sum report_delay if inlist(int(cum*100),95)
global cutoff = r(min)

* Count cases by delay in reporting
g x=floor(report_delay/5)*5+5/2
gcollapse (sum) count, by(x)
gegen total = total(count)
g running = sum(count)
g cum = running/total
replace count= count/total

* Figure
twoway 	bar count x, color(edkblue%85) barw(5.1) xlab(${cutoff}, labcolor(red) add) || 	///
		line cum x, yline(.95, lcolor(red)) xline(${cutoff}, lcolor(red))color(black) lp(solid) ///
		legend(order(1 "Density" 2 "Cumulative Density") size(medsmall) pos(3) ring(0)) xtitle("")  ///
		xlabel(0(100)400, labcolor(black)) xlab(${cutoff}, add custom labcolor(red)) ///
		ylab(.95, add custom labcolor(red))	
graph export "Output/cutoff.pdf", replace
