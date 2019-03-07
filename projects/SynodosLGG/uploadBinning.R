##Store binned locations

require(synapser)
synLogin()
require(tidyverse)

loc<-unique(read.table('tumorLocation.txt',sep='\t',header=T))%>%rename(`Binned Value`='Binned.Tumor.Location',`Actual`='tumorLocation')
loc$Term=rep('tumorLocation',nrow(loc))

hist<-unique(read.table('histology.txt',sep='\t',header=T))%>%rename(`Binned Value`='Binned..Histo.Read',`Actual`='his_read')
hist$Term=rep('his_read',nrow(hist))


biop<-unique(read.table('biopsySite.txt',sep='\t',header=T))%>%rename(`Binned Value`='Binned.Bx.Site',`Actual`='site_biopsy')
biop$Term=rep('site_biopsy',nrow(biop))

full.tab<-rbind(loc,hist,biop)

synStore(synBuildTable('LGG Mappings',parent='syn5698493',full.tab))


