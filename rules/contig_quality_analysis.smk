if(config["metaquast"]) :
    # mapping contigs on reference with metaquast
    rule metaquast :
        params : 
            reference_genomes = config["reference_genomes"],
            output_directory="outputs/{sample}/{assembler}/metaquast/results/",
            min_identity=config["metaquast_min_identity"]
        conda : "../envs/quast.yaml"
        threads : config["rule_metaquast"]["threads"]
        resources :
            cpus_per_task = config["rule_metaquast"]["threads"],
            mem_mb=config["rule_metaquast"]["memory"],
            runtime=eval(config["rule_metaquast"]["time"]),
        input : "outputs/{sample}/{assembler}/assembly.fasta",
        output : directory("outputs/{sample}/{assembler}/metaquast/results/summary/TSV/"),
        shell : "sources/contig_quality_analysis/metaquast_wraper.sh {input} {params.output_directory} {params.min_identity} {params.reference_genomes} "
if(config["metaquast"] and "abundance_information" in config) :
    rule metaquast_report_writer :
        input : 
            metaquast_output = "outputs/{sample}/{assembler}/metaquast/results/summary/TSV/", 
            coverage_information = config["abundance_information"]    
        conda : "../envs/python.yaml"
        output : "outputs/{sample}/{assembler}/metaquast/report.txt",
        shell : "python3 sources/contig_quality_analysis/metaquast_report_writer.py {input.metaquast_output} {input.coverage_information}  > {output}" 


if(config["read_mapping_evaluation"]) :
    # mapping reads on contigs should be flexible to either use long or short reads
    rule read_contig_mapping_evaluation : 
        params : 
            expand("{sample}", sample=get_samples("name")),
            output_directory="outputs/{sample}/{assembler}/",
            threshold = config["read_mapping_threshold"]
        input :
            reads = lambda wildcards: get_sample("read_path", wildcards),
            mapping = "outputs/{sample}/{assembler}/{reference_reads}_on_contigs.bam",
        threads : config["rule_read_contig_mapping_evaluation"]["threads"]
        resources :
            cpus_per_task = config["rule_read_contig_mapping_evaluation"]["threads"],
            mem_mb=config["rule_read_contig_mapping_evaluation"]["memory"],
            runtime=eval(config["rule_read_contig_mapping_evaluation"]["time"]),   
        output : "outputs/{sample}/{assembler}/{reference_reads}_on_contigs_mapping_evaluation/report.txt"
        conda : "../envs/python.yaml"
        shell : "python3 ./sources/contig_quality_analysis/read_mapping_evaluation.py {input.reads} {input.mapping} {params.threshold} > {output}"

if(config["short_read_mapping_evaluation"]):
    rule short_read_contig_mapping_evaluation:
        input:
            bam="outputs/{sample}/{assembler}/short_reads_on_contigs.bam",
            R1=lambda wildcards: get_short_read("short_reads_1", wildcards),
            R2=lambda wildcards: get_short_read("short_reads_2", wildcards)
        output:
            "outputs/{sample}/{assembler}/short_reads_on_contigs_mapping_evaluation/report.txt"
        conda:
            "../envs/python.yaml"
        threads: 1
        resources:
            cpus_per_task=1,
            mem_mb=5000,
            runtime=60
        shell:
            """
            python3 sources/contig_quality_analysis/read_mapping_evaluation_short_reads.py \
                {input.R1} \
                {input.R2} \
                {input.bam} \
                0 \
                > {output}
            """