# Parse arguments, --input is the input file, --snp is the snp file and --help is the help message
# Getopts is used to parse the arguments
while getopts "i:h" opt; do
    case $opt in
        i) input="$OPTARG" ;;
        h) echo "Usage: $0 -i input_prefix" >&2
           exit 1 ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2
           exit 1 ;;

    esac
done
if (($OPTIND<2)); then
  echo "No or too little options were passed";
  echo "Usage: $0 -i input_prefix" >&2
  exit 1;
fi

cwd=$(pwd -P)/..
dups_dir=$cwd/Data/PLINK/dups
# if directory sexcheck doesnt exist, create it
if [ ! -d $dups_dir ]; then
    mkdir $dups_dir
fi

# Making king-table to find related individuals
~/bin/plink2 --pfile $cwd/Data/PLINK/$input --make-king-table --king-table-filter 0.25 --out $dups_dir/$input

# Identifying the related individuals
awk 'NR!=1 {print $2,$1; print $4,$3}' $dups_dir/$input.kin0 > $cwd/Data/PLINK/FAILS/fail-relation-qc.txt
