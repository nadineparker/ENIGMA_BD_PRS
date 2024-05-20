
## Make new SNP ID mapping

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
par <- arg_parser("ENIGMA BD PRS Update SNP ID for PRSet")

par <- add_argument(
  par, "--sample-name", help="Sample/Cohort name.")
par <- add_argument(
  par, "--out-dir", help="path to directory for all project output files")
par <- add_argument(
  par, "--target-bim", help="path and prefix to QC'd target data")


parsed <- parse_args(par)

samplename <- parsed$sample_name
outdir <- parsed$out_dir
target_bim <- parsed$target_bim

setwd(paste0(outdir))


bim <- fread(target_bim)
bim$ID <- paste0(bim$V1, "_", bim$V4)
bim <- dplyr::select(bim, V2, ID)

write.table(bim, file = paste0(outdir, "/", samplename, "_SNPIDs.txt"),
            sep = "\t", row.names = F, col.names = F, quote = F)

