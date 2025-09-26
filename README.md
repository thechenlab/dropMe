
# set-up
define pipeline directory
```
pipe_dir=/n/data1/hms/scrb/chen/lab/bco/experiments/xBO203/pipeline/250713
```
pass Bismark reference
```
reference=/n/data1/hms/scrb/chen/lab/bco/references/bismark/GRCm39
```
pass cell barcode (CB) whitelist (derived from RNA library, in ATAC reverse-complement form
```
whitelist=/n/scratch/users/b/beo703/experiments/xBO273/whitelists/xBO273_100rupc_atacrc.txt
```
pass fastq inputs
```
fqs_dir=/n/data1/hms/scrb/chen/lab/bco/experiments/xBO203/fastqs
r1_fq=xBO203.M.R1.fastq.gz
r2_fq=xBO203.M.R2.fastq.gz
i2_fq=xBO203.M.I2.fastq.gz
```
define output directories

init directories
