require(tidyverse)
require(synapser)
synLogin()
tab<-synapser::synTableQuery("SELECT * FROM syn12164935 WHERE ( ( \"synapseProject\" = 'syn5698493' ) )")$asDataFrame()


ggplot(tab)+geom_jitter(aes(x=sex,y=age_biopsy_year,color=his_read))
ggsave('age_by_sex_histology.png')


ggplot(tab)+geom_jitter(aes(x=sex,y=age_biopsy_year,color=tumorLocation))
ggsave('age_by_sex_location.png')

