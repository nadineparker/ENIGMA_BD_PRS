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

## Sample name - if you plan to run this protocol for multiple samples this will be used as an identifier
export Sample_Name=YOUR_SAMPLE_NAME

## number of available cores for processing
##if submitting a slurm job you can comment this out
export NCORES=8

export MEMORY=$((${NCORES} * 2000))

## What operating system are you running this script on? PLEASE use "yes" or "no". CASE MATTERS!
## ALL three options must have an answer.
WINDOWS=no
MAC=yes
LINUX=no

## If you plan to run this script for multiple samples in parallel from the same project directory
# please specify clean as no below - some intermediate files will remain to avoid conflicts
CLEAN=yes

## Ensure you have Docker running/loaded


############### END NO NEED TO CHANGE ANYTHING BEYOND THIS POINT ###################

set -euo pipefail 

## Export Variables for Docker
export RSCRIPT="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home:rw --mount type=bind,source=${Project_Path},target=${Project_Path} ldpred2:latest Rscript"
export PLINK="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home:rw --mount type=bind,source=${Project_Path},target=${Project_Path} ldpred2:latest plink"
export PLINK2="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home:rw --mount type=bind,source=${Project_Path},target=${Project_Path} ldpred2:latest plink2"
export PYTHON="docker run --platform=linux/amd64 --mount type=bind,source=${PWD},target=/home:rw --mount type=bind,source=${Project_Path},target=${Project_Path} ldpred2:latest python"

## Make output directory
export OUTDIR=${Project_Path}/output_${Sample_Name}

# tar -zxvf ref.tar.gz

mkdir -p ${OUTDIR}

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>${OUTDIR}/RUN_ENIGMA_BD_PRS_${Sample_Name}.log 2>&1

date '+%A %W %Y %X'

## Running initial data check
${RSCRIPT} ${Project_Path}/scripts/DataCheck.R \
	--target-dir ${Sample_Dir} \
	--prefix ${Prefix} \
	--project-dir ${Project_Path} \
	--out-dir ${Project_Path}/output_${Sample_Name}

cat ${Project_Path}/output_${Sample_Name}/LOG_DataCheck

### Make non-duplicated SNP plink files

OUT_DIR=${Project_Path}/${Sample_Name}_tmp
mkdir -p ${OUT_DIR}

${PLINK} --bfile ${Sample_Dir}/${Prefix} \
	--threads ${NCORES} --memory ${MEMORY} \
	--allow-extra-chr --extract ${OUTDIR}/NonDup_SNPlist.txt \
	--make-bed --out ${OUT_DIR}/${Sample_Name}_rmDupSNP


### Ancestry + PCs

# Input parameters.
target_bfile=${OUT_DIR}/${Sample_Name}_rmDupSNP	#${Sample_Dir}/${Prefix}
target_name=${Sample_Name}
OUT_PREFIX=${Project_Path}
REF_DIR=${Project_Path}/ref
plink_prefix_1kg=${REF_DIR}/1000_Genomes_2022_from_plink2/all_hg38
ref_fasta=${REF_DIR}/GRCh38_full_analysis_set_plus_decoy_hla.fa.zst
deg2_relatives=${REF_DIR}/1000_Genomes_2022_from_plink2/deg2_hg38.king.cutoff.out.id


# Variables derived from input parameters.
pvar_chr_pos_ref_alt=${REF_DIR}/1000_Genomes_2022_from_plink2/all_hg38.chr_pos_ref_alt
snplist_prefix=${REF_DIR}/1000_Genomes_2022_from_plink2/all_hg38
common_snps_1kg=${REF_DIR}/1000_Genomes_2022_from_plink2/all_hg38.common_snps
target_pvar_chr_pos_ref_alt=${OUT_DIR}/${target_name}.chr_pos_ref_alt
common_snps_1kg_target=${OUT_DIR}/${target_name}.common_snps 	# rename not target specific

### Produces one file that we can comment out and add to the files delivered to the sites
## alters 1000G referece
if false; then
    # Processing of the reference files needs to be done only once (no need to repeat for each target dataset).
    # Make pvar file with chr:pos:ref:alt ids
    ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --pfile ${plink_prefix_1kg} vzs \
        --set-all-var-ids "@:#:\$r:\$a" --new-id-max-allele-len 23 missing \
        --make-just-pvar zs cols="" --out ${pvar_chr_pos_ref_alt}

    # Identify common SNPs in each ancestry.
    POPULATIONS="EUR AFR SAS EAS AMR"
    for ANCESTRY in ${POPULATIONS}; do
    out=${snplist_prefix}.${ANCESTRY}
    ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --pgen ${plink_prefix_1kg}.pgen --psam ${plink_prefix_1kg}.psam \
        --pvar ${pvar_chr_pos_ref_alt}.pvar.zst --autosome --remove ${deg2_relatives} --snps-only \
        --keep-if "SuperPop=${ANCESTRY}" --maf 0.01 --geno 0.01 --rm-dup 'force-first' --write-snplist --out ${out}
    done

    # Identify SNPs which are common in all ancestries
    N_POP=$(echo ${POPULATIONS} | awk '{print(NF)}')
    sort --parallel=${NCORES} ${snplist_prefix}.*.snplist | uniq -c | awk -v n_pop="${N_POP}" '$1==n_pop {print $2}' > ${common_snps_1kg}
    echo "N common SNPs = $(wc -l ${common_snps_1kg})"
fi
## above will be run before and output shared with sites -- can comment out in future


if true; then
    # See https://groups.google.com/g/plink2-users/c/ohV0F2e5onk for more details about the logic behind the following processing steps.
    # Align variant alleles to the reference genome sequence.
    # This orders ref and alt alleles so that ref allele matches allele in the reference sequence.
    # N.b. only reordering but no strand flip is attempted.
    # If neither of two alleles fits the reference, it adds PR (provisional reference) tag to the
    # INFO column.
    bfile_align="${OUT_DIR}/${target_name}.allign_to_ref"
    ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --bfile ${target_bfile} --make-pgen pvar-cols=+info \
        --rm-dup 'force-first' --autosome --snps-only 'just-acgt' --mac 1 --nonfounders --ref-from-fa --fa ${ref_fasta} \
        --out ${bfile_align}
    # Flip the strand of variants which contain PR tag in the INFO column, i.e. those which were
    # not aligned to the reference sequence in the previous command.
    pfile_align_flip=${target_bfile}.flip
    awk 'BEGIN{OFS="\t"; cpl["A"]="T";cpl["T"]="A";cpl["G"]="C";cpl["C"]="G"}
        {if($0!~/^#/ && $6=="PR") {$4=cpl[$4]; $5=cpl[$5]} print($0)}' \
        ${bfile_align}.pvar > ${pfile_align_flip}.pvar

    # Align variant alleles (which are now flipped) to reference sequence again.
    pfile_align_flip_align=${pfile_align_flip}.align
    ${PLINK2} --pvar ${pfile_align_flip}.pvar --psam ${bfile_align}.psam --pgen ${bfile_align}.pgen \
        --make-pgen 'pvar-cols=+info' --out ${pfile_align_flip_align} \
        --ref-from-fa --fa ${ref_fasta} \
        --threads ${NCORES} --memory ${MEMORY}

    # Make input file for --update-name taking only variants without PR tag in the INFO column,
    # i.e. those with alleles correctly aligned to the reference sequence.
    # The input file for --update-name contains two columns:
    #   (1) original variant ids;
    #   (2) new "chr:bp:ref:alt", where ref allele is the allele in the reference sequence.
    update_name_snps=${bfile_align}.update_name.snps
    awk 'BEGIN{OFS="\t"} {if($0!~/^#/ && $6!="PR") print($3,$1":"$2":"$4":"$5)}' \
        ${pfile_align_flip_align}.pvar > ${update_name_snps}
    # Make a list of SNPs to exclude, i.e. those for which alleles were not aligned to the
    # reference sequence neither on the original nor on the flipped strand.
    exclude_snps=${bfile_align}.exclude.snps
    touch ${exclude_snps} # ensure the file exists, even if there are no SNPs with allele mismatch.
    awk '{if($0!~/^#/ && $6=="PR") print($3)}' ${pfile_align_flip_align}.pvar > ${exclude_snps}

    # Make pgen file with "chr:bp:ref:alt" variant IDs keeping only variants which were aligned
    # to the reference sequence.
    # This step relies on the order of operations in plink2:
    # https://www.cog-genomics.org/plink/2.0/order.
    # First goes --update-name, then --exclude and finally --rm-dup.
    align_snps_plink_file=${target_bfile}.align_snps
    ${PLINK2} --pfile ${pfile_align_flip_align} \
        --make-pgen vzs --out ${align_snps_plink_file} \
        --update-name ${update_name_snps} --exclude ${exclude_snps} \
        --extract ${common_snps_1kg} --rm-dup 'force-first' list \
        --threads ${NCORES} --memory ${MEMORY}
    cp ${align_snps_plink_file}.log ${align_snps_plink_file}.pfile.log
    ${PLINK2} --pfile ${align_snps_plink_file} vzs --make-bed --write-snplist \
    	--out ${align_snps_plink_file} --threads ${NCORES} --memory ${MEMORY}
    common_snps_1kg_target=${align_snps_plink_file}
fi


# Get independent SNPs in 1000 Genomes data taking into account only SNPs which also present in target data.
indep_snps="${OUT_DIR}/1kg_indep_snps"
if true; then
    ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --pgen ${plink_prefix_1kg}.pgen --psam ${plink_prefix_1kg}.psam \
        --pvar ${pvar_chr_pos_ref_alt}.pvar.zst --extract ${common_snps_1kg_target}.snplist \
        --remove ${deg2_relatives} --nonfounders --indep-pairwise 200kb 0.5 --out ${indep_snps}
fi


## Related individuals
${PLINK2} --pfile ${align_snps_plink_file} vzs \
	--extract ${indep_snps}.prune.in \
	--threads ${NCORES} --memory ${MEMORY} \
	--make-king-table --king-table-filter 0.1 --out ${OUTDIR}/${Sample_Name}_rel


# Calculate PCA for 1000 Genomes unrelated
pca_1kg="${OUT_DIR}/pca_1kg"
n_pc=20
if true; then
   ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --pgen ${plink_prefix_1kg}.pgen --psam ${plink_prefix_1kg}.psam \
        --pvar ${pvar_chr_pos_ref_alt}.pvar.zst --extract ${indep_snps}.prune.in \
        --remove ${deg2_relatives} --nonfounders --pca ${n_pc} 'allele-wts' --freq counts \
        --out ${pca_1kg}
fi

# Project 1000 Genomes PCA
pca_1kg_project="${OUT_DIR}/pca_1kg_proj"
if true; then
    ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --pgen ${plink_prefix_1kg}.pgen --psam ${plink_prefix_1kg}.psam \
        --pvar ${pvar_chr_pos_ref_alt}.pvar.zst --read-freq ${pca_1kg}.acount \
        --score ${pca_1kg}.eigenvec.allele 2 5 'header-read' 'no-mean-imputation' 'variance-standardize' \
        --score-col-nums 6-$((${n_pc} + 5)) --out ${pca_1kg_project}
fi

# Project TOP PCA
pca_top_project="${OUT_DIR}/pca_${target_name}_proj"
if true; then
    ${PLINK2} --threads ${NCORES} --memory ${MEMORY} --pfile ${align_snps_plink_file} vzs --read-freq ${pca_1kg}.acount \
        --score ${pca_1kg}.eigenvec.allele 2 5 'header-read' 'no-mean-imputation' 'variance-standardize' \
        --score-col-nums 6-$((${n_pc} + 5)) --out ${pca_top_project}
fi


# Predict ancestry and produce PCA plots with color-coded ancestry.
${PYTHON} --version
${PYTHON} ${Project_Path}/scripts/anc_proj.py "${pca_1kg_project}.sscore" "${pca_top_project}.sscore" "${pca_top_project}"


mv ${OUT_DIR}/pca_${Sample_Name}_proj.ancestries.png ${OUTDIR}
mv ${OUT_DIR}/pca_${Sample_Name}_proj.ancestries.txt ${OUTDIR}

## Clean up tmp dir
rm ${Project_Path}/${Sample_Name}_tmp/*1kg*
rm ${Project_Path}/${Sample_Name}_tmp/*ref*
rm ${Project_Path}/${Sample_Name}_tmp/*flip*
rm ${Project_Path}/${Sample_Name}_tmp/*pca*

####### Genetic QC

## split anc_proj
${RSCRIPT} ${Project_Path}/scripts/MakeAncProjLists.R \
	--project-dir ${Project_Path} \
	--anc-dir ${OUTDIR} \
	--sample-name ${Sample_Name} \
	--out-dir ${Sample_Name}_tmp

## make plink files for each anc_proj
mkdir -p ${Project_Path}/anc_proj_files

cd ${Project_Path}/${Sample_Name}_tmp

for file in ${Sample_Name}_ancproj_AFR ${Sample_Name}_ancproj_AMR ${Sample_Name}_ancproj_EAS ${Sample_Name}_ancproj_EUR ${Sample_Name}_ancproj_SAS
do
	if [ -f "$file" ]; 
	then
		${PLINK} --bfile ${OUT_DIR}/${Sample_Name}_rmDupSNP.align_snps --threads ${NCORES} --memory ${MEMORY} --keep ${Project_Path}/${Sample_Name}_tmp/${file} --make-bed --out ${Project_Path}/anc_proj_files/${file}
	else
		echo "$file does not exist"
	fi
done



## anc_proj specific QC

cd ${Project_Path}/anc_proj_files

for ancFile in ${Sample_Name}_ancproj_AFR ${Sample_Name}_ancproj_AMR ${Sample_Name}_ancproj_EAS ${Sample_Name}_ancproj_EUR ${Sample_Name}_ancproj_SAS
do

	if [ -f "${ancFile}.fam" ];
        then

		count=$(wc -l ${ancFile}.fam | awk '{ print $1 }')
	
		if [ ${count} -gt 10 ];
		then
			
			## Initial SNP QC
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --maf 0.01 --hwe 1e-10 midp --geno 0.01 \
			--write-snplist --out ${Project_Path}/anc_proj_files/${ancFile}.qc.snps

			## Additional Sample and SNP QC
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --extract ${Project_Path}/anc_proj_files/${ancFile}.qc.snps.snplist \
			--mind 0.01 --maf 0.01 --hwe 1e-50 midp --geno 0.01 --write-snplist --make-just-fam --out ${Project_Path}/anc_proj_files/${ancFile}.qc.samples 

			## Heterozygosity
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --extract ${Project_Path}/anc_proj_files/${ancFile}.qc.samples.snplist \
			--keep ${Project_Path}/anc_proj_files/${ancFile}.qc.samples.fam --het --out ${Project_Path}/anc_proj_files/${ancFile}.qc

			## R to remove outliers in heterozygosity
			$RSCRIPT ${Project_Path}/scripts/het_rm.R --het-file ${Project_Path}/anc_proj_files/${ancFile}.qc.het

			## Generate final QC files
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --keep ${Project_Path}/anc_proj_files/${ancFile}.valid.sample \
			--extract ${Project_Path}/anc_proj_files/${ancFile}.qc.samples.snplist \
			--make-bed --out ${Project_Path}/anc_proj_files/${ancFile}.FinalQC

		else
			
			## Initial SNP QC
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --geno 0.5 \
			--write-snplist --out ${Project_Path}/anc_proj_files/${ancFile}.qc.snps

			## Additional Sample and SNP QC
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --extract ${Project_Path}/anc_proj_files/${ancFile}.qc.snps.snplist \
			--mind 0.01 --geno 0.5 --write-snplist --make-just-fam --out ${Project_Path}/anc_proj_files/${ancFile}.qc.samples 

			## Generate final QC files
			${PLINK} --bfile ${Project_Path}/anc_proj_files/${ancFile} \
			--threads ${NCORES} --memory ${MEMORY} --keep ${Project_Path}/anc_proj_files/${ancFile}.qc.samples.fam \
			--extract ${Project_Path}/anc_proj_files/${ancFile}.qc.samples.snplist \
			--make-bed --out ${Project_Path}/anc_proj_files/${ancFile}.FinalQC

		fi

	else
		echo "${ancFile}.fam does not exist"
	fi
done



cd ${Project_Path}/anc_proj_files

for ancFile in ${Sample_Name}_ancproj_AFR.FinalQC ${Sample_Name}_ancproj_AMR.FinalQC ${Sample_Name}_ancproj_EAS.FinalQC ${Sample_Name}_ancproj_EUR.FinalQC ${Sample_Name}_ancproj_SAS.FinalQC
do

	if [ -f "${ancFile}.fam" ];
        then
		echo ${Project_Path}/anc_proj_files/${ancFile} >> ${Project_Path}/anc_proj_files/${Sample_Name}_list.txt
	else
		echo "${ancFile} does not exist"
	fi
done

REF_PLINKFILE=$(head -n 1 ${Sample_Name}_list.txt)
echo "${REF_PLINKFILE} is the ref for merging"
tail -n +2 ${Project_Path}/anc_proj_files/${Sample_Name}_list.txt > ${Project_Path}/anc_proj_files/${Sample_Name}_merge_list.txt

plinkcount=$(wc -l ${Sample_Name}_merge_list.txt | awk '{ print $1 }')
echo "${plinkcount} + 1 plink files to merge"
	
if [ ${plinkcount} -gt 0 ];
then
	${PLINK} --bfile ${REF_PLINKFILE} \
	--merge-list ${Project_Path}/anc_proj_files/${Sample_Name}_merge_list.txt \
	--out ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD
else
	cp ${REF_PLINKFILE}.bed ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD.bed
	cp ${REF_PLINKFILE}.bim ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD.bim
	cp ${REF_PLINKFILE}.fam ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD.fam
fi

## Clean up anc_proj_files
rm ${Project_Path}/anc_proj_files/${Sample_Name}_list.txt
rm ${Project_Path}/anc_proj_files/${Sample_Name}_merge_list.txt
rm ${Project_Path}/anc_proj_files/${Sample_Name}_ancproj*

## Clean up tmp dir
rm ${Project_Path}/${Sample_Name}_tmp/*ancproj*
rm ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_rmDupSNP*

### Run PRS
cd ${Project_Path}

date '+%A %W %Y %X'

# Convert from plink format to bigSNPR .rds/.bk files
${RSCRIPT} ${Project_Path}/scripts/createBackingFile.R \
	--file-input ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD.bed \
	--file-output ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD.rds

# impute missing values
${RSCRIPT} ${Project_Path}/scripts/imputeGenotypes.R \
	--impute-simple mean0 \
	--geno-file-rds ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD.rds \
	--cores $NCORES

export fileGenoRDS=${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD.rds
export LD_FILES=${Project_Path}/ref/ldref_hm3_plus/LD_with_blocks_chr@.rds

# Generate PGS using LDPRED2-auto
cd ${Project_Path}/sumstats

for SUMSTATS in PGC_BIP*GRCh38.sumstats.gz
do
	NEW_NAME=$(echo ${SUMSTATS} | awk -F'[.]' '{print $1}')

	${RSCRIPT} ${Project_Path}/scripts/ldpred2.R \
		 --ldpred-mode auto \
		 --ld-file ${LD_FILES} \
		 --ld-meta-file ${Project_Path}/ref/map_hm3_plus.rds \
		 --cores ${NCORES} \
		 --col-stat B \
		 --col-stat-se SE \
		 --col-chr CHR \
		 --col-snp-id RSID \
		 --col-A1 EffectAllele \
		 --col-A2 OtherAllele \
		 --col-bp POS \
		 --col-pvalue P \
		 --col-n N \
		 --stat-type BETA \
		 --genomic-build hg38 \
		 --geno-file-rds ${fileGenoRDS} \
		 --sumstats ${Project_Path}/sumstats/${SUMSTATS} \
		 --out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_prs.txt
done

## Merge ldpred prs outputs and write to outdir
${RSCRIPT} ${Project_Path}/scripts/MergeLDpred2PRS.R \
	--sample-name ${Sample_Name} \
	--project-dir ${Project_Path} \
	--out-dir ${OUTDIR}

date '+%A %W %Y %X'

## Clean up tmp dir
rm ${Project_Path}/${Sample_Name}_tmp/*bk
rm ${Project_Path}/${Sample_Name}_tmp/*rds

## Update Target SNPIDs for PRSet
${RSCRIPT} ${Project_Path}/scripts/UpdateTargetSNPID.R \
	--sample-name ${Sample_Name} \
	--out-dir ${Project_Path}/${Sample_Name}_tmp \
	--target-bim ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD.bim

${PLINK} --bfile ${Project_Path}/anc_proj_files/${Sample_Name}_QC_ENIGMA_BD \
	--update-name ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_SNPIDs.txt 2 1 \
	--make-bed --out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD_PRSet

## Run PRSet using MiXeR-Pred and GWAS data
echo "Windows? ${WINDOWS}"
echo "Mac? ${MAC}"
echo "Linux? ${LINUX}"

cd ${Project_Path}/sumstats

SS=${Project_Path}/sumstats

for SUMSTATS in PGC_BIP_2024*hm3plus_GRCh38.sumstats.gz
do
  	NEW_NAME=$(echo ${SUMSTATS} | awk -F'[.]' '{print $1}')

	if [ ${WINDOWS} == yes ]
	then
		Rscript ${Project_Path}/scripts/WINDOWS/PRSice.R \
		--prsice ${Project_Path}/scripts/WINDOWS/PRSice_win64.exe \
		--dir ${Project_Path}/${Sample_Name}_tmp \
		--base ${Project_Path}/sumstats/${SUMSTATS} \
		--target ${tmp}/${Sample_Name}_QC_ENIGMA_BD_PRSet \
		--stat B --pvalue P --beta \
		--snp ID --A1 EffectAllele --A2 OtherAllele \
		--ld ${Project_Path}/ref/1000G_EUR_GRCh38_hm3plus_PRSet \
		--thread ${NCORES} --no-regress \
		--bed ${SS}/Bhaduri_Astro.bed:Bhaduri_Astro,${SS}/Bhaduri_Divid.bed:Bhaduri_Divid,${SS}/Bhaduri_Endo.bed:Bhaduri_Endo,${SS}/Bhaduri_Inter.bed:Bhaduri_Inter,${SS}/Bhaduri_IPC.bed:Bhaduri_IPC,${SS}/Bhaduri_Micro.bed:Bhaduri_Micro,${SS}/Bhaduri_Neur.bed:Bhaduri_Neur,${SS}/Bhaduri_Oligo.bed:Bhaduri_Oligo,${SS}/Bhaduri_RadGlia.bed:Bhaduri_RadGlia,${SS}/Bhaduri_Vasc.bed:Bhaduri_Vasc,${SS}/Lake_Astro.bed:Lake_Astro,${SS}/Lake_Endo.bed:Lake_Endo,${SS}/Lake_Ex.bed:Lake_Ex,${SS}/Lake_In.bed:Lake_In,${SS}/Lake_Micro.bed:Lake_Micro,${SS}/Lake_Oligo.bed:Lake_Oligo,${SS}/Lake_OPC.bed:Lake_OPC,${SS}/Lake_Per.bed:Lake_Per \
		--out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_CellType_prs.txt
	else
		echo "SKIP - You are not using Windows."
	fi


	if [ ${MAC} == yes ]
        then
        		Rscript ${Project_Path}/scripts/MAC/PRSice.R \
                --prsice ${Project_Path}/scripts/MAC/PRSice_mac \
                --dir ${Project_Path}/${Sample_Name}_tmp \
                --base ${Project_Path}/sumstats/${SUMSTATS} \
                --target ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD_PRSet \
                --stat B --pvalue P --beta \
                --snp ID --A1 EffectAllele --A2 OtherAllele \
                --ld ${Project_Path}/ref/1000G_EUR_GRCh38_hm3plus_PRSet \
                --thread ${NCORES} --no-regress \
				--bed ${SS}/Bhaduri_Astro.bed:Bhaduri_Astro,${SS}/Bhaduri_Divid.bed:Bhaduri_Divid,${SS}/Bhaduri_Endo.bed:Bhaduri_Endo,${SS}/Bhaduri_Inter.bed:Bhaduri_Inter,${SS}/Bhaduri_IPC.bed:Bhaduri_IPC,${SS}/Bhaduri_Micro.bed:Bhaduri_Micro,${SS}/Bhaduri_Neur.bed:Bhaduri_Neur,${SS}/Bhaduri_Oligo.bed:Bhaduri_Oligo,${SS}/Bhaduri_RadGlia.bed:Bhaduri_RadGlia,${SS}/Bhaduri_Vasc.bed:Bhaduri_Vasc,${SS}/Lake_Astro.bed:Lake_Astro,${SS}/Lake_Endo.bed:Lake_Endo,${SS}/Lake_Ex.bed:Lake_Ex,${SS}/Lake_In.bed:Lake_In,${SS}/Lake_Micro.bed:Lake_Micro,${SS}/Lake_Oligo.bed:Lake_Oligo,${SS}/Lake_OPC.bed:Lake_OPC,${SS}/Lake_Per.bed:Lake_Per \
                --out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_CellType_prs.txt
                
        else
            	echo "SKIP - You are not using a Mac."
        fi


	if [ ${LINUX} == yes ]
        then
            	${RSCRIPT} ${Project_Path}/scripts/LINUX/PRSice.R \
                --prsice ${Project_Path}/scripts/LINUX/PRSice_linux \
                --dir ${Project_Path}/${Sample_Name}_tmp \
                --base ${Project_Path}/sumstats/${SUMSTATS} \
                --target ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD_PRSet \
                --stat B --pvalue P --beta \
                --snp ID --A1 EffectAllele --A2 OtherAllele \
				--ld ${Project_Path}/ref/1000G_EUR_GRCh38_hm3plus_PRSet \
                --thread ${NCORES} --no-regress \
				--bed ${SS}/Bhaduri_Astro.bed:Bhaduri_Astro,${SS}/Bhaduri_Divid.bed:Bhaduri_Divid,${SS}/Bhaduri_Endo.bed:Bhaduri_Endo,${SS}/Bhaduri_Inter.bed:Bhaduri_Inter,${SS}/Bhaduri_IPC.bed:Bhaduri_IPC,${SS}/Bhaduri_Micro.bed:Bhaduri_Micro,${SS}/Bhaduri_Neur.bed:Bhaduri_Neur,${SS}/Bhaduri_Oligo.bed:Bhaduri_Oligo,${SS}/Bhaduri_RadGlia.bed:Bhaduri_RadGlia,${SS}/Bhaduri_Vasc.bed:Bhaduri_Vasc,${SS}/Lake_Astro.bed:Lake_Astro,${SS}/Lake_Endo.bed:Lake_Endo,${SS}/Lake_Ex.bed:Lake_Ex,${SS}/Lake_In.bed:Lake_In,${SS}/Lake_Micro.bed:Lake_Micro,${SS}/Lake_Oligo.bed:Lake_Oligo,${SS}/Lake_OPC.bed:Lake_OPC,${SS}/Lake_Per.bed:Lake_Per \
                --out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_CellType_prs.txt
        else
            	echo "SKIP - You are not using LINUX."
        fi

done


## Repeat the same PRSet runs with MiXeR-Pred inputs

for SUMSTATS_MIXER in PGC_BIP_2024*GRCh38_MiXeR_Pred_hm3plus.sumstats.gz
do
  	NEW_NAME=$(echo ${SUMSTATS_MIXER} | awk -F'[.]' '{print $1}')

	if [ ${WINDOWS} == yes ]
	then
		Rscript ${Project_Path}/scripts/WINDOWS/PRSice.R \
		--prsice ${Project_Path}/scripts/WINDOWS/PRSice_win64.exe \
		--dir ${Project_Path}/${Sample_Name}_tmp \
		--base ${Project_Path}/sumstats/${SUMSTATS_MIXER} \
		--target ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD_PRSet \
		--stat Ed --pvalue expEd --beta \
		--snp ID --A1 A1 --A2 A2 \
		--ld ${Project_Path}/ref/1000G_EUR_GRCh38_hm3plus_PRSet \
		--thread ${NCORES} --no-regress \
		--bed ${SS}/Bhaduri_Astro.bed:Bhaduri_Astro,${SS}/Bhaduri_Divid.bed:Bhaduri_Divid,${SS}/Bhaduri_Endo.bed:Bhaduri_Endo,${SS}/Bhaduri_Inter.bed:Bhaduri_Inter,${SS}/Bhaduri_IPC.bed:Bhaduri_IPC,${SS}/Bhaduri_Micro.bed:Bhaduri_Micro,${SS}/Bhaduri_Neur.bed:Bhaduri_Neur,${SS}/Bhaduri_Oligo.bed:Bhaduri_Oligo,${SS}/Bhaduri_RadGlia.bed:Bhaduri_RadGlia,${SS}/Bhaduri_Vasc.bed:Bhaduri_Vasc,${SS}/Lake_Astro.bed:Lake_Astro,${SS}/Lake_Endo.bed:Lake_Endo,${SS}/Lake_Ex.bed:Lake_Ex,${SS}/Lake_In.bed:Lake_In,${SS}/Lake_Micro.bed:Lake_Micro,${SS}/Lake_Oligo.bed:Lake_Oligo,${SS}/Lake_OPC.bed:Lake_OPC,${SS}/Lake_Per.bed:Lake_Per \
		--out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_CellType_prs.txt
	else
		echo "SKIP - You are not using Windows."
	fi


	if [ ${MAC} == yes ]
        then
            	Rscript ${Project_Path}/scripts/MAC/PRSice.R \
                --prsice ${Project_Path}/scripts/MAC/PRSice_mac \
                --dir ${Project_Path}/${Sample_Name}_tmp \
                --base ${Project_Path}/sumstats/${SUMSTATS_MIXER} \
                --target ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD_PRSet \
                --stat Ed --pvalue expEd --beta \
                --snp ID --A1 A1 --A2 A2 \
				--ld ${Project_Path}/ref/1000G_EUR_GRCh38_hm3plus_PRSet \
                --thread ${NCORES} --no-regress \
				--bed ${SS}/Bhaduri_Astro.bed:Bhaduri_Astro,${SS}/Bhaduri_Divid.bed:Bhaduri_Divid,${SS}/Bhaduri_Endo.bed:Bhaduri_Endo,${SS}/Bhaduri_Inter.bed:Bhaduri_Inter,${SS}/Bhaduri_IPC.bed:Bhaduri_IPC,${SS}/Bhaduri_Micro.bed:Bhaduri_Micro,${SS}/Bhaduri_Neur.bed:Bhaduri_Neur,${SS}/Bhaduri_Oligo.bed:Bhaduri_Oligo,${SS}/Bhaduri_RadGlia.bed:Bhaduri_RadGlia,${SS}/Bhaduri_Vasc.bed:Bhaduri_Vasc,${SS}/Lake_Astro.bed:Lake_Astro,${SS}/Lake_Endo.bed:Lake_Endo,${SS}/Lake_Ex.bed:Lake_Ex,${SS}/Lake_In.bed:Lake_In,${SS}/Lake_Micro.bed:Lake_Micro,${SS}/Lake_Oligo.bed:Lake_Oligo,${SS}/Lake_OPC.bed:Lake_OPC,${SS}/Lake_Per.bed:Lake_Per \
                --out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_CellType_prs.txt
        else
            	echo "SKIP - You are not using a Mac."
        fi


	if [ ${LINUX} == yes ]
        then
            	${RSCRIPT} ${Project_Path}/scripts/LINUX/PRSice.R \
                --prsice ${Project_Path}/scripts/LINUX/PRSice_linux \
                --dir ${Project_Path}/${Sample_Name}_tmp \
                --base ${Project_Path}/sumstats/${SUMSTATS_MIXER} \
                --target ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_QC_ENIGMA_BD_PRSet \
                --stat Ed --pvalue expEd --beta \
                --snp ID --A1 A1 --A2 A2 \
				--ld ${Project_Path}/ref/1000G_EUR_GRCh38_hm3plus_PRSet \
                --thread ${NCORES} --no-regress \
				--bed ${SS}/Bhaduri_Astro.bed:Bhaduri_Astro,${SS}/Bhaduri_Divid.bed:Bhaduri_Divid,${SS}/Bhaduri_Endo.bed:Bhaduri_Endo,${SS}/Bhaduri_Inter.bed:Bhaduri_Inter,${SS}/Bhaduri_IPC.bed:Bhaduri_IPC,${SS}/Bhaduri_Micro.bed:Bhaduri_Micro,${SS}/Bhaduri_Neur.bed:Bhaduri_Neur,${SS}/Bhaduri_Oligo.bed:Bhaduri_Oligo,${SS}/Bhaduri_RadGlia.bed:Bhaduri_RadGlia,${SS}/Bhaduri_Vasc.bed:Bhaduri_Vasc,${SS}/Lake_Astro.bed:Lake_Astro,${SS}/Lake_Endo.bed:Lake_Endo,${SS}/Lake_Ex.bed:Lake_Ex,${SS}/Lake_In.bed:Lake_In,${SS}/Lake_Micro.bed:Lake_Micro,${SS}/Lake_Oligo.bed:Lake_Oligo,${SS}/Lake_OPC.bed:Lake_OPC,${SS}/Lake_Per.bed:Lake_Per \
                --out ${Project_Path}/${Sample_Name}_tmp/${Sample_Name}_${NEW_NAME}_CellType_prs.txt
        else
            	echo "SKIP - You are not using LINUX."
        fi

done


cd ${Project_Path}/${Sample_Name}_tmp

cp *.all_score ${OUTDIR}

## Final clean up
rm -r ${Project_Path}/${Sample_Name}_tmp
if [ ${CLEAN} == yes ]
        then
		rm -r ${Project_Path}/anc_proj_files
	else
		echo "Clean is no - some intermediate files will remain"
	fi

date '+%A %W %Y %X'


