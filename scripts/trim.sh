#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name trim

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --export NONE


source ../software/miniconda3/etc/profile.d/conda.sh   
conda activate trim
which trim_galore cutadapt # shows what i used

module load gcc
module load fastqc

cd /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing/demultiplexed_sex_eggs || exit 1
mkdir -p ../trimmed_sex_eggs

for f in *.fq.gz; do # check if demultiplexed files are gz before running
  trim_galore --cores 8 -o ../trimmed_sex_eggs $f
done

cd ../trimmed_sex_eggs || exit 1
for f in *_trimmed.fq.gz; do mv -- "$f" "${f%_trimmed.fq.gz}-trimmed.fq.gz"; done