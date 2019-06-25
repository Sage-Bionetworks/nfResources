import pandas as pd
import mimetypes
import synapseclient
import json
from synapseutils import copy
syn = synapseclient.login()
import os
import math

wgs_md5=pd.read_csv(syn.get('syn19961910').path,names=['md5','','fname'],sep=' ')
rna_md5=pd.read_csv(syn.get('syn19961918').path,names=['md5','','fname'], sep=' ')

all_md5=wgs_md5.append(rna_md5)
all_md5['name']=[os.path.basename(p) for p in all_md5['fname']]

all_files=syn.tableQuery("SELECT id,name FROM syn11614205 where assay = 'rnaSeq' OR assay = 'wholeGenomeSeq'").asDataFrame()

df=all_md5.set_index("name").join(all_files.set_index('name'))

for id,md5 in zip(df['id'],df['md5']):
   if isinstance(id,str):
        ent=syn.get(id,downloadFile=False)
        oldFh=ent._file_handle
        fileHandle={}
        fileHandle["concreteType"] = "org.sagebionetworks.repo.model.file.S3FileHandle"
        fileHandle['fileName'] = oldFh['fileName']
        fileHandle["contentSize"] = oldFh['contentSize']
        fileHandle["contentType"] = oldFh['contentType']
        fileHandle["contentMd5"] = md5
        fileHandle["bucketName"] = oldFh['bucketName']
        fileHandle['key'] = oldFh['key']
        fileHandle['storageLocationId'] = oldFh['storageLocationId']
        fileHandle = syn.restPOST('/externalFileHandle/s3', json.dumps(fileHandle), syn.fileHandleEndpoint)
        ent.dataFileHandleId = fileHandle['id']
        ent = syn.store(ent)
