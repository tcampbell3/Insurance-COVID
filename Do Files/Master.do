
* Change to your compter URL
clear all
global user="C:\Users\travi\Dropbox\Covid Medicare"
cd "${user}"

*****************************
	// 1) Create Dataset
*****************************

* BRFSS: State-age-sex-race health outcomes
do "Do Files/1 - BRFSS" 

* Contiguous counties
do "Do Files/1 - SAHIE" 														// Small area health insurance
do "Do Files/1 - Republican vote share" 										// County repub vote share
do "Do Files/1 - Provisional County Data" 										// County covid and total deaths 
do "Do Files/1 - Clean webscraped data" 										// County covid deaths, cases, hosp.
do "Do Files/1 - Clean webscraped state data" 									// County demographics, vaccine
do "Do Files/1 - Medicaid Thresholds" 											// Medicaid policies
do "Do Files/1 - Contiguous counties" 											// Final data for analysis

* Covid-19 case dataset
do "Do Files/1 - Covid cases" 

* Delay from symptom panel
do "Do Files/1 - Dynamic delay in treatment" 

******************************************
	  // 2) State-age-race-sex panel
******************************************

* Baseline figure
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Baseline figure" 
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Baseline figure - reformat"

* Cutoff delay figure
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Impact over cutoff date" 

* Find cutoff for baseline time frame
do "Do Files/2 - Distribution of reporting delay" 

* Descriptive Statistics
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Summary statistics" 
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - CDC Counts"

* Regression table - specification
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Specification (insurance)" 
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Specification (delay)" 
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Specification (insurance delay interaction)" 

* Regression table - mechanism
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Mechanism" 

* Regression table - robustness to delays in reporting
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Reporting delay" 

* Robustness test - missing data
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/2 - Missing data thresholds" 


**************************************
	  // 3) Contiguous counties
**************************************

winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Covariate Balance" 
do "Do Files/3 - Contiguous counties map" 				
do "Do Files/3 - Contiguous counties histograms" 				
do "Do Files/3 - Contiguous counties 2sls" 	
do "Do Files/3 - Contiguous counties 2sls - reformat" 		
do "Do Files/3 - Contiguous counties 2sls per capita" 							
do "Do Files/3 - Contiguous counties reduced form"
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Contiguous counties specification" 
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Contiguous counties specification" per_capita
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Contiguous counties sample" 	 	
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Contiguous counties sample" 	per_capita 	
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "Do Files/3 - Testing contiguous county over cutoff date" 

do "Do Files/3 - Map of state death reporting difference"