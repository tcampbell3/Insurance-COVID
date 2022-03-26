
clear all
tempfile temp

* State case survellience counts
use "F:/Covid-19 Data/covid_cases", clear
sum cdc_report_dt
global max=r(max)
global min=r(min)
gcollapse (sum) cases_casesurv=positive deaths_casesurv=death, by(stabb)
save `temp', replace

* Webscraped data counts
use "Data/DTA/full_scrape", clear
drop if date<${min} | date>${max}
g str2 stnum = string(int(fipscode/1000),"%02.0f")
merge m:1 stnum using "Data\Medicaid Policies\statecode.dta", nogen keep(1 3)
gcollapse (sum) cases_scrape=casesweeklyavg deaths_scrape=confirmeddeathweeklyavg, by(stabb)
merge 1:1 stabb using `temp', nogen keep(3)

* Save Map
rename stabb state
g case_diff=(cases_casesurv-cases_scrape)/cases_scrape
maptile case_diff, geo(state) rev
graph export "Output/case_difference_map.png", replace

g death_diff=(deaths_casesurv-deaths_scrape)/deaths_scrape
maptile death_diff, geo(state) rev
graph export "Output/death_difference_map.png", replace
