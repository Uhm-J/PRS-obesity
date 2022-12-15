import argparse
import glob

# Create Argument parser, --dir is the project directory
parser = argparse.ArgumentParser()
parser.add_argument('--dir', help='Project directory')
args = parser.parse_args()

if args.dir[-1] != '/':
    args.dir = args.dir + '/'

# Create a list of all the vcf files in the project directory
vcf_files = glob.glob(args.dir + 'Data/VCF/*.vcf')
print(vcf_files)
# Loop through the vcf files
with open(args.dir+"/Data/PLINK/case.ped", 'w') as out:
    for vcf in vcf_files:
        print(vcf)
        with open(vcf) as f:
            # Open the vcf file

                # Create a new file with the same name but a .txt extension
                FID = str(0)
                IID = str(vcf.split("/")[-1].split("_")[0])
                PID = '.'
                MID = '.'
                Sex = str(1)  # 1 male, 2 female
                PT = str(1)  # 1 case, 2 test
                out.write('\t'.join([FID, IID, PID, MID, Sex, PT]))
                for line in f:
                    # Loop through the lines in the vcf file
                    if line.startswith('#') or line.startswith('CHROM'):
                        # Skip the header lines
                        continue
                    else:
                        # Interlace columns 10 and 11 and write to the new file
                        out.write('\t{}\t{}'.format(line.split('\t')[10], line.split('\t')[11]).strip('\n'))
                out.write('\n')


