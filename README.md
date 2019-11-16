# pds-cdwh
Tools for parsing data from the pds data pull

## pipeline
The pre-processing pipeline looks something like this:

`cat ${dataroot}${drug}/observation_fact_dx.csv |./procCSV/filter-pids.pl -e ICD9  --nodryRun -i -
cat ${dataroot}${drug}/observation_fact_dx.csv |./procCSV/filter-pids.pl -e ICD10 --nodryRun -i -
mkdir -p ../out/${drug}/all
cat ../out/${drug}/ICD9/bleeding.pid-code ../out/${drug}/ICD10/bleeding.pid-code|sort -u > ../out/${drug}/all/bleeding.pid-code
./procCSV/xlate-ae-patvars.pl -e all -a bleeding -d ${drug} --nodryRun  > ../out/${drug}/all/bleeding.patvars 2`
