#!/bin/bash
set -euo pipefail

bam=$1
output_directory=$2

mkdir -p "$output_directory/mapped"
mkdir -p "$output_directory/unmapped"

# ------------------------------------------------------------
# Definition used here:
# mapped/unmapped is evaluated per read, not per pair.
# In other words if a read in R1 is mapped and this very same read is unmapped in R2 bcs it's of low quality 
# it will appear in both the mapped and unmapped .html
# ------------------------------------------------------------

# R1 mapped: first in pair (-f 64), read itself mapped (-F 4)
samtools fastq \
    -f 64 \
    -F 4 \
    "$bam" \
    > "$output_directory/mapped/R1.fastq"

# R2 mapped: second in pair (-f 128), read itself mapped (-F 4)
samtools fastq \
    -f 128 \
    -F 4 \
    "$bam" \
    > "$output_directory/mapped/R2.fastq"

# R1 unmapped: first in pair (-f 64) and read itself unmapped (-f 4)
samtools fastq \
    -f 68 \
    "$bam" \
    > "$output_directory/unmapped/R1.fastq"

# R2 unmapped: second in pair (-f 128) and read itself unmapped (-f 4)
samtools fastq \
    -f 132 \
    "$bam" \
    > "$output_directory/unmapped/R2.fastq"