#!/bin/bash
#SBATCH -c 20
#SBATCH --mem-per-cpu=4G
#SBATCH -p short
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

splits_dir=$1

func() {

    r1_fq=$1
    r2_fq=${r1_fq/R1/R2}
    i2_fq=${r1_fq/R1/I2}
    cb_txt=${i2_fq%.fastq}.cbs.txt
    
    paste $cb_txt <(cat $r1_fq | awk 'NR % 4 == 1 {name=substr($0, 2)} NR % 4 == 2 {seq=$0} NR % 4 == 3 {plus=$0} NR % 4 == 0 {qual=$0; print name "\t" seq "\t" plus "\t" qual}') | \
    awk -F'\t' '{print "@" $1 ":" $2 "\n" $3 "\n" $4 "\n" $5}' | \
    gzip > ${r1_fq%.fastq}.nametag.fastq.gz
    
    paste $cb_txt <(cat $r2_fq | awk 'NR % 4 == 1 {name=substr($0, 2)} NR % 4 == 2 {seq=$0} NR % 4 == 3 {plus=$0} NR % 4 == 0 {qual=$0; print name "\t" seq "\t" plus "\t" qual}') | \
    awk -F'\t' '{print "@" $1 ":" $2 "\n" $3 "\n" $4 "\n" $5}' | \
    gzip > ${r2_fq%.fastq}.nametag.fastq.gz
    
}
export -f func

###
cd $splits_dir
ls *R1*.fastq | parallel -j $(nproc) func {}
