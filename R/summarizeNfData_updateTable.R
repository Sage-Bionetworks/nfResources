### from Sara https://raw.githubusercontent.com/Sage-Bionetworks/nfResources/master/R/summarizeNfData.R

##create  individual summary table
tabId='syn16858331' #this is the table of NF-Files
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

### get older table from synapse (aka "old")
old_ftab <- synTableQuery("SELECT * FROM syn17332021") # NF Data Snapshot in NExUS
old_ftab <- old_ftab$asDataFrame()

### need rowID and rowVersion when storing to synStore and updating rows
ftab_rowIDs <- left_join(ftab[,1:3], old_ftab[,1:5], by= c("diagnosis", "tumorType", "Model"))
#reorder colnames
ftab_rowIDs <- ftab_rowIDs[colnames(old_ftab[,1:5])]

### add the new values
ftab_rowIDs_values <- inner_join(ftab_rowIDs, ftab, by=c("diagnosis", "tumorType", "Model")) 
# this works since ftab collates results across diagnosis, tumorType, and model
# so there won't be two Schwannoma, Human Cell Line rows since assays would be ~ by these cols
# new rows are added because they won't have a rowID and rowVersion from the left_join
schema=Schema(name='NF Data Snapshot',columns=cols,parent='syn5702691') #parent is NExUS syn5702691
synStore(Table(schema,ftab_rowIDs_values)) 

library(ggplot2)
library(ggrepel)


p<-ggplot(subset(res,diagnosis%in%c("Neurofibromatosis 1")))+geom_bar(aes(x=assay,y=individuals,fill=tumorType),stat='identity',position='dodge')+facet_grid(Model~.)+ggtitle("Assay by tumor type in NF1")+theme(axis.text.x = element_text(angle = 90, hjust = 1))

p<-ggplot(subset(res,diagnosis%in%c("Neurofibromatosis 2")))+geom_bar(aes(x=assay,y=individuals,fill=tumorType),stat='identity',position='dodge')+facet_grid(Model~.)+ggtitle("Assay by tumor type in NF2")

