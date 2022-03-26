
* Set up
clear all
eststo clear
cd "${user}"
tempfile temp
tempvar positive

******************************
   // 1) Create panel ids
******************************

* Open survellience data and find time endpoints
use "F:/Covid-19 Data/covid_cases", clear
sum cdc_report_dt
global max=r(max)
global min=r(min)

* Age (1 = 20-29, 2 = 30-39, 3 = 40-49, 4 = 50-59, 5 = 60-69, 6 = 70-79, 7 = 80+)
g agecat = 	  1*inlist(age,"10 - 19 Years","0 - 9 Years") 						///
			+ 2*inlist(age,"20 - 29 Years") 									///
			+ 3*inlist(age,"30 - 39 Years") 									///
			+ 4*inlist(age,"40 - 49 Years")										///
			+ 5*inlist(age,"50 - 59 Years")										///
			+ 6*inlist(age,"60 - 69 Years")										///
			+ 7*inlist(age,"70 - 79 Years")										///
			+ 8*inlist(age,"80+ Years")											

* Sex (1 = male, 2 = female)
g sexcat = inlist(sex,"Male") + 2*inlist(sex,"Female")

* Race (1 = white only nonhispanic, 2 = black only nonhispanic, 3 = Hispanic, 4 = Other)
g racecat =   1*inlist(race_ethnicity_combined,"White, Non-Hispanic") 			///
			+ 2*inlist(race_ethnicity_combined,"Black, Non-Hispanic") 			///
			+ 3*inlist(race_ethnicity_combined,"Hispanic/Latino")				///
			+ 4*inlist(race_ethnicity_combined,"Native Hawaiian/Other Pacific Islander, Non-Hispanic") ///
			+ 4*inlist(race_ethnicity_combined,"Multiple/Other, Non-Hispanic")	///
			+ 4*inlist(race_ethnicity_combined,"Asian, Non-Hispanic")			///
			+ 4*inlist(race_ethnicity_combined,"American Indian/Alaska Native, Non-Hispanic")	

* Drop missing demographics
drop if inlist(racecat,0) | inlist(sexcat,0) | inlist(agecat,0,1)			// 20 or older, nonmissing demo

******************************
   // 2) Measure test delay
******************************

preserve

	* Expand panel
	keep delay_com onset_dt fips racecat sexcat agecat
	rename onset_dt time
	drop if inlist(delay_com,.) | delay_com > 30

	* ID variables
	gcontract *, freq(count) fast
	g id=_n
	frame put id fips racecat sexcat agecat time, into(`positive')
	frame `positive': save `temp', replace

	* Delay dates
	sum delay_com
	local last=r(max)
	forvalues i=0/`last'{
		local j = `i'+1
		g time`j'=time+`i'
	}
	drop time

	* Long transformation
	keep id time* count
	greshape long time, by(id) nochecks
	merge m:1 id using `temp', nogen	
	gcollapse (sum) delay = count, by(fips racecat sexcat agecat time)
	
	* Final data
	save `temp', replace
	
restore

******************************
	 // 3) Benchmark data
******************************	

* Collapse into counts
gcollapse (sum) positive hosp icu death (mean) delay_rep delay_pos delay_com hc_work 	///
pna abxchest acuterespdistress mechvent fever sfever chills myalgia runnose	///
sthroat cough sob nauseavomit headache abdom diarrhea medcond		///
, by(fips racecat sexcat agecat time)

* Merge delay
merge 1:1 fips racecat sexcat agecat time using `temp', nogen keep(1 3)

* Balanced panel
fillin fips racecat sexcat agecat time
drop _fillin

* Fill missing counts with zero
cap drop dummy
foreach v of varlist positive delay delay_p* hosp icu death {
	replace `v' = 0 if inlist(`v',.)
}

* Merge webscraped state counts
frame `positive'{
	use "Data/DTA/full_scrape", clear
	drop if date<${min} | date>${max}
	rename fips fips
	gcollapse (sum) positive_scrape_state=casesweeklyavg death_scrape_state=confirmeddeathweeklyavg ///
		hosp_scrape_state=admissions, by(fips)
	save `temp', replace
}
merge m:1 fips using `temp', keep(1 3) nogen

* Benchmark outcomes by county
cap drop dummy
foreach v of varlist positive death hosp{
	bys fips: gegen dummy = total(`v')
	replace `v' = `v' * `v'_scrape / dummy
	drop dummy `v'_scrape 
}

****************************
	// 4) Final panels
****************************	

* Collapse into state-demographic panel
g stfips = int(fips/1000)
gcollapse (sum) positive hosp icu death delay (mean) delay_rep delay_pos delay_com hc_work 	///
pna abxchest acuterespdistress mechvent fever sfever chills myalgia runnose	///
sthroat cough sob nauseavomit headache abdom diarrhea medcond		///
, by(stfips racecat sexcat agecat time)

* Merge BRFSS
merge m:1 stfips racecat sexcat agecat using Data/DTA/BRFSS, nogen keepus() keep(1 3)
drop if inlist(insurance,.)

* Save dataset
compress
order stfips racecat sexcat agecat time
gsort stfips racecat sexcat agecat time
save "F:/Covid-19 Data/delay_demographic", replace
	
