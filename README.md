# PRS-obesity
Obesity PRS calculation 

Snakemake pipeline used for preprocessing and performing quality control on genetic data. It uses Snakemake for rule-based workflow management and various tools 
such as PLINK and R scripts for the different steps of the pipeline. The pipeline starts with the conversion of raw data files to VCF, followed by the generation 
of PED and MAP files. It then uses PLINK2 to preprocess the data and generate various PLINK file formats, and PLINK1.9 to perform a sex check. The pipeline continues 
with missingness and relatedness checks, ancestry assignment, and pruning of the data.
Following protocol from (paper).



