#!/bin/bash
#SBATCH -c 1
#SBATCH --mem-per-cpu=2G
#SBATCH -p short
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

splits_dir=$1
spl=$2
group=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
group_dir=$splits_dir/group_${group}

o_dir=$group_dir/cells
mkdir -p $o_dir

cd $group_dir
python /home/beo703/scripts/bam_split_v2.py -i $group_dir/${spl}.sortn.bam -o $o_dir

