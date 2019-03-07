#create annotation keys

require(synapser)
synLogin()

assay=synTableQuery("select distinct value,valueDescription,source from syn10242922 where key='assay'")$asDataFrame()

write.csv(apply(assay,1,paste,collapse='|'),file='assays.csv',row.names = F,quote=F)

dataType=synTableQuery("select distinct value,valueDescription,source from syn10242922 where key='dataType'")$asDataFrame()

write.csv(apply(dataType,1,paste,collapse='|'),file='dataTypes.csv',row.names = F,quote=F)
