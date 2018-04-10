###merge and update data from clinical database
source("../../R/redCapProcessing.R")

require(synapser)
synLogin()
clindata<-synapser::synGet("syn12104365")$path
dataDict<-synapser::synGet("syn12104367")$path
dataLab<-synapser::synGet("syn12104366")$path
