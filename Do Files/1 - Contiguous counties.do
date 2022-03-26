* Set up
clear all
tempfile temp
tempvar tframe

* Save contingous counties
use "Data\Contiguous counties\county_adjacency2010.dta", clear
drop if fipscounty==fipsneighbor
g pair=_n
rename countyname countyname1
rename neighborname countyname2
rename fipscounty fips1
rename fipsneighbor fips2
greshape long countyname fips ,i(pair) j(new)
destring fips,replace
split countyname, parse(", ")
drop countyname
rename countyname1 county
rename countyname2 stabb
gegen total_counties=nunique(fips) if !inlist(stabb,"PR","VI","MP","AS")
drop if inlist(stabb,"PR","VI","MP","AS","NE")
drop new

* Insurance rate (under age 65)
merge m:1 fips using "Data/DTA/County insurance rate", nogen keep(1 3)

* Controls
merge m:1 fips using "Data/DTA/republican_vote_share", nogen keep(1 3)
merge m:1 fips using "Data/DTA/state_scrape", nogen keep(1 3)

* Covid outcomes
merge m:1 fips using "Data/DTA/county_provisional_deaths", nogen keep(1 3)
merge m:1 fips using "Data/DTA/county_scrape", nogen keep(1 3)

* Deaths are bottom coded at 9 for privacy in provisional data
foreach v of varlist deaths* {
	mdesc `v'
	local missing=r(miss)
	replace `v'=9 if inlist(`v',.)
	replace t_`v'=t_`v'[_n-1] if inlist(t_`v',.)
	replace t_`v'=t_`v'+`missing'*9
}

* Medicaid policy
g year= 2020
merge m:1 stabb year using "Data/DTA/Medicaid_FPL", keep(1 3) keepus(medicaid_FPL expansion_years) nogen
drop year

* Define treatment status
replace medicaid_FPL=0 if inlist(medicaid_FPL,.)
bys pair (fips): g j=_n
cap frame drop `tframe'
frame put pair medicaid_FPL j, into(`tframe')
frame `tframe'{
	greshape wide medicaid_FPL, i(pair) j(j)
	save `temp',replace
}
merge m:1 pair  using `temp', nogen
g treatment = medicaid_FPL1>medicaid_FPL2 if inlist(j,1)
replace treatment = medicaid_FPL2>medicaid_FPL1 if inlist(j,2)
drop j medicaid_FPL1 medicaid_FPL2
bys pair fips: gegen treated=max(treatment)

* Keep only contiguous counties with different medicaid thresholds
bys pair: gegen _min = min(treatment)
bys pair: gegen _max = max(treatment)
drop if !inlist(_min,0) | !inlist(_max,1)
drop _min _max

* Clean and save
gsort pair
gegen _dummy = group(pair)
drop pair
rename _dummy pair
replace startdate=startdate[_n-1] if inlist(startdate,.)
replace enddate=enddate[_n-1] if inlist(enddate,.)
order pair fips county stabb treated treatment insurance death* t_*
gsort pair fips
g stnum=int(fips/1000)
compress
save  "Data/DTA/contiguous_counties", replace