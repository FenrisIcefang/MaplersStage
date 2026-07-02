
rule reads_on_contigs_mapping : 
    params : 
        expand("{sample}", sample=get_samples("name")),
        preset = get_longread_preset,
    input :
        assembly = "outputs/{sample}/{assembler}/assembly.fasta",
        reads = get_long_read_path,
    output : "outputs/{sample}/{assembler}/reads_on_contigs.bam"
    conda : "../envs/mapping.yaml"
    threads : config["rules_mapping"]["threads"]
    resources :
        cpus_per_task = config["rules_mapping"]["threads"],
        mem_mb=config["rules_mapping"]["memory"],
        runtime=eval(config["rules_mapping"]["time"]),
    shell : "./sources/mapping.sh {output} {input.reads} {input.assembly} {params.preset} '' {threads}"

if(
    (is_binning_enabled() and (short_read_binning_enabled() or short_read_cobinning_enabled()))
    or config["short_read_mapping_evaluation"]
    or config.get("fastqc", False)
) :
    rule short_reads_on_contigs_mapping : 
        params : 
            expand("{sample}", sample=get_samples("name")),
        input :
            assembly = "outputs/{sample}/{assembler}/assembly.fasta",
            R1 = lambda wildcards: get_short_read("short_reads_1", wildcards),
            R2 = lambda wildcards: get_short_read("short_reads_2", wildcards) 
        output : "outputs/{sample}/{assembler}/short_reads_on_contigs.bam"
        conda : "../envs/mapping.yaml"
        threads : config["rules_mapping"]["threads"]
        resources :
            cpus_per_task = config["rules_mapping"]["threads"],
            mem_mb=config["rules_mapping"]["memory"],
            runtime=eval(config["rules_mapping"]["time"]),
        shell : "./sources/mapping.sh {output} {input.R1} {input.assembly} sr {input.R2} {threads}"



def get_additional_read_path(wildcards):
    name = wildcards.additional_read_name
    path = [p["path"] for p in config["additional_reads"] if p["name"] == name]
    print(name, path)
    if(len(path) == 1) : 
        return path

if(is_binning_enabled() and additional_reads_cobinning_enabled()) :
    rule additional_reads_on_contigs_mapping : 
        params : 
            additional_reads = config["additional_reads"],
            preset = get_longread_preset,
        input :
            assembly = "outputs/{sample}/{assembler}/assembly.fasta",
            reads = get_additional_read_path
        output : "outputs/{sample}/{assembler}/{additional_read_name}_reads_on_contigs.bam",
        conda : "../envs/mapping.yaml"
        threads : config["rules_mapping"]["threads"]
        resources :
            cpus_per_task = config["rules_mapping"]["threads"],
            mem_mb=config["rules_mapping"]["memory"],
            runtime=eval(config["rules_mapping"]["time"]),
        shell : "./sources/mapping.sh {output} {input.reads} {input.assembly} {params.preset} '' {threads}"

if(config['reference_mapping_evaluation']) :
    rule long_reads_on_reference_mapping : 
        input :
            reference = lambda wildcards: get_reference(wildcards.reference_name)
        params :
            reads = get_optional_long_read_path,
            preset = get_longread_preset
        output : "outputs/{sample}/long_reads_on_reference.{reference_name}.bam"
        conda : "../envs/mapping.yaml"
        threads : config["rules_mapping"]["threads"]
        resources :
            cpus_per_task = config["rules_mapping"]["threads"],
            mem_mb=config["rules_mapping"]["memory"],
            runtime=eval(config["rules_mapping"]["time"]),
        run:
            if params.reads == "none":
                shell("touch {output}")
            else:
                shell("./sources/mapping.sh {output} {params.reads} {input.reference} {params.preset} '' {threads}")


    rule short_reads_on_reference_mapping : 
        input :
            R1 = lambda wildcards: get_short_read("short_reads_1", wildcards),
            R2 = lambda wildcards: get_short_read("short_reads_2", wildcards),
            reference = lambda wildcards: get_reference(wildcards.reference_name)
        output : "outputs/{sample}/short_reads_on_reference.{reference_name}.bam"
        conda : "../envs/mapping.yaml"
        threads : config["rules_mapping"]["threads"]
        resources :
            cpus_per_task = config["rules_mapping"]["threads"],
            mem_mb=config["rules_mapping"]["memory"],
            runtime=eval(config["rules_mapping"]["time"]),
        shell : "./sources/mapping.sh {output} {input.R1} {input.reference} sr {input.R2} {threads}"

if(config.get("contigs_on_reference_mapping", False)) :
    rule contigs_on_reference_mapping :
        input :
            assembly = "outputs/{sample}/{assembler}/assembly.fasta",
            reference = lambda wildcards: get_reference(wildcards.reference_name)
        output : "outputs/{sample}/{assembler}/contigs_on_reference.{reference_name}.bam"
        conda : "../envs/mapping.yaml"
        threads : config["rules_mapping"]["threads"]
        resources :
            cpus_per_task = config["rules_mapping"]["threads"],
            mem_mb=config["rules_mapping"]["memory"],
            runtime=eval(config["rules_mapping"]["time"]),
        shell : "./sources/mapping.sh {output} {input.assembly} {input.reference} asm20 '' {threads}"
