#!/bin/bash

for i in `synapse query "select id from syn20629788 where \"parentId\"='syn20734474'"|cut -f 4` ;
	do synapse get $i;
    synapse get-annotations --id $i -o annote.txt;
	for j in *.bam;
		#do samtools sort -n -@ 7 -m 1500M -o $j $j;
		do samtools fastq -1 ${j%.bam}_1.fastq -2 ${j%.bam}_2.fastq -0 /dev/null -s /dev/null -n -F 0x900 -@ 7 -i $j;
		pigz ${j%.bam}_1.fastq;
		pigz ${j%.bam}_2.fastq;
		synapse store ${j%.bam}_1.fastq.gz -parentid syn20746308 --annotations `cat annote.txt`;
		synapse store ${j%.bam}_2.fastq.gz -parentid syn20746308 --annotations `cat annote.txt`;
		rm $j;
		rm ${j%.bam}_1.fastq.gz;
		rm ${j%.bam}_2.fastq.gz;
	done;
done
