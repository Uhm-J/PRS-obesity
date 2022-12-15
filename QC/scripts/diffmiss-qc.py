# Parse arguments
import argparse
parser = argparse.ArgumentParser(description='Run diffmiss QC')
parser.add_argument('--input', type=str, required=True, help='input file (.missing)')
parser.add_argument('--master-directory', type=str, required=True, help='master directory')

args = parser.parse_args()
fails = []

# Loop through input file
with open(args.input, 'r') as f:
    for line in f:
        # Remove new line, split on space, and remove empty strings in list
        line = list(filter(None, line.rstrip().split(' ')))
        if line[0].upper() == 'CHR': # Skip header
            continue
        elif float(line[4]) < 0.0002: # Check if P-value is less than 0.02%
            fails.append(line[1])

# Write output to file and create the file
with open(args.master_directory + '/FAILS/fail-diffmiss-qc.txt', 'w') as f:
    for fail in fails:
        f.write(fail + '\n')