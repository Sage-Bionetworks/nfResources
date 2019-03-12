### -------------------------------------------
# export synodos LGG redcap data (with label) and upload to synapse to update the data
# The script to merges the sample and clinical data
# Also joins data from 181005_NF1_LGG_Samples_for SAGE.xlsx and uploads to synapse
### -------------------------------------------

library(synapser)
library(tidyverse)
synLogin()

options(stringsAsFactors = FALSE)

# -------------------------------------------
# clinical data
# -------------------------------------------
clinical.dat <- read.csv(synGet("syn12104366")$path)
colnames(clinical.dat) <- c("record_id","dag","survey_id","timestamp","hospital_center",
                            "email","individualID","sex","race_ethnicity","nf1_inheritance",
                            "nf1_diagnosis","clinical_status","age_death_year","age_death_month",
                            "age_last_follow_up_year","age_last_follow_up_month","other_glioma",
                            "other_glioma_Optic_Pathway_Glioma","other_glioma_Brainstem",
                            "other_glioma_Other","other_glioma_txt","other_malignancy",
                            "other_malignancy_MPNST","other_malignancy_pheochromocytoma",
                            "other_malignancy_Other","other_malignancy_txt","pnf","adhd",
                            "autistic","airway_disease","germline_nf1","complete")

##remove duplicated input
#dups <- unique(clinical.dat$individualID[duplicated(clinical.dat$individualID)])
#clinical.dat <- clinical.dat[-grep(paste(dups, collapse = "|"),clinical.dat$individualID),]

#fix center names
table(clinical.dat$hospital_center)
clinical.dat$hospital_center[grep("Colorado",clinical.dat$hospital_center)] <- "Children's Hospital Colorado"
#clinical.dat$hospital_center[clinical.dat$hospital_center %in% c("Lurie's Children Hospital","Lurie's Children's Hospital")] <- "Lurie Children's Hospital"
clinical.dat$hospital_center[grep("Philadelphia",clinical.dat$hospital_center)] <- "Children's Hospital of Philadelphia"
clinical.dat$hospital_center[clinical.dat$hospital_center == "WashU"] <- "Wash U"
clinical.dat$hospital_center[grep("Fondazione",clinical.dat$hospital_center)] <- "Pediatric Neurosurgery, Fondazione A. Gemelli IRCCS"


#drop columns - record_id, dag, survey_id, timestamp,email,compelete
clinical.dat <- clinical.dat[, !colnames(clinical.dat) %in% 
                               c("record_id","dag","survey_id",
                                 "timestamp","email","complete")]

# "other_glioma" merge across boolean fields (types of glioma, please specify other)
glioma_cols <- colnames(clinical.dat)[grep("other_glioma",colnames(clinical.dat))]
glioma_cols <- glioma_cols[-1]

clinical.dat$other_glioma <- apply(clinical.dat,1,function(x){
  result = x['other_glioma']
  
  if(result == "Yes"){ ## if they said yes to other glioma
    temp <- c()
    for(col in glioma_cols[1:(length(glioma_cols)-2)]){ ## see which types of glioma are checked
      if(x[col] == "Checked"){
        temp <- c(temp,gsub("_"," ",sub("other_glioma_","",col)))
      }
    }
    if(x[glioma_cols[length(glioma_cols)]] != ""){
      temp <- c(temp,x[glioma_cols[length(glioma_cols)]])
    }
    result <- paste(temp,collapse = ", ")
  }
  
  return(result)
})

clinical.dat <- clinical.dat[,!colnames(clinical.dat) %in% glioma_cols]

# "other_malignancy" merge across boolean fields (other malignancy choices and please specify other)
malignancy_cols <- colnames(clinical.dat)[grep("other_malignancy",colnames(clinical.dat))]
malignancy_cols <- malignancy_cols[-1]

clinical.dat$other_malignancy <- apply(clinical.dat,1,function(x){
  result = x['other_malignancy']
  
  if(result == "Yes"){ ## if other malignancy
    temp <- c()
    for(col in malignancy_cols[1:(length(malignancy_cols)-2)]){ ## see if they checked a malignancy choice
      if(x[col] == "Checked"){
        temp <- c(temp,gsub("_"," ",sub("other_malignancy_","",col)))
      }
    }
    if(x[malignancy_cols[length(malignancy_cols)]] != ""){
      temp <- c(temp,x[malignancy_cols[length(malignancy_cols)]])
    }
    result <- paste(temp,collapse = ", ")
  }
  
  return(result)
})

clinical.dat <- clinical.dat[,!colnames(clinical.dat) %in% malignancy_cols]

# -------------------------------------------
# sample data
# -------------------------------------------
sample.dat <- read.csv(synGet("syn12104369")$path)

colnames(sample.dat) <- c("record_id","dag","survey_id","timestamp","hospital_center",
                          "email","individualID","specimenID",
                          "tumorLocation_Cerebellar",
                          "tumorLocation_Posterior-fossa-nos",
                          "tumorLocation_Brainstem-Midbrain",
                          "tumorLocation_Brainstem-Pons",
                          "tumorLocation_Brainstem-Medulla",
                          "tumorLocation_Brainstem-Cervicomedullary",
                          "tumorLocation_Brainstem-NOS",
                          "tumorLocation_Suprasellar",
                          "tumorLocation_Hypothalamic",
                          "tumorLocation_Optic-pathway",
                          "tumorLocation_Thalamic",
                          "tumorLocation_Pineal",
                          "tumorLocation_Ventricle",
                          "tumorLocation_Cortex-Frontal-lobe",
                          "tumorLocation_Cortex-Parietal-lobe",
                          "tumorLocation_Cortex-Temporal-lobe",
                          "tumorLocation_Cortex-Occipital-lobe",
                          "tumorLocation_Cortex-NOS",
                          "tumorLocation_Spinal-cord-Cervical",
                          "tumorLocation_Spinal-cord-Thoracic",
                          "tumorLocation_Spinal-cord-Lumbar",
                          "tumorLocation_Spinal-cord-NOS",
                          "tumorLocation_Disseminated-leptomeningeal",
                          "tumorLocation_Other",
                          "tumorLocation_txt",
                          "site_biopsy",
                          "site_biopsy_txt",
                          "age_biopsy_year",
                          "age_biopsy_month",
                          "his_read",
                          "his_read_other",
                          "treatment_prior_biopsy",
                          "treatment_prior_Chemotherapy",
                          "treatment_prior_Targeted-therapy",
                          "treatment_prior_RT",
                          "treatment_prior_Surgery",
                          "treatment_prior_agent",
                          "treatment_another_prior_biospy",
                          "treatment_another_Chemotherapy",
                          "treatment_another_Targeted-therapy",
                          "treatment_another_RT",
                          "treatment_another_agent",
                          "reason_biopsy_Unclear-diagnosis",
                          "reason_biopsy_Tumor-growth",
                          "reason_biopsy_Clinical-deterioration",
                          "reason_biopsy_Other",
                          "reason_biopsy_txt",
                          "treatment_post_biopsy",
                          "treatment_post_Chemotherapy",
                          "treatment_post_Targeted-therapy",
                          "treatment_post_RT",
                          "treatment_post_Surgery",
                          "treatment_post_agent",
                          "visual_acuity",
                          "he_slide","complete")

#remove duplicated input
# dups <- unique(sample.dat$specimenID[duplicated(sample.dat$specimenID)])
# length(dups) # 0
                                                            
#fix center names
# table(sample.dat$hospital_center)
sample.dat$hospital_center[grep("Colorado",sample.dat$hospital_center)] <- "Children's Hospital Colorado"
sample.dat$hospital_center[grep("Philadelphia",sample.dat$hospital_center)] <- "Children's Hospital of Philadelphia"
sample.dat$hospital_center[grep("Cincinnati",sample.dat$hospital_center)] <- "Cincinnati Children Hospital Medical Center"
sample.dat$hospital_center[grep("Fondazione",sample.dat$hospital_center)] <- "Pediatric Neurosurgery, Fondazione A. Gemelli IRCCS"

#drop columns - record_id, dag, survey_id, timestamp,email,compelete
sample.dat <- sample.dat[, !colnames(sample.dat) %in% 
                           c("record_id","dag","survey_id",
                             "timestamp","email","complete")]

# tumorLocation
tumor_cols <- colnames(sample.dat)[grep("tumorLocation",colnames(sample.dat))]
# get tumorLocation from checked/unchecked choices colnames
sample.dat$tumorLocation <- apply(sample.dat,1,function(x){
    temp <- c()
    for(col in tumor_cols[1:(length(tumor_cols)-2)]){
      if(x[col] == "Checked"){
        temp <- c(temp,gsub("-"," ",sub("tumorLocation_","",col)))
      }
    }
    if(x[tumor_cols[length(tumor_cols)]] != ""){
      temp <- c(temp,x[tumor_cols[length(tumor_cols)]])
    }
    result <- paste(temp,collapse = ", ")
  
  return(result)
})

sample.dat <- sample.dat[,!colnames(sample.dat) %in% tumor_cols]

# treatment_prior
prior_cols <- colnames(sample.dat)[grep("treatment_prior",colnames(sample.dat))]
prior_cols <- prior_cols[2:(length(prior_cols)-1)]

sample.dat$treatment_prior_biopsy <- apply(sample.dat,1,function(x){
  result = x['treatment_prior_biopsy']
  
  if(result == "Yes"){
    temp <- c()
    for(col in prior_cols[1:length(prior_cols)]){
      if(x[col] == "Checked"){
        temp <- c(temp,gsub("-"," ",sub("treatment_prior_","",col)))
      }
    }
    result <- paste(temp,collapse = ", ")
  }
  
  return(result)
})

sample.dat <- sample.dat[,!colnames(sample.dat) %in% prior_cols]


# treatment_another
another_cols <- colnames(sample.dat)[grep("treatment_another",colnames(sample.dat))]
another_cols <- another_cols[2:(length(another_cols)-1)]

sample.dat$treatment_another_prior_biospy <- apply(sample.dat,1,function(x){
  result = x['treatment_another_prior_biospy']
  if(result == "Yes"){
    temp <- c()
    for(col in another_cols[1:length(another_cols)]){
      if(x[col] == "Checked"){
        temp <- c(temp,gsub("-"," ",sub("treatment_another_","",col)))
      }
    }
    result <- paste(temp,collapse = ", ")
  }
  
  return(result)
})

sample.dat <- sample.dat[,!colnames(sample.dat) %in% another_cols]


#reason_biopsy
reason_cols <- colnames(sample.dat)[grep("reason_biopsy",colnames(sample.dat))]

sample.dat$reason_biopsy <- apply(sample.dat,1,function(x){
  temp <- c()
  for(col in reason_cols[1:(length(reason_cols)-2)]){
    if(x[col] == "Checked"){
      temp <- c(temp,gsub("-"," ",sub("reason_biopsy_","",col)))
    }
  }
  if(x[reason_cols[length(reason_cols)]] != ""){
    temp <- c(temp,x[reason_cols[length(reason_cols)]])
  }
  result <- paste(temp,collapse = ", ")
  
  return(result)
})

sample.dat <- sample.dat[,!colnames(sample.dat) %in% reason_cols]


# treatment_post
post_cols <- colnames(sample.dat)[grep("treatment_post",colnames(sample.dat))]
post_cols <- post_cols[2:(length(post_cols)-1)]

sample.dat$treatment_post_biopsy <- apply(sample.dat,1,function(x){
  result = x['treatment_post_biopsy']
  
  if(result == "Yes"){
    temp <- c()
    for(col in post_cols[1:length(post_cols)]){
      if(x[col] == "Checked"){
        temp <- c(temp,gsub("-"," ",sub("treatment_post_","",col)))
      }
    }
    result <- paste(temp,collapse = ", ")
  }
  
  return(result)
})

sample.dat <- sample.dat[,!colnames(sample.dat) %in% post_cols]


# -------------------------------------------
# merge data
# -------------------------------------------
result <- merge(clinical.dat,sample.dat,by = c("hospital_center","individualID"),all.y = TRUE)

# site_biopsy
result$site_biopsy <- apply(result,1,function(x){
  if(x["site_biopsy"]=="Other"){
    return(x["site_biopsy_txt"])
  }
  return(x["site_biopsy"])
})

result$site_biopsy_txt <- NULL

# his_read
result$his_read <- apply(result,1,function(x){
  if(x["his_read"]=="Other"){
    return(x["his_read_other"])
  }
  return(x["his_read"])
})

result$his_read_other <- NULL

#replace Yes/No, Checked/Unchecked with True/False
result$germline_nf1 <- sapply(result$germline_nf1,function(x){
  if(!is.na(x)){
    if(x=="Yes"){
      return(TRUE)
    }else if(x == "No"){
      return(FALSE)
    }
  }
  return("")
})

result$he_slide <- sapply(result$he_slide,function(x){
  if(!is.na(x)){
    if(x=="Yes"){
      return(TRUE)
    }else if(x == "No"){
      return(FALSE)
    }
  }
  return("")
})

# replace 0 with NA
result$age_last_follow_up_year <- sapply(result$age_last_follow_up_year,function(x){
  if(!is.na(x)){
    if(x==0){
      return(NA)
    }
  }
  return(x)
})

result$age_last_follow_up_month <- sapply(result$age_last_follow_up_month,function(x){
  if(!is.na(x)){
    if(x==0.0){
      return(NA)
    }
  }
  return(x)
})

###get synapse table rownames to update
tbl <- synTableQuery("SELECT * FROM syn12164935")
tbl.dat <- tbl$asDataFrame()
temp <- tbl.dat[,c("ROW_ID","ROW_VERSION","synapseProject","individualID","specimenID")]

final.result <- merge(temp,result,by = c("individualID","specimenID"),all.y = TRUE)
final.result <- final.result[,colnames(tbl.dat[,1:36])]

# -------------------------------------------
# read in 181005_NF1_LGG_Samples_for SAGE.xlsx to join some columns into final.result
# -------------------------------------------
NF1_lgg <- readxl::read_excel(synGet("syn18409961")$path)
#rename
colnames(NF1_lgg) <- c("individualID",
                       "hospital_center",
                       "tumorEntity", 
                       "identifier", 
                       "alternativeID", 
                       "sampleID_450k", 
                       "subgroup", 
                       "include_manuscript", 
                       "germline_NF1",
                       "somatic_NF1", 
                       "nf1_genotype",
                       "second_hits", 
                       "other",
                       "nf1_genotype2"
                        )
merged_result <- merge(final.result, NF1_lgg[c("individualID", "nf1_genotype", "second_hits", "germline_NF1", "somatic_NF1")], by = "individualID", all.y = TRUE)                                                                                                                                                                                           #take synodosID and compare to individualID                                                                                                                                  
missing=which(is.na(merged_result$individualID))

if(length(missing)>0)
  merged_result <- merged_result[-missing,]#excel blank leftover and excess on the excel

merged_results <- left_join(final.result, NF1_lgg[c("individualID", "nf1_genotype", "second_hits", "germline_NF1", "somatic_NF1")], by = "individualID")

schema <- synGet('syn12164935')
rows=synTableQuery('select * from syn12164935')
# as.list(synGetTableColumns(schema))

##ADD in project id!!!
merged_results$synapseProject=rep('syn6633069',nrow(merged_results))
merged_results$synapseProject[grep('SYN_NF',merged_results$individualID)]<-'syn5698493'

synDelete(rows)
table <- synStore(Table(schema,merged_results))

##now merge again with binned data
binned.data<-synTableQuery('select * from syn18407820')$asDataFrame()%>%select(Term,Actual,`Binned Value`)

#now do each individually (since i can't figure out the dplyr)
nf1.results<-merged_results%>%
    left_join(subset(binned.data,Term=='tumorLocation')%>%
          rename(tumorLocation=Actual,binnedTumorLocation=`Binned Value`)%>%
          select(-Term),by='tumorLocation')%>%
    left_join(subset(binned.data,Term=='his_read')%>%
        rename(his_read=Actual,binnedHisRead=`Binned Value`)%>%
        select(-Term),by='his_read')%>%
  left_join(subset(binned.data,Term=='site_biopsy')%>%
      rename(site_biopsy=Actual,binnedBiopsySite=`Binned Value`)%>%
      select(-Term),by='site_biopsy')%>%subset(synapseProject=='syn5698493')


##now let's create a prettier table
schema <- synGet('syn18416527')
rows=synTableQuery('select * from syn18416527')
synDelete(rows)
synStore(Table(schema,nf1.results))


