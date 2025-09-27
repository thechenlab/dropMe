#!/bin/bash
#SBATCH -c 4
#SBATCH --mem-per-cpu=500M
#SBATCH -p medium
#SBATCH -t 0-24:00
#SBATCH -o /home/beo703/reports/%N_%j.out
#SBATCH -e /home/beo703/reports/%N_%j.err
#SBATCH --mail-user='benno_orr@g.harvard.edu'
#SBATCH --mail-type=ALL

i_dir=$1

func() {

i2_fq=$1
cat $i2_fq | awk 'NR % 4 == 2 {print substr($0, 9, 16)}' > ${i2_fq%.fastq}.cbs.txt

}
export -f func

cd $i_dir
ls $i_dir/*I2*.fastq | parallel -j $(nproc) func {}
