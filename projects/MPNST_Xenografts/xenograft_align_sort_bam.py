"""
Author: xdo
Aim: A simple Snakemake workflow to map paired-end RNAseq with STAR and then run Disambiguate to take out xenograft mouse reads
Pre-Run:    
            source activate py3.5
Run: snakemake --cores 8  

Latest modification: 
    - 
"""
import sys
import subprocess 
import re
import os

import synapseclient
import synapseutils
from synapseclient import Project, File, Folder, Activity
from synapseclient import Schema, Column, Table, Row, RowSet, as_table_columns


##-----------------------------------------------##
## A set of functions
##-----------------------------------------------##
def message(mes):
  sys.stderr.write("\n " + str(mes) + "\n")

##-----------------------------------------------##
## set wd 
##-----------------------------------------------##
BASE_DIR = "/home/xdoan/MPNST/"

##-----------------------------------------------##
## declare variables
##-----------------------------------------------##
REF_DIR = BASE_DIR + "reference/"
hg38_FA = BASE_DIR + "reference/hg38/hg38.fa" 
hg38_GTF = BASE_DIR + "reference/hg38/hg38.gtf" 
mm10_FA = BASE_DIR + "reference/mm10/mm10.fa" 
mm10_GTF = BASE_DIR + "reference/mm10/mm10.gtf" 

# INDEX = BASE_DIR + "/index/hg38.fa" #hg38 index 
# REF_BED = "/home/xdo/Data/bwa/reference/hg38.ALR.bed"
# MKV_OUT = ["tis", "ois", "suf", "bwt", "bck", "lcp", "skp"]
# GENOME = "/home/xdo/Data/bwa/wgs/Esoph/eso-1060/hg38.genome"

##-----------------------------------------------##
## The list of samples to be processed
##-----------------------------------------------##
# WC0, = glob_wildcards(BASE_DIR + "01_dl_files/output/{smp}.bam") 

# WC = glob_wildcards(BASE_DIR + "01_dl_files/output/{smp}.bam") 
# SAMPLES = set(WC.smp) 

# # LANES = set(WC.lane)
# # PAIR1,PAIR2 = set(WC.pair) 
# for smp in SAMPLES:
#   message(smp)

# WC2 = glob_wildcards(BASE_DIR + "01_dl_files/output/{ind}_gerald_{etc}.bam") # etc = Flow cell, lane, index
# WC2 = glob_wildcards(BASE_DIR + "3_bamToFq/{ind}.fastq.gz") 
WC2 = glob_wildcards(BASE_DIR + "4_run_STAR/output/hg38/{ind}_Aligned.out.bam") 
INDIVIDUALS = set(WC2.ind)
for ind in INDIVIDUALS:
  message(ind)
##-----------------------------------------------##
## all rule
##-----------------------------------------------##
rule all:
  input: 
    BASE_DIR + "reference/mm10/chrName.txt",
    BASE_DIR + "reference/hg38/chrName.txt",
    # expand(BASE_DIR + "2_merge_bam/{ind}.bam", ind = INDIVIDUALS),
    # expand(BASE_DIR + "3_bamToFq/{ind}.fastq", ind = INDIVIDUALS),
    # expand(BASE_DIR + "4_run_STAR/output/hg38/{ind}_Aligned.out.bam", ind=INDIVIDUALS),
    # expand(BASE_DIR + "4_run_STAR/output/mm10/{ind}_Aligned.out.bam", ind=INDIVIDUALS),
    expand(BASE_DIR + "5_disambiguate/{ind}_summary.txt", ind = INDIVIDUALS)


# Function for retrieving list of files with same ind
def bamlist(individual):
    paths = []
    ind = str(individual) #3_run_STAR/output/hg38/{smp}_Aligned.sortedByCoord.out.bam
    for root, dirs, files in os.walk(r"/home/xdoan/MPNST/01_dl_files/output", topdown=True):
        for name in files:
            if name.startswith(ind) & name.endswith(".bam"):
                path = os.path.join(root, name)
                paths.append(path)
    return(paths)

rule merge_input_bams:
    input:
      # i = BASE_DIR + "3_run_STAR/output/hg38/{smp}_Aligned.sortedByCoord.out.bam".replace(smp = SAMPLES),
      bamlist = bamlist
    output:
      BASE_DIR + "2_merge_bam/{ind}.bam"
    shell:
      "samtools merge {output} {input.bamlist} "


## bam to fastq
##-----------------------------------------------##
rule bamToFQ:
    input:
        BASE_DIR + "2_merge_bam/{ind}.bam"
    output:
        BASE_DIR + "3_bamToFq/{ind}.fastq"
    shell:
        "bedtools bamtofastq -i {input} -fq {output} && rm {input}"

rule fqToGz:
    input:
        BASE_DIR + "3_bamToFq/{ind}.fastq"
    output:
        BASE_DIR + "3_bamToFq/{ind}.fastq.gz"
    shell:
        "pigz {input}"


## STAR alignment
##-----------------------------------------------##
rule starIndex_hg38:
  input: 
    ref = hg38_FA,
    gtf = hg38_GTF,
    starref = REF_DIR +"hg38/", 
    # tmpdir = TMP_DIR
  output: 
    BASE_DIR + "reference/hg38/chrName.txt"
  threads: 8
  shell: 
    "STAR --runThreadN {threads} --runMode genomeGenerate --genomeDir {input.starref} --genomeFastaFiles {input.ref} --sjdbGTFfile {input.gtf} --sjdbOverhang 100 --genomeSAindexNbases 4 --limitGenomeGenerateRAM 30000000000 --genomeSAsparseD 2"# --outTmpDir {input.tmpdir}"

rule starIndex_mm10:
  input:
    ref=mm10_FA,
    gtf=mm10_GTF,
    starref=REF_DIR +"mm10/",
    # tmpdir = TMP_DIR 
  output:
    BASE_DIR + "reference/mm10/chrName.txt"
  threads: 8
  shell: 
    "STAR --runThreadN {threads} --runMode genomeGenerate --genomeDir {input.starref} --genomeFastaFiles {input.ref} --sjdbGTFfile {input.gtf} --sjdbOverhang 100 --genomeSAindexNbases 4 --limitGenomeGenerateRAM 30000000000 --genomeSAsparseD 2"# --outTmpDir {input.tmpdir}"

rule star_se_hg38:
    input:
        fq1 = BASE_DIR + "3_bamToFq/{ind}.fastq.gz",
    output:
        BASE_DIR + "4_run_STAR/output/hg38/{ind}_Aligned.out.bam"
    log:
        BASE_DIR + "00logs/star/hg38/{ind}.log"
    params:
      starref = REF_DIR +"hg38",
      smp = BASE_DIR + "4_run_STAR/output/hg38/{ind}_", 
      logdir = BASE_DIR + "00logs/star/hg38/"
    threads: 8
    shell:
      """ STAR --runThreadN {threads} --genomeDir {params.starref} \
      --readFilesIn {input.fq1} --outSAMtype BAM Unsorted \
      --outFileNamePrefix {params.smp} --outStd Log {log} --readFilesCommand zcat"""

rule star_se_mm10:
    input:
        fq1 = BASE_DIR + "3_bamToFq/{ind}.fastq.gz",
    output:
        BASE_DIR + "4_run_STAR/output/mm10/{ind}_Aligned.out.bam"
    log:
        BASE_DIR + "00logs/star/mm10/{ind}.log"
    params:
      starref = REF_DIR +"hg38",
      smp = BASE_DIR + "4_run_STAR/output/mm10/{ind}_", 
      logdir = BASE_DIR + "00logs/star/mm10/"
    threads: 8
    shell:
      """ STAR --runThreadN {threads} --genomeDir {params.starref} \
      --readFilesIn {input.fq1} --outSAMtype BAM Unsorted \
      --outFileNamePrefix {params.smp} --outStd Log {log} --readFilesCommand zcat"""

rule disambiguate:
    input:
        human= BASE_DIR + "4_run_STAR/output/hg38/{ind}_Aligned.out.bam",
        mouse= BASE_DIR + "4_run_STAR/output/mm10/{ind}_Aligned.out.bam",
    output:
        BASE_DIR + "5_disambiguate/{ind}_summary.txt"
    params:
        prefix = "{ind}",
        outdir = BASE_DIR + "5_disambiguate/"
    shell:
        "ngs_disambiguate {input.human} {input.mouse} -s {params.prefix} -a star -o {params.outdir}"
      