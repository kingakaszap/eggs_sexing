#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name bam_filtering

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=08:00:00
#SBATCH --export NONE

module load gcc
module load samtools

mapped_bams="/work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing/mapped_brsri"
mapped_filtered_bams="/work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing/mapped_filtered_brsri"

mkdir -p $mapped_filtered_bams

for bam in $mapped_bams/*.bam; do

 base_name=$(basename "$bam")
 clean_name="${base_name%-trimmed.bam}"
 output_bam="$mapped_filtered_bams/${clean_name}-filtered.bam"

 samtools view -h -@ 4 $bam | grep -v -e 'XA:Z:' -e 'SA:Z:' \
    | samtools view -b -@ 4 -F 2308 -q 20 -o "$output_bam"
  samtools index "$output_bam"
done