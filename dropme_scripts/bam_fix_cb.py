##################################################
# imports
##################################################

import csv
import argparse
import os

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

import pysam

from collections import Counter
from itertools import combinations

##################################################
# functions
##################################################

def CtoT(sequence):
    # Find all positions of 'C' in the sequence
    c_positions = [i for i, nucleotide in enumerate(sequence) if nucleotide == 'C']
    
    # Generate all combinations of C positions to mutate
    all_combinations = []
    for r in range(0, len(c_positions) + 1):  # r is the number of C's to mutate
        all_combinations.extend(combinations(c_positions, r))
    
    # Generate sequences with C>T mutations and count mutations
    mutated_sequences = []
    for combination in all_combinations:
        sequence_list = list(sequence)  # Convert to a mutable list
        for pos in combination:
            sequence_list[pos] = 'T'  # Perform the mutation
        mutated_sequence = "".join(sequence_list)
        mutated_sequences.append((mutated_sequence, len(combination)))  # Include the mutation count
    
    return mutated_sequences

def cb_hist(counts, o_img):
    
    counts_df = pd.DataFrame(list(counts.items()), columns=['barcode', 'count'])
    
    x = counts_df['count']
    bins = np.logspace(np.log10(10), np.log10(1000000), 100)
    
    plt.hist(x, bins=bins, edgecolor='#36454F', linewidth=0.5)
    plt.xlabel('reads')
    plt.ylabel('count')
    plt.xscale("log")
    plt.savefig(o_img, format='png', dpi=300)
    plt.close()

##################################################
# main
##################################################

def main(input_bam, wl_txt):

    # auto vars
    o_dir = os.path.dirname(input_bam)
    output_bam = f'{input_bam[:-4]}.cor.bam'

    # load whitelist
    with open(wl_txt,'r') as f:
        wl = f.read().splitlines()

    # mutate
    wt_to_mt = {}
    for bc in wl:
        wt_to_mt[bc]=CtoT(bc)

    # remove degenerate mutated CBs
    combined_list = [item for sublist in wt_to_mt.values() for item in sublist]
    item_counts = Counter(combined_list)
    to_remove = {item for item, count in item_counts.items() if count > 1}
    wt_to_mt_filt = {key: [item for item in value if item not in to_remove] for key, value in wt_to_mt.items()}

    # invert dictionary
    mt_to_wt = {}
    for key, values in wt_to_mt_filt.items():
        for value in values:
            if value not in mt_to_wt:
                mt_to_wt[value[0]] = (key, value[1])

    # prep outputs
    clean_cbs = []
    cbs = []
    mut_freqs = {}

    valid_mt_cbs = mt_to_wt.keys()
    with pysam.AlignmentFile(input_bam, "rb") as bam_in:
        with pysam.AlignmentFile(output_bam, "wb", header=bam_in.header) as bam_out:
            for read in bam_in:

                # extract cell barcode from read name
                cb = read.query_name[:16]
                cbs.append(cb)

                if cb in valid_mt_cbs:
                    new_tuple = mt_to_wt[cb]
                    clean_cbs.append(new_tuple[0])
                    
                    # update {number of mutations in cell barcode} x {count}
                    if not new_tuple[1] in mut_freqs.keys():
                        mut_freqs[new_tuple[1]]=1
                    else:
                        mut_freqs[new_tuple[1]]+=1

                    read.set_tag("CB", new_tuple[0])
                    read.set_tag("BM", new_tuple[1], value_type="i")
                    read.query_name = f'{new_tuple[0]}:{read.query_name}'
                    bam_out.write(read)

    # save outputs

    cb_clean_counts=Counter(clean_cbs)
    df1=pd.DataFrame(list(cb_clean_counts.items()), columns=['barcode', 'count'])
    df1.to_csv(f'{input_bam[:-4]}.cb_counts_cor.csv', index=False)

    cb_counts=Counter(cbs)
    df2=pd.DataFrame(list(cb_counts.items()), columns=['barcode', 'count'])
    df2.to_csv(f'{input_bam[:-4]}.cb_counts_raw.csv', index=False)

    pd.Series(mut_freqs).to_csv(f'{input_bam[:-4]}.mut_freqs.csv', header=False)

#########################
# plot cell barcode histogams
#########################

    if args.plot:

        cb_hist(cb_clean_counts, f'{input_bam[:-4]}.cb_hist_corr.png')
        cb_hist(cb_counts, f'{input_bam[:-4]}.cb_hist_orig.png')

### plot mutation freqs #################


        data = mut_freqs
        reads=len(cbs)

        # Sort the dictionary by keys to ensure proper order on the x-axis
        sorted_data = dict(sorted(data.items()))
        x = list(sorted_data.keys())
        y = list(sorted_data.values())

        # Create the line plot
        plt.plot(x, y, marker='o')  # Add markers for better visibility of points
        plt.text(0.975, 0.975, f'{round(y[0]/reads*100,1)}% perfect match\n {round(sum(y)/reads*100,1)}% fuzzy match', transform=plt.gca().transAxes, verticalalignment='top', horizontalalignment='right')

        # Label the plot
        plt.xlabel("mutations")
        plt.ylabel("counts")
        plt.title("cell barcode error correction")
        plt.yscale('log')  # Use log scale for the y-axis to handle large range of values
        plt.savefig(f'{input_bam[:-4]}.mut_freq.png', format='png', dpi=300)
        plt.close()

##################################################
# args
##################################################

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--i_bam", type=str)
    parser.add_argument("-w", "--wl_txt", type=str)
    parser.add_argument("-p", "--plot", action="store_true")
    args = parser.parse_args()


    main(args.i_bam, args.wl_txt)

# in pipe env
'''
wl=/n/scratch/users/b/beo703/experiments/xBO236/whitelists/whitelist_gex100_atacrc.txt
bam=/n/scratch/users/b/beo703/experiments/xBO236/pipeline/xBO236_DM95_S2/split/output_012/xBO236_DM95_S2_R1.part_012_clean_trim_bismark_bt2_pe.bam
#python ~/scripts/bam_fix_cb.py -i $bam -w $wl -p
$w --wrap="python ~/scripts/bam_fix_cb.py -i $bam -w $wl -p"

'''
