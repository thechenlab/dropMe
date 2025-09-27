#!/bin/bash
#SBATCH -c 20
#SBATCH --mem-per-cpu=2G
#SBATCH -p short
#SBATCH -t 0-02:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

cells_dir=$1
fnc=$2
chunks=$3
pattern=$4
export fnc

func() {
  local i_bam=$1
  filter_non_conversion -p --consecutive --threshold $fnc $i_bam
  mv ${i_bam%.bam}.nonCG_filtered.bam ${i_bam%.bam}.fnc${fnc}.bam
  rm ${i_bam%.bam}.nonCG_removed_seqs.bam
}
export -f func

mapfile -t files < <(find "$cells_dir" -maxdepth 1 -name "$pattern" | sort)
total=${#files[@]}
files_per_chunk=$(( (total + chunks - 1) / chunks ))
start=$(( (SLURM_ARRAY_TASK_ID - 1) * files_per_chunk ))
end=$(( start + files_per_chunk - 1 ))
(( end >= total )) && end=$(( total - 1 ))

cd $cells_dir
parallel -j $(nproc) func ::: "${files[@]:$start:$((end-start+1))}"



