require(tidyverse)
require(synapser)
synLogin()
tab<-synapser::synTableQuery("SELECT * FROM syn18416527 WHERE ( ( \"synapseProject\" = 'syn5698493' ) )")$asDataFrame()


ggplot(tab)+geom_bar(aes(fill=sex,x=binnedHisRead),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave('age_by_sex_histology.png')


ggplot(tab)+geom_bar(aes(fill=sex,x=binnedTumorLocation),position='dodge')+ theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave('age_by_sex_location.png')

