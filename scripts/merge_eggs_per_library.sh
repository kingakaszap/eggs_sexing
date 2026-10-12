#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing  
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name merge

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=01:00:00
#SBATCH --export NONE

cd /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/RAD_eggs_sexing || exit 1

mkdir -p merged_by_library
for lib in POOLx2_a POOLx2_b; do # in the end i only need 2b
  cat run*_project806/${lib}_*_R1_001.fastq.gz > merged_by_library/${lib}_all_R1.fastq.gz
done

for lib in POOLx2_a POOLx2_b; do
  in=$(stat -c %s run*_project806/${lib}_*_R1_001.fastq.gz | awk '{s+=$1} END{print s}')
  out=$(stat -c %s merged_by_library/${lib}_all_R1.fastq.gz)
  echo "$lib input bytes: $in  output bytes: $out" # sanity check that sizes are the same
done

