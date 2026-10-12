#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name stacks

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --export NONE

module load gcc
module load stacks

cd /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap//RAD_eggs_sexing
mkdir -p stacks

gstacks -t 16 --phasing-dont-prune-hets --ignore-pe-reads  -M popmap_for_stacks.txt -I mapped_filtered_brsri -O stacks
# options taken directly from https://github.com/glavanc1/Timema_facultative_partheno/blob/master/README.md -- not sure about the threads if i can ask 16 cpus 

mkdir -p populations_raw_vcf

populations -t 16 -M popmap_for_stacks.txt  -P stacks  -O populations_raw_vcf --vcf 
 # change - no filtering done at this step 
 # keep all the snps identified by gstacks.
