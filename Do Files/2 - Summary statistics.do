
* Open Data
use "F:/Covid-19 Data/delay_demographic", clear
eststo clear

* Totals
gcollapse  (mean) insurance (sum) death positive hosp delay_count delay_length

* Label variables
label var insurance "\addlinespace[0.3cm] \textit{Means:} & \\ \hspace{.25cm} Insurance coverage"
label var death "\addlinespace[0.3cm] \textit{Totals:} & \\\hspace{.25cm} COVID-19 deaths"
label var positive "\hspace{.25cm} COVID-19 cases" 
label var hosp "\hspace{.25cm} New hospitalizations"
label var delay_count "\hspace{.25cm} Cases between symptom onset and CDC report"
label var delay_length "\hspace{.25cm} Days between symptom onset and CDC report"


* Summary statistics
estpost su insurance death positive hosp delay_count delay_length
esttab .  using "Output/sumstats.tex", cells(sum(fmt(3 0))) noobs  replace collabels(none) nomti nogap label

* Exit stata
exit, clear STATA