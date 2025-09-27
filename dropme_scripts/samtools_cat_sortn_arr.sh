#!/bin/bash
#SBATCH -c 10
#SBATCH --mem-per-cpu=2G
#SBATCH -p short
#SBATCH -t 0-3:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL
#SBATCH -J catsortn

splits_dir=$1
spl=$2
group=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
group_dir=$splits_dir/group_${group}

cd $group_dir
samtools cat -o $group_dir/${spl}.cat.bam *.cor.bam
samtools sort -n -@ $(nproc) -o $group_dir/${spl}.sortn.bam $group_dir/${spl}.cat*
