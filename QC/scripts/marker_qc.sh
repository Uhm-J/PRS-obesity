# Getopts is used to parse the arguments
while getopts "i:o:h" opt; do
    case $opt in
        i) input="$OPTARG" ;;
        o) output="$OPTARG" ;;
        h) echo "Usage: $0 -i input_prefix -o output_prefix" >&2
           exit 1 ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2
           exit 1 ;;

    esac
done
if (($OPTIND<4)); then
  echo "No or too little options were passed";
  echo "Usage: $0 -i input_prefix -o output_prefix" >&2
  exit 1;
fi

cwd=$(pwd -P)/..
cwd2=$(pwd -P)/..
data_dir=$cwd/Data/PLINK
marker_dir=$cwd/Data/PLINK/marker_qc

# if marker_qc does not exist, create it
if [ ! -d $marker_dir ]; then
    mkdir $marker_dir
fi


# Identification of all markers with an excessive missing rate
~/bin/plink2 --pfile $data_dir/$input --missing --make-pgen --out $marker_dir/$input
Rscript $cwd/scripts/vmiss-hist.Rscript $marker_dir/$input.vmiss $cwd/plots/$input.vmiss.pdf $cwd2

# test markers for different genotype call rates between cases and controls
~/bin/plink2 --pfile $data_dir/$input --make-bed --out $marker_dir/$input
plink1.9 --bfile $marker_dir/$input --test-missing --make-bed --out $marker_dir/$input
python $cwd/scripts/diffmiss-qc.py --input $marker_dir/$input.missing --master-directory $data_dir
#perl $cwd/scripts/run-diffmiss-qc.pl $marker_dir/$input $data_dir

# Eemoving poor SNPs
~/bin/plink2 --bfile $marker_dir/$input --exclude $data_dir/FAILS/fail-diffmiss-qc.txt --maf 0.01 --geno 0.05 \
--make-pgen --out $cwd/Data/Output/$output


# Creating files necessary for PRSice
# alelle frequency, eigenvec, eigenval, and cov file
~/bin/plink2 --pfile $cwd/Data/Output/$output --freq --out $cwd/Data/Output/$output
~/bin/plink2 --pfile $cwd/Data/Output/$output --pca 10 --out $cwd/Data/Output/$output
~/bin/plink2 --pfile $cwd/Data/Output/$output --covar $cwd/Data/Output/$output.eigenvec --write-covar cols=sid,fid,sex --make-bed --out $cwd/output/$output