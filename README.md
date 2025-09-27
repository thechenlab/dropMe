# intro
This workflow is designed for use with a computing cluster using SLURM job scheduler. You will likely need to adapt the pipeline or individual commands to fit with the computational platform you are working on.

# input

pass:

- output directory
- sample id
- Bismark reference
- cell barcode (CB) whitelist text file (from GEX library, in ATAC reverse complement format)
- scripts directory
- fastqs directory
- fastq filenames, with .{R1/R2/I2}.fastq.gz suffix convention

```bash
out_dir=/path/to/out_dir/yymmdd
sample=xBOxxx.M.yymmdd
reference=/path/to/bismark_reference
whitelist=/path/to/whitelist.txt
dropme_scripts_dir=/path/to/dropme_scripts
fqs_dir=/path/to/fastqs
r1_fq=xBOxxx.M.yymmdd.R1.fastq.gz
r2_fq=xBOxxx.M.yymmdd.R2.fastq.gz
i2_fq=xBOxxx.M.yymmdd.I2.fastq.gz
```

initialize output directories

```bash
bulk_dir=$out_dir/bulk
sc_dir=$out_dir/cells
mkdir -p $out_dir
mkdir -p $bulk_dir
mkdir -p $sc_dir
```

# bulk processing

split fastqs into 10M lines each

```bash
sbatch $dropme_scripts_dir/fastq_split_decmp.sh $fqs_dir/$i2_fq $bulk_dir
sbatch $dropme_scripts_dir/fastq_split_decmp.sh $fqs_dir/$r1_fq $bulk_dir
sbatch $dropme_scripts_dir/fastq_split_decmp.sh $fqs_dir/$r2_fq $bulk_dir
```

extract CBs from I2

```bash
sbatch $dropme_scripts_dir/fastq_cb_extract.sh $bulk_dir
```

append CBs to R1/R2

```bash
sbatch $dropme_scripts_dir/fastq_cb_tag.sh $bulk_dir
```

delete intermediate files

```bash
rm $bulk_dir/*.fastq
rm $bulk_dir/*.txt
```

trim, quality filter

```bash
sbatch $dropme_scripts_dir/fastp.sh $bulk_dir
```

align

```bash
chunks=40
pattern='*R1*.trim9.fastq.gz'
sbatch --array=1-$chunks $dropme_scripts_dir/scripts/bismark_align.sh $bulk_dir $chunks "$pattern" $reference
```

error-correct CBs

```bash
chunks=3
pattern='*_bismark_bt2_pe.bam'
sbatch --array=1-$chunks $dropme_scripts_dir/bam_fix_cb.sh $chunks "$pattern" $bulk_dir $whitelist $scripts_dir
```

# generate single-cell bams

group splits

```bash
pattern='*.cor.bam'
group_size=50
sbatch $dropme_scripts_dir/group.sh $bulk_dir $group_size "$pattern"
```

merge bulk splits within groups

```bash
groups=$(find "$bulk_dir" -maxdepth 1 -type d -name 'group_???' | wc -l)
sbatch --array=1-${groups} $dropme_scripts_dir/samtools_cat_sortn_arr.sh $bulk_dir $sample
```

split into single-cell bams within groups

```bash
sbatch --array=1-${groups} $dropme_scripts_dir/bam_split_arr.sh $bulk_dir $spl
```

merge single-cell bams across groups

```bash
sbatch $dropme_scripts_dir/bam_sc_merge.sh $bulk_dir $cells_dir $whitelist
```

# single-cell processing

deduplicate

```bash
sbatch $dropme_scripts_dir/bismark_dedup_parallel.sh $cells_dir
```

filter artificially methylated reads

```bash
fnc=3
chunks=5
pattern='*dedup.bam'
sbatch --array=1-$chunks $dropme_scripts_dir/bismark_fnc.sh $cells_dir $fnc $chunks "$pattern"
```

extract methylation calls

```bash
chunks=5
pattern='*dedup.fnc3.bam'
sbatch --array=1-$chunks $dropme_scripts_dir/bismark_methx.sh $cells_dir $chunks "$pattern"
```
