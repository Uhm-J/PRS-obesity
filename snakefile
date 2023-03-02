"""
Author: Jorrit van Uhm


TLDR;
This script is a pipeline for preprocessing and performing quality control on genetic data. It uses Snakemake for rule-based workflow management and various tools 
such as PLINK and R scripts for the different steps of the pipeline. The pipeline starts with the conversion of raw data files to VCF, followed by the generation 
of PED and MAP files. It then uses PLINK2 to preprocess the data and generate various PLINK file formats, and PLINK1.9 to perform a sex check. The pipeline continues 
with missingness and relatedness checks, ancestry assignment, and pruning of the data. The final outputs of the pipeline are specified in the 'all' rule.



This script is a pipeline for preprocessing and performing quality control on genetic data. It uses Snakemake for rule-based workflow management.

load_config(config_file):
Reads a JSON file with configuration parameters and returns the data as a dictionary.

get_patient_ids(wildcards=None):
Calls the 'ls' command to list the files in the directory specified in the configuration dictionary under the key 'RAW_DATA_DIR'.
The function decodes the output of the command, splits it on newline characters, and returns a list of patient IDs.

convert_cychp:
This is a Snakemake rule that takes as input a file in the 'RAW_DATA_DIR' directory and converts it to a VCF file using an R script.
The output is a VCF file in the 'VCF_DIR' directory.

convert_ped:
This is a Snakemake rule that takes as input the VCF files in the 'VCF_DIR' directory and generates a PED file.
The output is a PED file in the 'PLINK_DIR' directory.

convert_map:
This is a Snakemake rule that takes as input the VCF files in the 'VCF_DIR' directory and generates a MAP file using an R script.
The output is a MAP file in the 'PLINK_DIR' directory.

PLINK_preprocess:
This is a Snakemake rule that uses PLINK2 to preprocess the input ped and map files. It generates various PLINK file formats as outputs.
The HAPMAP dataset is also processed to generate PLINK file formats.

PLINK_sexCheck:
This is a Snakemake rule that uses PLINK1.9 to perform a sex check on the input PLINK files. It generates an output plot showing sex discrepancies.

PLINK_missvshet:
This is a Snakemake rule that uses PLINK2 to calculate missingness and heterozygosity statistics on the input PLINK files.
It generates an output plot showing missingness and an output file with a list of individuals to exclude based on missingness criteria.

PLINK_reldup:
This is a Snakemake rule that uses PLINK2 to identify and remove related individuals from the input PLINK files.
It generates an output plot showing relatedness and an output file with a list of individuals to exclude.

PLINK_ancestry_*:
This is a Snakemake rule that uses PLINK2 to perform principal component analysis and assign ancestry labels to the input PLINK files.
It generates an output plot showing ancestry and an output file with the assigned ancestry labels.

PLINK_removeInd:
This is a Snakemake rule that uses PLINK2 to prune the input PLINK files based on the lists of excluded individuals from the previous quality control steps.
It generates an output file with the pruned data.

PLINK_markerQC:
This is SNakemake rule that uses PLINK2 to identify markers with a lot of missing values or heterozygosity that is out of proportions.
It generates an output file with the low scoring markers.

all:
This is the top-level Snakemake rule that specifies the final output files of the pipeline. It depends on the outputs of the other rules.
"""

import subprocess
import json

def load_config(config_file):
    with open(config_file, "r") as f:
        return json.load(f)
    
def get_patient_ids(wildcards=None):
    result = subprocess.run(['ls', config["RAW_DATA_DIR"]], stdout=subprocess.PIPE)
    patient_ids = result.stdout.decode('utf-8').strip().split('\n')
    print('get_patient_ids function called')
    print(patient_ids)
    return patient_ids


config=load_config('config.json')
RDD=config['RAW_DATA_DIR']
VD=config['VCF_DIR']
plink2=config["PLINK2_BIN"]
data_dir=config["DATA_DIR"]
yaml_environment="env/env_prs.yaml"


rule all:
    input:
        ['{}/{}.{}'.format(config["PLINK_DIR"], config["TMP_NAME"], ext) for ext in ["pgen", "pvar", "psam", "bed"]],
        ['{}.{}'.format(config["HAPMAP"], ext) for ext in ["pgen", "pvar", "psam"]],
        "{}/plots/{}.clean_inds.vmiss.pdf".format(config["OUT_DIR"], config["TMP_NAME"]),
        '{}/{}.best'.format(config["OUT_DIR"], config["OUT_NAME"])

rule convert_cychp:
    threads: 1
    mem_mb: 1024
    conda: yaml_environment
    input:
        '{RDD}/{{patient}}'.format(RDD=RDD)
    output:
        '{VD}/{patient}.vcf'
    shell:
        'Rscript Preprocessing/scripts/convert_cychp.R {input} {output} {config[ANNOTATION_FILE]}'


rule convert_ped:
    threads: 4
    mem_mb: 8192
    conda: yaml_environment
    input:
        expand('{VD}/{patient}.vcf',VD=VD, patient=get_patient_ids())
    output:
        '{}/{}.ped'.format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        'python Preprocessing/scripts/generate_PED.py --dir {VD} --out {output}'

rule convert_map:
    threads: 4
    mem_mb: 8192
    input:
        expand('{VD}/{patient}.vcf',VD=VD, patient=get_patient_ids())
    output:
        '{}/{}.map'.format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        'Rscript Preprocessing/scripts/generate_MAP.R {VD} {output}'

# Preprocessing PLINK files
rule PLINK_preprocess:
    threads: 4
    mem_mb: 16384
    conda: yaml_environment
    input:
        ped='{}/{}.ped'.format(config["PLINK_DIR"], config["TMP_NAME"]),
        map='{}/{}.map'.format(config["PLINK_DIR"], config["TMP_NAME"])
    output:
        ['{}/{}.{}'.format(config["PLINK_DIR"], config["TMP_NAME"], ext) for ext in ["pgen", "pvar", "psam", "bed", "bim", "fam"]],
        ['{}.{}'.format(config["HAPMAP"], ext) for ext in ["pgen", "pvar", "psam"]]
    shell:
        "{plink2} --pedmap {config[PLINK_DIR]}/{config[TMP_NAME]} --make-pgen --sort-vars --out {config[PLINK_DIR]}/{config[TMP_NAME]} &&"
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]} --make-bed --out {config[PLINK_DIR]}/{config[TMP_NAME]} &&"
        "{plink2} --bfile {config[HAPMAP]} --make-pgen --sort-vars --out {config[HAPMAP]}"

# First step of QC: SexCheck
# using plink1.9 since this is depreciated in plink2       
rule PLINK_sexCheck:
    threads: 2
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_preprocess.output
    output:
        '{}/FAILS/fail-sexcheck-qc.txt'.format(config["PLINK_DIR"])
    shell:
        '{plink1.9} --bfile {config[PLINK_DIR]}/{config[TMP_NAME]} --check-sex --out {config[PLINK_DIR]}/{config[TMP_NAME]} &&'
        'grep PROBLEM {config[PLINK_DIR]}/{config[TMP_NAME]}.sexcheck > {config[PLINK_DIR]}/{config[TMP_NAME]}.sexprobs &&'
        "awk '{{print $1,$2}}' {config[PLINK_DIR]}/{config[TMP_NAME]}.sexprobs > {config[PLINK_DIR]}/FAILS/fail-sexcheck-qc.txt"

rule PLINK_missvshet:
    threads: 2
    mem_mb: 4096
    conda: yaml_environment
    input: 
        rules.PLINK_preprocess.output
    output:
        pdf='{}/plots/{}.miss_vs_het.pdf'.format(config['OUT_DIR'], config['TMP_NAME']),
        txt='{}/FAILS/fail-missing-qc.txt'.format(config["PLINK_DIR"])
    shell:
        '{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]} --missing --out {config[PLINK_DIR]}/{config[TMP_NAME]} &&'
        '{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]} --het --out {config[PLINK_DIR]}/{config[TMP_NAME]} &&'
        'Rscript QC/scripts/smiss-vs-het.Rscript {config[PLINK_DIR]}/{config[TMP_NAME]}.smiss {config[PLINK_DIR]}/{config[TMP_NAME]}.het {output.pdf} {output.txt}'

rule PLINK_reldup:
    threads: 2
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_preprocess.output
    output:
        '{}/FAILS/fail-relation-qc.txt'.format(config["PLINK_DIR"])
    shell:
        '{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]} --make-king-table --king-table-filter 0.25 --out {config[PLINK_DIR]}/{config[TMP_NAME]} &&'
        "awk 'NR!=1 {{print $2,$1; print $4,$3}}' {config[PLINK_DIR]}/{config[TMP_NAME]}.kin0 > {config[PLINK_DIR]}/FAILS/fail-relation-qc.txt"

rule PLINK_ancestry_prune:
    threads: 2
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_preprocess.output
    output:
        hapmap_pruned="{}/hapmap.pruned.pgen".format(config["PLINK_DIR"]),
        gwa_pruned="{}/{}.pruned.pgen".format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]} --extract {config[SNPS]} --make-pgen --out {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps &&"
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps --extract {config[PLINK_DIR]}/{config[TMP_NAME]}.prune.in --make-pgen --out {config[PLINK_DIR]}/{config[TMP_NAME]}.pruned &&"
        "{plink2} --pfile {config[HAPMAP]} --extract {config[PLINK_DIR]}/{config[TMP_NAME]}.prune.in --make-pgen --out {config[PLINK_DIR]}/hapmap.pruned"

rule PLINK_ancestry_convert:
    threads: 2
    mem_mb: 8192
    conda: yaml_environment
    input:
        rules.PLINK_ancestry_prune.output
    output:
        hapmap_bcf="{}/hapmap.bcf".format(config["PLINK_DIR"]),
        gwa_bcf="{}/{}.hapmap-snps.bcf".format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        "{plink2} --pfile {config[PLINK_DIR]}/hapmap.pruned --export vcf bgz vcf-dosage=DS-force --out {config[PLINK_DIR]}/hapmap &&"
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]}.pruned --export vcf bgz vcf-dosage=DS-force --out {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps &&"
        "bcftools view -Ob {config[PLINK_DIR]}/hapmap.vcf.gz > {config[PLINK_DIR]}/hapmap.bcf &&"
        "bcftools view -Ob {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.vcf.gz > {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.bcf &&"
        "bcftools index -f {config[PLINK_DIR]}/hapmap.bcf &&"
        "bcftools index -f {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.bcf"

rule PLINK_ancestry_fixref:
    threads: 4
    mem_mb: 8192
    conda: yaml_environment
    input:
        "{}/hapmap.bcf".format(config["PLINK_DIR"]),
        "{}/{}.hapmap-snps.bcf".format(config["PLINK_DIR"], config["TMP_NAME"])
        
    output:
        "{}/hapmap.fixref.bcf".format(config["PLINK_DIR"]),
        "{}/{}.hapmap-snps.fixref.bcf".format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        "echo {input} &&"
        "bcftools +fixref {input[0]} -Ob -- -d -f {config[REF_GENOME]} -m flip > {output[0]} &&"
        "bcftools +fixref {input[1]} -Ob -- -d -f {config[REF_GENOME]} -m flip > {output[1]} &&"
        "bcftools index -f {output[0]} &&"
        "bcftools index -f {output[1]}"

rule PLINK_ancestry_merge:
    threads: 4
    mem_mb: 8192
    conda: yaml_environment
    input:
        "{}/hapmap.fixref.bcf".format(config["PLINK_DIR"]),
        "{}/{}.hapmap-snps.fixref.bcf".format(config["PLINK_DIR"], config["TMP_NAME"])
    output:
        "{}/{}.hapmap-snps.merged.vcf".format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        "bcftools merge -Ob -o {output} {input[0]} {input[1]}"

rule PLINK_ancestry_PCA:
    threads: 4
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_ancestry_merge.output
    output:
        txt="{}/FAILS/fail-pca-qc.txt".format(config["PLINK_DIR"]),
        pdf='{}/plots/{}.ancestry.pdf'.format(config['OUT_DIR'], config['TMP_NAME'])
    shell:
        "{plink2} --vcf {input} --make-pgen --sort-vars --out {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.merged &&"
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.merged --pca 2 --make-pgen --out {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.merged &&"
        "Rscript QC/scripts/plot-pca.R {output.txt} {config[PLINK_DIR]}/{config[TMP_NAME]}.hapmap-snps.merged.eigenvec {config[HAPMAP]}.psam {output.pdf}"

rule PLINK_removeInd:
    threads: 4
    mem_mb: 4096
    conda: yaml_environment
    input:
        '{}/FAILS/fail-sexcheck-qc.txt'.format(config["PLINK_DIR"]),
        '{}/FAILS/fail-missing-qc.txt'.format(config["PLINK_DIR"]),
        '{}/FAILS/fail-relation-qc.txt'.format(config["PLINK_DIR"]),
        "{}/FAILS/fail-pca-qc.txt".format(config["PLINK_DIR"])
    output:
        "{}/{}.clean_inds.pgen".format(config["PLINK_DIR"], config["TMP_NAME"])
    shell:
        "cat {config[PLINK_DIR]}/FAILS/* | sort -k1 | uniq > {config[PLINK_DIR]}/FAILS/fail-qc-inds.txt &&"
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]} --remove {config[PLINK_DIR]}/FAILS/fail-qc-inds.txt --make-pgen --out {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds"

rule PLINK_markerQC_ExcessiveMissing:
    threads: 4
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_preprocess.output
    output:
        "{}/plots/{}.clean_inds.vmiss.pdf".format(config["OUT_DIR"], config["TMP_NAME"])
    shell:
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds --missing --make-pgen --out {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds &&"
        "Rscript QC/scripts/vmiss-hist.Rscript {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds.vmiss {output[0]}"

rule PLINK_markerQC_Diffmissing:
    threads: 4
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_preprocess.output
    output:
        "{}/FAILS/fail-diffmiss-qc.txt".format(config["PLINK_DIR"])
    shell:
        "{plink2} --pfile {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds --make-bed --out {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds &&"
        "plink1.9 --bfile {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds --test-missing --make-bed --out {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds &&"
        "python QC/scripts/diffmiss-qc.py --input {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds.missing --output {output}"

rule PLINK_markerQC:
    threads: 4
    mem_mb: 4096
    conda: yaml_environment
    input:
        rules.PLINK_markerQC_Diffmissing.output
    output:
        ['{}/{}.{}'.format(config["OUT_DIR"], config["OUT_NAME"], ext) for ext in ["pgen", "pvar", "psam", "eigenvec", "eigenval", "cov"]]
    shell:
        "{plink2} --bfile {config[PLINK_DIR]}/{config[TMP_NAME]}.clean_inds --exclude {input} --maf 0.01 --geno 0.05 --make-pgen --out {config[OUT_DIR]}/{config[OUT_NAME]} &&"
        "{plink2} --pfile {config[OUT_DIR]}/{config[OUT_NAME]} --freq --out {config[OUT_DIR]}/{config[OUT_NAME]} &&"
        "{plink2} --pfile {config[OUT_DIR]}/{config[OUT_NAME]} --pca 10 --out {config[OUT_DIR]}/{config[OUT_NAME]} &&"
        "{plink2} --pfile {config[OUT_DIR]}/{config[OUT_NAME]} --covar {config[OUT_DIR]}/{config[OUT_NAME]}.eigenvec --write-covar cols=sid,fid,sex --make-bed --out {config[OUT_DIR]}/{config[OUT_NAME]}"

rule PRSice:
    threads: 8
    mem_mb: 16384
    conda: yaml_environment
    input:
        rules.PLINK_markerQC.output
    output:
        '{}/{}.best'.format(config["OUT_DIR"], config["OUT_NAME"])
    shell:
        "Rscript PRSice.R --prsice {config[PRSICE]} --base {config[BASE_DATA]} --target {config[OUT_DIR]}/{config[OUT_NAME]}"
        "--binary-target F --pheno {config[Phenotype]} --cov {config[OUT_DIR]}/{config[OUT_NAME]}.covariate"
        "--base-maf MAF:0.01 --base-info INFO:0.8 --stat OR --or --out {config[OUT_DIR]}/{config[OUT_NAME]}"