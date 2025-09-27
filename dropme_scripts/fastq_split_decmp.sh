#!/bin/bash
#SBATCH -c 1
#SBATCH --mem-per-cpu=2G
#SBATCH -p short
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

fq=$1
splits_dir=$2
i_dir=$(dirname $fq)
sample=$(basename $fq .fastq.gz)
cd $i_dir

zcat $fq | split -a 3 -l 100000 -d --additional-suffix=.fastq - $splits_dir/${sample}.

