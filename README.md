# eggs_sexing
code used for sexing Bacillus eggs in October 2026

# Main sources used

I adapted the workflow and scripts from two papers and their corresponding github repos. I also used generative AI (Claude) for help in some parts. The parts I did differently from these two papers are indicated in the workflow.

### a) Timema pipeline

Paper:<br>
Larose, C., Lavanchy, G., Freitas, S., Parker, D. J., & Schwander, T. (2023). Facultative parthenogenesis: a transient state in transitions between sex and obligate asexuality in stick insects?. Peer Community Journal, 3.

https://peercommunityjournal.org/item/10_24072_pcjournal_283/

GitHub:<br>
https://github.com/glavanc1/Timema_facultative_partheno/tree/master

### b) Bacillus pipeline

Paper:<br>
Lavanchy, G., Brandt, A., Bastardot, M., Dumas, Z., Labédan, M., Massy, M., ... & Schwander, T. (2024). Evolution of alternative reproductive systems in Bacillus stick insects. Evolution, 78(6), 1109-1120.

https://academic.oup.com/evolut/article/78/6/1109/7631786#461344748

GiHub:<br>
https://github.com/AlexPopalex/bacillus/tree/main

# Workflow and notes

## 1) Fastqc on individual raw fasta files
- warnings/fail: per tile sequence quality, adapted content (pre-trim), per base sequence content, duplication levels. Otherwise OK.

## 2) Merge library
- across 3 project runs, 2 lanes each.
- Different from Timema pipeline where merging is done at the bam stage. Stacks manual said "If you have multiple pairs of files, you can run process_radtags multiple times (using a shell script) and concatenate the outputs together (or you can concatenate the input files together as well)".
so i assumed it's ok.
- script in [scripts/merge_eggs_per_library.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/merge_eggs_per_library.sh)

## 3) Demultiplex
- options taken from Bacillus paper, Methods:
-  --renz_1 ecoRI -c -q -r -t 143
- Script in [scripts/demultiplex.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/demultiplex.sh)
- Summary:
  
811912772 total sequences \
4466232 barcode not found drops (0.6%) \
16188653 low quality read drops (2.0%) \
13458996 RAD cutsite not found drops (1.7%) \
777798891 retained reads (95.8%) \ 

- Log file in [logs/process_radtags.merged_by_library.log](https://github.com/kingakaszap/eggs_sexing/blob/main/logs/process_radtags.merged_by_library.log)
  
## 4) Trim
- options and software from Bacillus paper (default parameters)
- using trim_galore 2.3.0
 and cutadapt 5.2 through miniconda
- Script in [scripts/trim.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/trim.sh)
- FastQC and MultiQC post-trimming: [logs/multiqc_trimmed.html](https://github.com/kingakaszap/eggs_sexing/blob/main/logs/multiqc_trimmed.html)
- Fail: high duplicate read counts (https://www.biostars.org/p/450909/ says its ok);
per sequence content - Joao said that Vincent said that was normal; otherwise all passed;
Mean quality scores around 43
- Lots of variation in nr of reads / egg; some explained by age; some of the low read eggs were also flagged in the lab, but not all.

## 5) Map to reference genome
- Bacillus rossius redtenbacheri refgenome downloaded from NCBI + indexed
- Options and pipeline from Timema GitHub
- Make separate slurm scripts per sample: [scripts/bwa_mem_SLURM_script_maker.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/bwa_mem_SLURM_script_maker.sh)
- Run samtools flagstat on some bams -> no qc failed reads; most samples have around 99% mapping rate. 2 samples under:
   - E25-500-trimmed.bam 3167447 + 0 mapped (89.65% : N/A) - ALSO in the ones flagged during lab
   - E25-529-trimmed.bam 338238 + 0 mapped (62.66% : N/A) - should not be among problematic ones; but low read count
- index and filter bam files: Filtering with options from Bacillus pipeline; script in [scripts/filter_bam_files.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/filter_bam_files.sh)
```
samtools view -h -@ 4 $bam | grep -v -e 'XA:Z:' -e 'SA:Z:' \
    | samtools view -b -@ 4 -F 2308 -q 20 -o "$output_bam"
  samtools index "$output_bam"
```
- these bams will be the basis of the X to autosome coverage ratio used for sexing

## 6) Variant calling
- Following Timema pipeline from GitHub (readme, section SNP calling) + Brsri reference genome for all individuals
- Input requires a popmap.txt file - I put all samples as the same population.
- Script in [scripts/variant_calling.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/variant_calling.sh)

## 7) Variant filtering 
- Mixing Timema and Bacillus pipeline
- Using vcftools
- 1 snp / rad locus
- Options:
  ```
   vcftools --vcf populations_1snp/populations.snps.vcf \
  --min-alleles 2 --max-alleles 2 \
  --minDP 8 \
  --mac 3 \
  --max-missing 0.5 \
  --recode --recode-INFO-all \
  --out populations_1snp/DP8_miss50_mac3_1snp
  ```
- Script in [scripts/vcf_filter_timema.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/vcf_filter_timema.sh)

## 8) Compare coverage of X chromosome vs autosomes 
- X = Scaffold 2 (from bacillus paper) which is refseqAccession":"NC_086331.1" from ref genome
- run bedtools like [this](https://github.com/glavanc1/Timema_facultative_partheno/blob/master/ID_Tdi_X.sh) script; genome_calc section. Differences: they have paired end and I have single end, also they merge by lane/run here and i did it earlier.
- Use [GenomeCoverageBed_tidier.py](https://github.com/glavanc1/Timema_facultative_partheno/blob/master/accessory_scripts/genomeCoverageBed_tidier.py) for output (unchanged)
- Then [Timema_cov_tidyer.py](https://github.com/glavanc1/Timema_facultative_partheno/blob/master/accessory_scripts/Timema_cov_tidier.py) - asked Claude to adapt this script. Also changed options: keeping only scaffolds > 1m bp while they kept >1000 bp.
- then using some of [Tim_cov_analysis.R](https://github.com/glavanc1/Timema_facultative_partheno/blob/master/Tim_cov_analysis.R). Per egg, divide coverage of X / average coverage of autosomal scaffolds above a size threshold.

## 9) Analysis of both coverage and heterozygosity in R
- Script: [scripts/analysis.R](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/analysis.R)
- Final df-s in [data/eggs_sex_coverage_heterozygosity.xlsx](https://github.com/kingakaszap/eggs_sexing/blob/main/data/eggs_sex_coverage_heterozygosity.xlsx)
  and [data/eggs_sex_assigned.xlsx](https://github.com/kingakaszap/eggs_sexing/blob/main/data/eggs_sex_assigned.xlsx). Sex was assigned arbitarily. For heterozygosity, I used heterozygosity on the X as a metric, but values for X-to-autosomal heterozygosity ratios are also in the first df.
  - Plot in [plots/coverage_and_heterozygosity.png](https://github.com/kingakaszap/eggs_sexing/blob/main/plots/coverage_and_heterozygosity.png)
  

  





