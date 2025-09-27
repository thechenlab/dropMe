#!/bin/bash
#SBATCH -c 1
#SBATCH --mem-per-cpu=1G
#SBATCH -p priority
#SBATCH -t 0-1:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

#############################################
# input
#############################################

i_dir=$1
group_size=$2
pattern=$3

#############################################
# array prep
#############################################

cd $i_dir

count=0
group=1

#for file in $pattern; do
for file in $pattern; do
    group_dir=$(printf "group_%03d" $group)
    mkdir -p $group_dir
    mv $file $group_dir
    ((count++))
    if (( count % group_size == 0 )); then
      ((group++))
    fi
done

#############################################
# submit
#############################################

: <<'COMMENT'

i_dir=/n/scratch/users/b/beo703/experiments/xBO273/dropMe/250702/splits
pattern='*.cor.bam'
group_size=50

sbatch ~/scripts/group.sh $cells_dir $group_size $pattern


COMMENT