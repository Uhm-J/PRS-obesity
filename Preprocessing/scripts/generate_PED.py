import argparse
import glob

# Create Argument parser, --dir is the project directory
parser = argparse.ArgumentParser()
parser.add_argument('--dir', help='Project directory')
parser.add_argument('--out', help='Project directory')
args = parser.parse_args()

# Ensure that the project directory ends in a '/' character
if args.dir[-1] != '/':
    args.dir = args.dir + '/'

# Create a list of all the vcf files in the project directory
vcf_files = glob.glob(args.dir + '*.vcf')
print(vcf_files)
# Loop through the vcf files
with open(args.out, 'w') as out:
    for vcf in vcf_files:
        print(vcf)
        # Open the vcf file
        with open(vcf) as f:
            # Extract the family ID (FID) and individual ID (IID) from the vcf file name
            FID = str(vcf.split("/")[-1].split("_")[0])
            IID = str(vcf.split("/")[-1].split("_")[0])
            # Set the paternal ID (PID) and maternal ID (MID) to '0' if the father and mother are not in the dataset
            PID = '0'
            MID = '0'
            # Set the sex to '1' for male, '2' for female, and '0' for unknown
            Sex = str(1)
            # Set the phenotype (PT) to '1' for control, '2' for case, and '-9'/'0'/non-numeric for missing data if case/control
            PT = str(2)
            # Write the FID, IID, PID, MID, Sex, and PT values to the "case.ped" file
            out.write('\t'.join([FID, IID, PID, MID, Sex, PT]))
            # Loop through the lines in the vcf file
            for line in f:
                # Skip the header lines that start with '#' or "CHROM"
                if line.startswith('#') or line.startswith('CHROM'):
                    continue
                else:
                    # Interlace columns 10 and 11 from the vcf file and write them to the "case.ped" file
                    out.write('\t{}\t{}'.format(line.split('\t')[10], line.split('\t')[11]).strip('\n'))
            # Write a newline character to the "case.ped" file to separate each vcf file's data
            out.write('\n')

# Close the "case.ped" file when all vcf files have been processed