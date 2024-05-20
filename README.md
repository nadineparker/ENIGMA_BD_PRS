# ENIGMA BD PRS Project Instructions
The following instructions are for generating polygenic scores for the ENIGMA Bipolar Disorder working group. 

## Recommendations (Please Read)
Given the large size of some necessary files, **we strongly recommend running this analysis on a server where you can request 32GB of memory (RAM) and which has at least 25GB of free storage**. We also recommend using our singularity or docker containers which include all necessary software to run the analyses on Linux machines. We have successfully tested the docker container with smaller data sets (n=100 participants) on a MAC M1 chip laptop (16GB of RAM; runtime ~7hrs). Although, we still recommend using a machine with more RAM as larger samples will increase runtime or may not complete. We have not tested the containers using a Windows OS and therefore do not recommend using a Windows machine.  

## 1. Download Project Files
Download the entire ``ENIGMA_BD_PRS`` directory on the project google drive [here](https://drive.google.com/drive/folders/1cAJwvyLLcCnJhfIFltBF3xyUwIIBYRJW). All necessary project files are located in that directory. NOTE: some files are large, therefore, (1) this download will take time (hours) and (2) we recommend having ~25GB of free space on your system.

PLEASE DO NOT CHANGE THE LOCATION OF EXISTING FILES OR FOLDERS IN THE DOWNLOADED ``ENIGMA_BD_PRS DIRECTORY``. However, you can add your own files to this project directory.

## 2.	Format Your Genetic Data
This protocol assumes the input data has (i) already been imputed, (ii) is in PLINK v1 binary format (.bed, .bim, .fam files), and (iii) is in genomic build GRCh38.
 
1. If your data is not imputed you may wish to use the [ENIGMA Genetics Imputation Protocol](https://enigma.ini.usc.edu/protocols/genetics-protocols/imputation-protocol/).
2. If your data is imputed but in another format (ped/map, vcf, bgen, etc.) you can use [PLINK](https://www.cog-genomics.org/plink/1.9/input) to convert to the required format. Below is an example for .ped/.map and .vcf formats
```
plink --file ped_map_FilePrefix --make-bed --out New_FilePrefix
```
or
```
plink --vcf vcf_FilePrefix --make-bed --out New_FilePrefix
```
3. If your data is in another genomic build you can use the [liftOver](https://genome.ucsc.edu/cgi-bin/hgLiftOver) tool to convert to the GRCh38 (or hg38) build. Note once genomic coordinates have been lifter you will need to generate new plink files updating the chromosomes and positions of your plink v1 files. An example script (MakeLiftedPlinkFiles.sh) is provided on this GitHub page.

If you require help with converting your data please post an issue on the GitHub page using the issues tabe above.

## 3.	Perform the Analyses
Within the downloaded “ENIGMA_BD_PRS” directory, you will find 3 potential scripts to run the analyses:
  - ``Singularity_RUN_ENIGMA_BD_PRS.sh`` – to run the singularity container. Instructions directly below in Using the Singularity Container
  -	``Docker_RUN_ENIGMA_BD_PRS.sh`` – to run the docker container. Skip to instructions in [Using the Docker Container](https://github.com/nadineparker/ENIGMA_BD_PRS/edit/main/README.md#using-the-docker-container)
  -	``RUN_ENIGMA_BD_PRS_noContainer.sh`` – to run the analyses without any containers (requires installing software). Skip to instructions in [Not Using a Container](https://github.com/nadineparker/ENIGMA_BD_PRS/edit/main/README.md#not-using-a-container)

As mentioned above, we recommend using the singularity or docker containers on a linux based server with at least 32GB of RAM and 25GB of free storage space. Below are some steps to perform the analyses with Singularity, Docker, or no container. 

### Using the Singularity Container:
1. Ensure that your system has singularity installed or download it from https://docs.sylabs.io/guides/3.0/user-guide/installation.html.
2. Navigate to the “ENIGMA_BD_PRS” and open the “Singularity_RUN_ENIGMA_BD_PRS.sh” script. Add the appropriate information requested at the top of the script and save the edits. Below is a list of the required information:
    - ``Base_Dir``: replace the text “/PATH/TO/BASE/DIR” with the full path to a parent directory that contains all the necessary files and downloaded project directory. For example: export Base_Dir=/Users/nadine
    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS_FILES directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS_FILES
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
4. Once the analysis is complete see the [Sharing Outputs](https://github.com/nadineparker/ENIGMA_BD_PRS/edit/main/README.md#4-sharing-outputs) section


### Using the Docker Container:
1. Ensure your system has docker installed or download it from https://www.docker.com/get-started/. If using Docker Desktop, you may want to increase the resources. Navigate to settings Resources and maximize the available CPU limit, Memory limit, and Swap.
2. While docker is running/loaded, open a terminal and type the following command depending on your operating system:
```
LINUX: 
MAC: docker pull –platform=linux/amd64 ghcr.io/comorment/ldpred2:latest
```
3. You will also need to ensure you have R on your system. If not you can download R from here https://www.r-project.org/.
4. Navigate to the ``ENIGMA_BD_PRS`` directory and open the ``Docker_RUN_ENIGMA_BD_PRS.sh`` script. Add the appropriate information requested at the top of the script and save the edits. Below is a list of the required information:

    - ``Base_Dir``: replace the text “/PATH/TO/BASE/DIR” with the full path to a parent directory that contains all the necessary files and downloaded project directory. For example: export Base_Dir=/Users/nadine
    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS_FILES directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS_FILES
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
6. Once the analysis is complete see the [Sharing Outputs](https://github.com/nadineparker/ENIGMA_BD_PRS/edit/main/README.md#4-sharing-outputs) section



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

    - ``Project_Path``: replace the text “/PATH/TO/DOWNLOADED/FOLDER/ENIGMA_BD_PRS” with the full path to the ENIGMA_BD_PRS_FILES directory. For example: export Project_DIR=/Users/nadine/Documents/ENIGMA_BD_PRS_FILES
    - ``Sample_Dir``: replace the text “/PATH/TO/GENETIC/DATA” with the full path to your cohorts PLINK v1 files (NOTE, .bed, .bim, .fam should all be in the same directory). For example: export Sample_Dir=/Users/nadine/Documents
    - ``Prefix``: add the prefix used for the PLINK v1 files (.bed, .bim, .fam). For example: export Prefix=TOP_GRCh38
    - ``Sample_Name``: add the sample name/identifier. This will be used to name files. If you are running this analysis for multiple samples/cohorts this name will help differentiate outputs. For example: export Sample_Name=TOP
    - ``NCORES``: this specifies the number of system cores/threads you would like to use for analysis. The available cores will vary based on machine.
    - ``MEMORY``: this specifies the amount of memory available per core in MB. REMEMBER, you will need around 32GB or RAM to run the analyses. The default setting is to use 8 cores with ~8GB of memory (64GB of RAM) which takes ~1.5 hours to run (with n =2000 participants).
    - You will also need to set the operating system being used. The three options (WINDOWS, MAC, LINUX) will need to be set to either a “yes” or a “no” and must be in lower case letters. The yes option can only be used once or there will be errors. We highly recommend using a Linux machine/server (the current default).
    - ``CLEAN``: if set to “yes” (the default) all intermediate files and directories will be removed at the end of the analysis. NOTE: if you are running multiple analyses for different samples in parallel you will need to set CLEAN=no. This will prevent necessary directories from being deleted when one sample finishes before the other(s).
    - ``PLINK``: replace the text “/path/to/plink” with the full path to the plink executable file. For example: export PLINK=/Users/nadine/Documents/plink_linux/plink
    - ``PLINK2``: replace the text “/path/to/plink2” with the full path to the plink2 executable file. For example: export PLINK2=/Users/nadine/Documents/plink2_linux/plink2
    - Ensure that you have R and python on your machine and if using a server ensure they are loaded. For example to load R on a server you may need to add something resembling “module load R/4.0.0” to the script or to your batching script.

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
4. Once the analysis is complete see the [Sharing Outputs](https://github.com/nadineparker/ENIGMA_BD_PRS/edit/main/README.md#4-sharing-outputs) section

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

We ask that you share all files in this directory along with the **ENIGMA BD phase 1 covariates** and the standard **ENIGMA FreeSurfer cortical and subcortical measures**. If you already have imaging and covariate data stored on the USC server there is no need to re-share this data. 

Please ensure the participant identifiers used for the genetic data match the covariates and imaging data. If not, please provide a list which matches the different identifiers.

Email Nadine Parker when you are ready to share your data.

