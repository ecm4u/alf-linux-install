# alf-linux-install
helpers for installing and configuring Alfresco components

## About

This project contains some helper scripts for installing and/or configuring Alfresco components. The scripts and tools had been created initially for the [ecm4u Alfresco Virtual Appliance](https://www.ecm4u.de/was-wir-tun/produkte/alfresco/alfresco-virtual-appliance) but could be used in any linux based environment. So it is shared here in the hope that these will help others as well. 

## Contributions

Do you also have fixes, scripts, Webscripts, JavaScripts to install/configure/run Alfresco (on linux) which you think could help others? Please create a pull request! We would be happy to extend the collection.

## Solr

###  solr-install.sh  

The script downloads the zip deployment version for [Alfresco Search Services](https://github.com/Alfresco/SearchServices) and configues the required cores. solrhome by default is expected in `/var/lib/solr/solrhome` but could be modified in the envionment.

The script is also a replacement for the default core config generation done by java on bootstrap `create.alfresco.defaults=alfresco,archive`. Instead the script syncs the config from the template dir and sets the parameters based on config files stored outside the search service directory since it will be fully replaced on any update.
````
./solr-install.sh {download|install|config}
````
When executing with `install` it checks if the zip is already in the configured download directory, replaces the existing installation and then generates the configuration from scratch. So if you have done modifications in shared.properties or in the core's solrcore.properties make sure you put them into 
* `solr-core-alfresco.properties`, `solr-core-archive.properties`: modifications which should apply for a single core only
* `solr-core-shared.properties`: modifications which should apply for all cores
* `solr-custom-shared.properties`: modifications in `solrhome/conf/shared.properties`