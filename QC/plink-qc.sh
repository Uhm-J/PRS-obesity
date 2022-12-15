# if directory logs doesnt exist, create it
if [ ! -d ../logs ]; then
    mkdir ../logs
fi

data="raw-GWA-data"
hapmap="hapmap3r2_CEU.CHB.JPT.YRI.founders.no-at-cg-snps"
snps="hapmap3r2_CEU.CHB.JPT.YRI.no-at-cg-snps.txt"
clean_ind="clean-inds-GWA-data"
clean="clean-GWA-data"

bash scripts/plink-preprocess.sh -i $data -f $hapmap 2>&1 | tee ../logs/plink-preprocess.log
bash scripts/sexcheck.sh -i $data 2>&1 | tee ../logs/sexcheck.log
bash scripts/missvshet.sh -i $data -o $data 2>&1 | tee ../logs/missvshet.log
bash scripts/related_duplicated.sh -i $data 2>&1 | tee ../logs/related_duplicated.log
bash scripts/ancestry.sh -i $data -s $snps -f $hapmap -o ancestry  2>&1 | tee ../logs/ancestry.log
bash scripts/remove_ind_fails.sh -i $data -o $clean_ind 2>&1 | tee ../logs/remove_ind_fails.log
bash scripts/marker_qc.sh -i $clean_ind -o $clean 2>&1 | tee ../logs/marker_qc.log

# grep for error in all the logs and print them
creation=$(date +"%d-%m-%Y_%H:%M")
mkdir ../logs/$creation
mv ../logs/*.log ../logs/$creation
if grep -q -i "error" ../logs/$creation/*.log; then
    echo "There was an error in the log file, please check it";
    grep -i error ../logs/$creation/*.log | tee ../logs/$creation/errors_$creation.logSum
    exit 1;
elif grep -q -i "fail" logs/$creation/*.log; then
    echo "There was an error in the log file, please check it";
    grep -i fail logs/$creation/*.log | tee ../logs/$creation/errors_$creation.logSum
    exit 1;
fi

# If -d flag is passed, delete all the data files
if [ "$1" == "-d" ]; then
    rm -r data
fi