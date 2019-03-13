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

ggplot(tab)+geom_bar(aes(fill=sex,x=binnedHisRead),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave('age_by_sex_histology.png')


#TODO: do biopsy site instead of tumor location
ggplot(tab)+geom_bar(aes(fill=sex,x=binnedBiopsySite),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave('age_by_sex_location.png')

#TODO: mutation heatmap with clinical data

library(ggsurvminer)
#biopsy in months
biop_month=tab$age_biopsy_year*12+mod(tab$age_biopsy_month,12)

#followupin months
follow_month=tab$age_last_follow_up_year*12+mod(tab$age_last_follow_up_month,12)

#death
death=tab$age_death_year*12+mod(tab$age_death_month,12)

##create  new df
surv.df<-data.frame(diag=biop_month,follow=follow_month,event=!is.na(death),
  LGG_PA=ifelse(tab$binnedHisRead=="LGG - PA",'LGG -PA','other'),
  HGG=ifelse(tab$binnedHisRead=='HGG - GBM','GBM','other'),
  withFurtherTreatment=ifelse(tab$treatment_post_biopsy!='No','Treated','Untreated'))

fit.lgg<-surv_fit(survival::Surv(diag,follow,event)~LGG_PA,data=surv.df)

#TODO: high grade versus low grade, with death
fit.hgg<-surv_fit(survival::Surv(diag,follow,event)~HGG,data=surv.df)


#TODO: with/without followup
fit.treat<-surv_fit(survival::Surv(diag,follow,event)~withFurtherTreatment,data=surv.df)
ggsurvplot_facet(fit.treat,facet.by=c('LGG_PA'),data=surv.df)


fit.treat<-surv_fit(survival::Surv(diag,follow,event)~LGG_PA,data=surv.df)
ggsurvplot_facet(fit.treat,facet.by=c('withFurtherTreatment'),data=surv.df)
#ggsurvplot_facet(fit.treat,facet.by=c('HGG'),data=surv.df)

#TODO: LGG PA vs other


