
* Set up
clear all
eststo clear
cd "${user}"

* Open data
use "F:/Covid-19 Data/delay_demographic", clear

* Stack dataset
preserve
	g stack=2
	tempfile temp
	save `temp',replace
restore
g stack=1
append using `temp'

* Treatment variables
g _insurance = insurance * (stack==1)
g _delay = delay_count * (stack==2 )

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
		local absorb="stfips#stack"
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
		local absorb="stfips#stack time#stack"
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
		local absorb="stfips#stack time#stack agecat#stack"
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
		local absorb="stfips#stack time#stack agecat#stack sexcat#stack"
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
		local absorb="stfips#stack time#stack agecat#stack sexcat#stack racecat#stack"
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
		local controls="c.(_d*)#stack"
		local absorb="stfips#stack time#stack agecat#stack sexcat#stack racecat#stack"
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
		local controls="c.(_d* _h*)#stack"
		local absorb="stfips#stack time#stack agecat#stack sexcat#stack racecat#stack"
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
		local controls="c.(_d* _h* _c*)#stack"
		local absorb="stfips#stack time#stack agecat#stack sexcat#stack racecat#stack"
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
		sum population if stack==1, meanonly
		local mean: di %10.0fc round(r(mean))	
		local mean = trim("`mean'")		
		estadd local pop = "`mean'"
		
		* Average total cases
		cap drop _total_cases
		bys stfips agecat sexcat racecat: gegen _total_cases= sum(positive) if stack==1
		sum _total_cases if stack==1, meanonly
		local mean: di %10.0fc round(r(mean))	
		local mean = trim("`mean'")		
		estadd local cases = "`mean'"	
		
		* Number of groups
		cap drop _total_groups
		gegen _total_groups= group(stfips agecat sexcat racecat) if stack==1
		sum _total_groups if stack==1, meanonl
		local _g=r(max)
		local mean: di %10.0fc round(r(max))	
		local mean = trim("`mean'")		
		estadd local groups = "`mean'"			
		
		* Number of days
		cap drop _total_days
		gegen _total_days= group(time) if stack==1
		sum _total_days if stack==1 , meanonly 
		local _d = r(max)
		local mean: di %10.0fc round(r(max))	
		local mean = trim("`mean'")		
		estadd local days = "`mean'"			
		
		* Average insurance rate
		sum insurance if stack==1, meanonly
		local _i = r(mean)
		local mean: di %10.3fc round(r(mean),.001)	
		local mean = trim("`mean'")		
		estadd local insurance = "`mean'"			
	
	* Loop over outcome rows
	foreach y in death positive hosp  {
	
		* Outcome (stack 1 is impact of insurance on delay; stack 2 is impact of delay on outcome)
		cap drop _y
		g _y = delay_count
		replace _y = `y' if inlist(stack,2) 
	
		* Total 
		cap drop _total
		gegen _total = sum(`y') if stack==1
		sum _total if stack==1, meanonly
		local _t=r(mean)
	
		* Regression
		reghdfe _y _insurance _delay `controls' i.stack, a(`absorb') vce(cluster stfips#agecat#sexcat#racecat)
	
		* Estimate
		nlcom _b[_insurance] * `_g' * `_d' * (1-`_i') * _b[_delay]
		mat b=r(b)
		mat v=r(V)
		local pvalue = 2*normal(-abs(b[1,1]/(sqrt(v[1,1]))))
		
		* Store regression coefficient
		local b: di %10.3gc round(b[1,1],.001)	
		local b = trim("`b'")
		local se: di %10.3gc round(sqrt(v[1,1]),.001)	
		local se = trim("`se'")
		local N=r(N)
		local star =""
		if `pvalue'<.1{
			local star "^{*}"
		}
		if `pvalue'<.05{
				local star "^{**}"
		}
		if `pvalue'<.01{
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
esttab col* using Output/controls_delay_insurance.tex,				 			///
	stats(	blank b_death se_death N_death 										///
			blank b_positive se_positive N_positive								///
			blank b_hosp se_hosp N_hosp											///
			fips time age sex race dem hea com, 								///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 deaths}}"				///
			"\addlinespace[0.1cm]\hspace{.25cm}\$\Delta\$Delays with full insurance" ///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 	
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 cases}}" 				///
			"\addlinespace[0.1cm]\hspace{.25cm}\$\Delta\$Delays with full insurance" ///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Sample size"						/// 				
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 hositalizations}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}\$\Delta\$Delays with full insurance" ///
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
	prehead(\begin{tabular}{l*{20}{x{2.3cm}}} \toprule) 							///
	posthead(\midrule)  														///
	postfoot(\bottomrule \end{tabular}) 

	
* Exit stata
exit, clear STATA