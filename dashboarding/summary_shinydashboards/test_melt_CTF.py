# coding: utf-8

# In[1]:


import pandas
import numpy
import datetime
import synapseutils
import synapseclient
from synapseclient import Entity, Project, Column, Team, Wiki


# In[2]:


def synapseLogin():
    """
    First tries to login to synapse by finding the local auth key cached on user's computing platform, if not found,
    prompts the user to provide their synapse user name and password, then caches the auth key on their computing
    platform.

    :return:
    """
    try:
        syn = synapseclient.login()
    except Exception as e:
        print('Please provide your synapse username/email and password (You will only be prompted once)')
        username = input("Username: ")
        password = getpass.getpass(("Password for " + username + ": ").encode('utf-8'))
        syn = synapseclient.login(email=username, password=password, rememberMe=True)

    return syn


# In[3]:


synapseLogin()


# In[4]:


def getdf(syn, id):
    """

    :param syn:
    :param id:
    :return:
    """
    df = syn.tableQuery('select * from {id}'.format(id=id)).asDataFrame()
    return df


# In[5]:


"""
Create a master matrix/table for consortium metrics.

:param args:
:param syn:
:return:
"""
# project and publication attributes
p_atr = ['projectName',
         'id',
         'fundingAgency',
         'citation',
         'doi',
         'tumorType',
         'diseaseFocus']

### from table syn16787123
p_view_atr = ['projectName',
              'id',
              'studyFileviewId',
              'projectStatus',
              'dataStatus',
              'fundingAgency',
              'summary',
              'summarySource',
              'projectLeads',
              'institutions',
              'tumorType',
              'diseaseFocus']


# file view attributes
f_atr = ['id',
        'name',
        'projectId',
        'assay',
        'consortium',
        'dataSubtype',
        'dataType',
        'diagnosis',
        'tumorType',
        'fileFormat',
        'fundingAgency',
        'individualID',
        'nf1Genotype',
        'nf2Genotype',
        'species',
        'resourceType',
        'isCellLine',
        'isMultiSpecimen',
        'isMultiIndividual',
        'studyId',
        'studyName',
        'benefactorId',
        'specimenID',
        'sex'
        'age',
        'readPair',
        'createdOn',
        'modifiedOn']

# csbc project info integration
csbc_atr = ["projectId",
            "name_project",
            "consortium",
            "institution",
            "grantNumber",
            "grantType",
            "teamMembersProfileId",
            "teamProfileId",
            "createdOn_project",
            "modifiedOn_project",
            "publication_count",
            "publication_geodata_produced",
            "fileId","name_file",
            "createdOn_file",
            "modifiedOn_file",
            "age",
            "analysisType",
            "assay",
            "cellLine",
            "cellSubType",
            "cellType",
            "compoundDose",
            "compoundName",
            "concreteType",
            "dataSubtype",
            "dataType",
            "diagnosis",
            "diseaseSubtype",
            "dnaAlignmentMethod",
            "experimentalCondition",
            "experimentalTimePoint",
            "fileFormat",
            "fundingAgency",
            "individualID",
            "individualIdSource",
            "inputDataType",
            "isCellLine",
            "isPrimaryCell",
            "isStranded",
            "libraryPrep",
            "modelSystem",
            "organ",
            "outputDataType",
            "peakCallingMethod",
            "platform",
            "readLength",
            "resourceType",
            "rnaAlignmentMethod",
            "runType",
            "scriptLanguageVersion",
            "sex","softwareAuthor",
            "softwareLanguage",
            "softwareRepository",
            "softwareRepositoryType",
            "softwareType",
            "species",
            "specimenID",
            "study",
            "tissue",
            "transcriptQuantificationMethod",
            "transplantationDonorSpecies",
            "transplantationDonorTissue",
            "transplantationRecipientTissue",
            "transplantationType",
            "tumorType"]


# In[6]:


# merging all the things
# 0 publications view syn16857542
# 1 project table  syn16787123
# 2 all portal - files syn16858331
# 3 tools syn9898965
views = ['syn16857542', 'syn16787123', 'syn16858331', 'syn16859448']

dfs = [getdf(synapseclient.login(), synid) for synid in views]
[d.reset_index(inplace=True, drop=True) for d in dfs]


# In[7]:


# Project attributes
# change columns to represent project attributes and unify key name to be projectId
dfs[0].rename(index=str, columns={"id": "projectId", "name" : "projectName"}, inplace=True)
dfs[1].rename(index=str, columns={"id": "projectId", "name": "projectName"}, inplace=True)


# In[11]:


dfs[2].rename(index=str, columns={"id": "fileId", "name": "name_file", "createdOn": "createdOn_file",
                                  "modifiedOn": "modifiedOn_file", "modifiedBy": "modifiedBy_file"}, inplace=True)
dfs[3].rename(index=str, columns={"id": "fileId", "name": "name_file", "createdOn": "createdOn_file",
                                  "modifiedOn": "modifiedOn_file", "modifiedBy": "modifiedBy_file", "study" :"projectId"}, inplace=True)


# In[8]:


# take out non CTF funded projects
dfs[0] = dfs[0][~dfs[0].fundingAgency.isin(['NTAP', 'NIH-NCI'])]
dfs[1] = dfs[1][~dfs[1].fundingAgency.isin(['NTAP', 'NIH-NCI'])]
dfs[2] = dfs[2][~dfs[2].fundingAgency.isin(['NTAP', 'NIH-NCI'])]
dfs[3] = dfs[3][~dfs[3].fundingAgency.isin(['NTAP', 'NIH-NCI'])]


# In[29]:


pandas.set_option('display.max_columns', 500)
dfs[1]


# In[10]:


dfs[2].studyName.unique() #there are 4 consoritums under the CTF funding agency


# In[13]:


nf1 = ['Synodos NF1 Preclinical Models (Iowa Sanford Exemplar)',
       'Synodos NF1 Preclinical Models (Minnesota CCHMC Recombinetics)']
dfs[2].loc[dfs[2]['studyName'].isin(nf1)]

### dfs[2] has the files


# In[14]:


# there are projects without publications
len(set(dfs[1].projectId.unique()) - set(dfs[0].projectId.unique()))


# In[15]:


# Associate publications information to projects
project_info_df = pandas.merge(dfs[1].drop(['featured'],axis=1), dfs[0].drop(['featured'],axis=1), on=['projectId','projectName', 'fundingAgency', 'diseaseFocus', 'tumorType','studyName','studyId','manifestation'], how='left')

#project_info_df = pandas.merge(dfs[1], dfs[0], on=['projectId','projectName', 'fundingAgency', 'diseaseFocus', 'tumorType'], how='left')


# In[16]:


project_info_df = project_info_df[
    [ 'projectName',
     'projectId',
     'studyFileviewId',
     'dataStatus',
     'fundingAgency',
     'projectLeads',
     'institutions',
     'tumorType',
     'diseaseFocus',
     'citation',
     'doi']
]


# In[17]:


publication_count = list(project_info_df.groupby(['projectId']))
dfs[1]['publication_count'] = [len(x[1]) if len(x[1]) != 1 else 0 for x in publication_count]


# In[18]:


dfs[0] = dfs[0].astype(object).replace(numpy.nan, '')


# In[19]:


dfs[1]['publication_geodata_produced'] = 0  ### don't have data location...run getPMIDDF or set to zero


# In[20]:


dfs[3]


# In[50]:


# File attributes
# remove tools files (subset of all datafiles) from all datafiles
tools_files_id = list(set(dfs[2]["name_file"].unique()).intersection(set(dfs[3]["name_file"].unique())))

# # no files that are also tools for CTF
list(set(dfs[3]["name_file"].unique()).intersection( set(dfs[2]["name_file"].unique())))


# In[23]:


cols_to_add2 = dfs[3].columns.difference(dfs[2].columns)
cols_to_add3 = dfs[2].columns.difference(dfs[3].columns)
dfs[2] = pandas.concat([dfs[2], pandas.DataFrame(columns=cols_to_add2)])
dfs[3] = pandas.concat([dfs[3], pandas.DataFrame(columns=cols_to_add3)])


# In[24]:


dfs[2].loc[dfs[2]['studyName'].isin(nf1)]


# In[33]:


### edit synodos nf1 preclinical studyId to projectId (both nested in the same projectId but have own files)
dfs[2].loc[dfs[2]['studyName'].isin(nf1), 'projectId'] = dfs[2].loc[dfs[2]['studyName'].isin(nf1), 'studyId']


# In[37]:


# concat files and tools to get all the files information data frame
file_info_df = pandas.concat([dfs[3], dfs[2]], sort = False)


# In[38]:


final_df = pandas.merge( dfs[1], file_info_df, on= ['projectId'], how='left')


# In[39]:





# In[40]:


final_df = final_df.drop(
    ["summary_y",
     "summarySource",
     "featured_x",
     "consortium_x",
     "fundingAgency_y",
     "featured_y",
     "tumorType_y",
     "etag",
     "studyName_y",
      "consortium_x",
      "studyId_y",
      "manifestation_y",
      "diseaseFocus_y",
      "studyLeads",
      "projectStatus",
      "cellType",
      "compoundName",
      "experimentalCondition",
      "modelSystemName"
      ]
    , axis = 1)



# final_df = final_df.drop(
#     ["summary_x",
#      "summarySource",
#      "featured_x",
#      "consortium_x",
#      "fundingAgency_y",
#      "featured_y",
#      "tumorType_y",
#      "etag"]
#     , axis = 1)


# In[41]:


final_df.columns


# In[42]:

final_df.rename(columns={
    "fundingAgency_x":"fundingAgency",
    "tumorType_x":"tumorType",
    "projectName":'name_project',
    "isCellLine":"cellLine",
    "consortium_y" : "consortium",
    "summary_x" : "summary",
    "studyName_x" : "studyName",
    "studyId_x" : "studyId",
    "manifestation_x" : "manifestation",
    "diseaseFocus_x": "diseaseFocus"},
                inplace=True)


final_df.loc[final_df['studyName'].isin(nf1)]

# final_df.rename(columns={
#     "fundingAgency_x":"fundingAgency",
#     "tumorType_x":"tumorType",
#     "projectName":'name_project',
#     "isCellLine":"cellLine",
#     "consortium_y" : "consortium"},
#                 inplace=True)


# In[43]:


# annotate tools files to be a resourceType tool - for now
final_df.loc[final_df.summary.isin(list(dfs[3].summary)), 'resourceType'] = 'tool'


# In[44]:


pandas.set_option('display.max_columns', 500)
final_df.describe(include="all")


# In[45]:


# # double check if we didn't loose a project
if len(final_df.projectId.unique()) == len(dfs[1].projectId):
    print("All projects were successfully associated with files")
else:
    print("lost a project")


# In[46]:

print(list(final_df.columns))

# check types
col_types = [col for col in list( final_df.columns ) if final_df[col].dtype == numpy.float64]
print("column names of type numpy.float64 \n:", col_types)


# In[47]:


len(final_df.columns)


# In[48]:


def changeFloatToInt(final_df, col):
    """

    :param final_df:
    :param col:
    :return:
    """
    final_df[col] = final_df[col].fillna(0).astype(int)
    final_df[col].replace(0, '', inplace=True)


# In[33]:


cols = ['createdOn_file','modifiedOn_file','readPair']

[changeFloatToInt(final_df, col) for col in cols]


# In[49]:


### parent is CTF data resource now
syn = synapseclient.Synapse()
syn.login()

existing_table="syn19040577"
rowset=syn.tableQuery("select * from "+existing_table)
syn.delete(rowset)

# results = syn.tableQuery("select * from syn18956617") #current
#table = synapseclient.table.build_table("CTF Project Information Integration", 'syn4984604', final_df)
table=syn.store(synapseclient.table.Table(existing_table,final_df))




# In[50]:


#table = syn.store(table)
