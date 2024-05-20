
############################## MERGE LDPRED2 PRS ##############################

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
par <- arg_parser("ENIGMA BD PRS Merge PRS")

par <- add_argument(
  par, "--sample-name", help="Sample/Cohort name.")
par <- add_argument(
  par, "--project-dir", help="path to directory housing all downloaded project relevant files")
par <- add_argument(
  par, "--out-dir", help="path to directory for all project output files")


parsed <- parse_args(par)

samplename <- parsed$sample_name
projectdir <- parsed$project_dir
outdir <- parsed$out_dir

system(paste0("mkdir -p ", outdir))
setwd(paste0(outdir))


### Step1: Check for plink1 files

prs_files <- list.files(path = paste0(projectdir,"/", samplename, "_tmp" ), 
                         pattern = "GRCh38_prs.txt", full.names = T)

prs_read <- lapply(prs_files, function(prsfile){
  
  df <- fread(prsfile)
  
  new_name <- gsub(paste0(projectdir, "/"), "", prsfile)
  new_name <- gsub(paste0(samplename, "_tmp/"), "", new_name)
  
  df$PRS <- new_name
  df <- as.data.frame(df)
  
})

prs_df <- rbindlist(prs_read)

write.table(prs_df, file = paste0(outdir, "/", samplename, "_PRS.txt"),
            quote = F, sep = "\t", row.names = F)
