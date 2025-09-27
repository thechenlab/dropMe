#!/bin/bash
#SBATCH -c 20
#SBATCH --mem-per-cpu=4G
#SBATCH -p priority
#SBATCH -t 0-12:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL
#SBATCH -J fastp

# RAM efficiency 1GB=96.7%

i_dir=$1

func() {

    r1_adapt=CTATCTCTTATACACATCTCCAAACC
    r2_adapt=CTGTCTCTTATACACATCTGACGCTG

    r1_fq=$1
    r2_fq=${r1_fq/R1/R2}

    r1_trim_fq=${r1_fq%.fastq.gz}.trim9.fastq.gz
    r2_trim_fq=${r2_fq%.fastq.gz}.trim9.fastq.gz
    rep_html=${r1_fq%.fastq.gz}.trim9.fastp.html

    fastp -w 1 --adapter_sequence=$r1_adapt --adapter_sequence_r2=$r2_adapt --trim_front1 9 --trim_front2 0 --trim_tail1 0 --trim_tail2 9\
    -i $r1_fq -I $r2_fq -o $r1_trim_fq -O $r2_trim_fq \
    -h $rep_html
}
export -f func

cd $i_dir
# *
ls $i_dir/*R1*.fastq.gz | parallel -j $(nproc) func {}
