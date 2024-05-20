
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
par <- arg_parser("ENIGMA BD PRS Genetic List Anc_Proj")

par <- add_argument(
  par, "--project-dir", help="path to directory housing all downloaded project relevant files")
par <- add_argument(
  par, "--sample-name", help="Sample name used throughout script")
par <- add_argument(
  par, "--anc-dir", help="path to directory for anc_proj files")
par <- add_argument(
  par, "--out-dir", help="path to directory for all project output files")

parsed <- parse_args(par)

projectdir <- parsed$project_dir
ancdir <- parsed$anc_dir
samplename <- parsed$sample_name
outdir <- parsed$out_dir

system(paste0("mkdir -p ", projectdir, "/", outdir))
setwd(paste0(projectdir, "/", outdir))

anc_proj <- fread(paste0(ancdir, "/pca_", samplename, "_proj.ancestries.txt"))
# anc_proj <- fread("output_TOP/pca_TOP_proj.ancestries.txt")
anc_proj <- anc_proj[,c(1:2, 25)]

anc_proj %>% group_by(SuperPop) %>% 
  group_walk(
    ~ write_tsv(
      .x, file = paste0(projectdir, "/", outdir, "/", samplename, "_ancproj_", .y$SuperPop),
      col_names=F)
  )


# anc_proj %>% group_by(SuperPop) %>% 
#   group_walk(
#     ~ write_tsv(
#       .x, file = paste0("anc_proj_test_", .y$SuperPop),
#       col_names=F)
#   )
