

******************************
		// 1) Import 
******************************

* Temp frame and file
tempvar tframe
frame create `tframe'
tempfile tfile

* Import data
cd "${user}"
local i =1
forvalues year =2015/2019{

	* Unzip data
	cd "${user}\Data\BRFSS"
	unzipfile "LLCP`year'XPT", replace
	cd "${user}"

	* Import year of data
	frame `tframe'{
		import sasxport5 "Data\BRFSS\LLCP`year'.xpt", clear
		gen year=`year'
		destring seqno, replace
		save `tfile', replace
	}
	
	* Append data
	if `i'==1{
		use `tfile', clear
	}
	else{
		append using `tfile'
	}
	local i = `i'+1
	
	* Erase data that is not needed
	cap erase "Data\BRFSS\LLCP`year'.XPT"
	
}

******************************
// 2) Panel state-age-sex-race
******************************

* State
rename _state stfips
drop if inlist(stfips,66,72,78,11)	// drop guam, puerto rico, Virgian Islands, DC

* Age (1 = 20-29, 2 = 30-39, 3 = 40-49, 4 = 50-59, 5 = 60-69, 6 = 70-79, 7 = 80+)
g agecat = 	  1*inlist(_ageg5yr,1,2) 											///
			+ 2*inlist(_ageg5yr,3,4) 											///
			+ 3*inlist(_ageg5yr,5,6)											///
			+ 4*inlist(_ageg5yr,7,8)											///
			+ 5*inlist(_ageg5yr,9,10)											///
			+ 6*inlist(_ageg5yr,11,12)											///
			+ 7*inlist(_ageg5yr,13)	
drop if inlist(agecat,0)

* Sex (1 = male, 2 = female)
g sexcat = sex								// 2015 - 2017
replace sexcat= sex1 if inlist(sexcat,.)	// 2018
replace sexcat= _sex if inlist(sexcat,.)	// 2019
drop if !inlist(sexcat,1,2)

* Race (1 = white only nonhispanic, 2 = black only nonhispanic, 3 = Hispanic, 4 = Other)
g racecat =   1*inlist(_race_g1,1) 												///
			+ 2*inlist(_race_g1,2) 												///
			+ 3*inlist(_race_g1,3)												///
			+ 4*inlist(_race_g1,4,5) 		
drop if inlist(racecat,0)

* Move panel id's to front of dataframe
order stfips agecat sexcat racecat


******************************
   // 3) Exposure Variables
******************************

* Insurance
g insurance = inlist(hlthpln1,1) if !inlist(hlthpln1,.,7,9)

* Under insurance
g underinsurance = inlist(medcost,1) & inlist(hlthpln1,1) if !inlist(hlthpln1,.,7,9) & !inlist(medcost,.,7,9)

* Full insurance
g fullinsurance = inlist(medcost,2) & inlist(hlthpln1,1) if !inlist(hlthpln1,.,7,9) & !inlist(medcost,.,7,9)


******************************
   // 4) Control Variables
******************************

* Control: Marital status
g _d_couple = inlist(marital,1,6) & !inlist(marital,9,.)

* Control: College (some)
g _d_college = inlist(_educag,3,4) & !inlist(_educag,9,.)

* Control: Employment
g _d_employed = inlist(employ1,1,2) & !inlist(employ1,9,.)

* Control: Smoking (everyday or somedays currently)
g _h_smoke = inlist(smokday2,1,2) & !inlist(smokday2,7,9,.)

* Control: Drinking (days per week)
g _h_drink = alcday5
replace _h_drink =0 if alcday5 ==888
replace _h_drink =. if alcday5 ==777 | alcday5==999
replace _h_drink = alcday5-100 if alcday5>100 & alcday5<200
replace _h_drink = (alcday5-200)/30*7 if alcday5>200 & alcday5<300

* Control: poor pyhsical health days
g _h_physical = physhlth
replace _h_physical=0 if physhlth==88
replace _h_physical=. if physhlth==77|physhlth==99

* Control: poor health in general
g _h_poorhealth=inlist(genhlth,5) if !inlist(genhlth,7,9,.)

* Comorbidity list from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7314621/#CR7

* Comorbidity: Obesity
g _c_obese = inlist(_bmi5cat,4) & !inlist(_bmi5cat,.)

* Comorbidity: Hypertension
g _c_hypertension=inlist(bphigh4,1) if !inlist(bphigh4,7,9,.)

* Comorbidity: Cardiovascular and

* Comorbidity: Diabetes
replace diabete4 = diabete3 if inlist(diabete4,.)
g _c_diabetes=inlist(diabete4,1) if !inlist(diabete4,7,9,.)

* Comorbidity: Malignancy

* Comorbidity: Respiratory system (chronic obstructive pulmonary disease, C.O.P.D., emphysema or chronic bronchitis)
replace chccopd2 = chccopd1 if inlist(chccopd2,.)
g _c_respiratory=inlist(chccopd2,1) if !inlist(chccopd2,7,9,.)

* Comorbidity: Renal (kidney) disorders
g _c_kidney=inlist(chckdny2,1) if !inlist(chckdny2,7,9,.)

* Comorbidity: Immunodificiency

* Comorbidity: Chronic lung disease

* Comorbidity: Cardiovasular disease

* Cancer (not skin cancer)
g _c_cancer=inlist(chcocncr,1) if !inlist(chcocncr,7,9,.)


******************************
   // 5) Cleanup and save
******************************

* Collapse into summary statistics
g population = 1
gcollapse (sum) population (mean) insurance underinsurance fullinsurance _d_* _h_* _c_* [aw=_llcpwt], by(stfips agecat sexcat racecat)

* Benchmark population
gegen test=sum(population)
sum test, meanonly
replace population = population * 328239523/r(mean)
drop test

* Clean and save
order stfips agecat sexcat racecat
gsort stfips agecat sexcat racecat
compress
save Data/DTA/BRFSS, replace





