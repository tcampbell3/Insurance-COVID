
* Set up
clear all
eststo clear
cd "${user}"


******************************
   // 1) Create panel ids
******************************

* Open full dataset
use "F:/Covid-19 Data/covid_cases", clear

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

* List panel id
local panelid = "stfips racecat sexcat agecat"
drop if inlist(racecat,0) | inlist(sexcat,0) | inlist(agecat,0,1)			// 20 or older, nonmissing demo


* Temprary frames and files
tempvar positive

* Save summary statistics by panel-time
frame put * , into(`positive')
frame `positive'{
	gcollapse (sum) positive hosp icu death (mean) delay_rep delay_pos delay_com hc_work 	///
	pna abxchest acuterespdistress mechvent fever sfever chills myalgia runnose	///
	sthroat cough sob nauseavomit headache abdom diarrhea medcond 				///
	, by(`panelid' time)
}

* local timeframe
sum time, meanonly
local start=r(min)
local end=r(max)

******************************
   // 2) Create delay panel
******************************

* Expand panel
keep delay_com onset_dt `panelid'
rename onset_dt time
drop if inlist(delay_com,.)
gcontract *, freq(count) fast
g id=_n

* Save total number of treatment delays for each group-date

	* Save dates each case delayed treatment 
	sum delay
	local max=r(max)+7
	forvalues i = 0/`max'{
		g _diff`i' = time + (`i'-7) if delay>=`i'-7
	}
	
	* Temprary frames and files
	tempfile temp
	tempvar f1
	tempvar f2
	frame create `f2' `panelid' time
	
	* Loop over group
	gegen _group=group(`panelid')
	sum _group
	local total = r(max)
	forvalues i=1/`total'{
		
		qui{
		
		* Put fips into temp frame amd count delays
		cap frame drop `f1'
		frame put if inlist(_group,`i'), into(`f1')
		frame `f1'{
		
			* Wide long transformation
			greshape long _diff , i(id) nochecks
			drop if inlist(_diff,.)
						
			* Count total delays by day relative to onset 
			forvalues j=-7/30{
				if `j'<0{
					local m="pre"
				}
				else{
					local m="post"
				}
				local z = abs(`j')
				g delay_`m'_`z' = count * inlist(_j,`j'+7)
			}
			
			* Collapse into group-time count
			gcollapse (sum) delay_p* , by(`panelid' _diff)
			rename _diff time
			format time %td
			save `temp', replace
		
		}
		
		* Stack fips
		frame `f2': append using `temp'
		
		}
		
		di in red "Group: `i'/`total'"
		
	}
	
	
******************************
	 // 3) Merge panels
******************************	

* Save temp file
frame `f2': save `temp', replace

* Create final panel
frame `positive'{
	
	* Merge tempfile
	merge 1:1 `panelid' time using `temp', nogen
	
	* Create balanced panel
	fillin `panelid' time
	drop _fillin
	
	* Total number of symptomatic people delaying treatment during first 30 days symptomatic
	egen delay = rowtotal(delay_post_1-delay_post_30)
	
	* Merge BRFSS
	merge m:1 `panelid' using Data/DTA/BRFSS, nogen keepus() keep(1 3)
	drop if inlist(insurance,.)
	
	* Fill missing counts with zeros
	foreach v of varlist positive delay delay_p* hosp icu death{
		replace `v' = 0 if inlist(`v',.)
	}
	
	* Drop outside of time frame (symptom onset dates are sometimes later than the "time" = min(onset,report.test))
	drop if time<`start' | time>`end'
	
	* Save dataset
	compress
	order `panelid' time
	gsort `panelid' time
	save "F:/Covid-19 Data/test", replace
	
}

