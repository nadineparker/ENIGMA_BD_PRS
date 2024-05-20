
rm(list=ls())

# install packages if not installed already and load them
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
  par, "--het-file", help="full path to het file from QC.")

parsed <- parse_args(par)

hetfile <- parsed$het_file

dat <- fread(hetfile, header=T)
m <- mean(dat$F)
s <- sd(dat$F)
valid <- subset(dat, F <= m+4*s & F >= m-4*s)

newname <- gsub(".qc.het", "", hetfile)

write.table(valid[,c(1,2)], paste0(newname, ".valid.sample"), 
            quote=F, row.names=F)
q(save="no")
