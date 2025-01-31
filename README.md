# ENIGMA BD PRS Project Instructions
The following instructions are for generating polygenic scores for the ENIGMA Bipolar Disorder working group. 

## Recommendations (Please Read)
Given the large size of some necessary files, **we strongly recommend running this analysis on a server where you can request 32GB of memory (RAM) and which has at least 25GB of free storage**. We also recommend using our singularity or docker containers which include all necessary software to run the analyses on Linux machines. We have successfully tested the docker container with smaller data sets (n=100 participants) on a MAC M1 chip laptop (16GB of RAM; runtime ~7hrs). Although, we still recommend using a machine with more RAM as larger samples will increase runtime or may not complete. We have not tested the containers using a Windows OS and therefore do not recommend using a Windows machine.  

## 1. Download Project Files
Download and unzip the ``ENIGMA_BD_PRS.zip`` directory from figshare (https://doi.org/10.6084/m9.figshare.25872160.v3). All necessary project files are located in that directory. NOTE: some files are large, therefore, (1) this download will take time (hours) and (2) we recommend having ~25GB of free space on your system.

PLEASE DO NOT CHANGE THE LOCATION OF EXISTING FILES OR FOLDERS IN THE DOWNLOADED ``ENIGMA_BD_PRS DIRECTORY``. However, you can add your own files to this project directory.

## 2.	Format Your Genetic Data
This protocol assumes the input data has (i) already been imputed, (ii) is in PLINK v1 binary format (.bed, .bim, .fam files), and (iii) is in genomic build GRCh38.
 
1. If your data is not imputed, you may wish to use the [ENIGMA Genetics Imputation Protocol](https://enigma.ini.usc.edu/protocols/genetics-protocols/imputation-protocol/).
2. If your data is imputed but in another format (ped/map, vcf, bgen, etc.) you can use [PLINK](https://www.cog-genomics.org/plink/1.9/input) to convert to the required format. Below is an example for .ped/.map and .vcf formats
```
plink --file ped_map_FilePrefix --make-bed --out New_FilePrefix
```
or
```
plink --vcf vcf_FilePrefix --make-bed --out New_FilePrefix
```
3. If your data is in another genomic build, we provide in the ``ENIGMA_BD_PRS`` project directory (or subdirectories) (i) the [LiftOver](https://genome.ucsc.edu/cgi-bin/hgLiftOver) tool **FOR LINUX SYSTEMS ONLY**, (ii) a chain file to convert from GRCh37 (hg19) to GRCh38 (hg38), and (iii) a script to run the genomic build conversion using either the Singularity (Auto_LiftOver_Singularity.sh) or Docker (Auto_LiftOver_Docker.sh) containers built for this project. Instructions on converting genomic builds are in the [Additional LiftOver Instructions](https://github.com/nadineparker/ENIGMA_BD_PRS#additional-liftover-instructions) section below. Running the analyses with genetic data in the wrong build will produce an error. If your data is in GRCh37 (hg19) or GRCh36 (hg18) the error will inform you.

If you require help with converting your data please post an issue on the GitHub page using the issues tab above.

## 3.	Perform the Analyses
Within the downloaded “ENIGMA_BD_PRS” directory, you will find 3 potential scripts to run the analyses:
  - ``Singularity_RUN_ENIGMA_BD_PRS.sh`` – to run the singularity container. Instructions directly below in the "Using the Singularity Container" section.
  -	``Docker_RUN_ENIGMA_BD_PRS.sh`` – to run the docker container. Skip to instructions in [Using the Docker Container](https://github.com/nadineparker/ENIGMA_BD_PRS#using-the-docker-container)
  -	``RUN_ENIGMA_BD_PRS_noContainer.sh`` – to run the analyses without any containers (requires installing software). Skip to instructions in [Not Using a Container](https://github.com/nadineparker/ENIGMA_BD_PRS#not-using-a-container)

As mentioned above, we recommend using the singularity or docker containers on a linux based server with at least 32GB of RAM and 25GB of free storage space. Below are some steps to perform the analyses with Singularity, Docker, or no container. 

### Using the Singularity Container:
1. Ensure that your system has singularity installed or download it from https://docs.sylabs.io/guides/3.0/user-guide/installation.html.
2. Navigate to the “ENIGMA_BD_PRS” and open the “Singularity_RUN_ENIGMA_BD_PRS.sh” script. Add the appropriate information requested at the top of the script and save the edits. Below is a list of the required information:
    - ``Base_Dir``: replace the text “/PATH/TO/BASE/DIR” with the full path to a parent directory that contains all the necessary files and downloaded project directory. For example: export Base_Dir=/Users/nadine
    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS
    - ``Sample_Dir``: replace the text “/PATH/TO/GENETIC/DATA” with the full path to your cohorts PLINK v1 files (NOTE, .bed, .bim, .fam should all be in the same directory). For example: export Sample_Dir=/Users/nadine/Documents
    - ``Prefix``: add the prefix used for the PLINK v1 files (.bed, .bim, .fam). For example: export Prefix=TOP_GRCh38
    - ``Sample_Name``: add the sample name/identifier. This will be used to name files. If you are running this analysis for multiple samples/cohorts this name will help differentiate outputs. For example: export Sample_Name=TOP
    - ``NCORES``: this specifies the number of system cores/threads you would like to use for analysis. The available cores will vary based on machine.
    - ``MEMORY``: this specifies the amount of memory available per core in MB. REMEMBER, you will need around 32GB or RAM to run the analyses. The default setting is to use 8 cores with ~8GB of memory (64GB of RAM) which takes ~1.5 hours to run (with n =2000 participants).
    - You will also need to set the operating system being used. The three options (WINDOWS, MAC, LINUX) will need to be set to either a “yes” or a “no” and must be in lower case letters. The yes option can only be used once or there will be errors. We highly recommend using a Linux machine/server (the current default).
    - ``CLEAN``: if set to “yes” (the default) all intermediate files and directories will be removed at the end of the analysis. NOTE: if you are running multiple analyses for different samples in parallel you will need to set CLEAN=no. This will prevent necessary directories from being deleted when one sample finishes before the other(s).

3. Once the above information is added and saved in the ``Singularity_RUN_ENIGMA_BD_PRS.sh`` script you can run the analyses (a) by batching a job script or (b) running the analyses locally.
    - We provide an example script to batch SLURM jobs (BATCH_BD_PRS.job). This will need to be augmented for your server. NOTE: Ensure the cores and memory stated in the ``Singularity_RUN_ENIGMA_BD_PRS.sh`` script does not exceed the requested cores and memory in the slurm job script.
    - You can also run the script locally by opening a terminal, navigating to the ENIGMA_BD_PRS directory, and entering the following command: 
``
sh Singularity_RUN_ENIGMA_BD_PRS.sh 
``
or 
``
bash Singularity_RUN_ENIGMA_BD_PRS.sh 
``
4. Once the analysis is complete see the [Sharing Outputs](https://github.com/nadineparker/ENIGMA_BD_PRS#4-sharing-outputs) section


### Using the Docker Container:
1. Ensure your system has docker installed or download it from https://www.docker.com/get-started/. If using Docker Desktop, you may want to increase the resources. Navigate to settings Resources and maximize the available CPU limit, Memory limit, and Swap.
2. While docker is running/loaded, open a terminal and type the following command depending on your operating system:
```
LINUX/Windows/MAC (Intel): docker pull ghcr.io/comorment/ldpred2:latest 
MAC (M1/M2): docker pull -–platform=linux/amd64 ghcr.io/comorment/ldpred2:latest
```
3. You will also need to ensure you have R on your system. If not you can download R from here https://www.r-project.org/.
4. Navigate to the ``ENIGMA_BD_PRS`` directory and open the ``Docker_RUN_ENIGMA_BD_PRS.sh`` script. Add the appropriate information requested at the top of the script and save the edits. Below is a list of the required information:

    - ``Base_Dir``: replace the text “/PATH/TO/BASE/DIR” with the full path to a parent directory that contains all the necessary files and downloaded project directory. For example: export Base_Dir=/Users/nadine
    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS
    - ``Sample_Dir``: replace the text “/PATH/TO/GENETIC/DATA” with the full path to your cohorts PLINK v1 files (NOTE, .bed, .bim, .fam should all be in the same directory). For example: export Sample_Dir=/Users/nadine/Documents
    - ``Prefix``: add the prefix used for the PLINK v1 files (.bed, .bim, .fam). For example: export Prefix=TOP_GRCh38
    - ``Sample_Name``: add the sample name/identifier. This will be used to name files. If you are running this analysis for multiple samples/cohorts this name will help differentiate outputs. For example: export Sample_Name=TOP
    - ``NCORES``: this specifies the number of system cores/threads you would like to use for analysis. The available cores will vary based on machine.
    - ``MEMORY``: this specifies the amount of memory available per core in MB. REMEMBER, you will need around 32GB or RAM to run the analyses. The default setting is to use 8 cores with ~8GB of memory (64GB of RAM) which takes ~1.5 hours to run (with n =2000 participants).
    - You will also need to set the operating system being used. The three options (WINDOWS, MAC, LINUX) will need to be set to either a “yes” or a “no” and must be in lower case letters. The yes option can only be used once or there will be errors. We highly recommend using a Linux machine/server (the current default).
    - ``CLEAN``: if set to “yes” (the default) all intermediate files and directories will be removed at the end of the analysis. NOTE: if you are running multiple analyses for different samples in parallel you will need to set CLEAN=no. This will prevent necessary directories from being deleted when one sample finishes before the other(s).

5. Once the above information is added and saved in the ``Docker_RUN_ENIGMA_BD_PRS.sh`` script you can run the analyses (a) by batching a job script or (b) running the analyses locally.
    - We provide an example script to batch SLURM jobs (BATCH_BD_PRS.job). This will need to be augmented for your server. NOTE: Ensure the cores and memory stated in the ``Docker_RUN_ENIGMA_BD_PRS.sh`` script does not exceed the requested cores and memory in the slurm job script.
    - You can also run the script locally by opening a terminal, navigating to the ENIGMA_BD_PRS directory, and entering the following command: 
``
sh Docker_RUN_ENIGMA_BD_PRS.sh 
``
or 
``
bash Docker_RUN_ENIGMA_BD_PRS.sh 
``
6. Once the analysis is complete see the [Sharing Outputs](https://github.com/nadineparker/ENIGMA_BD_PRS#4-sharing-outputs) section



### Not Using a Container:
1. The following tools and packages must be installed:
    - PLINK v1.9 (stable version) can be downloaded from here https://www.cog-genomics.org/plink/1.9/
      - Don’t forget to unzip the PLINK download
    - PLINK v2.0 (alpha version) can be downloaded from here https://www.cog-genomics.org/plink/2.0/  
      -  Don’t forget to unzip the PLINK download
    - R v4 or higher is recommended which can be downloaded from here https://cran.r-project.org/ 
      - While the scripts attempt to install all required packages, it may be good to install the following packages in advance: data.table, tidyverse, argparser, bigsnpr, tools
    - Python v3.7.4 or higher is recommended which can be downloaded from here https://www.python.org/downloads/ 
      - You will need to install the following packages: pandas, matplotlib, sys, os, numpy, seaborn, scikit-learn

2. Navigate to the “ENIGMA_BD_PRS” directory and open the “RUN_ENIGMA_BD_PRS_noContainer.sh” script. Add the appropriate information requested at the top of the script and save the edits. Below is a list of the required information:

    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS
    - ``Sample_Dir``: replace the text “/PATH/TO/GENETIC/DATA” with the full path to your cohorts PLINK v1 files (NOTE, .bed, .bim, .fam should all be in the same directory). For example: export Sample_Dir=/Users/nadine/Documents
    - ``Prefix``: add the prefix used for the PLINK v1 files (.bed, .bim, .fam). For example: export Prefix=TOP_GRCh38
    - ``Sample_Name``: add the sample name/identifier. This will be used to name files. If you are running this analysis for multiple samples/cohorts this name will help differentiate outputs. For example: export Sample_Name=TOP
    - ``NCORES``: this specifies the number of system cores/threads you would like to use for analysis. The available cores will vary based on machine.
    - ``MEMORY``: this specifies the amount of memory available per core in MB. REMEMBER, you will need around 32GB or RAM to run the analyses. The default setting is to use 8 cores with ~8GB of memory (64GB of RAM) which takes ~1.5 hours to run (with n =2000 participants).
    - You will also need to set the operating system being used. The three options (WINDOWS, MAC, LINUX) will need to be set to either a “yes” or a “no” and must be in lower case letters. The yes option can only be used once or there will be errors. We highly recommend using a Linux machine/server (the current default).
    - ``CLEAN``: if set to “yes” (the default) all intermediate files and directories will be removed at the end of the analysis. NOTE: if you are running multiple analyses for different samples in parallel you will need to set CLEAN=no. This will prevent necessary directories from being deleted when one sample finishes before the other(s).
    - ``PLINK``: replace the text “/path/to/plink” with the full path to the plink executable file. For example: export PLINK=/Users/nadine/Documents/plink_linux/plink
    - ``PLINK2``: replace the text “/path/to/plink2” with the full path to the plink2 executable file. For example: export PLINK2=/Users/nadine/Documents/plink2_linux/plink2
    - Ensure that you have R and python on your machine and if using a server ensure they are loaded. For example to load R on a server you may need to add something resembling “module load R/4.0.0” to your batching script.

3. Once the above information is added and saved in the ``RUN_ENIGMA_BD_PRS_noContainer.sh`` script you can run the analyses (a) by batching a job script or (b) running the analyses locally.
    - We provide an example script to batch SLURM jobs (BATCH_BD_PRS.job). This will need to be augmented for your server. NOTE: Ensure the cores and memory stated in the ``RUN_ENIGMA_BD_PRS_noContainer.sh`` script does not exceed the requested cores and memory in the slurm job script.
    - You can also run the script locally by opening a terminal, navigating to the ENIGMA_BD_PRS directory, and entering the following command: 
``
sh RUN_ENIGMA_BD_PRS_noContainer.sh 
``
or 
``
bash RUN_ENIGMA_BD_PRS_noContainer.sh 
``
4. Once the analysis is complete see the [Sharing Outputs](https://github.com/nadineparker/ENIGMA_BD_PRS#4-sharing-outputs) section

## 4. Sharing Outputs
All outputs will be written to a directory named output_”SampleName”. The list of output files include:
  -	``LOG_DataCheck`` – a log file with results of the input data formatting check
  -	``NonDup_SNPlist`` – a list of non-duplicated SNPs which may be required for reporting consensus of SNPs across sites
  -	``pca_”Sample_Name”_proj.ancestries.png`` – a figure plotting principle components for projected ancestries using the 1000 Genomes super populations
  -	``pca_”Sample_Name”_proj.ancestries.txt`` – a text file containing genetic principle components and assignments of participants to 1000 Genomes super populations
  -	``RUN_ENIGMA_BD_PRS_”Sample_Name”.log`` – a log file for the entire analyses
  -	``“Sample_Name”_PGC_BIP_2024…txt.all_score`` – a total of 8 files containing cell-type based polygenic scores
  -	``“Sample_Name”_PRS.txt`` – a file containing BD polygenic scores
  -	``“Sample_Name”_rel.kin0`` – a file containing individuals with second degree genetically defined relatedness.
  -	``“Sample_Name”_rel.log`` – a log file for the genetic relatedness estimation

We ask that you share all files in this directory along with the **[ENIGMA BD phase 1 covariates](https://github.com/nadineparker/ENIGMA_BD_PRS#enigma-bd-phase-1-covariates)** and the standard **ENIGMA FreeSurfer cortical (SurfAvg/ThickAvg.csv) and subcortical (LandRvolumes.csv) measures**. If you already have imaging and covariate data stored on the USC server there is no need to re-share this data. 

Please ensure the participant identifiers used for the genetic data match the covariates and imaging data. If not, please provide a list which matches the different identifiers.

Email Nadine Parker when you are ready to share your data.

## Additional Information
### ENIGMA BD Phase 1 Covariates
 - ``SubjID`` - Subject ID should match the format of the IDs in the LandRvolumes.csv file and the SurfAvg/ThickAvg.csv files from the subcortical and cortical projects as well as the genetic data in the outputs from this analysis.
 - ``Dx`` - Diagnosis coded as bipolar patient = BD and control = CN
 - ``FullDx`` - Full diagnosis coded as: BD1, BD2, BDNOS, SchizoAffective. Set all controls = NA
 - ``Age`` - Years at time of scan
 - ``Sex`` - Males = M, Females = F
 - ``Lithium`` - Subject taking lithium at the time of scan: 1 = yes, 0 = no
 - ``AntiEpileptic`` - Subject taking antiepileptic at the time of scan: 1 = yes, 0 = no
 - ``Gen1AntiPsych`` - Subject taking 1st generation (Typical) antipsychotics at the time of scan: 1 = yes, 0 = no
 - ``Gen2AntiPsych`` - Subject taking 2nd generation (Atypical) antipsychotics at the time of scan: 1 = yes, 0 = no
 - ``AntiDep`` - Subject taking antidepressants at the time of scan: 1 = yes, 0 = no
 - ``MoodState`` - At the time of scan: Euthymic, Depressed, Manic, Hypomanic, Mixed. Set all controls = NA
 - ``AgeofOnset`` - Age of Onset (in years) of the first DSM-defined mood episode. Set all controls = NA
 - ``HistoryPsychosis`` - History of psychotic episodes: 1 = yes, 0 = no. Set all controls = NA
 - ``Site`` - If cohort data was collected across multiple sites, indicate site for each subject. If all data is from same site, mark entire column = NA
 - ``Ethnicity`` - Self-reported ancestry or ethnicity 

### Additional LiftOver Instructions
#### Using the Auto_LiftOver* scripts provided
1. Ensure that your system has singularity installed (https://docs.sylabs.io/guides/3.0/user-guide/installation.html) or docker installed (https://www.docker.com/get-started/).
   If using Docker Desktop, you may want to increase the resources. Navigate to settings Resources and maximize the available CPU limit, Memory limit, and Swap. Additionally, While docker is running/loaded, to initiate the container open a terminal and type the following command depending on your operating system:
```
LINUX/Windows/MAC (Intel): docker pull ghcr.io/comorment/ldpred2:latest 
MAC (M1/M2): docker pull -–platform=linux/amd64 ghcr.io/comorment/ldpred2:latest
```
2. Navigate to the “ENIGMA_BD_PRS” project directory and depending on which container you choose open the “Auto_LiftOver_Singularity.sh” or “Auto_LiftOver_Docker.sh” script. Add the appropriate information requested at the top of the script and save the edits. Below is a list of the required information:
    - ``Base_Dir``: replace the text “/PATH/TO/BASE/DIR” with the full path to a parent directory that contains all the necessary files and downloaded project directory. For example: export Base_Dir=/Users/nadine
    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS
    - ``Sample_Dir``: replace the text “/PATH/TO/GENETIC/DATA” with the full path to your cohorts PLINK v1 files (NOTE, .bed, .bim, .fam should all be in the same directory). For example: export Sample_Dir=/Users/nadine/Documents
    - ``Prefix``: add the prefix used for the PLINK v1 files (.bed, .bim, .fam). For example: export Prefix=TOP_GRCh38
    - ``liftover_chain``: This is hard coded to the provided chain file needed to convert from hg19 to hg38. If your data is in the hg18 (GRCh36) build you can download the hg18 to hg38 file from here (https://hgdownload.cse.ucsc.edu/goldenpath/hg18/liftOver/). If you require another chain file see here (https://hgdownload.soe.ucsc.edu/downloads.html).
    - ``NCORES``: this specifies the number of system cores/threads you would like to use for analysis. The available cores will vary based on machine.
    - ``MEMORY``: this specifies the amount of memory available per core in MB. REMEMBER, you will need around 32GB or RAM to run the analyses. The default setting is to use 8 cores with ~8GB of memory (64GB of RAM).
  
3. Once the above information is added and saved you can run the LiftOver conversion (a) by batching a job script or (b) running the analyses locally.
    - to run the analysis locally enter the following: 
``
sh Auto_LiftOver_Singularity.sh 
``
or 
``
sh Auto_LiftOver_Docker.sh 
``

#### NOT using the Auto_LiftOver* scripts provided
If you cannot run the containers on you system or you are not working on a linux system, you can run the LiftOver conversion using the instructions below. We encourage you to familiarize yourself with the following:
- instructinos on formatting a BED file here https://genome.ucsc.edu/FAQ/FAQformat.html#format1.
- the command line version of the LiftOver tool see instructions here https://genome.ucsc.edu/FAQ/FAQdownloads.html#liftOver.

Below are some basic instructions on how to generate a BED file and use the command line LiftOver tool to convert from GRCh37 (hg19) to CRCh38 (hg38).
   
 1. Generate a BED file using your .bim plink file. Below is an example using R code:
```
library(data.table); library(dplyr)

## Read in the bim file
bim <- read.table("YOUR_FILE.bim", sep = "\t", header=F)

## Generate a zero base position by subtracting 1 from the current position
bim$Pos0 <- bim$V4 - 1

## Select the necessary columns and order them for BED formatting
bim <- dplyr::select(bim, V1, Pos0, V4, V2)
bim <- bim[order(bim, V1, Pos0),]

## Ensure correct formatting of columns
bim$Pos0 <- as.integer(bim$Pos0)
bim$V4 <- as.integer(bim$V4)
bim$V1 <- paste0("chr", bim$V1)

## Write out your BED file
write.table(bim, file="YOUR_NAME_FOR_LIFTOVER.bed", row.names = F, col.names = F, sep = "\t", quote = F)
```

 2. Run LiftOver using the command line tool (https://genome-store.ucsc.edu/) and a chainfile downloaded from here (https://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/). You will need to supply the following to run liftOver:
    - ``liftOver`` the executable file to run the analyses
    - ``YOUR_NAME_FOR_LIFTOVER.bed`` - the BED file that contains coordinates to lift to a new build (generated in the step above).
    - ``hg19toHG38.over.chan.gz`` - a chainfile for lifting from your current genetic build to build GRCh38 (hg19). This example uses a GRCh37 (hg19) to GRCh38 (hg38) chainfile
    - ``YOUR_NAME_FOR_LIFTED_GRCh38_FILE.bed`` - a file name for the new BED file generated with the lifted coordinates in build GRCh38 (hg38)
    - ``YOUR_NAME_FOR_UNLIFTED_FILE.bed`` - a file name for the new BED file generated for those coordinates that could not be lifted to build GRCh38 (hg38)
Below is an example script:
```
## NOTE You may want to batch this script
liftOver YOUR_NAME_FOR_LIFTOVER.bed hg19toHG38.over.chan.gz YOUR_NAME_FOR_LIFTED_GRCh38_FILE.bed YOUR_NAME_FOR_UNLIFTED_FILE.bed
```
NOTE, the ``YOUR_NAME_FOR_LIFTED_GRCh38_FILE.bed`` file will not contain all of the original SNPs but should have a large majority (>90%) or something may have went wrong.

#### Here are instructions on how to generate new plink v1 files for analyses once you have lifted coordinates to GRCh38 (hg38).
 1. First you will need to clean up the lifted data to make sure the chromosomes are correctly formated. Below is an example usine R code:

```
## Read in the lifted bed file with coordinates in GRCh38
lifted_GRCh38 <- read.table("YOUR_LIFTED.bed", headter=F, sep="\t")

## Make sure the chromosome column can be converted to numeric and includes autosomes only
lifted_GRCh38$V1 <- gsub("chr", "", lifted_GRCh38$V1)
lifted_GRCh38 <- lifted_GRCh38[lifted_GRCh38$V1 %in% c(1:22),]
lifted_GRCh38$V1 <- as.numeric(lifted_GRCh38$V1)

## Write out a new clean version of the lifted GRCh38 coordinates
write.table(lifted_GRCh38, file="YOUR_LIFTED_CLEAN.bed", sep = "\t", row.names = F, col.names = F, quote = F)
```

2. Then you will need to update your existing plink v1 files. Below is an example script:
```
## Use the cleaned bed file from above to update the chromosome column
 # Note, column 1 below is the cleand chromosome column and column 4 below is the SNP identifier
plink --bfile YOUR_OLD_PLINK_Prefix --update-chr YOUR_LIFTED_CLEAN.bed 1 4 --make-bed --out YOUR_NEW_PLINK_Prefix

## Use the cleaned bed file to update the position coordinates for the new Plink files
 # Note, column 3 below contains the new coordinates in build GRCh38 (hg38)
plink --bfile YOUR_NEW_PLINK_Prefix --update-map YOUR_LIFTED_CLEAN.bed 3 4 --make-bed --out YOUR_NEWER_PLINK_Prefix
```





