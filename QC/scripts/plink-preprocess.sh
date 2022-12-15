#!/bin/bash

# Parse arguments, --input is the input file, --snp is the snp file and --help is the help message
# Getopts is used to parse the arguments
while getopts "i:f:h" opt; do
    case $opt in
        i) input="$OPTARG" ;;
        f) hapmap="$OPTARG" ;;
        h) echo "Usage: $0 -i input_prefix -f hapmap_prefix" >&2
           exit 1 ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2
           exit 1 ;;

    esac
done
if (($OPTIND<4)); then
  echo "No or too little options were passed";
  echo "Usage: $0 -i input_prefix -f hapmap_prefix" >&2
  exit 1;
fi

cwd=$(pwd -P)/..
# Create an array of directories that contain data, plots, data/FAILS
for i in Data/PLINK Data/Output Data/Output/plots Data/PLINK/FAILS; do
    if [ ! -d $cwd/$i ]; then
        mkdir $cwd/$i
    fi
done



# Unpack the data
tar xfvz $cwd/$input.tgz -C $cwd/Data/

# Converting data to plink2 format
~/bin/plink2 --pedmap $cwd/Data/PLINK/$input --make-pgen --sort-vars --out $cwd/data/$input
~/bin/plink2 --pfile $cwd/Data/PLINK/$input --make-bed --out $cwd/Data/PLINK/$input
~/bin/plink2 --bfile $cwd/Data/PLINK/$hapmap --make-pgen --sort-vars --out $cwd/Data/PLINK/$hapmap
