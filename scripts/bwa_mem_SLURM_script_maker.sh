#!/bin/bash --login
#SBATCH --account tschwand_alt_splicing
#SBATCH --mail-type ALL
#SBATCH --mail-user kkaszap@unil.ch
#SBATCH --job-name make_scripts

#SBATCH -o logs/%x_%j.stdout
#SBATCH -e logs/%x_%j.stderr

#SBATCH --partition cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --export NONE


## This script makes a separate slurm script for each sample.
## They can be submitted separately through a for loop.
## The script requires three arguments:
dir=$1 ## the directory containing the demultiplexed fastq reads (I usually call it 'clean')
genome=$2 ## the path and name of the reference genome
THREADS=$3 ## the number of threads requested per job

## Usage example:
## bash bwa_mem_SLURM_script_maker.sh $(pwd)/clean/ $(pwd)/genome/1_Tdi_b3v08.fasta 1

cd $dir/.. || exit 1

mkdir -p /work/FAC/FBM/DEE/tschwand/miya/Gene_duplication/kkaszap/scripts/bwa_mem_SLURM_scripts
mkdir -p mapped_brsri

for i in $(ls $dir/*.fq.gz)
do

        j=$(echo $i | tr '/' '\n' | grep '.fq.gz' | sed 's/.fq.gz//g')
#       echo "Sample = $j
        echo "#!/bin/bash --login" > ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
       #  echo "#SBATCH -p cpu" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --account=tschwand_alt_splicing" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --job-name=bwa_mem_${j}" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --mem=16G" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        
        echo "#SBATCH --time=2:00:00" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --mail-user kkaszap@unil.ch" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --mail-type=ALL" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH -o logs/%x_%j.stdout" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH -e logs/%x_%j.stderr" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --partition cpu" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --nodes=1" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --ntasks=1" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "#SBATCH --cpus-per-task=${THREADS}" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "module load gcc/11.5.0" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "module load bwa/0.7.19" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "module load samtools/1.21" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh
        echo "bwa mem -t ${THREADS} ${genome} $i | samtools sort --output-fmt=BAM --threads ${THREADS} -o $(pwd)/mapped_brsri/${j}.bam -" >> ./bwa_mem_SLURM_scripts/${j}_bwa_mem_slurm.sh

done
