# 1. Install packages
# BiocManager::install("affyio")


# Set input file equal to first argument
project_dir=commandArgs()[6]
print(commandArgs())
if (substr(project_dir, nchar(project_dir), nchar(project_dir)) != "/") {
  project_dir <- paste0(project_dir, "/")
}


lib_files <- paste(project_dir, "lib/", sep="")
input_dir <- paste(project_dir, "Data/Raw/cychp/", sep="")


# 2. Load packages
library(affyio)
library(dplyr)

annotate <- function(in_name, out_name, annotation){
  print(in_name)
  geno <- Read.CYCHP(in_name)
  
  # background
  # From this: http://media.affymetrix.com/support/developer/powertools/changelog/gcos-agcc/cychp.html, it explains the cychp format.
  # Essentially, the Genotyping Data Group contains the call coming from BRLMM-P, which I assumed part of the Chas software.
  # The index is in 0-based and can be mapped to the probes set
  
  # create a data frame for the probes
  ProbeSetName = geno$DataGroup$ProbeSets$Datasets$CopyNumber$DataColumns$ProbeSetName
  Chromosome = geno$DataGroup$ProbeSets$Datasets$CopyNumber$DataColumns$Chromosome
  Position = geno$DataGroup$ProbeSets$Datasets$CopyNumber$DataColumns$Position
  probes_df = data.frame("ProbeSetName" = ProbeSetName, "Chromosome" = Chromosome, "Position" = Position)
  # create a column for 0-based index
  probes_df$Index = as.numeric(rownames(probes_df)) - 1

  
  # create a datafrane for the calls
  Index = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$Index
  Call = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$Call
  Confidence = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$Confidence
  ForcedCall = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$ForcedCall
  ASignal = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$ASignal
  BSignal = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$BSignal
  SignalStrength = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$SignalStrength
  Contrast = geno$DataGroup$Genotyping$Datasets$Calls$DataColumns$Contrast
  
  calls_df = data.frame("Index" = Index,
                        "Call" = Call,
                        "Confidence" = Confidence,
                        "ForcedCall" = ForcedCall,
                        "ASignal" = ASignal,
                        "BSignal" = BSignal,
                        "SignalStrength" = SignalStrength,
                        "Contrast" = Contrast)
  
  
  # convert calls 
  # 6 = AA (0/0), 7=BB (1/1), 8=AB (0/1)
  # Is 11 no calls? Annotate 11 as . for No Call
  calls_df = calls_df %>% mutate(Genotype = case_when(Call==6 ~ "0/0",  Call==7 ~ "1/1", Call==8 ~ "0/1",  Call==11 ~ "."))
  
  # merge based on index
  merged_calls_probes = merge(probes_df, calls_df, by = "Index")
  
  
  # merge with annotation
  merged_calls_probes_rs = merge(merged_calls_probes, annotation, by.x=c("ProbeSetName"), by.y = c("Probe.Set.ID"))
  
  # sanity check
  # checking if the labeling of the chromosome is correct
  eq <- merged_calls_probes_rs$Chromosome.x==merged_calls_probes_rs$Chromosome.y
  
  # checking if the position is correct
  eq <- merged_calls_probes_rs$Position==merged_calls_probes_rs$Physical.Position
  merged_calls_probes_rs = merged_calls_probes_rs %>% mutate(A_Allele = case_when(Call==6 ~ Allele.A,  Call==7 ~ Allele.B, Call==8 ~ Allele.A,  Call==11 ~ "0"))
  merged_calls_probes_rs = merged_calls_probes_rs %>% mutate(B_Allele = case_when(Call==6 ~ Allele.A,  Call==7 ~ Allele.B, Call==8 ~ Allele.B,  Call==11 ~ "0"))
  
  # create a df for vcf format
  #I'm assuming that Allele.A is reference and Allele.B is alternate
  vcf_fmt_df = data.frame("CHROM" = merged_calls_probes_rs$Chromosome.x,
                          "POS" = merged_calls_probes_rs$Position,
                          "ID" = merged_calls_probes_rs$dbSNP.RS.ID,
                          "REF" = merged_calls_probes_rs$Allele.A,
                          "ALT" = merged_calls_probes_rs$Allele.B,
                          "QUAL" = ".",
                          "FILTER" = ".",
                          "INFO" = ".",
                          "FORMAT" = "GT",
                          "GT" = merged_calls_probes_rs$Genotype,
                          "Allele.A" = merged_calls_probes_rs$A_Allele,
                          "Allele.B" = merged_calls_probes_rs$B_Allele
                  )
                          
  
  write.table(vcf_fmt_df, out_name, quote = F, sep = "\t", row.names = F)
}

annotation = read.csv(paste(lib_files, "CytoScanHD_Array.na33.annot.csv", sep = ''), comment.char = "#")

files <- list.files(input_dir)
for(file in files){
  full_name <- paste(input_dir, file, sep="")
  out <- paste(project_dir, "Data/VCF/", file, ".vcf", sep="")
  annotate(full_name, out, annotation)
}
