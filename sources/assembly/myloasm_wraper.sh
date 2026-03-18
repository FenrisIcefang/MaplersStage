#!/bin/sh
# This script assemble a set of reads into a metagenome, using MetaMDBG
sample="$1"
tmp_directory="$2"
output="$3"
Ncpu=$(nproc)

mkdir -p "$tmp_directory"
myloasm $sample -o $tmp_directory -t $Ncpu --hifi
mv $tmp_directory"/assembly_primary.fa" $output


#--bloom-filter-size
