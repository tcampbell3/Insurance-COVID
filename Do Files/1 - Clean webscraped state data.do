clear all

* Tempframe to store files
tempvar tframe
frame create `tframe'
tempfile temp
tempfile temp2

* Loop files
use "Data\Medicaid Policies\statecode.dta" , clear
replace stname="Rhode Island" if inlist(stname,"Rhodes Island")
replace stname=proper(stname)
save `temp2',replace
g loop=lower(subinstr(stname, " ", "_",.))
gegen num=group(loop)
sum num
local numfiles=r(max)
forvalues i = 1/`numfiles'{
	di "File `i' out of `numfiles'"
	local s=loop[`i']
	qui{
	foreach path in "county_level_latest_data_for_" "county_level_vaccination_data_for_"{
		frame `tframe'{
			import delimited "Data\Webscrape state/`path'`s'.csv", delimiter(comma) varnames(3) ///
				encoding(UTF-8) stringcols(1/100) clear
			replace county=county+" city" if county==county[_n+1]				// cities come first
			save `temp',replace
		}
		append using `temp'
	}
	replace stname=proper(subinstr("`s'", "_", " ",.)) if inlist(stname,"")
	}
}
gduplicates drop								// webscrape could accidently download same county twice

* Get county FIPS codes
drop if inlist(county,"","Unknown")
replace county=subinstr(county, " Census Area", "",.)
replace county="Carson" if inlist(county,"Carson City") & inlist(stname,"Nevada")
replace county="Oglala Lakota" if inlist(county,"Oglala Lakota County") & inlist(stname,"South Dakota")
collapse (firstnm) populationdensity householdsize percentuninsured percentlivinginpoverty percentpopulation65yrs svi ccvi pct_vax=percentoftotalpopfullyvaccinated pct_vax65=percentof65popfullyvaccinatedres nchsurbanruralstatus, by(stname county)
merge m:1 stname using `temp2', keep(1 3) nogen
merge 1:1 stabb county using "Data/DTA/crosswalk.dta", keep(1 3) nogen
replace fips = 48001 if inlist(stabb, "TX") & inlist(county,"Anderson")
replace fips = 02270 if inlist(stabb, "AK") & inlist(county,"Kusilvak")

* Strings
foreach v of varlist populationdensity householdsize percentuninsured percentlivinginpoverty percentpopulation65yrs svi ccvi pct_vax pct_vax65 nchsurbanruralstatus {
	replace `v'=subinstr(`v', ",", "",.)
	replace `v'="" if inlist(`v',"null","N/A")
	destring `v',replace
}
encode nchsurbanruralstatus, g(metro)

* Texas data
frame `tframe'{

	* Vaccinated 65+
	import excel "Data\COVID-19 Vaccine Data by County (Texas).xlsx", sheet("By County, Age") firstrow clear
	keep if inlist(AgeGroup,"65-79 years","80+ years")
	gcollapse (sum) vaccine65 = PeopleFullyVaccinated, by(CountyName)
	save `temp', replace
	
	* Import Other variables
	import excel "Data\COVID-19 Vaccine Data by County (Texas).xlsx", sheet("By County") firstrow clear	
	drop in 1/3
	drop if inlist(CountyName,"Other","")
	merge 1:1 CountyName using `temp', nogen  keep(1 3)
	rename CountyName county
	g stabb="TX"
	merge 1:1 stabb county using "Data/DTA/crosswalk.dta", keep(1 3) nogen
	replace fips = 48001 if inlist(stabb, "TX") & inlist(county,"Anderson")
	
	* Final variables
	foreach v of varlist PeopleFullyVaccinated Population16 Population65{
		destring `v',replace
	}
	g pct_vax = PeopleFullyVaccinated / Population16
	g pct_vax65 = vaccine65 / Population65
	keep pct_vax* fips
	save `temp', replace
}
merge 1:1 fips using `temp', update keepus(pct_vax pct_vax65) nogen

* Save
order fip
drop stname county nchsurbanrural stnum stabb
compress
save Data/DTA/state_scrape, replace
clear all