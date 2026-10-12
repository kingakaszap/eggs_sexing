#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name coverage

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=12G
#SBATCH --time=08:00:00
#SBATCH --export NONE

module load gcc
module load samtools
module load bedtools2

samtools faidx /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing/brsri_ref/ncbi_dataset/data/GCF_032445375.1/GCF_032445375.1_Brsri_v3_genomic.fna 
cd /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing

mkdir -p coverage

for bam in ./mapped_filtered_brsri/*-filtered.bam; do
  name=$(basename $bam -filtered.bam)
  genomeCoverageBed -ibam $bam -g  /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing/brsri_ref/ncbi_dataset/data/GCF_032445375.1/GCF_032445375.1_Brsri_v3_genomic.fna.fai > coverage/${name}_coverage.out
done