
* Move to covid folder
cd "F:/Covid-19 Data"

* Temp file and frame
tempfile temp
tempvar tframe
frame create `tframe'

* Import data 
import delimited "COVID_Cases_Restricted_Detailed_02282021_Part_1.csv", encoding(UTF-8) clear varnames(1)
forvalues j = 2/3{
	
	frame `tframe'{
		import delimited "COVID_Cases_Restricted_Detailed_02282021_Part_`j'.csv", ///
			encoding(UTF-8) clear varnames(1)
		save  `temp', replace
	}
	append using `temp'
}
cap frame drop `tframe'


* County
destring county_fips, replace force
rename county_fips fips

* State
g stfips = int(fips/1000)
drop if stfips > 56 | inlist(stfips,.)	// drop missing, american samoa, guam...
rename res_state stabb
rename res_county county

* Time
foreach v of varlist cdc_case_earliest_dt cdc_report_dt onset_dt pos_spec_dt {
	split `v', parse("-")
	destring `v'1, replace force
	replace `v'1 = 2020 if `v'1 <2020 & !inlist(`v'1,.)
	tostring `v'1, replace
	g d_`v' = `v'2+"/"+`v'3+"/"+`v'1
	drop `v'*
	g `v' = date(d_`v',"MDY")
	format `v' %td
	drop d_`v'
}
rename cdc_case_earliest_dt time

* Outcomes and controls
g positive=1
g delay_length = (pos_spec_dt - onset_dt)  * (pos_spec_dt - onset_dt>0)
foreach v of varlist *_yn{
	local name =  substr("`v'" , 1, strlen("`v'") - 3)
	g `name' = inlist(`v',"Yes") if inlist(`v',"Yes","No")
	drop `v'
}

* Save 
compress
save "covid_cases", replace
cd "${user}"
