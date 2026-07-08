if("metaMDBG" in config["assemblers"]) :
    rule metaMDBG_assembly :
        params : 
            expand("{name}", name=get_samples("name")),
            tmp_directory="outputs/{sample}/metaMDBG/tmp/",
            technology=get_sample_technology,
            cleanup=config.get("cleanup_tmp", "yes")
        conda : "../envs/metaMDBG.yaml"
        threads : config["rule_metaMDBG_assembly"]["threads"]
        resources :
            cpus_per_task = config["rule_metaMDBG_assembly"]["threads"],
            mem_mb=config["rule_metaMDBG_assembly"]["memory"],
            runtime=eval(config["rule_metaMDBG_assembly"]["time"]),
        input : get_long_read_path,
        output : "outputs/{sample}/metaMDBG/assembly.fasta"
        shell : "./sources/assembly/metaMDBG_wraper.sh {input} {params.tmp_directory} {output} {params.technology} {params.cleanup}"

if("myloasm" in config["assemblers"]) :
    rule myloasm_assembly :
        params : 
            expand("{name}", name=get_samples("name")),
            tmp_directory="outputs/{sample}/myloasm/tmp/",
            technology=get_sample_technology,
            cleanup=config.get("cleanup_tmp", "yes")
        conda : "../envs/myloasm.yaml"
        threads : config["rule_myloasm_assembly"]["threads"]
        resources :
            cpus_per_task = config["rule_myloasm_assembly"]["threads"],
            mem_mb=config["rule_myloasm_assembly"]["memory"],
            runtime=eval(config["rule_myloasm_assembly"]["time"]),
        input : get_long_read_path,
        output : "outputs/{sample}/myloasm/assembly.fasta"
        shell : "./sources/assembly/myloasm_wraper.sh {input} {params.tmp_directory} {output} {params.technology} {params.cleanup} {threads}"


if("metaflye" in config["assemblers"]) :
    rule metaflye_assembly :
        params : 
            expand("{name}", name=get_samples("name")),
            output_directory="outputs/{sample}/metaflye/",
            technology=get_sample_technology,
            cleanup=config.get("cleanup_tmp", "yes")
        conda : "../envs/flye.yaml"
        threads : config["rule_metaflye_assembly"]["threads"]
        resources :
            cpus_per_task = config["rule_metaflye_assembly"]["threads"],
            mem_mb=config["rule_metaflye_assembly"]["memory"],
            runtime=eval(config["rule_metaflye_assembly"]["time"]),
        input : get_long_read_path,
        output : "outputs/{sample}/metaflye/assembly.fasta",
        shell : "./sources/assembly/metaflye_wraper.sh {input} {params.output_directory} {params.technology} {params.cleanup}"

if("hifiasm_meta" in config["assemblers"]) :
    rule hifiasm_meta_assembly :
        params : 
            expand("{name}", name=get_samples("name")),
            output_directory="outputs/{sample}/hifiasm_meta/",
            cleanup=config.get("cleanup_tmp", "yes")
        conda : "../envs/hifiasm_meta.yaml"
        threads : config["rule_hifiasm_meta_assembly"]["threads"]
        resources :
            cpus_per_task = config["rule_hifiasm_meta_assembly"]["threads"],
            mem_mb=config["rule_hifiasm_meta_assembly"]["memory"],
            runtime=eval(config["rule_hifiasm_meta_assembly"]["time"]),
        input : get_long_read_path,
        output : "outputs/{sample}/hifiasm_meta/assembly.fasta",
        shell : "./sources/assembly/hifiasm_meta_wraper.sh {input} {params.output_directory} {params.cleanup}"


if("operaMS" in config["assemblers"]) :
    rule operaMS_assembly :
        params : 
            expand("{name}", name=get_samples("name")),
            tmp_directory="outputs/{sample}/operaMS/tmp/",
            operaMS_path=config.get("operaMS_path", "outputs/tools/OPERA-MS"),
            short_read_assembly=config.get("short_read_assembly", "none"),
            cleanup=config.get("cleanup_tmp", "yes")
        conda : "../envs/operaMS.yaml"
        threads : config["rule_operaMS_assembly"]["threads"]
        resources :
            cpus_per_task = config["rule_operaMS_assembly"]["threads"],
            mem_mb=config["rule_operaMS_assembly"]["memory"],
            runtime=eval(config["rule_operaMS_assembly"]["time"]),
        input : 
            long_reads = get_long_read_path,
            auxiliary_short_read_1 = lambda wildcards: get_auxiliary_short_read("auxiliary_short_reads_1", wildcards),
            auxiliary_short_read_2 = lambda wildcards: get_auxiliary_short_read("auxiliary_short_reads_2", wildcards),
        output : "outputs/{sample}/operaMS/assembly.fasta"
        shell : "./sources/assembly/operaMS_wraper.sh {params.operaMS_path} {input.long_reads} {input.auxiliary_short_read_1} {input.auxiliary_short_read_2} {params.short_read_assembly} {params.tmp_directory} {output} {params.cleanup} {threads}"


if("metaspades" in config["assemblers"]) :
    rule metaspades_assembly :
        params :
            expand("{name}", name=get_samples("name")),
            output_directory="outputs/{sample}/metaspades/",
            long_reads=get_optional_long_read_path,
            technology=get_metaspades_long_read_technology,
            cleanup=config.get("cleanup_tmp", "yes")
        conda : "../envs/spades.yaml"
        threads : config["rule_metaspades_assembly"]["threads"]
        resources :
            cpus_per_task = config["rule_metaspades_assembly"]["threads"],
            mem_mb = config["rule_metaspades_assembly"]["memory"],
            runtime = eval(config["rule_metaspades_assembly"]["time"]),
        input :
            reads_1 = lambda wildcards: get_short_read("short_reads_1", wildcards),
            reads_2 = lambda wildcards: get_short_read("short_reads_2", wildcards)
        output : "outputs/{sample}/metaspades/assembly.fasta",
        shell : "./sources/assembly/metaspades_wraper.sh {input.reads_1} {input.reads_2} {params.output_directory} {params.long_reads} {params.technology} {params.cleanup} {threads} {resources.mem_mb}"


if("custom_assembly" in config["assemblers"]) :
    rule link_assembly : 
        input : config["custom_assembly_path"],
        output : "outputs/{sample}/custom_assembly/assembly.fasta"
        shell : "ln -sr {input} {output}"
