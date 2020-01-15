#fix spore annotations

require(synapser)

synapser::synLogin()
library(readxl)
diag.data<-read_xlsx(synGet('syn18459532')$path)

fv<-synTableQuery('SELECT * FROM syn11581437 WHERE ( ( "study" IS NULL ) )')$asDataFrame()

fv$fileFormat<-sapply(fv$name,function(x) unlist(strsplit(x,split='.',fixed=T))[2])
fv$specimenID<-sapply(fv$name,function(x) unlist(strsplit(x,split='.',fixed=T))[1])
fv$assay<-rep('brightFieldMicroscopy',nrow(fv))
fv$dataType<-rep('image',nrow(fv))
fv$diagnosis<-rep('Neurofibromatosis 1',nrow(fv))
fv$species<-rep('human',nrow(fv))

require(tidyverse)

full.fv<-fv%>%left_join(rename(diag.data,specimenID='Sample ID'),by='specimenID')
full.fv$tumorType<-full.fv$`Diagnosis Horvai`
full.fv<-full.fv[,-c(60,61,62,63)]
full.fv$tumorType[grep('plex',full.fv$tumorType)]<-'Plexiform Neurofibroma'
#full.fv$tumorType[grep('plexiform NF',full.fv$tumorType)]<-'Plexiform Neurofibroma'
full.fv$tumorType[grep('MPNST',full.fv$tumorType)]<-'Malignant Peripheral Nerve Sheath Tumor'
full.fv$tumorType[grep('NF',full.fv$tumorType)]<-'Neurofibroma'
synStore(Table('syn11581437',full.fv))
