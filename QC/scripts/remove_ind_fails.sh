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
data_dir=$cwd/Data/PLINK
# Removing failed individuals
cat $data_dir/FAILS/* | sort -k1 | uniq > $data_dir/FAILS/fail-qc-inds.txt
~/bin/plink2 --pfile $data_dir/$input --remove $data_dir/FAILS/fail-qc-inds.txt --make-pgen --out $data_dir/$output