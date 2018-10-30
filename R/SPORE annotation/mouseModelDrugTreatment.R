##process Clapp lab sample files

library(synapser)
synLogin()
require(tidyverse)
require(xlsx)
library(lubridate)


processPkData<-function(pkdata=pkdata,parid=parid){
  tab<-xlsx::read.xlsx(synGet(pkdata)$path,sheetIndex=1,startRow=3,header=T)[1:30,1:6]
  
  for(i in 1:nrow(tab)){
    x=tab[i,]
    #  apply(tab,1,function (x){
    #x=list(x)
    print(x)
    mid=x$`CPAC..`
    fname=paste(mid,'mousePKData',pkdata,'.csv',sep='')
    print(fname)
    write.csv(x,file=fname,row.names=F,col.names=T)
    annotes=list(
      individualID=mid,
      specimenID=mid,
      #sex=switch(as.character(x$Gender),'F'='female','M'='male'),
      species='Mouse',
      #modelSystem='Peri+',
      compoundName='Imatinib',
  
          dataType='Pharmacokinetic Study',
      assay='HPLC-MSMS',
      experimentalCondition=as.character(x$Treatment),
      experimentalTimePoint=as.character(x$X.hr.),
      experimentalTimePointUnit='hours'
            #these are non-standard
    )
    if(x$Treatment=='AZD6244 + Imatinib')
      annotes$secondCompoundName='AZD-6244'
    print(annotes)
    res=synStore(File(fname,parentId=parid,annotations=annotes))
  }
  
}


processSingleDrugScreen<-function(tv.single,parid){
  tab<-xlsx::read.xlsx(synGet(tv.single)$path,sheetIndex=1)[,1:15]
 # head(tab)
  #all.vars<-apply(tab,1,function(x){
  for(i in 1:nrow(tab)){
    x=tab[i,]
#  apply(tab,1,function (x){
    #x=list(x)
    print(x)
    fname=paste(x$Mouse.,'mouseData',tv.single,'.csv',sep='')
    write.csv(x,file=fname,row.names=F,col.names=T)
    annotes=list(
    individualID=x$Mouse.,
    specimenID=x$Mouse.,
    sex=switch(as.character(x$Gender),'F'='female','M'='male'),
    species='Mouse',
    modelSystem='Peri+',
    compoundName='SELUMETINIB',
    compoundDose=gsub('mg/kg','',unlist(strsplit(as.character(x$Drug..Dose),split=' '))[3]),
    compoundDoseUnit='mg/kg',
      dataType='Volume',
      assay='Vernier Caliper',
    experimentalCondition=as.character(x$`Drug.Group`),
    experimentalTimePoint=gsub("h",'',unlist(strsplit(as.character(x$Time.point),split='-'))[2]),
    experimentalTimePointUnit='hours',
    dob=seconds(lubridate::parse_date_time(x$DOB,'ymd'))*1000,
    dod=seconds(lubridate::parse_date_time(x$DOD,'ymd'))*1000
    #these are non-standard
    )
    print(annotes)
    res=synStore(File(fname,parentId=parid,annotations=annotes))
  }
}

processComboDrugScreen<-function(tv.combo=tv.combo,parid=parid){
  tab<-xlsx::read.xlsx(synGet(tv.combo)$path,sheetIndex=1,startRow=2)[,1:14]
  # head(tab)
  #all.vars<-apply(tab,1,function(x){
  for(i in 1:nrow(tab)){
    x=tab[i,]
    mid=as.character(x$Mouse.)
    if(is.na(mid)||mid==' ')
      next
    #  apply(tab,1,function (x){
    #x=list(x)
  #  print(x)
    fname=paste(mid,'mouseComboData',tv.single,'.csv',sep='')
    write.csv(x,file=fname,row.names=F,col.names=T)
    annotes=list(
      individualID=mid,
      specimenID=mid,
      sex=switch(as.character(x$Gender),'F'='female','M'='male'),
      species='Mouse',
      modelSystem='Peri+',
      compoundDoseUnit='mg/kg',
      dataType='Volume',
      assay='Vernier Caliper',
      experimentalCondition=as.character(x$Duration.Time.pt),
      experimentalTimePoint=gsub("H",'',unlist(strsplit(as.character(x$Duration.Time.pt),split='-'))[2]),
      experimentalTimePointUnit='hours',
      dob=seconds(lubridate::parse_date_time(x$DOB,'ymd'))*1000,
      dod=seconds(lubridate::parse_date_time(x$DOD,'ymd'))*1000
      #these are non-standard
    )
    if(is.na(x$Drug..Dose)){
      }else if(x$Drug..Dose=="AZD6244(10mg/kg)"){
      annotes$compoundName='AZD-6244'
      annotes$compoundDose=10
    }else if(x$Drug..Dose=='AZD(10mg)+G(50mg)'){
      annotes$compoundName='AZD-6244'
      annotes$secondCompoundName='IMATINIB'
      annotes$compoundDose=10
      annotes$secondCompoundDose=50
      annotes$secondCompoundDoseUnit='mg/kg'
    }else if(x$Drug..Dose=='AZD(10mg)+XL(15mg)'){
      annotes$compoundName='AZD-6244'
      annotes$secondCompoundName='XL-184'
      annotes$compoundDose=10
      annotes$secondCompoundDose=15
      annotes$secondCompoundDoseUnit='mg/kg'  
    }else if(x$Drug..Dose=='XL184 (15mg/kg)'){
      annotes$compoundName='XL-184'
      annotes$compoundDose=15
    }else if(x$Drug..Dose=='Gleevec(50mg/kg)'){
      annotes$compoundName='IMATINIB'
      annotes$compoundDose=50
    }else if(x$Drug..Dose=='Control-(HPMC)'){
      annotes$compoundName='HPMC'
  }
    
    print(annotes)
    res=synStore(File(fname,parentId=parid,annotations=annotes))
  }
  
}
tv.single='syn12493013'
tv.combo='syn12493014'
pkdata='syn12493012'
parid='syn12493011'

#processPkData(pkdata,parid)
#processSingleDrugScreen(tv.single,parid)
processComboDrugScreen(tv.combo,parid)
