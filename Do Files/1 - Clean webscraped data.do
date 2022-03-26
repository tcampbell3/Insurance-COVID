clear all

* Count files in directory
local list:dir "Data/Webscrape" files "*"
local numfiles : word count `list'
di "`numfiles'"

* Tempframe to store files
tempvar tframe
frame create `tframe'
tempfile temp

* Loop files
import delimited "Data\Webscrape\county1 .csv", delimiter(comma) varnames(3) encoding(UTF-8) stringcols(7/18) clear
forvalues i = 2/`numfiles'{
	di "File `i' out of `numfiles'"
	qui{
	frame `tframe'{
		import delimited "Data\Webscrape\county`i' .csv", delimiter(comma) varnames(3) ///
			encoding(UTF-8) stringcols(7/18) clear
		save `temp',replace
	}
	append using `temp'
	}
}
gduplicates drop								// webscrape could accidently download same county twice

* Crosswalk
cap frame drop `tframe'
frame put county fipscode, into(`tframe')
frame `tframe'{
	gduplicates drop
	g stnum=string(int(fipscode/1000),"%02.0f")
	merge m:1 stnum using "Data\Medicaid Policies\statecode.dta" , keepus(stabb) keep(3) nogen
	gen tail1 = word(county,-1)
	gen head1 = substr(county,1,length(county) - length(tail1) - 1)
	replace county = head1 if inlist(tail1,"County","Borough","City","Municipality","Parish")
	replace county=subinstr(county, " Census Area", "",.)
	replace county=subinstr(county, " City and", "",.)
	rename fipscode fips
	bys county stabb: g test=_N
	replace county = county + " city" if inlist(test,2) & inlist(tail1,"City")
	keep county fips stabb
	gsort fips
	drop if county=="DoÃ±a Ana"
	save Data/DTA/crosswalk,replace
}

* Format dates
foreach v of varlist date startdate enddate{
	split `v', parse("-")
	forvalues i = 1/3{
		destring `v'`i',replace
	}
	drop `v'
	g `v'=mdy(`v'2,`v'3,`v'1)
	drop `v'1-`v'3
	format `v' %td
}

* Format hospital variables
rename dayrollingaverageofdailyadmissio admissions
rename totaladmissionsofconfirmedcovid1 admissions_7
rename v11 admissions_per_bed
rename weekoverweekpercentagechangeinto admissions_pct_change 
rename percentageofstaffedadultinpatien pct_staffed_covid_bed
rename weekoverweekabsolutechangeinperc weekly_pct_staffed_covid_bed
rename totalnumberofhospitalreportsrece hospital_reports
rename percentageofstaffedadulticubedsu pct_icu_covid_bed
rename v17 weekly_pct_icu_covid_bed
foreach v of varlist admissions* pct_* weekly_* {
	replace `v' = lower(strtrim(trim(`v')))
	replace `v'="" if inlist(`v',"null")
	destring `v',replace
}
foreach v of varlist pct*{
	replace `v'=`v'/100
}

* Collapse into summary statistics by county
save Data/DTA/full_scrape, replace
drop county
gcollapse (sum) cases=casesweeklyavg tests=testsweeklyavg deaths_confirmed=confirmeddeathweeklyavg admissions (mean) pct_staffed_covid_bed pct_icu_covid_bed  positive_rate=testpositivityrateweeklyavg (min) start (max) end, by(fips)

* Totals
foreach v of varlist cases tests deaths* admissions{
	gegen t_`v' = total(`v')
}
foreach v of varlist pct*{
	gegen t_`v' = mean(`v')
}

* Save
rename fipscode fips
order fips start end
compress
save Data/DTA/county_scrape, replace
clear all