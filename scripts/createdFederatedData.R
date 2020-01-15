library(tidyverse)
library(synapser)


parseArgs<-function(){
    require(optparse)

    option_list<-list(
        make_option(c('-t','--table',dest='tab',help='synapse id of table to query')),
        make_option(c('-p','--project',dest='proj',help='Project id parent of new table')),
        make_option(c('-n','--name',dest='tname',help='Name of new table')),
        make_option())

    args<-parse_args(OptionParser(option_list))
    return(args)
}


main<-function(){
    args<-parseArgs()
    synLogin()

    tab<-synapser::synTableQuery()$asDataFrame()
    assayType=''
    dataType=switch(assayType)

}


main()
