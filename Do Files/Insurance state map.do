
* Prepare state uninsurance rate
use Data/DTA/BRFSS, clear
g uninsured = 1-insurance
sum uninsured [aw=population]
gcollapse uninsured [aw=population], by(stfips)
rename stfips fips
merge m:1 fips using "Data\state_fips.dta", nogen keep(1 3)

* Create map
maptile uninsured, geography(state) cutvalues(.05 .07 .09 .12) ///
fc(eltblue*.2 "180 230 230"  "70 175 200" "64 135 166" edkblue) ///
twopt(legend(lab(2 "Less than 5.0") lab(3 "5.0 to 6.9") lab(4 "7.0 to 8.9") lab(5 "9.0 to 11.9") lab(6 "12.0 or more")))

* Save Map
graph export Output/brfss_insurance.pdf, replace 

/* ACS Insurance map 2019
https://www.census.gov/content/dam/Census/library/visualizations/2020/demo/p60-271/figure7.pdf