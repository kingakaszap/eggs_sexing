#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name vcf_filter

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --export NONE

module load vcftools
module load gcc
module load stacks

cd /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing
mkdir -p populations_1snp

populations -t 8 -M popmap_for_stacks.txt -P stacks -O populations_1snp --write-single-snp --vcf || exit 1
# --min/max-alleles 2: biallelic SNPs only (Bacillus allowed 2-3
# --minDP 8: genotypes with depth < 8 out (Bacillus)
# --mac 3: minor allele count >= 3 (bacillus  andTimema both do this)
# --max-missing 0.5: bacillus , Timema is stricter, does 0.75)
vcftools --vcf populations_1snp/populations.snps.vcf \
  --min-alleles 2 --max-alleles 2 \
  --minDP 8 \
  --mac 3 \
  --max-missing 0.5 \
  --recode --recode-INFO-all \
  --out populations_1snp/DP8_miss50_mac3_1snp