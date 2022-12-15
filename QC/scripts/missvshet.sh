# Parse arguments, --input is the input file, --snp is the snp file and --help is the help message
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
mvh_dir=$cwd/Data/PLINK/missvshet
output=$cwd/Data/Output/plots/$output.miss_vs_het.pdf
# if directory missvshet doesnt exist, create it
if [ ! -d $mvh_dir ]; then
    mkdir $mvh_dir
fi

# Create missing and heterozygosity files
~/bin/plink2 --pfile $cwd/Data/PLINK/$input --missing --out $mvh_dir/$input
~/bin/plink2 --pfile $cwd/data/PLINK/$input --het --out $mvh_dir/$input

# Creating a plot of missingness vs heterozygosity
Rscript $cwd/scripts/smiss-vs-het.Rscript $mvh_dir/$input.smiss $mvh_dir/$input.het $output $cwd2

