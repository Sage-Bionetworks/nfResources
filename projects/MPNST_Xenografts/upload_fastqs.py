#!/usr/bin/env python
import synapseclient
import os
from synapseclient import Activity
from synapseclient import Entity, Project, Folder, File, Link
from synapseclient import Evaluation, Submission, SubmissionStatus
from synapseclient import Wiki

syn = synapseclient.Synapse()

syn.login()

for filenm in os.listdir('/home/xdoan/MPNST/05_disambiguate_to_fastq') : 
    if filenm.endswith(".bam") or filenm.endswith("fastq"):
        filepath = os.path.join('/home/xdoan/MPNST/05_disambiguate_to_fastq', filenm)
        test_entity = File(filepath, parent= 'syn18535479')
        test_entity = syn.store(test_entity)