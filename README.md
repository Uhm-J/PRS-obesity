# Pipeline for Processing CYCHP Array Files to PRS Scores

## Table of Contents

-   [Pipeline for Processing CYCHP Array Files to PRS Scores](#pipeline-for-processing-cychp-array-files-to-prs-scores)
    -   [Input](#input)
    -   [Output](#output)
    -   [Configuration](#configuration)
    -   [Dependencies](#dependencies)
    -   [Execution](execution)
    -   [Rules](#rules)
        -   [`convert_cychp`](#convert_cychp)
        -   [`convert_ped`](#convert_ped)
        -   [`convert_map`](#convert_map)
        -   [`PLINK_preprocess`](#plink_preprocess)
        -   [QC Steps](#qc-steps)
        -   [`removeInd`](#removeind)
        -   [`PRSice`](#PRSice)
        -   [`all`](#all)

## Introduction

This pipeline is implemented using Snakemake, a Python-based workflow management system. It allows for the automation of complex pipelines and the management of dependencies between tasks.

The purpose of this pipeline is to process CYCHP array files, a type of genetic data, and generate polygenic risk scores (PRS).

## Input

The input to this pipeline consists of CYCHP array files stored in a specified directory (configured in the `config.json` file). The pipeline expects these files to be named according to a specific convention: `{patient}.cychp`.

## Output

The output of this pipeline is a PRS file, stored in a specified directory (configured in the `config.json` file). The output file will be named according to a specified convention (also configured in the `config.json` file).

## Configuration

The pipeline can be configured through the `config.json` file. This file should contain the following key-value pairs:

-   `RAW_DATA_DIR`: The directory containing the CYCHP array files.
-   `VCF_DIR`: The directory where VCF (Variant Call Format) files will be stored.
-   `PLINK2_BIN`: The path to the `plink2` binary.
-   `PLINK1.9_BIN`: The path to the `plink1.9` binary.
-   `DATA_DIR`: The directory where data files will be stored.
-   `ANNOTATION_FILE`: The path to the annotation file.
-   `PLINK_DIR`: The directory where PLINK files will be stored.
-   `HAPMAP`: The path to the HapMap file.
-   `OUT_DIR`: The directory where the output files will be stored.
-  `TMP_NAME`: The temporary name to use for the PLINK files.
-   `OUT_NAME`: The name to use for the output file.

## Dependencies

This pipeline has the following dependencies:

-   Python 3
-   Snakemake
-   R >4.1 (and several packages)
 

### Resources

This pipeline also needs the following files:

- Plink2 & Plink1.9 binary files ([CC Chang et al., 2015](https://academic.oup.com/gigascience/article/4/1/s13742-015-0047-8/2707533)).
- PRSice linux executable and R script ([SW Choi et al., 2019](https://academic.oup.com/gigascience/article/8/7/giz082/5532407))
- Cytoscan Array Analysis annotation file ([Affymetrix](https://www.affymetrix.com/api/downloads/na33/genotyping/))
-  International Hapmap Consortium ([IHP](https://www.genome.gov/10001688/international-hapmap-project)) 
 

## Execution

To run this pipeline, navigate to the directory containing the `Snakefile` and execute the following command:

Copy code

`snakemake -c [cores]` 

This will execute the pipeline according to the rules defined in the `Snakefile` and the configurations specified in the `config.json` file.

## Rules

The pipeline consists of the following rules:

### `convert_cychp`

This rule converts CYCHP array files to VCF format.

Input: A CYCHP array file (`{patient}.cychp`).

Output: A VCF file (`{patient}.vcf`).

### `convert_ped`

This rule generates a PED file from the VCF files.

Input: One or more VCF files (`{patient}.vcf`).

Output: A PED file (`{TMP_NAME}.ped`).

### `convert_map`

This rule generates a MAP file from the VCF files.

Input: One or more VCF files (`{patient}.vcf`).

Output: A MAP file (`{TMP_NAME}.map`).

### `PLINK_preprocess`

This rule preprocesses the
Output: PLINK files with the following extensions: `.pgen`, `.pvar`, `.psam`, `.bed`, `.bim`, `.fam`.

### QC Steps
The pipeline includes a series of QC steps that are performed using PLINK (adapted from ([CA Anderson et al., 2010](https://pubmed.ncbi.nlm.nih.gov/21085122/)). These steps are:

-   `PLINK_sexcheck`: This rule checks for discrepancies between reported and expected sex.
-   `PLINK_missvshet`: This rule checks for individuals with high missingness and extreme heterozygosity..
-   `PLINK_reldup`:  This rule checks for individuals that are related. 
-  `PLINK_ancestry`: This rule checks for individuals that do not have the desired ethnicity.
-  `PLINK_markerQC_diffmissing`: This rule checks for markers that have a high missing rate in the individuals. 

### `removeInd`

This rule removes individuals that fail any of the QC steps from the dataset.

Input: PLINK files with the following extensions: `.pgen`, `.pvar`, `.psam`, `.bed`.

Output: PLINK files with the following extensions: `.pgen`, `.pvar`, `.psam`, `.bed`.


### `PRSice`

This rule generates a clumped file and a set of plots showing the distribution of variant p-values and the proportion of variance explained by each variant.

Input: PLINK files with the following extensions: `.pgen`, `.pvar`, `.psam`, `.bed`.

Output: Clumped file (`{OUT_NAME}.best`) and plots showing the distribution of variant p-values and the proportion of variance explained by each variant.

### `all`

This is the default rule and represents the final target of the pipeline. It specifies the dependencies for the final output files.

Input: PLINK files with the following extensions: `.pgen`, `.pvar`, `.psam`, `.bed`, HapMap file with the following extensions: `.pgen`, `.pvar`, `.psam`, PRS file (`{OUT_NAME}.best`), and plots showing the distribution of variant p-values and the proportion of variance explained by each variant.

Output: PRS file (`{OUT_NAME}.best`).
