#!/bin/bash

# Getopts is used to parse the arguments
while getopts "i:s:f:o:h" opt; do
    case $opt in
        i) input="$OPTARG" ;;
        s) snps="$OPTARG" ;;
        f) hapmap="$OPTARG" ;;
        o) output="$OPTARG" ;;
        h) echo "Usage: $0 -i input_prefix -s snps.txt -f hapmap_prefix -o output_prefix" >&2
           exit 1 ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2
           exit 1 ;;

    esac
done
if (($OPTIND < 8)); then
  echo "No or too little options were passed"
  echo "Usage: $0 -i input_prefix -s snps.txt -f hapmap_prefix -o output_prefix" >&2
  exit 1
fi

# Create variables for directories and files based on arguments
cwd=$(pwd -P)/..
cdw2=$(pwd -P)/..
data_dir=$cwd/Data/PLINK
ancestry_dir=$data_dir/ancestry
output=$cwd/Data/Output/plots/$output.ancestry.pdf

# Create function that checks if there's an error or fail in the log file and stops the script if there is
log=$cwd/logs/ancestry.log
function check_error {
    if grep -q -i "error" $log; then
        echo "There was an error in the log file, please check it";
        exit 1;
    elif grep -q -i "fail" $log; then
        echo "There was an error in the log file, please check it";
        exit 1;
    fi
}
# If ancestry directory does not exist, create it
if [ ! -d $ancestry_dir ]; then
    mkdir $ancestry_dir
fi

 Extract (predefined) snps from raw-GWA-data
~/bin/plink2 --pfile $data_dir/$input --extract $data_dir/$snps --make-pgen --out $ancestry_dir/$input.hapmap-snps

# Extract overlapping snps from hapmap and raw-GWA-data
~/bin/plink2 --pfile $ancestry_dir/$input.hapmap-snps --extract $data_dir/$input.prune.in --make-pgen --out $ancestry_dir/$input.pruned
~/bin/plink2 --pfile $data_dir/$hapmap --extract $data_dir/$input.prune.in --make-pgen --out $ancestry_dir/$hapmap.pruned
check_error

# Convert data to bcf format
~/bin/plink2 --pfile $ancestry_dir/$hapmap.pruned --export vcf bgz vcf-dosage=DS-force --out $ancestry_dir/$hapmap
~/bin/plink2 --pfile $ancestry_dir/$input.pruned --export vcf bgz vcf-dosage=DS-force --out $ancestry_dir/$input.hapmap-snps
check_error

bcftools view -Ob $ancestry_dir/$hapmap.vcf.gz > $ancestry_dir/$hapmap.bcf
bcftools view -Ob $ancestry_dir/$input.hapmap-snps.vcf.gz > $ancestry_dir/$input.hapmap-snps.bcf
check_error

# Normalize BCF files ?
#bcftools norm -m-any -Ob hapmap3r2_CEU.CHB.JPT.YRI.founders.no-at-cg-snps.vcf.gz > hapmap3r2_CEU.CHB.JPT.YRI.founders
# .no-at-cg-snps.norm.bcf
#bcftools norm -m-any -Ob raw-GWA-data.hapmap-snps.vcf.gz  > raw-GWA-data.hapmap-snps.norm.bcf

# Index both bcf files
bcftools index -f $ancestry_dir/$hapmap.bcf
bcftools index -f $ancestry_dir/$input.hapmap-snps.bcf
check_error

# Fix ref to make sure that the reference genome is the same for both files
ref='/home/jorrit/Reference-genomes/hg19/Build/hg19_ref_genome.fa'
bcftools +fixref $ancestry_dir/$input.hapmap-snps.bcf -Ob -- -d -f $ref -m flip > $ancestry_dir/$input.hapmap-snps.fixref.bcf
bcftools +fixref $ancestry_dir/$hapmap.bcf -Ob -- -d -f $ref -m flip > $ancestry_dir/$hapmap.fixref.bcf
check_error

# Index both fixed bcf files
bcftools index -f $ancestry_dir/$input.hapmap-snps.fixref.bcf
bcftools index -f $ancestry_dir/$hapmap.fixref.bcf
check_error

# Merge the two bcf files
bcftools merge -Ob -o $ancestry_dir/$input.hapmap-snps.merged.vcf $ancestry_dir/$hapmap.fixref.bcf $ancestry_dir/$input.hapmap-snps.fixref.bcf
check_error

# Convert back to plink2 format
~/bin/plink2 --vcf $ancestry_dir/$input.hapmap-snps.merged.vcf --make-pgen --sort-vars --out $ancestry_dir/$input.hapmap-snps.merged
check_error

# Run ancestry analysis
~/bin/plink2 --pfile $ancestry_dir/$input.hapmap-snps.merged --pca 2 --make-pgen --out $ancestry_dir/$input.hapmap-snps.merged
check_error

# Plot the results and find outliers
Rscript $cwd/scripts/plot-pca.R $cdw2 $ancestry_dir/$input.hapmap-snps.merged.eigenvec $data_dir/$hapmap.psam $output
check_error
echo "PCA constructed and plotted successfully."
