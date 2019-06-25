##update consortia on files

library(synapser)
synLogin()


proj.id='syn11391664'

proj.annotes<-synTableQuery(paste('select distinct id,consortium from',proj.id))$asDataFrame()%>%rename(projectId='id')

fv.id='syn16858331'
fv.annotes<-synTableQuery(paste('select id,projectId,consortium from',fv.id,'where consortium is NULL'),includeRowIdAndRowVersion=TRUE)$asDataFrame()

#fv.annotes<-read.csv(fv.annote.file$filepath)

require(tidyverse)

new.fv<-fv.annotes%>%left_join(proj.annotes,by='projectId')
new.fv$consortium.x<-new.fv$consortium.y
up.fv<-new.fv%>%select(-consortium.y)%>%rename(consortium='consortium.x')
synStore(Table(fv.id,up.fv))
