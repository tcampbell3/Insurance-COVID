
* Set up
clear all
eststo clear
cd "${user}"

* Open data
use "F:/Covid-19 Data/delay_demographic", clear

* Specification
local controls="_d* _h* _c*"
local absorb="stfips time agecat sexcat racecat"
local y = "death"
local cluster = "stfips#agecat#sexcat#racecat"
cap program drop _controls
program _controls
	estadd local fips = "\checkmark"
	estadd local time = "\checkmark"
	estadd local age = "\checkmark"
	estadd local sex = "\checkmark"
	estadd local race = "\checkmark"
	estadd local dem = "\checkmark"
	estadd local hea= "\checkmark"
	estadd local com = "\checkmark"
	end

* Regressions
reghdfe `y' insurance `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance delay_count  `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance hosp `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance positive `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance delay_count hosp `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance delay_count positive `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance hosp positive `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls
reghdfe `y' insurance delay_count hosp positive `controls', a(`absorb') vce(cluster `cluster')
eststo
_controls

* Save Table
esttab using Output/mechanisms.tex, keep(insurance delay_count hosp positive) b(%10.4fc) se(%10.4fc) star( * .1 ** .05 *** .01) nonotes stats(N r2 fips time age sex race dem hea com, fmt(%010.0fc %010.2fc) label("Observations" "\$R^2$" "Controls: state fixed effects" "Controls: time fixed effects (daily)" "Controls: age fixed effects" "Controls: sex fixed effects" "Controls: race fixed effects" "Controls: demographics" "Controls: health" "Controls: comorbidities"))  nomti coef(insurance "Insurance coverage rate (2019)" delay "Case reports delayed from symptom onset" positive "Covid-19 daily cases" hosp "Covid-19 daily hospitalizations") replace
	
* Exit stata
exit, clear STATA