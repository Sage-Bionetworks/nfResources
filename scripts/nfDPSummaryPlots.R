##do some project summary stats for NTAP
require(synapser)
synLogin()

full.fv<-synTableQuery("SELECT * FROM syn16858331")$asDataFrame()

require(ggplot2)

require(tidyverse)
sum<-full.fv%>%
  subset(isMultiSpecimen!='TRUE')%>%
  subset(resourceType=='experimentalData')%>%
  subset(tumorType%in%c('Cutaneous Neurofibroma','High Grade Glioma','Low Grade Glioma','Meningioma','JMML','Neurofbiroma','Plexiform Neurofibroma','Cutaneous Neurofibroma','Schwannoma'))%>%
  select(specimenID,tumorType,assay,accessType,dataType)%>%distinct()


ggplot(sum)+geom_bar(aes(x=dataType,fill=tumorType),position='dodge')+theme(axis.text.x = element_text(angle = 90, hjust = 1))+ggtitle('Number of NF specimens measured by data type')
ggsave('allTumorTypesByData.png')

subset(sum,tumorType=='Cutaneous Neurofibroma')%>%
ggplot()+geom_bar(aes(x=assay,fill=accessType),position='dodge')+theme(axis.text.x = element_text(angle = 90, hjust = 1))+ggtitle('Number of cNF specimens measured by')
ggsave('cNFspecimensByAssay.png')
