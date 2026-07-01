###### Utility function ######

# Return a list containing the attribute "attribute" of each sample
# attribute = {name, read_path, short_reads_1, short_reads_2}
def get_samples(attribute) : 
    return [sample[attribute] for sample in config["samples"]]

# Return the attribute "attribute" of an assembly with the name "sample"
def get_sample(attribute, wildcards):
    index = get_samples("name").index(wildcards.sample)
    return get_samples(attribute)[index]

# Return short reads either from the sample section or from global config
def get_short_read(attribute, wildcards):
    index = get_samples("name").index(wildcards.sample)
    sample = config["samples"][index]

    if attribute in sample:
        return sample[attribute]
    elif attribute in config:
        return config[attribute]
    else:
        raise ValueError(
            f"{attribute} not found neither in sample '{wildcards.sample}' nor in global config"
        )
def sample_has_long_reads(wildcards):
    return sample_name_has_long_reads(wildcards.sample)

def sample_has_short_reads(wildcards):
    return sample_name_has_short_reads(wildcards.sample)

def get_config_sample(sample_name):
    index = get_samples("name").index(sample_name)
    return config["samples"][index]

def sample_name_has_long_reads(sample_name):
    sample = get_config_sample(sample_name)
    return "read_path" in sample and sample["read_path"] != "none"

def sample_name_has_short_reads(sample_name):
    sample = get_config_sample(sample_name)

    if "short_reads_1" in sample and "short_reads_2" in sample:
        return True
    elif "short_reads_1" in config and "short_reads_2" in config:
        return True
    return False

def get_samples_with_long_reads():
    out = []
    for sample in config["samples"]:
        if "read_path" in sample and sample["read_path"] != "none":
            out.append(sample["name"])
    return out

def get_samples_with_short_reads():
    out = []
    for sample in config["samples"]:
        if sample_name_has_short_reads(sample["name"]):
            out.append(sample["name"])
    return out

##### Sequencing technology and assembler compatibility #####

ASSEMBLER_COMPATIBILITY = {
    "metaMDBG": ["hifi", "ont"],
    "metaflye": ["hifi", "ont"],
    "myloasm": ["hifi", "ont"],
    "hifiasm_meta": ["hifi"],
    "operaMS": ["hifi", "ont"],
    "metaspades": ["illumina"],
    "custom_assembly": ["hifi", "ont", "illumina"],
}

ALLOWED_TECHNOLOGIES = ["hifi", "ont", "illumina"]
SHORT_READ_ASSEMBLERS = ["metaspades"]

def get_sample_technology(wildcards):
    return get_sample("technology", wildcards)

def get_long_read_path(wildcards):
    tech = get_sample_technology(wildcards)
    read_path = get_config_sample(wildcards.sample).get("read_path", "none")
    if tech == "illumina" or read_path == "none":
        raise ValueError(
            f"Sample '{wildcards.sample}' does not have long reads compatible with "
            "this long-read rule."
        )
    return read_path

def get_optional_long_read_path(wildcards):
    if sample_has_long_reads(wildcards):
        return get_sample("read_path", wildcards)
    return "none"

def get_longread_preset(wildcards):
    tech = get_sample_technology(wildcards)
    if tech == "ont":
        return "lr:hq"
    if tech == "hifi":
        return "map-hifi"
    raise ValueError(f"No long-read minimap2 preset for technology '{tech}'")

def get_metaspades_long_read_technology(wildcards):
    tech = get_sample_technology(wildcards)
    if tech == "hifi":
        return "pacbio"
    if tech == "ont":
        return "ont"
    return "none"

def validate_sample_technology_config():
    for sample in config["samples"]:
        sample_name = sample.get("name", "<missing name>")
        if "technology" not in sample:
            raise ValueError(f"Sample '{sample_name}' must define a technology.")

        technology = sample["technology"]
        if technology not in ALLOWED_TECHNOLOGIES:
            raise ValueError(
                f"Sample '{sample_name}' has unknown technology '{technology}'. "
                f"Allowed values are: {ALLOWED_TECHNOLOGIES}."
            )

        if technology in ["hifi", "ont"] and not sample_name_has_long_reads(sample_name):
            raise ValueError(
                f"Sample '{sample_name}' uses technology '{technology}' and must "
                "define a long-read read_path."
            )

        if technology == "illumina" and not sample_name_has_short_reads(sample_name):
            raise ValueError(
                f"Sample '{sample_name}' uses technology 'illumina' and must define "
                "short_reads_1 and short_reads_2."
            )

    for assembler in config["assemblers"]:
        if assembler not in ASSEMBLER_COMPATIBILITY:
            raise ValueError(
                f"Assembler '{assembler}' is not listed in ASSEMBLER_COMPATIBILITY."
            )

    for assembler in SHORT_READ_ASSEMBLERS:
        if assembler not in ASSEMBLER_COMPATIBILITY:
            raise ValueError(
                f"Assembler '{assembler}' is not listed in ASSEMBLER_COMPATIBILITY."
            )

    for assembler in config["assemblers"]:
        compatible_samples = [
            sample["name"]
            for sample in config["samples"]
            if sample["technology"] in ASSEMBLER_COMPATIBILITY[assembler]
        ]

        if len(compatible_samples) == 0:
            sample_tech_summary = [
                f"{sample['name']}={sample['technology']}"
                for sample in config["samples"]
            ]

            raise ValueError(
                f"Assembler '{assembler}' has no compatible sample in this config.\n"
                f"  Compatible technologies for '{assembler}': {ASSEMBLER_COMPATIBILITY[assembler]}\n"
                f"  Sample technologies found: {sample_tech_summary}"
            )
            
    if config["short_read_binning"]:
        configured_short_read_assemblers = [
            assembler
            for assembler in config["assemblers"]
            if assembler in SHORT_READ_ASSEMBLERS
        ]
        if len(configured_short_read_assemblers) == 0:
            raise ValueError(
                "short_read_binning is enabled but no short-read assembler is "
                f"listed in config['assemblers']. Add one of: {SHORT_READ_ASSEMBLERS}."
            )

    for sample in config["samples"]:
        compatible_assemblers = [
            assembler
            for assembler in config["assemblers"]
            if sample["technology"] in ASSEMBLER_COMPATIBILITY[assembler]
        ]
        if len(compatible_assemblers) == 0:
            raise ValueError(
                f"Sample '{sample['name']}' with technology '{sample['technology']}' "
                "has no compatible assembler in config['assemblers']."
            )

def get_compatible_sample_assembler_pairs(require_long_reads=False, require_short_reads=False, allowed_assemblers=None):
    pairs = []
    for sample in config["samples"]:
        sample_name = sample["name"]
        technology = sample["technology"]
        if require_long_reads and not sample_name_has_long_reads(sample_name):
            continue
        if require_short_reads and not sample_name_has_short_reads(sample_name):
            continue
        for assembler in config["assemblers"]:
            if allowed_assemblers is not None and assembler not in allowed_assemblers:
                continue
            if technology in ASSEMBLER_COMPATIBILITY[assembler]:
                pairs.append({"sample": sample_name, "assembler": assembler})
    return pairs

def compatible_expand(pattern, require_long_reads=False, require_short_reads=False, allowed_assemblers=None):
    pairs = get_compatible_sample_assembler_pairs(
        require_long_reads,
        require_short_reads,
        allowed_assemblers,
    )
    return expand(
        pattern,
        zip,
        sample=[p["sample"] for p in pairs],
        assembler=[p["assembler"] for p in pairs],
    )

def compatible_fraction_expand(pattern, require_long_reads=False, require_short_reads=False, allowed_assemblers=None):
    expanded = []
    for fraction in config["fractions"]:
        expanded += compatible_expand(
            pattern.replace("{fraction}", fraction),
            require_long_reads=require_long_reads,
            require_short_reads=require_short_reads,
            allowed_assemblers=allowed_assemblers,
        )
    return expanded

def compatible_binner_expand(pattern, require_long_reads=False, require_short_reads=False, allowed_assemblers=None):
    expanded = []
    for binner in config["binners"]:
        expanded += compatible_expand(
            pattern.replace("{binner}", binner),
            require_long_reads=require_long_reads,
            require_short_reads=require_short_reads,
            allowed_assemblers=allowed_assemblers,
        )
    return expanded

def compatible_short_read_assembler_expand(pattern):
    return compatible_expand(
        pattern,
        require_short_reads=True,
        allowed_assemblers=SHORT_READ_ASSEMBLERS,
    )

def compatible_short_read_mapping_expand(pattern):
    expanded = []
    if config["short_read_mapping_evaluation"] or config["short_read_cobinning"]:
        expanded += compatible_expand(pattern, require_short_reads=True)
    if config["short_read_binning"]:
        expanded += compatible_short_read_assembler_expand(pattern)
    return list(dict.fromkeys(expanded))

def get_binning_triples(include_short_read_binning=True):
    triples = []

    def add_binning_outputs(binning_names, require_long_reads=False, require_short_reads=False, allowed_assemblers=None):
        pairs = get_compatible_sample_assembler_pairs(
            require_long_reads,
            require_short_reads,
            allowed_assemblers,
        )
        for pair in pairs:
            for binning_name in binning_names:
                triples.append({
                    "sample": pair["sample"],
                    "assembler": pair["assembler"],
                    "binning": binning_name,
                })

    if config["binning"]:
        add_binning_outputs(
            expand("{binner}_bins_reads_alignement", binner=config["binners"]),
            require_long_reads=True,
        )
    if include_short_read_binning and config["short_read_binning"]:
        add_binning_outputs(
            expand("{binner}_bins_short_reads_alignement", binner=config["binners"]),
            require_short_reads=True,
            allowed_assemblers=SHORT_READ_ASSEMBLERS,
        )
    if config["short_read_cobinning"]:
        add_binning_outputs(
            expand("{binner}_bins_cobinning_alignement", binner=config["binners"]),
            require_long_reads=True,
            require_short_reads=True,
        )
    if config["additional_reads_cobinning"]:
        add_binning_outputs(
            expand("{binner}_bins_additional_reads_cobinning_alignement", binner=config["binners"]),
            require_long_reads=True,
        )

    return triples

def compatible_binning_expand(pattern, include_short_read_binning=True):
    triples = get_binning_triples(include_short_read_binning)
    return expand(
        pattern,
        zip,
        sample=[t["sample"] for t in triples],
        assembler=[t["assembler"] for t in triples],
        binning=[t["binning"] for t in triples],
    )

def compatible_binning_target_expand(pattern):
    expanded = []
    for target_bin in config["kraken2_target_bins"]:
        for output in compatible_binning_expand(pattern.replace("{target_bin}", str(target_bin))):
            expanded.append(output)
    return expanded

validate_sample_technology_config()

# Return the path to the reads of a fraction of an assembly 
def get_read_path(wildcards) : 
    if(wildcards.fraction == "full") : 
        return get_long_read_path(wildcards)
    return "outputs/" + wildcards.sample + "/" + wildcards.assembler + "/" + wildcards.fraction + "_reads.fastq"

# Return the path to the reads of all fractions of an assembly 
def get_all_read_path(wildcards) :
    out = []
    for f in config["fractions"] :
        wildcards.fraction = f
        out.append(get_read_path(wildcards))
    return out

def get_reference_names() : 
    return [os.path.splitext(os.path.basename(r))[0] for r in config["reference_genomes"]]

def get_reference(reference_name) : 
    for ref in config["reference_genomes"] : 
        if reference_name in ref : 
            return ref
    return None

# It determines the correct inputs according to the choice of fractions for the FastQC. 
def get_fastqc_R1(wildcards):
    if wildcards.fraction == "full":
        return get_short_read("short_reads_1", wildcards)
    return f"outputs/{wildcards.sample}/{wildcards.assembler}/fastqc/{wildcards.fraction}/R1.fastq"

def get_fastqc_R2(wildcards):
    if wildcards.fraction == "full":
        return get_short_read("short_reads_2", wildcards)
    return f"outputs/{wildcards.sample}/{wildcards.assembler}/fastqc/{wildcards.fraction}/R2.fastq"

##### Additional rules #####  
include : "rules/assembly.smk"
include : "rules/mapping.smk"
include : "rules/binning.smk"
include : "rules/bin_quality_analysis.smk"
include : "rules/read_quality_analysis.smk"
include : "rules/contig_quality_analysis.smk"

##### Improvements #####
"""
replace minimap2 by mapquick for hifi long reads mapping ?
replace kraken2 by sourmash for taxonomic assignation ?
"""


binnings = []
if(config["binning"] == True) : 
    binnings += expand("{binner}_bins_reads_alignement", binner = config["binners"])
if(config["short_read_binning"] == True) :
    binnings += expand("{binner}_bins_short_reads_alignement", binner = config["binners"])
if(config["short_read_cobinning"] == True) :
    binnings += expand("{binner}_bins_cobinning_alignement", binner = config["binners"])
if(config["additional_reads_cobinning"] == True) :
    binnings += expand("{binner}_bins_additional_reads_cobinning_alignement", binner = config["binners"])



rule all :
    input :
        compatible_expand("outputs/{sample}/{assembler}/assembly.fasta"),

        # Read quality analysis (fastqc ou nanoplot, kraken2, kat)
        compatible_fraction_expand("outputs/{sample}/{assembler}/fastqc/{fraction}/R1_fastqc.html", require_short_reads=True)
            if(config.get("fastqc", False) == True) else "Snakefile",

        compatible_fraction_expand("outputs/{sample}/{assembler}/fastqc/{fraction}/R2_fastqc.html", require_short_reads=True)
            if(config.get("fastqc", False) == True) else "Snakefile",

        compatible_fraction_expand("outputs/{sample}/{assembler}/nanoplot/{fraction}/NanoPlot-report.html", require_long_reads=True)
            if(config.get("nanoplot", False) == True) else "Snakefile",
        compatible_fraction_expand("outputs/{sample}/{assembler}/kraken2/{fraction}/krona.html", require_long_reads=True)
            if(config["kraken2"] == True) else "Snakefile",
        compatible_fraction_expand("outputs/{sample}/{assembler}/kat/{fraction}-stats.tsv", require_long_reads=True)
            if(config["kat"] == True) else "Snakefile",
        compatible_expand("outputs/{sample}/{assembler}/kat/kat-plot.pdf", require_long_reads=True)
            if(config["kat"] == True and "mapped" in config["fractions"] and "unmapped" in config["fractions"]) else "Snakefile",

        # Contig quality analysis (read mapping, short read mapping, metaquast, reference mapping)
        compatible_expand("outputs/{sample}/{assembler}/reads_on_contigs_mapping_evaluation/report.txt", require_long_reads=True)
            if(config["read_mapping_evaluation"] == True) else "Snakefile",
        compatible_expand("outputs/{sample}/{assembler}/metaquast/report.txt")
            if(config["metaquast"] == True and ("abundance_information" in config)) else "Snakefile",
        compatible_expand("outputs/{sample}/{assembler}/metaquast/results/summary/TSV/")
            if(config["metaquast"] == True) else "Snakefile",
        expand("outputs/{sample}/long_reads_on_reference.{reference}.bam", sample=get_samples_with_long_reads(), reference=get_reference_names())
            if(config["reference_mapping_evaluation"] == True) else "Snakefile",
        expand("outputs/{sample}/short_reads_on_reference.{reference}.bam", sample=get_samples_with_short_reads(), reference=get_reference_names())
            if(config["reference_mapping_evaluation"] == True) else "Snakefile", 
        compatible_short_read_mapping_expand("outputs/{sample}/{assembler}/short_reads_on_contigs.bam")
            if(config["short_read_mapping_evaluation"] == True or config["short_read_binning"] == True or config["short_read_cobinning"] == True) else "Snakefile",
        compatible_expand("outputs/{sample}/{assembler}/short_reads_on_contigs_mapping_evaluation/report.txt", require_short_reads=True)
            if(config["short_read_mapping_evaluation"] == True) else "Snakefile",

        # Bins quality analysis (checkm, separate read and contig quality analysis by bin quality)
        compatible_binning_expand("outputs/{sample}/{assembler}/{binning}/checkm/checkm_report.txt")
            if(config["checkm"] == True) else "Snakefile",
        compatible_binning_expand("outputs/{sample}/{assembler}/{binning}/checkm/checkm-plot.pdf")
            if(config["checkm"] == True) else "Snakefile",
        compatible_binning_expand("outputs/{sample}/{assembler}/{binning}/gtdbtk/results/gtdbtk.bac120.summary.tsv")
            if(config["gtdbtk"] == True) else "Snakefile",
        compatible_binning_target_expand("outputs/{sample}/{assembler}/{binning}/kraken2/bin.{target_bin}/krona.html")
            if(config["kraken2_on_bins"] == True) else "Snakefile",
        compatible_binning_expand("outputs/{sample}/{assembler}/{binning}/read_contig_mapping_plot.pdf", include_short_read_binning=False)
            if(config["checkm"] == True and config["read_mapping_evaluation"] == True) else "Snakefile",
        compatible_binning_expand("outputs/{sample}/{assembler}/{binning}/read_contig_mapping.txt", include_short_read_binning=False)
            if(config["checkm"] == True and config["read_mapping_evaluation"] == True) else "Snakefile",
        compatible_binner_expand("outputs/{sample}/{assembler}/{binner}_bins_short_reads_alignement/read_contig_mapping_plot.pdf", require_short_reads=True, allowed_assemblers=SHORT_READ_ASSEMBLERS)
            if(config["checkm"] == True and config["short_read_binning"] == True) else "Snakefile",
        compatible_binner_expand("outputs/{sample}/{assembler}/{binner}_bins_short_reads_alignement/read_contig_mapping.txt", require_short_reads=True, allowed_assemblers=SHORT_READ_ASSEMBLERS)
            if(config["checkm"] == True and config["short_read_binning"] == True) else "Snakefile",
