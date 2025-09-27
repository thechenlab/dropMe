#!/bin/bash
#SBATCH -c 4
#SBATCH --mem-per-cpu=4G
#SBATCH -p short
#SBATCH -t 0-4:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

# universal vars
chunks=$1
pattern=$2
i_dir=$3
scripts_dir=$5

# custom vars
wl=$4
export wl

# custom func
func() {
  local i_bam=$1
  python $scripts_dir/bam_fix_cb.py -i $i_bam -w $wl
}
export -f func

# call func on fraction of files in input dir matching pattern
mapfile -t files < <(find "$i_dir" -maxdepth 1 -name "$pattern" | sort)
total=${#files[@]}
files_per_chunk=$(( (total + chunks - 1) / chunks ))
start=$(( (SLURM_ARRAY_TASK_ID - 1) * files_per_chunk ))
end=$(( start + files_per_chunk - 1 ))
(( end >= total )) && end=$(( total - 1 ))
cd $i_dir
parallel -j $(nproc) func ::: "${files[@]:$start:$((end-start+1))}"

