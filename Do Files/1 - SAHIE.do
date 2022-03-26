/*	DESCRIPTION OF DO FILE

This dofile imports the 2018 Small Area Health Insurance Estimates (SAHIE) using 
the American Community Survey (ACS). This data set gives insurance coverage rates
by county an demographics, annually. The estimates use adminstrative data and are
likely more accurate than could be measured with public use ACS. The goal is to
estimate insurance coverage by county-age-sex, which are available in covid
data. Cannot use race since only available at state level

STEPS:

	1) Import and clean data
	
	2) Convert estimates to insurance coverage rate by county-age-sex (cannot use race)


*/

******************************
	// 1) Import and Clean
******************************

* Unzip data
unzipfile "Data/sahie-2018-csv.zip"

* Import data
import delimited "sahie_2018.csv", delimiter(comma) varnames(1) rowrange(81) clear

* Variable names
rename filenamesahie year
rename v3 stfips
rename v4 countyfips
rename v5 geocat
rename v6 agecat
rename v8 sexcat
rename v9 iprcat
rename v10 population
rename v22 pct_insured
rename v24 stname
rename v25 countyname

* Trim strings
replace stname = trim(stname)
replace countyname = trim(countyname)

* Keep what will be used
keep year stfips countyfips geocat agecat sexcat iprcat population pct_insured stname countyname
g fips=stfips+countyfips

* Destring
foreach v of varlist *{
	cap destring `v', replace
}
compress

******************************
	// 2) Insurance Rate
******************************

* County level observations (remove state level)
drop if inlist(geocat,40)|!inlist(sexcat,0)|!inlist(iprcat,0)|!inlist(agecat,0)

* Insurance rate
g insurance=pct_insured/100
gegen ave_insurance=mean(insurance) [aw=population]

* Save data
keep fips insurance ave_insurance population
compress
save "Data/DTA/County insurance rate", replace
clear all

* Delete unused file
cap erase "sahie_2018.csv"



