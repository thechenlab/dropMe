#!/bin/bash
#SBATCH -c 3
#SBATCH --mem-per-cpu=16G
#SBATCH -p medium
#SBATCH -t 0-96:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

splits_dir=$1
chunks=$2
pattern=$3
reference=$4
export splits_dir reference

func() {
    local r1_fq=$1
    local r2_fq=${r1_fq/R1/R2}
    bismark $reference -1 $r1_fq -2 $r2_fq -o $splits_dir --pbat --parallel 1
}

mapfile -t files < <(find "$splits_dir" -maxdepth 1 -name "$pattern" | sort)
total=${#files[@]}
files_per_chunk=$(( (total + chunks - 1) / chunks ))
start=$(( (SLURM_ARRAY_TASK_ID - 1) * files_per_chunk ))
end=$(( start + files_per_chunk - 1 ))
(( end >= total )) && end=$(( total - 1 ))

cd $splits_dir
for f in "${files[@]:$start:$((end-start+1))}"; do
  func "$f"
done


