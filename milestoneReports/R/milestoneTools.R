##primary functions to retrieve project information


pvid='syn10147576'
con='cNF Initiative'

# We need to list all projects to generate reports for
# @export 
getProjectsByConsortium<-function(pvid,consortium){
  require(synapser)
  synLogin()
  query=paste("SELECT id,name FROM ",pvid)
  if(!missing(consortium))
    query=paste0(query," WHERE consortium = '",consortium,"'")
  #print(query)
  res=synTableQuery(query)$asDataFrame()
  return(res)
  
}

#get the distinct milsteons for each project id
# @export
fvid='syn8077013'
sid='11374339'
getMilestonesForProject<-function(fvid,sid){
  require(synapser)
  synapser::synLogin()
  query=paste0("SELECT distinct milestoneReport from ',fvid,' where studyId = '",sid,"'")
  return(synapser::synTableQuery(query)$asDataFrame())
}


