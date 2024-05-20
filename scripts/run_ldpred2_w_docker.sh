#!/bin/bash

# pull docker image and tag it as "ldpred2:latest"
docker pull --platform=linux/amd64 ghcr.io/comorment/ldpred2:latest
docker image tag ghcr.io/comorment/ldpred2:latest ldpred2:latest

bash  # make sure you run bash locally, not zsh (which is the default shell in some systems - e.g. macOS)

# input/output files
export fileGeno=/REF/examples/prsice2/EUR.bed
export fileGenoRDS=EUR.rds
export fileSumstats=/REF/examples/prsice2/Height.gwas.txt.gz
export fileOut=Height

# set environmental variables. Replace $REPOS with 
# the full path to the folder containing cloned "containers" and "ldpred2_ref" repositories
export REPOS=~/Repositories
export REFERENCE=$REPOS/containers/reference  # clone of https://github.com/comorment/containers
export LDPRED2_REF=$REPOS/ldpred2_ref  # clone of https://github.com/comorment/ldpred2_ref
export CONTAINER="ldpred2:latest"
export RSCRIPT="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home --mount type=bind,source=${REFERENCE},target=/REF --mount type=bind,source=${LDPRED2_REF},target=/ldpred2_ref -w=/home/ ${CONTAINER} Rscript"

# run tasks
# $RSCRIPT /home/createBackingFile.R --file-input $fileGeno --file-output /home/$fileGenoRDS
$RSCRIPT createBackingFile.R --file-input $fileGeno --file-output $fileGenoRDS

# impute
$RSCRIPT imputeGenotypes.R --impute-simple mean0 --geno-file-rds $fileGenoRDS

# Generate PGS using LDPRED2-auto
$RSCRIPT ldpred2.R \
 --ldpred-mode auto \
 --col-stat OR \
 --col-stat-se SE \
 --stat-type OR \
 --geno-file-rds $fileGenoRDS \
 --sumstats $fileSumstats \
 --out $fileOut.auto

