clear all
import delimited "Data\Contiguous counties\countypres_2000-2016.csv", clear 
keep if inlist(year,2016)& inlist(party,"republican")
foreach v in candidatevotes fips{
	replace `v'="" if inlist(`v', "NA")
	destring `v' ,replace
}
g republican_share = candidatevotes / totalvotes
keep fips republican_share
drop if inlist(fips,.)
compress
gsort fips
save Data/DTA/republican_vote_share, replace