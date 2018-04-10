##redcap formating

#'
#'takes a redcap table and makes a data.frame out of it
redCapToTable<-function(data,data_labels,data_dict){
  dat<-read.csv(data)
  labs<-read.csv(data_labels)
  dict<-read.csv(data_dict)
   
}
