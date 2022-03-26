
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
	
	* Loop over outcome rows
	foreach y in death positive hosp {
	
		* Regression
		reghdfe `y' delay_count `controls', a(`absorb') vce(cluster stfips#agecat#sexcat#racecat)
		local b: di %10.4gc round(_b[delay],.0001)	
		local b = trim("`b'")
		local se: di %10.4gc round(_se[delay],.0001)	
		local se = trim("`se'")
		local N=e(N)
		local star =""
		if _P[delay]<.1{
			local star "^{*}"
		}
		if _P[delay]<.05{
				local star "^{**}"
		}
		if _P[delay]<.01{
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
		
		* Blank Row for space and titles
		estadd local blank=""

	}	

}


* Save Table
esttab col* using Output/controls_delay.tex,				 							///
	stats(	blank b_death se_death N_death 										///
			blank b_positive se_positive N_positive								///
			blank b_hosp se_hosp N_hosp											///
			fips time age sex race dem hea com, 								///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 deaths}}"				///
			"\addlinespace[0.1cm]\hspace{.25cm}Cases reports delayed from symptom onset" ///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 	
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 cases}}" ///
			"\addlinespace[0.1cm]\hspace{.25cm}Cases reports delayed from symptom onset" ///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 hositalizations}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Cases reports delayed from symptom onset" ///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 		
		"\addlinespace[0.3cm] \midrule Controls: state fixed effects"			/// 		
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