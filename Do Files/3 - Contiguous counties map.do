clear all
use  "Data/DTA/contiguous_counties", clear
replace medicaid=0 if inlist(medicaid,.)
gcollapse (max) treated medicaid , by(fips stabb)
g county=fips
*maptile medicaid, geo(county2014) cutv(50 125 150 205)  stateoutline(medium) twopt(legend(pos(5) order(6 "215" 5 "200" 4 "138" 3 "100" 2 "Nonexpansion" 1 "Omitted"))) 
maptile medicaid, geo(county2014) cutv(50 125 150 205)  stateoutline(medium) twopt(legend(off)) 
graph export "Output/contiguous_counties_thresh_map.pdf", replace
maptile treated, geo(county2014) fc(BuRd) stateoutline(medium) twopt(legend(pos(5) order(3 "Treated" 2 "Control" 1 "Omitted"))) 
graph export "Output/contiguous_counties_treated_map.png", replace

