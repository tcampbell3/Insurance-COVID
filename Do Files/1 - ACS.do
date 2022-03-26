


* Insurance rate
clear all
tempfile temp b c
local year="2019"
local geo="county"
local key="bf0f4e24f672b69a2bb2208f3bb4b5a35878f0c8"
local data="group(B27001)"
!curl -k  "https://api.census.gov/data/`year'/acs/acs5?get=NAME,`data'&for=`geo':*&key=`key'" -o "`temp'.txt" 
filefilter "`temp'.txt" `b', replace from(",\n") to("\n")
filefilter `b' `c', replace from("[") to("")
filefilter `c' "`temp'.txt", replace from("]") to("")
import delimited "`temp'.txt", clear case(upper)
drop *A *M
g fips = STATE*1000+COUNTY
rename C27001_004E insure_m_18
rename C27001_005E uninsure_m_18
rename C27001_007E insure_m_18_64
rename C27001_008E uninsure_m_18_64
rename C27001_010E insure_m_64
rename C27001_011E uninsure_m_64
rename C27001_014E insure_f_18
rename C27001_015E uninsure_f_18
rename C27001_017E insure_f_18_64
rename C27001_018E uninsure_f_18_64
rename C27001_020E insure_f_64
rename C27001_021E uninsure_f_64
gegen insured = rowtotal(insure*)
gegen uninsured = rowtotal(uninsure*)
g insurance = insured/(uninsured+insured)
keep fips insurance
compress
save Data/DTA/county_insurance, replace




* Insurance rate
clear all
tempfile temp b c
local year="2019"
local geo="county"
local key="bf0f4e24f672b69a2bb2208f3bb4b5a35878f0c8"
local data="C27001_004E,C27001_005E,C27001_007E,C27001_008E,C27001_010E,C27001_011E,C27001_014E,C27001_015E,C27001_017E,C27001_018E,C27001_020E,C27001_021E"
!curl -k  "https://api.census.gov/data/`year'/acs/acs5?get=NAME,`data'&for=`geo':*&key=`key'" -o "`temp'.txt" 
filefilter "`temp'.txt" `b', replace from(",\n") to("\n")
filefilter `b' `c', replace from("[") to("")
filefilter `c' "`temp'.txt", replace from("]") to("")
import delimited "`temp'.txt", clear case(upper)
g fips = STATE*1000+COUNTY
rename C27001_004E insure_m_18
rename C27001_005E uninsure_m_18
rename C27001_007E insure_m_18_64
rename C27001_008E uninsure_m_18_64
rename C27001_010E insure_m_64
rename C27001_011E uninsure_m_64
rename C27001_014E insure_f_18
rename C27001_015E uninsure_f_18
rename C27001_017E insure_f_18_64
rename C27001_018E uninsure_f_18_64
rename C27001_020E insure_f_64
rename C27001_021E uninsure_f_64
gegen insured = rowtotal(insure*)
gegen uninsured = rowtotal(uninsure*)
g insurance = insured/(uninsured+insured)
keep fips insurance
compress
save Data/DTA/county_insurance, replace

