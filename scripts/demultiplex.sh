#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name demultiplex

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=10:00:00
#SBATCH --export NONE

module load gcc
module load stacks

cd /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing || exit 1

mkdir -p demultiplexed_sex_eggs

process_radtags -f merged_by_library/POOLx2_b_all_R1.fastq.gz -i gzfastq \
  -b barcodes_POOLx2_b.tsv -o demultiplexed_sex_eggs \
   --renz_1 ecoRI -c -q -r -t 143

  # r: rescues barcodes and cut sites w small errors
  # c: clean -remove reads with an uncalled base
  # q: quality filter
  # t 143: truncates reads to 143 basepairs;
  #151-8 base barcode is 143

  # options taken from https://academic.oup.com/evolut/article/78/6/1109/7631786#461344757

# renz_1 ecoRI: r enzyme
