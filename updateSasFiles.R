###update sas files

require(synapser)
synLogin()

synids=c("syn12617093","syn12617090")

require(sas7bdat)

for(i in synids){
  tab<-read.sas7bdat(synGet(i)$path)
  fname=paste(i,'asCSV.csv',sep='')
  write.table(tab,file=fname,sep=',')
  synStore(File(fname,parentId='syn4939888'),used=i)
}
