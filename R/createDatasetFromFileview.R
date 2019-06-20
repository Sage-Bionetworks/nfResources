###downlod and create dataset

#nfinteractome
fv_id='syn8449668'
dest_folder_id='syn5732874'

#ipsc
fv_id='syn8662666'
dest_folder_id='syn6098029'

#columbia LGG
fv_id='syn11614207'
dest_folder_id='syn8466184'

#mattingly data
fv_id='syn11581628'
dest_folder_id='syn18637022'

require(synapser)
synLogin()

ids<-synTableQuery(paste('select id from',fv_id))$asDataFrame()$id
#ids<-setdiff(ids$id,'syn17095981')#get rid of the id of the zip file itself
dir.create(fv_id)

paths<-sapply(ids,function(x) {
  pa<-synGet(x)$path
  file.copy(pa,fv_id)
  paste(fv_id,'/',basename(pa),sep='')
})

fname=paste(fv_id,'allFiles',sep='')
zip(fname,paths)
#this fails:
#synStore(File(paste(fname,'.zip',sep=''),parentId=dest_folder_id),used=list(list(ids)))
#this works
print(paste("synapse store",paste(fname,'.zip',sep=''),'--parentid',dest_folder_id,'--used ',paste(ids,collapse=' ')))




