
* Set up
clear all
eststo clear
use  "Data/DTA/contiguous_counties", clear

* Per capita counts if on
if "`1'"=="per_capita"{
	foreach y in cases deathsinvolvingcovid19 deaths_confirmed deathsfromallcauses admissions tests {
		replace `y'=`y'/population
	}
	local controls="c.tests##i.c_tests i.c_pos* i.c_repub  i.c_populationdensity i.c_householdsize i.c_percent* i.c_svi i.c_ccvi i.c_pct_vax i.metro"	
}

* Flexible demographic controls
foreach v of varlist tests positive repub population populationdensity householdsize percentlivinginpoverty percentpopulation65yrs svi ccvi pct_vax* {
	fasterxtile c_`v' = `v', nq(10)
	replace c_`v'=100 if inlist(c_`v',.)
}

* Dummy regression
quietly reg insurance
eststo dummy

* Loop Columns
forvalues c = 1/5{
	
	* Row Counter
	global r=1
	global rows="" // blank row for "Mean . (SD)" label
	
	* Store Estimates
	est restore dummy
	eststo col`c'
	
	* Controls
	if `c'==1{
		local controls="c.tests##i.c_tests"	
		local absorb="pair"
		estadd local pair = "\checkmark"
		estadd local tests = "\checkmark"
		estadd local demo = ""
		estadd local vax = ""
		estadd local pos = ""
	}
	if `c'==2{
		local controls="i.c_repub  i.c_populationdensity i.c_householdsize i.c_percent* i.c_svi i.c_ccvi i.metro"	
		local absorb="pair"
		estadd local pair = "\checkmark"
		estadd local tests = ""
		estadd local demo = "\checkmark"
		estadd local vax = ""
		estadd local pos = ""
	}
	if `c'==3{
		local controls="i.c_repub  i.c_populationdensity i.c_householdsize i.c_percent* i.c_svi i.c_ccvi i.c_pct_vax i.metro"	
		local absorb="pair"
		estadd local pair = "\checkmark"
		estadd local tests = ""
		estadd local demo = "\checkmark"
		estadd local vax = "\checkmark"
		estadd local pos = ""
	}
	if `c'==4{
		local controls="i.c_pos* i.c_repub  i.c_populationdensity i.c_householdsize i.c_percent* i.c_svi i.c_ccvi i.c_pct_vax i.metro"	
		local absorb="pair"
		estadd local pair = "\checkmark"
		estadd local tests = ""
		estadd local demo = "\checkmark"
		estadd local vax = "\checkmark"
		estadd local pos = "\checkmark"
	}		
	if `c'==5{
		local controls="c.tests##i.c_tests i.c_pos* i.c_repub  i.c_populationdensity i.c_householdsize i.c_percent* i.c_svi i.c_ccvi i.c_pct_vax i.metro"	
		local absorb="pair"
		estadd local pair = "\checkmark"
		estadd local tests = "\checkmark"
		estadd local demo = "\checkmark"
		estadd local vax = "\checkmark"
		estadd local pos = "\checkmark"
	}
	
	* Control for population if not per capita and demographic controls are on
	if "`1'"!="per_capita" & `c'>1 {
		local controls="`controls' i.c_population"	
	}
		
	* Summary statistics at bottom of table (unweighted)
		
		* Number of pairs
		unique pair
		local mean: di %10.0fc round(r(unique))	
		local mean = trim("`mean'")		
		estadd local cases = "`mean'"	
		
		* Number of counties
		unique fips
		local mean: di %10.0fc round(r(unique))	
		local mean = trim("`mean'")		
		estadd local groups = "`mean'"					
		
		* Average insurance rate
		sum insurance, meanonly
		local mean: di %10.3fc round(r(mean),.001)	
		local mean = trim("`mean'")		
		estadd local insurance = "`mean'"			
	
	* Loop over outcome rows
	foreach y in cases deathsinvolvingcovid19 deaths_confirmed deathsfromallcauses admissions pct_staffed_covid_bed pct_icu_covid_bed {
	
		* Totals
		sum insurance, meanonly
		local I = r(mean)
		unique fips
		local G = r(unique)
		cap drop dummy
		gegen dummy=total(`y')
		sum dummy, meanonly
		local sumY=r(mean)
		if inlist("`v'","pct_staffed_covid_bed","pct_icu_covid_bed"){
			local G=1
			local sumY=1
		}

		* Regression
		reghdfe `y' `controls' (insurance=treatment), a(`absorb') vce(cluster stnum pair) old
		
		* Convert to percentage
		lincom insurance  * (1-`I') * `G' / `sumY'
		
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
		local mean: di %10.0fc round(`sumY')	
		local mean = trim("`mean'")		
		estadd local t_`y' = "`mean'"		
	
		* Blank Row for space and titles
		estadd local blank=""

	}	

}

* Save Table
esttab col* using Output/contiguous_controls`1'.tex,				 				///
	stats(	blank b_cases se_cases t_cases										///
			blank b_deathsinvolvingcovid19 se_deathsinvolvingcovid19 t_deathsinvolvingcovid19	///
			blank b_deaths_confirmed se_deaths_confirmed t_deaths_confirmed		///
			blank b_deathsfromallcauses se_deathsfromallcauses t_deathsfromallcauses	///
			blank b_admissions se_admissions t_admissions						///
			blank b_pct_staffed_covid_bed se_pct_staffed_covid_bed 				///
			blank b_pct_icu_covid_bed se_pct_icu_covid_bed 						///
			cases groups insurance												///
			pair tests demo vax pos,				 							///
		fmt( %010.0gc )															///
		label(																	///
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 cases}}"				///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 deaths (probable)}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 deaths (confirmed)}}"	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 	
		"\addlinespace[0.3cm] \underline{\textit{Deaths (any cause)}}" 			///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 hospitalizations}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
			"\addlinespace[0.2cm]\hspace{.25cm}Total"							/// 
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 \% Staffed Beds}}" 	///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
		"\addlinespace[0.3cm] \underline{\textit{Covid-19 \% ICU Beds}}" 		///
			"\addlinespace[0.1cm]\hspace{.25cm}Insurance" 						///
			" " 																///
		"\addlinespace[0.3cm] \midrule Number of pairs"							///
		"\addlinespace[0.1cm]Number of counties"								/// 
		"\addlinespace[0.1cm]Ave. county insurance rate"						/// 
		"\addlinespace[0.3cm]Controls: pair fixed effects"						/// 		
		"\addlinespace[0.1cm]Controls: testing"									/// 		
		"\addlinespace[0.1cm]Controls: demographics"							/// 
		"\addlinespace[0.1cm]Controls: vaccinations"							/// 	
		"\addlinespace[0.1cm]Controls: positive test rate"						/// 			
		))																		///
	keep( ) replace nomtitles nonotes booktabs nogap nolines			 		///
	prehead(\begin{tabular}{l*{20}{x{1.7cm}}} \toprule) 						///
	posthead(\midrule)  														///
	postfoot(\bottomrule \end{tabular}) 

	
* Exit stata
exit, clear STATA