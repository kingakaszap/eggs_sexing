# October 2026
# sexing bacillus eggs based on X-to-autosome coverage and based on heterozygosity on the X
# males are expected to have half the coverage of X as of autosomes
# and have near 0 heterozygosity on the x

# libraries and data ----

library(readxl)
library(tidyverse)
library(writexl)
library(modeest)

# reads per egg
reads <- read.table("data/trim_galore_filtered_reads_plot.tsv", sep = '\t', header = TRUE)

# age of eggs
egg_age <- read_xlsx("data/EGG_AGE.xlsx")

# eggs flagged in lab
flagged <- read_xlsx("data/flagged_eggs.xlsx")

# coverage per egg
d <- read.csv("data/Brsri_minlen=1000000_contig_cov.txt", check.names = FALSE)

# heterozygosity per egg
# function to count heterozygous sites
# dif function
count_het <- function(vcf) {
  con <- gzfile(vcf); on.exit(close(con))
  l <- readLines(con)
  l <- l[!startsWith(l, "##")]                       # drop header lines, keep #CHROM line
  d <- read.table(text = l, sep = "\t", header = TRUE, comment.char = "",
                  quote = "", check.names = FALSE, colClasses = "character")
  gt <- as.matrix(d[, -(1:9), drop = FALSE])         # first 9 columns = site info
  gt <- matrix(substr(gt, 1, 3), nrow = nrow(gt), dimnames = list(NULL, colnames(gt)))  # GT part only
  called <- gt != "./." # exclude missing sites
  het    <- gt == "0/1" | gt == "1/0" # heterozygous sites
  # everything else (0/0 and 1/1) is homozygous
  data.frame(Egg_ID  = sub("-filtered$", "", colnames(gt)),
             sites  = colSums(called),
             het    = colSums(het),
             het_frac = colSums(het) / colSums(called),
             # heterozygosity of this scaffold: heterozygous sites/called sites
             row.names = NULL)}
# function to read X and autosomes together
het_X_vs_A <- function(x_vcf, a_vcf) {
  x <- count_het(x_vcf); a <- count_het(a_vcf)
  names(x)[-1] <- paste0("X_", names(x)[-1])
  names(a)[-1] <- paste0("A_", names(a)[-1])
  out <- merge(x, a, by = "Egg_ID")
  out$X_het_over_A <- out$X_het_frac / out$A_het_frac
  out
}
# get data
het_filtered <- het_X_vs_A("data/filtered_X.vcf", "data/filtered__autosomes.vcf.gz")

# checks ----
# check 1: for heterozygosity: check that everything is separated by / and not by | 
gt_check <- function(vcf) {
  con <- gzfile(vcf); on.exit(close(con))
  l <- readLines(con)
  l <- l[!startsWith(l, "#")]                        
  fields <- strsplit(l, "\t", fixed = TRUE)
  g <- unlist(lapply(fields, function(f) substr(f[-(1:9)], 1, 3)))   # GT part of every cell
  sort(table(g), decreasing = TRUE)
}

gt_check("data/filtered_X.vcf")
gt_check("data/filtered__autosomes.vcf.gz")
# good

# check 2: for reads: observed varying number of reads per egg. Check against egg age

reads <- reads %>% rename(Egg_ID = Sample)
combined <- left_join(reads, egg_age, by = "Egg_ID")
nrow(combined)

(plot <- ggplot (combined, aes (x = Time_point, y = Passed.filters))+ geom_point() + 
    xlab("egg age")+ ylab("reads")+theme_bw())
ggsave("plots/age_vs_reads_per_egg.png",plot, dpi = 300, height = 5, width = 7)

# check 3: if the ones that were flagged in lab are the ones with low reads
combined <- combined %>%  mutate(flagged = ifelse(Egg_ID %in% flagged$Egg_ID, 
                                                  "yes", "no"))
# just look at df - some low read ones flagged during lab maybe failed to amplify

# coverage -----
# some parts adapted from Tim_cov_analysis
# with ai help

eggs <- setdiff(colnames(d), c("contig", "length"))
Xname <- "NC_086331.1" # x chromosome from paper and sequence report from ncbi file

coverage_data <- do.call(rbind, lapply(eggs, function(e) {
  v <- d[[e]]; names(v) <- d$contig
  X <- v[[Xname]]
  auto <- v[names(v) != Xname]          # autosomes only
  
  # sanity checks that i did indeed remove the x
  stopifnot(Xname %in% names(v),                 # X exists in the table
            !(Xname %in% names(auto)),           # X is not among  autosomes
            length(auto) == length(v) - 1)       # exactly one scaffold was removed
  auto <- auto[auto > 0]     # drop scaffolds with zero coverage
  
  mod <- as.numeric(mlv(auto, method = "shorth"))    #normalise by the shorth mode
  # as in timema script
  data.frame(Egg_ID = e, n_autosomes = length(auto),
             X_cov = X, autosomes_cov_mode = mod, autosomes_cov_median = median(auto), autosomes_cov_mean = mean(auto),
             X_cov_over_mode = X / mod, X_cov_over_med = X / median(auto), X__cov_over_mean = X / mean(auto))
}))

(ggplot(coverage_data, aes(x = Egg_ID, y = X__cov_over_mean ))+geom_point() + theme_bw()+
    labs (x = "egg")) # looks like a nice separation generally

all_egg_data <- left_join(combined, coverage_data, by = "Egg_ID")
# View(all_egg_data)

# x heterozygosity ----

# with filtering closer to original script 
# options mixed from bacillus and timema scripts

heterozygosity_filt <- left_join(all_egg_data, het_filtered, by = "Egg_ID")

heterozygosity_filt$Time_point<-as.factor(heterozygosity_filt$Time_point)

(plot_heterozygosity = ggplot(heterozygosity_filt, aes(x = X__cov_over_mean, y= X_het_frac, 
colour = Female_population, fill = Female_population))+
    geom_point(size =1.7) +theme_bw()+ylab("X heterozygosity ")+ scale_colour_brewer(palette= "Set1")+
    xlab ("\nX coverage / mean coverage")+ ylab("X heterozygosity\n")+
    labs(colour = "Population",
    fill = "Population") +
    theme(axis.text = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12),
          axis.title = element_text(size = 12)))

ggsave("plots/coverage_and_heterozygosity.png", dpi = 300, width = 8, height = 5)

write_xlsx(x = heterozygosity_filt, path = "data/eggs_sex_coverage_heterozygosity.xlsx",col_names = TRUE)

# do cutoffs ----

# Sex by coverage : 
# 0.75 to 1: Female
# under 0.75 Male
# (excludes 2 outliers with very high X cov that were also flagged in the lab)
# keeps 1 as a male that sits on 0.60 coverage, otherwise quite unambigous
heterozygosity_filt <- heterozygosity_filt %>% 
  mutate(sex_by_cov = case_when
         (X__cov_over_mean < 0.75 ~ "male",
          X__cov_over_mean > 0.75 & X__cov_over_mean< 1 ~ "female"))
# Sex by heterozygosity
# > 0.027 Female (based on plot so that left bottom blob will be males)
# below male
heterozygosity_filt <- heterozygosity_filt %>% 
  mutate(sex_by_het = ifelse(
    X_het_frac < 0.027, "male", "female"))

# assign them sex:
# if sex by cov and sex by het agrees, assign male/female
# for male-like heterozygosity but female-like coverage ones, give 
# potential asex female pot_asex_F

heterozygosity_filt <- heterozygosity_filt %>% 
  mutate(sex = case_when (
    sex_by_cov == "male" & sex_by_het == "male" ~ "male",
    sex_by_cov == "female" & sex_by_het == "female" ~ "female",
    sex_by_cov == "female" & sex_by_het == "male" ~ "female_pot_asex"))

eggs_sexing_table <- heterozygosity_filt %>% 
  select(Egg_ID, Passed.filters, Female_ID, Female_population, 
         Time_point, flagged, X__cov_over_mean, X_sites, X_het, X_het_frac,
         A_sites, A_het, A_het_frac, X_het_over_A, sex_by_cov, sex_by_het,sex)

write_xlsx(x = eggs_sexing_table, path = "data/eggs_sex_assigned.xlsx",col_names = TRUE)
