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
# if directory sexcheck doesnt exist, create it
if [ ! -d $cwd/Data/PLINK/sexcheck ]; then
    mkdir $cwd/Data/PLINK/sexcheck
fi

# Perfoming sexcheck with plink1.9, since plink2 does not have this option
plink1.9 --bfile $cwd/Data/PLINK/$input --check-sex --out $cwd/Data/PLINK/sexcheck/$input

# Identifying the failed individuals
grep PROBLEM $cwd/Data/PLINK/sexcheck/$input.sexcheck > $cwd/Data/PLINK/sexcheck/$input.sexprobs
awk '{print $1,$2}' $cwd/Data/PLINK/sexcheck/$input.sexprobs > $cwd/Data/PLINK/FAILS/fail-sexcheck-qc.txt
