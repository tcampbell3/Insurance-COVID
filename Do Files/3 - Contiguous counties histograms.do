clear all
use  "Data/DTA/contiguous_counties", clear

* Per capita
replace tests = tests / population 
hist tests, xtitle("Tests per capita") color(blue) bin(100)
graph export "Output/hist_tests_per_capita.pdf", replace

* Count
replace tests = tests * population 
hist tests, xtitle("Tests (count)") color(red) bin(100)
graph export "Output/hist_tests_count.pdf", replace
