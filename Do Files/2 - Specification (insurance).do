
* Set up
clear all
eststo clear
cd "${user}"

* Open data
use "F:/Covid-19 Data/delay_demographic", clear

* Dummy regression
quietly reg insurance
eststo dummy

* Loop Columns
forvalues c = 1/8{
	
	* Row Counter
	global r=1
	global rows="" // blank row for "Mean . (SD)" label
	
	* Store Estimates
	est restore dummy
	eststo col`c'
	
	
	* Controls
	if `c'==1{
		local controls=""
		local absorb="stfips"
		estadd local fips = "\checkmark"
		estadd local time = ""
		estadd local age = ""
		estadd local sex = ""
		estadd local race = ""
		estadd local dem = ""
		estadd local hea= ""
		estadd local com = ""
	}
	if `c'==2{
		local controls=""
		local absorb="stfips time"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = ""
		estadd local sex = ""
		estadd local race = ""
		estadd local dem = ""
		estadd local hea= ""
		estadd local com = ""
	}
	if `c'==3{
		local controls=""
		local absorb="stfips time agecat"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = "\checkmark"
		estadd local sex = ""
		estadd local race = ""
		estadd local dem = ""
		estadd local hea= ""
		estadd local com = ""
	}
	if `c'==4{
		local controls=""
		local absorb="stfips time agecat sexcat"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = "\checkmark"
		estadd local sex = "\checkmark"
		estadd local race = ""
		estadd local dem = ""
		estadd local hea= ""
		estadd local com = ""
	}		
	if `c'==5{
		local controls=""
		local absorb="stfips time agecat sexcat racecat"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = "\checkmark"
		estadd local sex = "\checkmark"
		estadd local race = "\checkmark"
		estadd local dem = ""
		estadd local hea= ""
		estadd local com = ""
	}
	if `c'==6{
		local controls="_d*"
		local absorb="stfips time agecat sexcat racecat"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = "\checkmark"
		estadd local sex = "\checkmark"
		estadd local race = "\checkmark"
		estadd local dem = "\checkmark"
		estadd local hea= ""
		estadd local com = ""
	}
	if `c'==7{
		local controls="_d* _h*"
		local absorb="stfips time agecat sexcat racecat"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = "\checkmark"
		estadd local sex = "\checkmark"
		estadd local race = "\checkmark"
		estadd local dem = "\checkmark"
		estadd local hea= "\checkmark"
		estadd local com = ""
	}
	if `c'==8{
		local controls="_d* _h* _c*"
		local absorb="stfips time agecat sexcat racecat"
		estadd local fips = "\checkmark"
		estadd local time = "\checkmark"
		estadd local age = "\checkmark"
		estadd local sex = "\checkmark"
		estadd local race = "\checkmark"
		estadd local dem = "\checkmark"
		estadd local hea= "\checkmark"
		estadd local com = "\checkmark"
	}
	
	* Summary statistics at bottom of table (unweighted)
		
		* Average group population
		sum population, meanonly
		local mean: di %10.0fc round(r(mean))	
		local mean = trim("`mean'")		
		estadd local pop = "`mean'"
		
		* Average total cases
		cap drop _total_cases
		bys stfips agecat sexcat racecat: gegen _total_cases= sum(positive)
		sum _total_cases, meanonly
		local mean: di %10.0fc round(r(mean))	
		local mean = trim("`mean'")		
		estadd local cases = "`mean'"	
		
		* Number of groups
		cap drop _total_groups
		gegen _total_groups= group(stfips agecat sexcat racecat)
		sum _total_groups, meanonly
		local _g=r(max)
		local mean: di %10.0fc round(r(max))	
		local mean = trim("`mean'")		
		estadd local groups = "`mean'"			
		
		* Number of days
		cap drop _total_days
		gegen _total_days= group(time)
		sum _total_days, meanonly
		local _d = r(max)
		local mean: di %10.0fc round(r(max))	
		local mean = trim("`mean'")		
		estadd local days = "`mean'"			
		
		* Average insurance rate
		sum insurance, meanonly
		local _i = r(mean)
		local mean: di %10.3fc round(r(mean),.001)	
		local mean = trim("`mean'")		
		estadd local insurance = "`mean'"			
	
	* Loop over outcome rows
	foreach y in death positive hosp delay_count delay_length {
	
		* Total 
		cap drop _total
		gegen _total = sum(`y')
		sum _total, meanonly
		local _t=r(mean)
	
		* Regression
		reghdfe `y' insurance `controls', a(`absorb') vce(cluster stfips#agecat#sexcat#racecat)
		
		* Convert to percentage
		lincom insurance * `_g' * `_d' * (1-`_i') / `_t'
		
		* Store regression coefficient
		local b: di %10.3gc round(r(estimate),.001)	
		local b = trim("`b'")
		local se: di %10.3gc round(r(se),.001)	
		local se = trim("`se'")
		local N=e(N)
		local star =""
		if _P[insurance]<.1{
			local star "^{*}"
		}
		if _P[insurance]<.05{
				local star "^{**}"
		}
		if _P[insurance]<.01{
			local star "^{***}"		
		}
		
		* Open stored estimates
		est restore col`c'
		
		* Beta
		estadd local b_`y' = "\$`b'`star'\$"
		
		* Standard Error
		estadd local se_`y' = "(`se')"
		
		* N
		estadd scalar N_`y' = `N'
		
		* Total 
		sum _total, meanonly
		local mean: di %10.0fc round(r(mean))	
		local mean = trim("`mean'")		
		estadd local t_`y' = "`mean'"		
	
		* Blank Row for space and titles
		estadd local blank=""

	}	

}


* Save Table
esttab col* using Output/controls.tex,				 							///
	stats(	blank b_death se_death N_death t_death								///
			blank b_positive se_positive N_positive	t_positive					///
			blank b_hosp se_hosp N_hosp	t_hosp									///
			blank b_delay_count se_delay_count N_delay_count t_delay_count		///
			blank b_delay_length se_delay_length N_delay_length t_delay_length	///
			pop cases groups days insurance										///
			fips time age sex race dem hea com, 								///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 deaths}}"				///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 	
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 cases}}" 				///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 			
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 hositalizations}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Case reports delayed from symptom onset}}" ///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Ave. days delayed from symptom onset}}" ///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						///
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \midrule Ave. group population"					///
		"\addlinespace[0.1cm]Ave. group total cases"							///
		"\addlinespace[0.1cm]Number of groups"									///
		"\addlinespace[0.1cm]Number of days"									/// 
		"\addlinespace[0.1cm]Ave. group insurance rate"							/// 
		"\addlinespace[0.3cm]Controls: state fixed effects"						/// 		
		"\addlinespace[0.1cm]Controls: time fixed effects (daily)"				/// 		
		"\addlinespace[0.1cm]Controls: age fixed effects"						/// 
		"\addlinespace[0.1cm]Controls: sex fixed effects"						/// 	
		"\addlinespace[0.1cm]Controls: race"									/// 			
		"\addlinespace[0.1cm]Controls: demographics"							/// 	
		"\addlinespace[0.1cm]Controls: health"									/// 	
		"\addlinespace[0.1cm]Controls: comorbidities"							/// 	
		))																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 						///
	posthead(\midrule)  														///
	postfoot(\bottomrule \end{tabular}) 

	
* Exit stata
exit, clear STATA