# eggs sexing
code used for sexing Bacillus eggs in October 2026

# Main sources used

I adapted the workflow and scripts from two papers and their corresponding github repos, as well as using AI (Claude) help in some parts. The parts that I did differently from these two papers are indicated in the workflow.

a) Timema pipeline

Paper: https://peercommunityjournal.org/item/10_24072_pcjournal_283/

GitHub: https://github.com/glavanc1/Timema_facultative_partheno/tree/master

b) Bacillus pipeline

Paper: https://academic.oup.com/evolut/article/78/6/1109/7631786#461344748

GiHub: https://github.com/AlexPopalex/bacillus/tree/main

# Workflow

## 1) Fastqc on individual raw fasta files
- warnings/fail: per tile sequence quality, adapted content (pre-trim), per base sequence content, duplication levels. Otherwise OK:

## 2) Merge library
- across 3 project runs, 2 lanes each.
- Different from Timema pipeline where merging is done at the bam stage. Stacks manual said If you have multiple pairs of files, you can run process_radtags multiple times (using a shell script) and concatenate the outputs together (or you can concatenate the input files together as well).
so i assumed its ok.
- script in [scripts/merge_eggs_per_library.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/merge_eggs_per_library.sh)

## 3) Demultiplex
- options taken from Bacillus paper, Methods
- Script in [scripts/demultiplex.sh](https://github.com/kingakaszap/eggs_sexing/blob/main/scripts/demultiplex.sh)
- Summary:
  
811912772 total sequences
4466232 barcode not found drops (0.6%)
16188653 low quality read drops (2.0%)
13458996 RAD cutsite not found drops (1.7%)
777798891 retained reads (95.8%)

- Log file in





