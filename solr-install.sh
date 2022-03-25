#!/bin/bash

# (c) 2022 heiko.robert@ecm4u.de
# the script downloads and configures Alfresco Search Service
# version defaults to ASS_VERSION but could be provided as parameter

ASS_VERSION=${ASS_VERSION:-2.0.3}

# please check Alfresco Search Services Release Notes
# https://hub.alfresco.com/t5/alfresco-content-services-blog/search-services-2-0-2-release/ba-p/308070
# https://hub.alfresco.com/t5/alfresco-content-services-blog/search-services-2-0-1-release/ba-p/303712
# https://hub.alfresco.com/t5/alfresco-content-services-blog/search-services-2-0-0-release/ba-p/301308
# https://hub.alfresco.com/t5/alfresco-content-services-blog/search-services-1-4-3-release/ba-p/301127
# https://hub.alfresco.com/t5/alfresco-content-services-blog/search-service-1-4-2-release/ba-p/298334

ASS_DISTRIBUTION=alfresco-search-services-${ASS_VERSION}.zip
#ASS_DL_URL=https://download.alfresco.com/cloudfront/release/community/SearchServices/${ASS_VERSION}/${ASS_DISTRIBUTION}
ASS_DL_URL=https://artifacts.alfresco.com/nexus/content/repositories/public/org/alfresco/alfresco-search-services/${ASS_VERSION}/${ASS_DISTRIBUTION}

###### setup START ######################################
ASS_BASE=${ASS_BASE:-$ALF_HOME/alfresco-search-services}
SOLR_BASE=${SOLR_BASE:-/var/lib/solr}
SOLR_HOME=${SOLR_HOME:-$SOLR_BASE/solrhome}
SOLR_USER=${SOLR_USER:-alfresco}
SOLR_LOGDIR=${SOLR_LOGDIR:-/var/log/solr/}
CONFSET=/opt/alfresco/scripts/confset
# prefix for custom solr core property overwrites
SOLR_CORE_CUSTOM_PREFIX=$ALF_HOME/conf/solr-core
SOLR_CUSTOM_PREFIX=$ALF_HOME/conf/solr-custom

ENABLED_CORES=${ENABLED_CORES:=alfresco,archive}
IFS=',' CORE_LIST=($ENABLED_CORES); unset IFS
###### setup END ########################################

get_sol_config(){
    local PROPFILE=${SOLR_CUSTOM_PREFIX}-${1}.properties
	if [[ -f $PROPFILE ]];then
		grep -v '^#.*$' $PROPFILE | sort | grep -v '^[[:space:]]*$'
	else
		touch "$PROPFILE"
	fi
}
get_solrcore_config(){
    PROPFILE=${SOLR_CORE_CUSTOM_PREFIX}-${1}.properties
    if [[ -f $PROPFILE ]];then
        grep -v '^#.*$' ${SOLR_CORE_CUSTOM_PREFIX}-${1}.properties | sort | grep -v '^[[:space:]]*$'
    else
        touch "$PROPFILE"
    fi
}

download_ass(){
    if [ ! -f "$DL_TARGET/$ASS_DISTRIBUTION" ]; then
        echo "downloading $ASS_DISTRIBUTION ..."
        wget --directory-prefix=$DL_TARGET "$ASS_DL_URL"
    fi    
}

check_ass_dirs(){
    SOLR_DIRS="$ASS_BASE $ASS_BASE $SOLR_HOME $SOLR_BASE/contentstore"
    for dir in $SOLR_DIRS;do
        if [[ ! -d $dir ]];then
            sudo mkdir -p $dir
            sudo chown -R $SOLR_USER:$SOLR_USER $dir
        fi
    done
    ln -snf ../../var/lib/solr/solrhome $ALF_HOME/solr_home
}


setup_ass_config(){
    echo "   Initialising core config"

    for core in "${CORE_LIST[@]}"; do
        echo "   Setting up SOLR core ${core}"
        cp -r $ALF_HOME/alfresco-search-services/solrhome/templates/rerank $SOLR_HOME/${core}
        touch $SOLR_HOME/${core}/core.properties
        $CONFSET name=${core} $SOLR_HOME/${core}/core.properties

        for conf in $(get_solrcore_config shared);do
            # echo "   setting $conf"
            $CONFSET "$conf" $SOLR_HOME/${core}/conf/solrcore.properties
        done

        for conf in $(get_solrcore_config ${core});do
            # echo "   setting $conf"
            $CONFSET "$conf" $SOLR_HOME/${core}/conf/solrcore.properties
        done
    done

    echo "   Initialising shared.properties"
    cp -r $ALF_HOME/alfresco-search-services/solrhome/conf $SOLR_HOME/
    cp $ALF_HOME/alfresco-search-services/solrhome/solr.xml $SOLR_HOME/
    for conf in $(get_sol_config shared);do
	    $CONFSET "$conf" $SOLR_HOME/conf/shared.properties
    done

    if [[ -f $ALF_HOME/alfresco-search-services/solrhome/security.json ]];then
        cp $ALF_HOME/alfresco-search-services/solrhome/security.json $SOLR_HOME/
    fi
}

case "$1" in
    download)
        download_ass
    ;;

    install)
        download_ass
        rm -rf $ALF_HOME/alfresco-search-services
        check_ass_dirs
        unzip -qq "$DL_TARGET/$ASS_DISTRIBUTION" -d $ALF_HOME
        setup_ass_config
    ;;

    config)
        setup_ass_config
    ;;

  *)
	echo "Usage: $0 {download|install|config}"
	exit 1
	;;
	
esac
