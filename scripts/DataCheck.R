
############################## Check Genetic Data ##############################

rm(list=ls())

## install packages if not installed already and load them
if(!require(data.table)){
  install.packages("data.table")
  library(data.table)
}

if(!require(tidyverse)){
  install.packages("tidyverse")
  library(tidyverse)
}

if(!require(argparser)){
  install.packages("argparser")
  library(argparser)
}


### Define command line input options 
par <- arg_parser("ENIGMA BD PRS Genetic Data Check")

par <- add_argument(
  par, "--target-dir", help="path to directory .bim, .bed, and .fam files for target sample.")
par <- add_argument(
  par, "--prefix", help="Prefix to plink .bim, .bed, and .fam files for target sample.")
par <- add_argument(
  par, "--project-dir", help="path to directory housing all downloaded project relevant files")
par <- add_argument(
  par, "--out-dir", help="path to directory for all project output files")


parsed <- parse_args(par)

targetdir <- parsed$target_dir
prefix <- parsed$prefix
projectdir <- parsed$project_dir
outdir <- parsed$out_dir

system(paste0("mkdir -p ", outdir))
setwd(paste0(outdir))


### Step1: Check for plink1 files

plinkfiles <- list.files(path = targetdir, pattern = prefix)

sink("./LOG_DataCheck")

# ls(plinkfiles)

ifelse(paste0(prefix, ".bed") %in% plinkfiles, "Found .bed", "ERROR: missing .bed file")
ifelse(paste0(prefix, ".bim") %in% plinkfiles, "Found .bim", "ERROR: missing .bim file")
ifelse(paste0(prefix, ".fam") %in% plinkfiles, "Found .fam", "ERROR: missing .fam file")



### Step 2: Check .bim files are in the right build
ref <- readRDS(paste0(projectdir, "/ref/map_hm3_plus.rds"))
check_snp <- fread(paste0(targetdir, "/", prefix, ".bim"))

check_snp_ref <- merge(check_snp, ref, by.x="V2", by.y="rsid")

ifelse(length(intersect(check_snp_ref$V4, check_snp_ref$pos))/nrow(check_snp_ref)>0.90,
       "ERROR: Your data is in build hg37. Please lift the SNP positions to build hg38 in your .bim file",
       "")
ifelse(length(intersect(check_snp_ref$V4, check_snp_ref$pos_hg18))/nrow(check_snp_ref) >0.09,
       "ERROR: Your data is in build hg18. Please lift the SNP positions to build hg38 in your .bim file",
       "")
ifelse(length(intersect(check_snp_ref$V4, check_snp_ref$pos_hg38))/nrow(check_snp_ref) >0.90,
       "Your data is in build hg38. Thanks!", 
       stop("ERROR: Your data is not in build hg38. Please lift the SNP positions to build hg38 in your .bim file"))


### Step 3: remove duplicated SNP identifiers and CHR:POS
check_snp <- check_snp[duplicated(check_snp$V2) ==F,]
check_snp$ID <- paste0(check_snp$V1, "_", check_snp$V4)
check_snp <- check_snp[duplicated(check_snp$ID) ==F,]

SNPlist <- dplyr::select(check_snp, V2)

write.table(SNPlist, file=paste0(outdir, "/NonDup_SNPlist.txt"),
            sep = "\t", quote = F, row.names = F, col.names = F)





# ### Step 2: Check .bim files have rsid as SNP identifier
# check_snp <- fread(paste0(targetdir, "/", prefix, ".bim"))
# ## check_snp <- fread("/cluster/projects/p697/users/nadinepa/ENIGMA/TEST_Protocol/TOP_BIPSCZvsCTRL_merged_EUR_addrs_20220127.bim")
# 
# rs_check <- lapply(sample(1:nrow(check_snp), 100000), function(n_row){
#   
#   data.frame(
#     rsid = ifelse(startsWith(check_snp$V2[n_row], "rs") == TRUE, 1, 0)
#   )
#   
# })
# 
# rs_check_df <- rbindlist(rs_check)
# 
# ifelse(sum(rs_check_df$rsid)/nrow(rs_check_df) >0.5, 
#        "Your genetic data contains an rsid for SNP identifiers. Thanks!",
#        "ERROR: Your data does not use an rsid as a SNP identifier. Please update your .bim file.")
