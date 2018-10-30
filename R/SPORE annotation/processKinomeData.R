#kinome processing

library(synapser)
library(xlsx)
synLogin()
synId<-'syn14015659'

parentId='syn14015559'
origFile=synGet(synId)
tab<-read.xlsx(file=origFile$path,sheetIndex=1)

samps<-colnames(tab)[-c(1:3)]

new.files<-sapply(samps,function(x){
  new.tab<-data.frame(tab[,1:3],tab[,x])
  colnames(new.tab)[4]<-paste(x,'log2fc')
  fname=paste(x,'_sampls_spore_kinome.csv',sep='')
  write.csv(new.tab,file=fname)
  res<-synStore(File(fname,parentId=parentId,annotations=list(dataType='kinomics',diagnosis='Neurofibromatosis 1',tumorType='Plexiform Neurofibroma',sampleID=x,individualID=x,isCellLine=FALSE,study='DHART Project 1 pNF Study',species='Human',studySite='Matt Steensma, VAI',consortium='DHART SPORE',fundingAgency='NIH-NCI',resourceType='experimentalData')))
  res
})

sids=unlist(sapply(new.files,function(x) x$properties$id))
act=Activity(name='individual files',used=t(sids))

synStore(origFile,activity=act)
