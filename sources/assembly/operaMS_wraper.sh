#!/bin/sh
#SBATCH --time=3-00:00:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1

opera_path="$1"
long_reads="$2"
short_reads_1="$3"
short_reads_2="$4"
short_read_assembly="$5"
tmp_directory="$6"
cleanup="${7:-yes}"


if [ ! -d "$opera_path" ]; then
   echo "not here"
   mkdir -p "$opera_path"
   cd "$opera_path"
   cd ..
   git clone https://github.com/CSB5/OPERA-MS.git
   cd OPERA-MS
   make
   perl OPERA-MS.pl check-dependency
fi

CONTIG_ARG=""
if [ -n "$short_read_assembly" ] && [ "$short_read_assembly" != "none" ]; then
    CONTIG_ARG="--contig-file $short_read_assembly"
fi

perl "$opera_path"/OPERA-MS.pl \
    --num-processors $(nproc) \
    --no-ref-clustering \
    $CONTIG_ARG \
    --short-read1 "$short_reads_1" \
    --short-read2 "$short_reads_2" \
    --long-read "$long_reads" \
    --out-dir "$tmp_directory"

mv "$tmp_directory"/OPERA-MS_results/final_assembly.fasta "$tmp_directory"/assembly.fasta

if [ "$cleanup" != "no" ] && [ -f "$tmp_directory/assembly.fasta" ]; then
    rm -rf "$tmp_directory"
fi