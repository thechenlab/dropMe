#!/bin/bash
#SBATCH -c 20
#SBATCH --mem-per-cpu=2G
#SBATCH -p priority
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL
#SBATCH -J bamscmer

splits_dir=$1
cells_dir=$2
whitelist=$3
export splits_dir cells_dir whitelist

#mkdir -p "$cells_dir"

merge_cb () {

    local cb=$1

    shopt -s nullglob
    local -a files=( "$splits_dir"/group_*/cells*/"${cb}.bam" )
    shopt -u nullglob

    (( ${#files[@]} == 0 )) && {
        echo "WARN: ${cb} - no files found" >&2
        return
    }

    samtools cat -o "$cells_dir/${cb}.bam" "${files[@]}"

}
export -f merge_cb

parallel -j 0 merge_cb :::: "$whitelist"