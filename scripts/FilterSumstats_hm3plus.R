
library(data.table); library(tidyverse)

# read in hm3plus reference
ref <- readRDS("Protocol/ref/map_hm3_plus.rds")

# read in sumstats
BIP_EUR <- fread("Protocol/sumstats/PGC_BIP_2024_EUR_no23andMe_GRCh38.sumstats.gz")
BIP_EUR_T1 <- fread("Protocol/sumstats/PGC_BIP_2024_EUR_Type1_GRCh38.sumstats.gz")
BIP_EUR_T2 <- fread("Protocol/sumstats/PGC_BIP_2024_EUR_Type2_GRCh38.sumstats.gz")
BIP_Multi <- fread("Protocol/sumstats/PGC_BIP_2024_Multi_no23andMe_GRCh38.sumstats.gz")

## Restict to hm3plus
BIP_EUR <- BIP_EUR[BIP_EUR$RSID %in% ref$rsid,]
BIP_EUR_T1 <- BIP_EUR_T1[BIP_EUR_T1$RSID %in% ref$rsid,]
BIP_EUR_T2 <- BIP_EUR_T2[BIP_EUR_T2$RSID %in% ref$rsid,]
BIP_Multi <- BIP_Multi[BIP_Multi$RSID %in% ref$rsid,]

# Write out hm3plus restricted sumstats
# fwrite(
#   BIP_EUR, quote=F, row.names = F, sep = "\t",
#   file = "Protocol/sumstats/PGC_BIP_2024_EUR_no23andMe_hm3plus_GRCh38.sumstats.gz")
# 
# fwrite(
#   BIP_EUR_T1, quote=F, row.names = F, sep = "\t",
#   file = "Protocol/sumstats/PGC_BIP_2024_EUR_Type1_hm3plus_GRCh38.sumstats.gz")
# 
# fwrite(
#   BIP_EUR_T2, quote=F, row.names = F, sep = "\t",
#   file = "Protocol/sumstats/PGC_BIP_2024_EUR_Type2_hm3plus_GRCh38.sumstats.gz")
# 
# fwrite(
#   BIP_Multi, quote=F, row.names = F, sep = "\t",
#   file = "Protocol/sumstats/PGC_BIP_2024_Multi_no23andMe_hm3plus_GRCh38.sumstats.gz")
