#!/bin/bash
#SBATCH -c 4
#SBATCH --mem-per-cpu=2G
#SBATCH -p priority
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

cells_dir=$1
echo $cells_dir

cd $cells_dir
ls $cells_dir/*.bam | parallel -j $(nproc) deduplicate_bismark -p --bam {}

for f in *.deduplicated.bam; do
    mv $f ${f%.deduplicated.bam}.dedup.bam
done

