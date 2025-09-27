#!/bin/bash
#SBATCH -c 20
#SBATCH --mem-per-cpu=500M
#SBATCH -p short
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

cells_dir=$1
chunks=$2
pattern=$3
export cells_dir

func() {
local i_bam=$1
r1tr5p=9;r1tr3p=3;r2tr5p=3;r2tr3p=9
bismark_methylation_extractor $i_bam \
--merge_non_CpG --comprehensive --gzip \
--no_header \
--bedGraph \
--ignore_r2 $r1tr5p \
--ignore_3prime_r2 $r1tr3p \
--ignore $r2tr5p \
--ignore_3prime $r2tr3p \
--output_dir $cells_dir
rm ${i_bam%.bam}.bedGraph.gz
mv ${i_bam%.bam}.bismark.cov.gz "${i_bam%.bam}.methx_${r1tr5p}-${r1tr3p}-${r2tr5p}-${r2tr3p}.CG.cov.gz"
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

