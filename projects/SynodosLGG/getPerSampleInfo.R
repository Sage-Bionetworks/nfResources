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

##now work on generating tables
#table 1
#Demographic table:  includes age at biopsy, sex, race/ethnicity, nf1 inheritance, binned bx site, binned histo read

tab<-tab%>%mutate(hasOtherMutation=ifelse(is.na(tab$`Second_hit (first)`),'No','Yes'))

tab1=tab%>%group_by(binnedBiopsySite,binnedHisRead,sex,nf1_inheritance,clinical_status,hasOtherMutation)%>%
  mutate(totalNum=n_distinct(individualID),meanAge=mean(age_biopsy_year),minAge=min(age_biopsy_year),maxAge=max(age_biopsy_year))%>%
  select(totalNum,meanAge,minAge,maxAge)%>%
  count(sex,nf1_inheritance,clinical_status,hasOtherMutation,meanAge,minAge,maxAge)%>%spread(sex,n)

write.csv(tab1,'tab1_extraMutationDemographics.csv',row.names = F)
#table2
tab<-tab%>%mutate(`LGG`=ifelse(tab$binnedHisRead=="LGG - PA",'LGG - PA','LGG - Other'))
tab$`LGG`[grep('HGG',tab$binnedHisRead)]<-'HGG'

tab2=tab%>%group_by(LGG,sex,clinical_status,binnedBiopsySite,hasOtherMutation)%>%
  mutate(totalNum=n_distinct(individualID),meanAge=mean(age_biopsy_year),minAge=min(age_biopsy_year),maxAge=max(age_biopsy_year))%>%
  select(totalNum,meanAge,minAge,maxAge)%>%
  count(sex,hasOtherMutation,clinical_status,meanAge,minAge,maxAge)%>%spread(sex,n)

write.csv(tab2,'tab2_lggPA_vs_otherDemographics.csv',row.names = F)
tab$priorTreatment=ifelse(tab$treatment_prior_biopsy=='No','No','Yes')
tab$postTreatment=ifelse(tab$treatment_post_biopsy=='No','No','Yes')
tab3<-tab%>%group_by(LGG,priorTreatment,postTreatment,binnedBiopsySite,hasOtherMutation,clinical_status)%>%
  mutate(totalNum=n_distinct(individualID),meanAge=mean(age_biopsy_year),minAge=min(age_biopsy_year),maxAge=max(age_biopsy_year))%>%
  select(totalNum,meanAge,minAge,maxAge)%>%
  count(hasOtherMutation,priorTreatment,postTreatment,clinical_status,meanAge,minAge,maxAge)%>%
  spread(LGG,n)

write.csv(tab3,'tab3_priorPostTreatment_otherDemo.csv',row.names = F)

tab$anyTreatment=apply(tab,1,function(x) ifelse(x[['priorTreatment']]=='Yes'||x[['postTreatment']]=='Yes','Yes','No'))
tab4<-tab%>%group_by(LGG,anyTreatment,binnedBiopsySite,hasOtherMutation,clinical_status)%>%
  mutate(totalNum=n_distinct(individualID),meanAge=mean(age_biopsy_year),minAge=min(age_biopsy_year),maxAge=max(age_biopsy_year))%>%
  select(totalNum,meanAge,minAge,maxAge)%>%
  count(hasOtherMutation,anyTreatment,clinical_status,meanAge,minAge,maxAge)%>%
  spread(LGG,n)

write.csv(tab4,'tab4_anyTreatment.csv',row.names = F)

tab$ageBin<-rep('over17',nrow(tab))
tab$ageBin[which(tab$age_biopsy_year<18)]<-'11to17'
tab$ageBin[which(tab$age_biopsy_year<11)]<-'under11'


tab5<-tab%>%group_by(ageBin,LGG,anyTreatment,binnedBiopsySite,hasOtherMutation,clinical_status)%>%
  count(hasOtherMutation,priorTreatment,postTreatment,clinical_status,ageBin)%>%
  spread(ageBin,n)
  
write.csv(tab5,'tab5_binnedAgedemo.csv',row.names = F)

##now figures 
#ggplot(tab)+geom_jitter(aes(y=ageInMonths,color=sex,x=binnedHisRead),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
#ggsave('sex_by_biopsy_age.png')


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
files=c('sex_by_biopsy_age.png','sex_by_histology.png','lgg_pa_km.png','treatment_km.png','biopLocation_by_sex.png', dir('.')[grep('tab',dir('.'))])
tab='syn18416527'

for(f in files)
  synStore(File(f,parentId=resultsdir),used=tab,executed=this.script)

