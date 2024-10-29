#!/bin/bash

############### Please Fill in the paths below

## Base Directory - this should be a parent directory that holds all project data
 # project data includes your genetic plink files + all downloaded files, software, and containers
export Base_Dir=/PATH/TO/BASE/DIR

## Path to project directory with all downloaded files
export Project_Path=/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS

## Path to Your Samples PLINK Files
export Sample_Dir=/PATH/TO/GENETIC/DATA

## Plink Sample Prefix - the plink file prefix (filename before .bed, .fam, .bim suffix)
export Prefix=YOUR_PLINK_FILES_PREFIX

## Path to liftover chain file
# we provide build hg19/GRCh37 to hg39/GRCh38 - however you can provide the location to an alternative file
export liftover_chain=${Project_Path}/scripts/hg19ToHg38.over.chain.gz

## number of available cores for processing
##if submitting a slurm job you can comment this out
export NCORES=8

export MEMORY=$((${NCORES} * 7700)) 	## orig = 4 cores with 7700 memory

##################################################################################
############### END - Do Not Make Changes Beyond This Point ######################
##################################################################################

export liftover=${Project_Path}/scripts/liftOver

export plink1="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home:rw --mount type=bind,source=${Project_Path},target=${Project_Path} ldpred2:latest plink"
export plink2="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home:rw --mount type=bind,source=${Project_Path},target=${Project_Path} ldpred2:latest plink2"

# Make Non-Duplicated SNP ID Plink files
${plink2} --bfile ${Sample_Dir}/${Prefix} --rm-dup 'force-first' \
        --make-bed --out ${Sample_Dir}/${Prefix}_noDup --threads ${NCORES} --memory ${MEMORY}

#pfile_lift="${out_dir}/${batch_name}.lift"
#if (test $# -eq 1) || (echo "$@" | grep -Fwq lift); then
#    echo ">>> lift"
    # Ensure chromosomes are renamed properly for liftover (chr1, ..., chrM etc.).
    bim_tmp="${Project_Path}/${Prefix}.lift.tmp"
    ${plink2} --bfile ${Sample_Dir}/${Prefix}_noDup --output-chr chrM \
        --make-just-bim --out ${bim_tmp} \
        --threads ${NCORES} --memory ${MEMORY}
    # If PAR region is split in the batch_bfile, after applying '--output-chr chrM',
    # SNPs in PAR will be on "chrXY".
    # Liftover requires SNPs in PAR region to be on chrX, otherwise they will not be lifted corectly.
    bed_orig="${Project_Path}/${Prefix}.liftover.orig.bed"
    awk '{if($1=="chrXY") print("chrX",$4-1,$4,$2); else print($1,$4-1,$4,$2);}' \
        ${bim_tmp}.bim > ${bed_orig}
    unlifted_snps="${Project_Path}/${Prefix}.unlifted_snps"
    if [ -f "${liftover_chain}" ]; then
        echo "Lifting coordinates using ${liftover_chain}"
        bed_mapped="${Project_Path}/${Prefix}.liftover.mapped.bed"
        bed_unmapped="${Project_Path}/${Prefix}.liftover.unmapped.bed"
        ${liftover} ${bed_orig} ${liftover_chain} ${bed_mapped} ${bed_unmapped}
        grep -Pv "^#" ${bed_unmapped} | cut -f4 > ${unlifted_snps}
    else
        echo "liftover_chain is not provided. Coordinates are not lifted."
        bed_mapped=${bed_orig}
        touch ${unlifted_snps} # Ensure that (empty) file exists.
    fi
    ${plink1} --bfile ${Sample_Dir}/${Prefix}_noDup \
        --update-chr ${bed_mapped} 1 4 --update-map ${bed_mapped} 3 4 --exclude ${unlifted_snps} \
        --allow-extra-chr --make-bed --out ${Project_Path}/${Prefix}_b38_lifted \
        --threads ${NCORES} --memory ${MEMORY}
    #last_pfile=${pfile_lift}
    echo "<<< lift"
#fi

