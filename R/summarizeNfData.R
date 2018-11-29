##create  individual summary table

tabId='syn16858331'
query='SELECT COUNT(DISTINCT individualID) AS individuals, tumorType, diagnosis, assay, species, isCellLine FROM syn16858331 WHERE tumorType IS NOT NULL GROUP BY tumorType, diagnosis, assay, species, isCellLine ORDER BY "individuals" DESC'

require(synapser)
synLogin()

res<-synTableQuery(query)$asDataFrame()


require(tidyverse)

res$isCellLine[is.na(res$isCellLine)]<-"false"
rr<-c(which(is.na(res$assay)),which(is.na(res$species)))
res<-res[-rr,]
res<-res%>%mutate(Model=paste(species,ifelse(isCellLine,'CellLine','Tissue')))

ftab<-res%>%reshape2::dcast(diagnosis+tumorType+Model~assay,value.var='individuals',fun.aggregate = sum)
rem<-which(colSums(ftab[,4:ncol(ftab)])==0)
ftab<-ftab[,]
write.csv(ftab[,-rem+3],file='NFDataSnapshot.csv',row.names=F)

#ftab[which(is.na(ftab),arr.ind=T)]<-0

cols=lapply(names(ftab),function(x) Column(name=x,columnType=ifelse(x%in%c('diagnosis','tumorType','Model'),'STRING','INTEGER')))
schema=Schema(name='NF Data Snapshot',columns=cols,parent='syn5702691')
synStore(Table(schema,ftab),used=tabId)

library(ggplot2)
library(ggrepel)


p<-ggplot(subset(res,diagnosis%in%c("Neurofibromatosis 1")))+geom_bar(aes(x=assay,y=individuals,fill=tumorType),stat='identity',position='dodge')+facet_grid(Model~.)+ggtitle("Assay by tumor type in NF1")+theme(axis.text.x = element_text(angle = 90, hjust = 1)) 

p<-ggplot(subset(res,diagnosis%in%c("Neurofibromatosis 2")))+geom_bar(aes(x=assay,y=individuals,fill=tumorType),stat='identity',position='dodge')+facet_grid(Model~.)+ggtitle("Assay by tumor type in NF2")

