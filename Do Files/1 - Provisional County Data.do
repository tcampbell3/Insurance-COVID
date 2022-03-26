clear all

* Import data
import delimited "Data\Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv"

* Format dates
drop date
foreach v of varlist startdate enddate{
	split `v', parse("/")
	forvalues i = 1/3{
		destring `v'`i',replace
	}
	drop `v'
	g `v'=mdy(`v'1,`v'2,`v'3)
	drop `v'1-`v'3
	format `v' %td
}

* Names
rename state stabb
rename county county
rename fips fips
rename urban urban

* Totals
foreach v of varlist deaths*{
	replace `v'=9 if inlist(`v',.)	// Deaths are bottom coded at 9 for privacy in county_provisional_deaths data
	gegen t_`v' = total(`v')
}

* Save
order fips
keep fips t_* deaths* startdate enddate
compress
save Data/DTA/county_provisional_deaths, replace