###merge and update data from clinical database

require(synapser)
synLogin()
require(tidyverse)

data.table<-'syn12164935'

fvdata<-'syn11614205'
columbiafv<-'syn11614207'

samp.data<-synTableQuery('SELECT * FROM syn12164935')$asDataFrame()%>%select(-c(ROW_ID,ROW_VERSION))

col.samp.data<-subset(samp.data,synapseProject=='syn6633069')
col.samp.data$individualID=paste("PT",col.samp.data$individualID,sep='')

lgg.samp.data<-subset(samp.data,synapseProject=='syn5698493')
##fix lGG sampl data from colorado

lgg.data<-synTableQuery('SELECT * FROM syn11614205')$asDataFrame()

col.data<-synTableQuery('SELECT * FROM syn11614207')$asDataFrame()
##first get duplications in individualID

##then get missing individualID


fixSex<-function(df){
  df$sex<-apply(df,1,function(x){ 
    if(any(tolower(x[c('sex.x','sex.y')]))=='male') 
      return("male")
    else if(any(tolower(x[c('sex.x','sex.y')]))=='female')
      return('female')
     else 
        return(NA)})
}

##
new.lgg<-lgg.data%>%select(-specimenID)%>%left_join(lgg.samp.data,by='individualID')


new.col<-col.data%>%select(-specimenID)%>%left_join(col.samp.data,by='individualID')
