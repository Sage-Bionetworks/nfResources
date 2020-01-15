##fix annotation
require(synapser)
synLogin()
require(tidyverse)

jhu.meta<-synTableQuery("SELECT * FROM syn13363852 WHERE ( ( \"resourceType\" = 'experimentalData' ) AND ( \"assay\" = 'exomeSeq' ) AND ( \"isMultiIndividual\" = 'false' ) AND ( \"individualID\" IS NULL ) )")$asDataFrame()

pat.data<-read.csv(synGet('syn18079902')$path)

jhu.meta$SM_Tag=sapply(jhu.meta$name,function(x) unlist(strsplit(as.character(x),split='.',fixed=T))[1])
full=jhu.meta%>%left_join(pat.data,by='SM_Tag')

jhu.meta$sex=sapply(full$Gender,function(x) ifelse(x=='M','male','female'))

jhu.meta$specimenID=full$Subject_ID


synStore(Table(synGet('syn13363852')$properties$id,select(jhu.meta,-SM_Tag)))
