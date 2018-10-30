###downlod and create dataset

#nfinteractome
fv_id='syn8449668'
dest_folder_id='syn5732874'

#ipsc
fv_id='syn8662666'
dest_folder_id='syn6098029'

require(synapser)
synLogin()

ids<-synTableQuery(paste('select id from',fv_id))$asDataFrame()

dir.create(fv_id)

paths<-sapply(ids$id,function(x) {
  pa<-synGet(x)$path
  file.copy(pa,fv_id)
  paste(fv_id,'/',basename(pa),sep='')
})

fname=paste(fv_id,'allFiles',sep='')
zip(fname,paths)
synStore(File(paste(fname,'.zip',sep=''),parentId=dest_folder_id))





