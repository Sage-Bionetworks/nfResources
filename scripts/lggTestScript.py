import synapseclient


syn = synapseclient.login()

syn.setEndpoints(**synapseclient.client.STAGING_ENDPOINTS)

syn.get('syn11887916')

#To reset to Production, either restart your python session or call this command:
syn.setEndpoints(**synapseclient.client.PRODUCTION_ENDPOINTS)
