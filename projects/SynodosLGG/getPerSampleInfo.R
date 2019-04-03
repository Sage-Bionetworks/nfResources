require(tidyverse)
require(synapser)
synLogin()
tab<-synapser::synTableQuery("SELECT * FROM syn18416527 WHERE ( ( \"synapseProject\" = 'syn5698493' ) )")$asDataFrame()

#TODO: move 2 65yos
oldies<-which(tab$age_biopsy_year>25)
if(length(oldies)>0)
  tab<-tab[-oldies,]

#TODO: remove 005
tab<-tab[!tab$individualID%in%c("SYN_NF_005"),]
tab<-mutate(tab,ageInMonths=age_biopsy_year*12+round(age_biopsy_month%%12))

##SECOND HIT
tab<-tab%>%mutate(hasOtherMutation=ifelse(is.na(tab$`Second_hit (first)`),'No','Yes'))

##LGG vs HGG
tab<-tab%>%mutate(`LGG-All`=ifelse(tab$binnedHisRead%in%c("LGG - PA","LGG - PA (PMA)"),'LGG - PA','LGG - Other'))
tab$`LGG`[grep('HGG',tab$binnedHisRead)]<-'HGG - All'

##TREATMENT
tab$priorTreatment=ifelse(tab$treatment_prior_biopsy=='No','No','Yes')
tab$postTreatment=ifelse(tab$treatment_post_biopsy=='No','No','Yes')
tab$`prior/post Treatment`=ifelse(apply(tab,1,function(x){ x[['priorTreatment']]=='Yes'||x[['postTreatment']]=='Yes'}),'Yes','No')

##AGE BINS
tab$ageBin<-rep('over17',nrow(tab))
tab$ageBin[which(tab$age_biopsy_year<18)]<-'11to17'
tab$ageBin[which(tab$age_biopsy_year<11)]<-'under11'

##now work on generating tables
#table 1
#Demographic table:  includes age at biopsy, sex, race/ethnicity, nf1 inheritance, binned bx site, binned histo read

age.summary<-function(tab){
  
}


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
      arr=as.numeric(unlist(select(tab,!!as.name(val))))
      res=data.frame(value=paste(min(arr,na.rm=T),'-',max(arr,na.rm=T)),counts=mean(arr,na.rm=T),percent=median(arr,na.rm=T))
    }else{
      res=count(tab,!!as.name(val))%>%mutate(percent=100*n/sum(n))%>%rename(value=!!as.name(val),counts=n)
  }
      res$Variable=rep(val,nrow(res))
      return(res%>%select(Variable,value,counts,percent))
  }))
}

cnames=c('binnedTumorLocation','binnedBiopsySite','nf1_inheritance','clinical_status','hasOtherMutation','race_ethnicity','binnedHisRead','sex','age_biopsy_year')

tab1<-factor.generator(tab,cnames)

#tab1=tab%>%group_by(binnedBiopsySite,binnedHisRead,sex,nf1_inheritance,clinical_status,hasOtherMutation)%>%
#  mutate(totalNum=n_distinct(individualID),meanAge=mean(age_biopsy_year),minAge=min(age_biopsy_year),maxAge=max(age_biopsy_year))%>%
#  select(totalNum,meanAge,minAge,maxAge)%>%
#  count(sex,nf1_inheritance,clinical_status,hasOtherMutation,meanAge,minAge,maxAge)%>%spread(sex,n)

write.csv(tab1,'tab1_allSampleDemographics.csv',row.names = F)
#table2

cnames=c('binnedBiopsySite','nf1_inheritance','clinical_status','hasOtherMutation','sex','age_biopsy_year','binnedHisRead')

tab2=factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'LGG')
write.csv(tab2,'tab2_lggPA_vs_otherDemographics.csv',row.names = F)


#tab3<-factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'priorTreatment')
#write.csv(tab3,'tab3_priorTreatment_otherDemo.csv',row.names = F)
#tab4<-factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'postTreatment')
#write.csv(tab4,'tab3_postTreatment_otherDemo.csv',row.names = F)
#tab$anyTreatment=apply(tab,1,function(x) ifelse(x[['priorTreatment']]=='Yes'||x[['postTreatment']]=='Yes','Yes','No'))

tab5<-factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'prior/post Treatment')


write.csv(tab5,'tab4_anyTreatment.csv',row.names = F)



tab6<-factor.by.group(subset(tab,LGG!='HGG - All'),cnames,'ageBin')
write.csv(tab6,'tab5_binnedAgedemo.csv',row.names = F)

##now figures 
ggplot(tab)+geom_jitter(aes(y=ageInMonths,color=sex,x=binnedHisRead),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave('sex_by_biopsy_age.png')


#ggplot(tab)+geom_bar(aes(fill=sex,x=binnedHisRead),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
#ggsave('sex_by_histology.png')



#ggplot(tab)+geom_bar(aes(fill=sex,x=binnedBiopsySite),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
#ggsave('biopLocation_by_sex.png')

#TODO: mutation heatmap with clinical data

library(survminer)
#biopsy in months
biop_month=tab$age_biopsy_year*12+mod(tab$age_biopsy_month,12)

#followupin months
follow_month=tab$age_last_follow_up_year*12+mod(tab$age_last_follow_up_month,12)

#death
death=tab$age_death_year*12+mod(tab$age_death_month,12)

##create  new df
surv.df<-data.frame(diag=biop_month,follow=follow_month,event=!is.na(death),
  LGG_PA=ifelse(tab$binnedHisRead=="LGG - PA",'LGG - PA','other'),
  HGG=ifelse(tab$binnedHisRead=='HGG - GBM','GBM','other'),
  withFurtherTreatment=ifelse(tab$treatment_post_biopsy!='No','Treated','Untreated'))

fit.lgg<-surv_fit(survival::Surv(diag,follow,event)~LGG_PA,data=surv.df)

#TODO: high grade versus low grade, with death
fit.hgg<-surv_fit(survival::Surv(diag,follow,event)~HGG,data=surv.df)


#TODO: with/without followup
fit.treat<-surv_fit(survival::Surv(diag,follow,event)~withFurtherTreatment,data=surv.df)
ggsurvplot_facet(fit.treat,facet.by=c('LGG_PA'),data=surv.df)
ggsave('lgg_pa_km.png')

fit.treat<-surv_fit(survival::Surv(diag,follow,event)~LGG_PA,data=surv.df)
ggsurvplot_facet(fit.treat,facet.by=c('withFurtherTreatment'),data=surv.df)
ggsave('treatment_km.png')
#ggsurvplot_facet(fit.treat,facet.by=c('HGG'),data=surv.df)

#TODO: LGG PA vs other

resultsdir='syn18423589'
#store images here
this.script='https://raw.githubusercontent.com/Sage-Bionetworks/nfResources/master/projects/SynodosLGG/getPerSampleInfo.R'
files=c(dir('.')[grep('png',dir('.'))], dir('.')[grep('tab',dir('.'))])
tabId='syn18416527'

for(f in files)
  synStore(File(f,parentId=resultsdir),used=tabId,executed=this.script)

