require(tidyverse)
require(synapser)
synLogin()
tab<-synapser::synTableQuery("SELECT * FROM syn18416527 WHERE ( ( \"synapseProject\" = 'syn5698493' ) )")$asDataFrame()
tab$race_ethnicity[which(tab$race_ethnicity=="White/Ethnicity Unknown")]<-'Unknown'
##reducing by mol.data
have.mol<-synapser::synTableQuery("SELECT Synodos_ID,methylationSubtype FROM syn18420940 where Include_manuscript = 1")$asDataFrame()

#TODO: move 2 65yos
oldies<-which(tab$age_biopsy_year>25)
if(length(oldies)>0)
  tab<-tab[-oldies,]

#TODO: remove 005
tab<-tab[!tab$individualID%in%c("SYN_NF_005"),]
tab<-mutate(tab,ageInMonths=age_biopsy_year*12+round(age_biopsy_month%%12))

##upload reason bins

#re-order binned his read
tab$binnedHisRead=factor(tab$binnedHisRead,levels=c("LGG - PA",
  "LGG - PA (PMA)",
  "LGG - PA with atypical features",
  "LGG - grade 2 (DA)",
  "LGG - Grade 2 (OA)",
  "LGG - grade 2 (PXA)",
  "LGG - NOS",
  "Brain Tumor - NOS",
  "HGG - GBM"))

overlaps<-intersect(tab$individualID,have.mol$Synodos_ID)
print(paste('have',length(overlaps),'patients with molecular and clinical data'))
tab<-subset(tab,individualID%in%overlaps)%>%left_join(rename(have.mol,individualID='Synodos_ID'),by='individualID')


##SECOND HIT
tab<-tab%>%mutate(hasOtherMutation=ifelse(is.na(tab$`Second_hit (first)`),'No','Yes'))

##LGG vs HGG
tab<-tab%>%mutate(`LGG-All`=ifelse(tab$binnedHisRead%in%c("LGG - PA"),'LGG - PA','LGG - Other'))
tab$`LGG`=rep('LGG',nrow(tab))
tab$`LGG`[grep('HGG',tab$binnedHisRead)]<-'HGG - All'

##TREATMENT
tab$priorTreatment=ifelse(tab$treatment_prior_biopsy=='No','No','Yes')
tab$postTreatment=ifelse(tab$treatment_post_biopsy=='No','No','Yes')
tab$`prior/post Treatment`=ifelse(apply(tab,1,function(x){ x[['priorTreatment']]=='Yes'||x[['postTreatment']]=='Yes'}),'Yes','No')

##AGE BINS
tab$ageBin<-rep('over17',nrow(tab))
tab$ageBin[which(tab$age_biopsy_year<18)]<-'11to17'
tab$ageBin[which(tab$age_biopsy_year<11)]<-'under11'

tab$under18=sapply(tab$age_biopsy_year,function(x) ifelse(x<18,'under18','18andover'))

tab$ageBin2=rep('over17',nrow(tab))
tab$ageBin2[which(tab$age_biopsy_year<18)]<-'10to17'
tab$ageBin2[which(tab$age_biopsy_year<10)]<-'under10'

tab$ageBin3=rep('over17',nrow(tab))
tab$ageBin3[which(tab$age_biopsy_year<18)]<-'13to17'
tab$ageBin3[which(tab$age_biopsy_year<13)]<-'under13'


##now work on generating tables
#table 1
#Demographic table:  includes age at biopsy, sex, race/ethnicity, nf1 inheritance, binned bx site, binned histo read


factor.by.group<-function(tab,cnames,grouping){
  vals=unique(unlist(select(tab,!!as.name(grouping))))
  do.call(rbind,lapply(vals,function(x){
    tab1<-filter(tab,!!as.name(grouping)==x)
    res<-factor.generator(tab1,cnames)
    res$group=x
    names(res)[which(colnames(res)=='group')]<-grouping
    res
  }))

}

factor.generator<-function(tab,cnames){
  counted.tab<-do.call(rbind,lapply(cnames,function(val,tab1){
    if(val=='age_biopsy_year'){
      di=unique(select(tab,individualID,!!as.name(val)))
      arr=as.numeric(unlist(select(di,!!as.name(val))))
      res=data.frame(value=paste(min(arr,na.rm=T),'-',max(arr,na.rm=T)),patients=mean(arr,na.rm=T),samples=median(arr,na.rm=T),percentPatient=NA,percentSamples=NA)
    }else{
      res=tab%>%group_by(!!as.name(val))%>%summarize(patients=n_distinct(individualID),samples=n_distinct(specimenID))%>%mutate(percentPatient=format(100*patients/sum(patients),digits=2),percentSamples=format(100*samples/sum(samples),digits=2))%>%rename(value=!!as.name(val))
  }
      res$Variable=rep(val,nrow(res))
      res<-res%>%
          mutate(patsWithPer=paste0(patients,' (',percentPatient,'%)'))%>%
        mutate(sampsWithPer=paste0(samples,' (',percentSamples,'%)'))
      
      return(res%>%select(Variable,value,patients,samples,percentPatient,percentSamples,patsWithPer,sampsWithPer))
  }))
}


library(readxl)
loc<-read_xls("~/Downloads/Synodos_Sage Data_updated binned_7-8-19.xls")%>%select(individualID,binnedReasonBiopsy,reason_biopsy)%>%unique()
##now what do i do? 
loc$biopsyReason=sapply(loc$binnedReasonBiopsy,function(x) unlist(strsplit(x,split=':'))[1])
tab<-tab%>%left_join(loc,by='individualID')

cnames=c('age_biopsy_year','sex','race_ethnicity','nf1_inheritance','binnedBiopsySite','binnedHisRead','biopsyReason','prior/post Treatment','clinical_status','hasOtherMutation','methylationSubtype')

tab$groupedBiopsySite=sapply(tab$binnedBiopsySite,function(x){
  if(x%in%(c("Brainstem","Midline")))
    return('Brainstem/Midline')
  else
    return(x)
})
write.tables=FALSE
if(write.tables){
tab1<-factor.generator(tab,cnames)

write.csv(tab1,'tab1_allSampleDemographics.csv',row.names = F)
#table2

cnames=c('age_biopsy_year','sex','nf1_inheritance','binnedBiopsySite','binnedHisRead','biopsyReason','prior/post Treatment','clinical_status','hasOtherMutation','methylationSubtype')

tab2=factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'LGG-All')
write.csv(tab2,'tab2_lggPA_vs_otherDemographics.csv',row.names = F)

tab3=factor.by.group(tab,cnames,'LGG')
write.csv(tab3,'tab2_lgg_vs_hggDemographics.csv',row.names = F)

tab5<-factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'prior/post Treatment')

write.csv(tab5,'tab4_anyTreatment.csv',row.names = F)

tab6<-factor.by.group(tab,cnames,'ageBin')
write.csv(tab6,'tab5_binnedAgedemo.csv',row.names = F)

tab6<-factor.by.group(tab,cnames,'hasOtherMutation')
write.csv(tab6,'ta6_otherMutationdemo.csv',row.names = F)

tab7<-factor.by.group(tab,cnames,'methylationSubtype')
write.csv(tab7,'tab7_methSubtype.csv',row.names = F)

##add new PA vs Other tab, and a new PA vs nonHGG tab
new.tab<-tab
new.tab$isPA=sapply(tab$methylationSubtype,function(x) ifelse(x=='PA',TRUE,FALSE))


tab8<-factor.by.group(new.tab,cnames,'isPA')
write.csv(tab8,'tab8_isPAsubtype.csv')


tab10<-factor.by.group(new.tab[grep("LGG",new.tab$binnedHisRead),],cnames,'isPA')
write.csv(tab10,'tab10_LGGonly_isPAsubtype.csv')

#PA vs all other non-HGG (MYB + LGGNT + GG + RGNT + N/A) (i.e. do not include APA or GBM).
new.tab<-tab
new.tab$isPAnonHGG=sapply(tab$methylationSubtype,function(x) ifelse(x=='PA','PA',ifelse(x%in%c('APA','GBM'),'other','nonHGGnonPA')))

tab9<-factor.by.group(new.tab[grep("LGG",new.tab$binnedHisRead),],cnames,'isPAnonHGG')
write.csv(tab9,'tab9_isPANonHGGsubtype.csv')


##last tab? 
#OPHG (14 subjects/14 samples) vs Cortex (20 subjects/21 samples) vs Cerebellar/PF NOS (12 subjects/13 samples ) vs Brainstem/Midline together (8 subjects/8 samples)


tab11<-factor.by.group(new.tab,cnames,'groupedBiopsySite')
write.csv(tab11,'tab11_groupedBiopsySite.csv')

new.tab$updatedMethylationStats=sapply(tab$methylationSubtype,function(x) ifelse(x%in%c('GBM','APA'),'GBM+APA','other'))

tab12<-factor.by.group(new.tab,cnames,'updatedMethylationStats')
write.csv(tab12,'tab12_apaHggMethylStatus.csv')

tab13<-factor.by.group(new.tab,cnames,'under18')
write.csv(tab13,'tab13_under18.csv')

tab14<-factor.by.group(new.tab,cnames,'ageBin2')
write.csv(tab14,'tab14_ageBin2.csv')

tab15<-factor.by.group(new.tab,cnames,'ageBin3')
write.csv(tab15,'tab15_ageBin3.csv')

}
#TODO: mutation heatmap with clinical data

if(require(survminer)){
  lgg.only<-which(tab$binnedHisRead!='HGG - GBM')
  
#biopsy in months
biop_month=tab$age_biopsy_year*12+mod(tab$age_biopsy_month,12)
#followupin months
follow_month=tab$age_last_follow_up_year*12+mod(tab$age_last_follow_up_month,12)

##months since biopsy
surv_month=follow_month-biop_month#sapply(follow_month-biop_month,function(x) max(0,x))

#death
death=ifelse(is.na(tab$age_death_year*12+mod(tab$age_death_month,12)),FALSE,TRUE)

#no.hgg=
##create  new df, with each of the comparisons that michael wants.
surv.df<-data.frame(diag=biop_month,follow=follow_month,event=!is.na(death),
  surv_month=surv_month,
  BiopsySite=ifelse(tab$groupedBiopsySite%in%c('OPHG','Ventricle'),'OPHGCortical',tab$groupedBiopsySite),
  Histology=ifelse(tab$binnedHisRead=='HGG - GBM','HGG','LGG'),
  PA_histology=ifelse(tab$binnedHisRead=='LGG - PA','LGG - PA',ifelse(tab$binnedHisRead == 'HGG - GBM','HGG','LGG Other')),
  MethylationHGGAPA=ifelse(tab$methylationSubtype%in%c('GBM','APA'),'HGGAPA','Other'),
  MethylationHggApaLgg=ifelse(tab$methylationSubtype%in%c('GBM','APA'),'HGGAPA',ifelse(tab$methylationSubtype=='PA','PA','NonPAother')),
  MethylationPA=ifelse(tab$methylationSubtype=='PA','PA','nonPA'),
  OtherMutation=tab$hasOtherMutation)


lgg.df<-data.frame(diag=biop_month[lgg.only],
  follow=follow_month[lgg.only],
  event=!is.na(death[lgg.only]),
  MethylationPA=ifelse(tab[lgg.only,]$methylationSubtype=='PA','PA','nonPA'),
  OtherMutation=tab[lgg.only,]$hasOtherMutation)


#create list of formulas
formulas<-list(biopsySite=survival::Surv(surv_month,death,type='right')~BiopsySite,
  histology=survival::Surv(surv_month,death,type='right')~Histology,
  histologyPA=survival::Surv(surv_month,death,type='right')~PA_histology,
  MethylationPA=survival::Surv(surv_month,death,type='right')~MethylationPA,
  MethylationHGGAPA=survival::Surv(surv_month,death,type='right')~MethylationHGGAPA,
  MethylationHggApaLgg=survival::Surv(surv_month,death,type='right')~MethylationHggApaLgg,
  OtherMutation=survival::Surv(surv_month,death,type='right')~OtherMutation)


fit=surv_fit(formulas,data=surv.df)
res=ggsurvplot_list(fit,data=surv.df,risk.table=F,pval=T,cumevents=F)
names(res)<-sapply(names(res),function(x) unlist(strsplit(x,split='::'))[2])


for(k in names(res)){
  #  print(k)
  pdf(paste0(k,'_all_km.pdf'),width=10)
  print(res[[k]],newpage=FALSE)
  dev.off()
}

lgg.surv=surv_month[lgg.only]
lgg.death=death[lgg.only]
lgg.formula<-list(MethylationPA=survival::Surv(lgg.surv,as.numeric(lgg.death),type='right')~MethylationPA,
  OtherMutation=survival::Surv(lgg.surv,as.numeric(lgg.death),type='right')~OtherMutation)

lgg.fit=surv_fit(lgg.formula,data=lgg.df)
#surv_pvalue(fit)
##toDO: add in N
##todo: remove median survival, add in text. 

res2=ggsurvplot_list(lgg.fit,data=lgg.df,risk.table=F,pval=T,conf.int=F)
names(res2)<-sapply(names(res2),function(x) unlist(strsplit(x,split='::'))[2])

for(k in names(res2)){
  #  print(k)
  pdf(paste0(k,'_LGG_km.pdf'),width=10)
  print(res2[[k]],newpage=FALSE)
  dev.off()
}
resultsdir='syn18423589'
#store images here
this.script='https://raw.githubusercontent.com/Sage-Bionetworks/nfResources/master/projects/SynodosLGG/getPerSampleInfo.R'
files=c(dir('.')[grep('pdf',dir('.'))], dir('.')[grep('tab',dir('.'))])
tabId='syn18416527'

for(f in files){}
#  synStore(File(f,parentId=resultsdir),used=tabId,executed=this.script)
}
