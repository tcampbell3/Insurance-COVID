# Insurance-COVID
Replication files for the [Campbell, Galvani, Friedman, & Fitzpatrick (2022)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4001496) *Exacerbation of COVID-19 mortality by the fragmented United States healthcare system*.

The "Master.do" do-file reports each step of the analysis. The analysis was carried out on Stata 16. 

The primary analysis uses data for COVID-19 deaths and hospitalizations from [COVID-19 Case Surveillance Restricted Use Detailed Data](https://data.cdc.gov/Case-Surveillance/COVID-19-Case-Surveillance-Restricted-Access-Detai/mbd7-r32t), which is not publically available. We measure the insurance coverage, health, and comorbidities for each state-sex-age-race group before the pandemic using publically available from the CDC, [Behavioral Risk Factors Surveillance Systems (2015-2019)](https://www.cdc.gov/brfss/annual_data/annual_2019.html). Since the Case Surveillance data is restricted use, the replication files only include the steps of our analysis in Stata (.do files), we are unable to include data for replication. Interested researchers can apply for access using the above hyperlink. Unfortunately, the data is provisional, implying the current data may be different from that used in our analysis.

Replication files are also included for our county-level analysis of Medicaid expansion. 
The data for the county-level analysis comes from multiple sources. We measure the 2019 county-level insurance rate using the [2008 - 2019 Small Area Health Insurance Estimates (SAHIE) using the American Community Survey (ACS)](https://www.census.gov/data/datasets/time-series/demo/sahie/estimates-acs.html). The data for county-level deaths and covid-19 deaths related deaths (probable/confirmed) comes from [Provisional COVID-19 Death Counts in the United States by County](https://data.cdc.gov/NCHS/Provisional-COVID-19-Death-Counts-in-the-United-St/kn79-hsxy). The county-level data for COVID-19 confirmed deaths, cases, tests, and hospitalizations is web scraped from the CDC's [COVID-19 Integrated County View](https://covid.cdc.gov/covid-data-tracker/#county-view). Data on the republican share of the 2016 presidential vote is taken from [County Presidential Election Returns 2000-2016](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ). All of the source data for the county-level analysis is publically available, hence the replication files include both the data and programs. County-level replication exercises should begin at line 66 of the "Master.do" do-file.

[![DOI](https://zenodo.org/badge/474384156.svg)](https://zenodo.org/badge/latestdoi/474384156)

## Author
- Travis Campbell -- Contact me at tbcampbell@umass.edu
