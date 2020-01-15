import pandas
import mimetypes
import synapseclient
import json

syn = synapseclient.login()


def storeS3(ent,key,destination,contentSize=None,md5=None,syn="syn"):
    filetype = mimetypes.guess_type(ent.name,strict=False)[0]
    if filetype is None:
        filetype = ""
    fileHandle={}
    fileHandle["concreteType"] = "org.sagebionetworks.repo.model.file.S3FileHandle"
    fileHandle['fileName'] = ent.name
    fileHandle["contentSize"] = contentSize
    fileHandle["contentType"] = filetype
    fileHandle["contentMd5"] = md5
    fileHandle["bucketName"] = destination['bucket']
    fileHandle['key'] = key
    fileHandle['storageLocationId'] = destination['storageLocationId']
    fileHandle = syn.restPOST('/externalFileHandle/s3', json.dumps(fileHandle), syn.fileHandleEndpoint)
    ent.dataFileHandleId = fileHandle['id']
    ent = syn.store(ent)
    return(ent)

#f=pandas.read_csv('../CBTTC/CBTTC NF data rnaSeq md5.csv')
f=pandas.read_csv('../CBTTC/CBTTC NF data wgSeq md5.csv')

destination = {'uploadType':'S3',
               'concreteType':'org.sagebionetworks.repo.model.project.ExternalS3StorageLocationSetting',
               'bucket':'kf-study-us-east-1-prd-sd-bhjxbdqk'}
destination = syn.restPOST('/storageLocation', body=json.dumps(destination))

for index,row in f.iterrows():
    fname=row['path'].split('/')[-1]
    key='/'.join(row['path'].split('/')[3:])
    print(fname)
    print(key)
    entityFile = synapseclient.File(parentId = row['parent'],name=fname)
    annotations = dict(row.drop(['path','parent'], errors = 'ignore'))
    entityFile.annotations = annotations
    md5=row['md5']
    newEntity = storeS3(entityFile,key,destination,md5=md5,syn=syn)
    print(newEntity.id)
