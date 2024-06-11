#!/bin/bash
############################################################################################################
# 
############################################################################################################

# NODE_API_ENABLE=true
# NODE_API_KEY
# NODE_INSPECTOR_ENABLE=true
# NODE_RESTREAMER_ENABLE=true
# NODE_SOCIALPUSHER_ENABLE=true
# NODE_SUPPRESSOR_ENABLE=true
# NODE_HLS_ENABLE=true

# NODE_WEBHOOKS_ENABLE=true
# NODE_WEBHOOKS_ENDPOINT="https://test.webhook.app/api/v1/broadcast/webhook"

# NODE_ROUND_TRIP_AUTH_ENABLE=true
# NODE_ROUND_TRIP_AUTH_HOST=round-trip-auth.example.com
# NODE_ROUND_TRIP_AUTH_PORT=443
# NODE_ROUND_TRIP_AUTH_PROTOCOL=https
# NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE="/validateCredentials"
# NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE="/invalidateCredentials"

# NODE_CLOUDSTORAGE_ENABLE=true
# NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY=
# NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY=
# NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME=
# NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION=
# NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE=false
# R5P_WEBINAR_ENABLE=false
# KAFKA_HOST=

RED5_HOME="/usr/local/red5pro"
PACKAGES_DEFAULT=(jsvc ntp ffmpeg)

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
}
log_d() {
    log
    printf "\033[0;33m [INFO]  --- %s \033[0m\n" "${@}"
}
log_w() {
    log
    printf "\033[0;35m [WARN] --- %s \033[0m\n" "${@}"
}
log_e() {
    log
    printf "\033[0;31m [ERROR]  --- %s \033[0m\n" "${@}"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

install_pkg(){
    for i in {1..5};
    do
        
        local install_issuse=0;
        apt-get -y update --fix-missing &> /dev/null
        
        for index in ${!PACKAGES[*]}
        do
            log_i "Install utility ${PACKAGES[$index]}"
            apt-get install -y ${PACKAGES[$index]} &> /dev/null
        done
        
        for index in ${!PACKAGES[*]}
        do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${PACKAGES[$index]}|grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${PACKAGES[$index]} utility didn't install, didn't find MIRROR !!! "
                install_issuse=$(($install_issuse+1));
            else
                log_i "${PACKAGES[$index]} utility installed"
            fi
        done
        
        if [ $install_issuse -eq 0 ]; then
            break
        fi
        if [ $i -ge 5 ]; then
            log_e "Something wrong with packages installation!!! Exit."
            exit 1
        fi
        sleep 20
    done
}

config_node_apps_plugins(){
    log_i "Clean unnecessary apps and plugins"

    ### Streammanager
    if [ -d "$RED5_HOME/webapps/streammanager" ]; then
        rm -r $RED5_HOME/webapps/streammanager
    fi
    ### Template
    if [ -d "$RED5_HOME/webapps/template" ]; then
        rm -r $RED5_HOME/webapps/template
    fi
    ### Videobandwidth
    if [ -d "$RED5_HOME/webapps/videobandwidth" ]; then
        rm -r $RED5_HOME/webapps/videobandwidth
    fi

    if [[ "$NODE_API_ENABLE" == "true" ]]; then
        log_i "Red5Pro WEBAPP API - enable"

        if [ -z "$NODE_API_KEY" ]; then
            log_e "Parameter NODE_API_KEY is empty. EXIT."
            exit 1
        fi
        local token_pattern='security.accessToken='
        local debug_logaccess_pattern='debug.logaccess=false'
        local token_new="security.accessToken=${NODE_API_KEY}"
        local debug_logaccess='debug.logaccess=true'
        sed -i -e "s|$token_pattern|$token_new|" -e "s|$debug_logaccess_pattern|$debug_logaccess|" "$RED5_HOME/webapps/api/WEB-INF/red5-web.properties"
        echo " " >> $RED5_HOME/webapps/api/WEB-INF/security/hosts.txt
        echo "*" >> $RED5_HOME/webapps/api/WEB-INF/security/hosts.txt
    else
        log_d "Red5Pro WEBAPP API - disable"
        if [ -d "$RED5_HOME/webapps/api" ]; then
            rm -r $RED5_HOME/webapps/api
        fi
    fi

    ### Inspector
    if [[ "$NODE_INSPECTOR_ENABLE" == "true" ]]; then
        log_i "Red5Pro WEBAPP INSPECTOR - enable"
    else
        log_d "Red5Pro WEBAPP INSPECTOR - disable"
        if [ -d "$RED5_HOME/webapps/inspector" ]; then
            rm -r $RED5_HOME/webapps/inspector
        fi
        if [ -f "$RED5_HOME/plugins/inspector.jar" ]; then
            rm $RED5_HOME/plugins/inspector.jar
        fi
    fi
    ### Red5Pro HLS
    if [[ "$NODE_HLS_ENABLE" == "true" ]]; then
        log_i "Red5Pro HLS - enable"
    else
        log_d "Red5Pro HLS - disable"
        if ls $RED5_HOME/plugins/red5pro-mpegts-plugin* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-mpegts-plugin*
        fi
    fi
    ### Red5Pro Restreamer
    if [[ "$NODE_RESTREAMER_ENABLE" == "true" ]]; then
        log_i "Red5Pro Restreamer - enable"
        log_i "HERE need to add Restreamer configuration!!!"
    else
        log_d "Red5Pro Restreamer - disable"
        if ls $RED5_HOME/plugins/red5pro-restreamer-plugin* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-restreamer-plugin*
        fi
    fi
    ### Red5Pro Socialpusher
    if [[ "$NODE_SOCIALPUSHER_ENABLE" == "true" ]]; then
        log_i "Red5Pro Socialpusher - enable"
        log_i "HERE need to add Socialpusher configuration!!!"
    else
        log_d "Red5Pro Socialpusher - disable"
        if ls $RED5_HOME/plugins/red5pro-socialpusher-plugin* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-socialpusher-plugin*
        fi
    fi
    ### Red5Pro Client-suppressor
    if [[ "$NODE_SUPPRESSOR_ENABLE" == "true" ]]; then
        log_i "Red5Pro client-suppressor - enable"
        log_i "HERE need to add Client-suppressor configuration!!!"
    else
        log_d "Red5Pro client-suppressor - disable"
        if ls $RED5_HOME/plugins/red5pro-client-suppressor* >/dev/null 2>&1; then
            rm $RED5_HOME/plugins/red5pro-client-suppressor*
        fi
    fi
    ### VOD via Cloud Storage
    if [[ "$NODE_CLOUDSTORAGE_ENABLE" == "true" ]]; then
        log_i "Red5Pro Digital Ocean Cloudstorage plugin - enable"
        if [ -z "$NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_FILE_ACCESS" ]; then
            log_e "Parameter NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_FILE_ACCESS is empty. EXIT."
            exit 1
        fi

        log_i "Config Digital Ocean Cloudstorage plugin: $RED5_HOME/conf/cloudstorage-plugin.properties"
        do_service="#services=com.red5pro.media.storage.digitalocean.DOUploader,com.red5pro.media.storage.digitalocean.DOBucketLister"
        do_service_new="services=com.red5pro.media.storage.digitalocean.DOUploader,com.red5pro.media.storage.digitalocean.DOBucketLister"
        max_transcode_min="max.transcode.minutes=.*"
        max_transcode_min_new="max.transcode.minutes=30"

        do_spaces_access_key="do.access.key=.*"
        do_spaces_access_key_new="do.access.key=${NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY}"
        do_spaces_secret_key="do.secret.access.key=.*"
        do_spaces_secret_key_new="do.secret.access.key=${NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY}"
        do_spaces_bucket_name="do.bucket.name=.*"
        do_spaces_bucket_name_new="do.bucket.name=${NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME}"
        do_spaces_region="do.bucket.location=.*"
        do_spaces_region_new="do.bucket.location=${NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION}"
        do_spaces_bucket_files_access="# do.files.private=.*"
        do_spaces_bucket_files_access_new="do.files.private=${NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_FILE_ACCESS}"

        stream_dir="streams.dir=.*"
        stream_dir_new="streams.dir=$RED5_HOME/webapps/"

        sed -i -e "s|$do_service|$do_service_new|" -e "s|$stream_dir|$stream_dir_new|" -e "s|$max_transcode_min|$max_transcode_min_new|" -e "s|$do_spaces_access_key|$do_spaces_access_key_new|" -e "s|$do_spaces_secret_key|$do_spaces_secret_key_new|" -e "s|$do_spaces_bucket_name|$do_spaces_bucket_name_new|" -e "s|$do_spaces_region|$do_spaces_region_new|" -e "s|$do_spaces_bucket_files_access|$do_spaces_bucket_files_access_new|" "$RED5_HOME/conf/cloudstorage-plugin.properties"

        if [[ "$NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE" == "true" ]]; then

            if [[ "$NODE_CLOUDSTORAGE_POSTPROCESSOR_MP4_ENABLE" == "true" ]]; then
                PACKAGES=("${PACKAGES_DEFAULT[@]}")
                install_pkg
                log_i "Config Digital Ocean Cloudstorage plugin - PostProcessor to FLV and MP4: $RED5_HOME/conf/red5-common.xml"

                STR1='<property name="writerPostProcessors">\n<set>\n<value>com.red5pro.media.processor.OrientationPostProcessor</value>\n<value>com.red5pro.media.processor.DOUploaderPostProcessor</value>\n</set>\n</property>'
                sed -i "/Writer post-process example/i $STR1" "$RED5_HOME/conf/red5-common.xml"
                
                log_i "Copy FFMPEG to /usr/local/red5pro/"
                mv /usr/bin/ffmpeg /usr/local/red5pro/ffmpeg
                chmod +x /usr/local/red5pro/ffmpeg
            else
                log_i "Config Digital Ocean Cloudstorage plugin - PostProcessor to FLV: $RED5_HOME/conf/red5-common.xml"

                STR1='<property name="writerPostProcessors">\n<set>\n<value>com.red5pro.media.processor.DOUploaderPostProcessor</value>\n</set>\n</property>'
                sed -i "/Writer post-process example/i $STR1" "$RED5_HOME/conf/red5-common.xml"
            fi
        fi

        log_i "Config Digital Ocean Cloudstorage plugin - Live app DOFilenameGenerator in: $RED5_HOME/webapps/live/WEB-INF/red5-web.xml ..."

        local filenamegenerator='<bean id="streamFilenameGenerator" class="com.red5pro.media.storage.digitalocean.DOFilenameGenerator"/>'
        local filenamegenerator_new='-->\n<bean id="streamFilenameGenerator" class="com.red5pro.media.storage.digitalocean.DOFilenameGenerator"/>\n<!--'
        sed -i -e "s|$filenamegenerator|$filenamegenerator_new|" "$RED5_HOME/webapps/live/WEB-INF/red5-web.xml"
    else
        log_d "Red5Pro Digital Ocean Cloudstorage plugin (Spaces) - disable"
    fi

    ### Red5Pro Webhooks
    if [[ "$NODE_WEBHOOKS_ENABLE" == "true" ]]; then
        log_i "Red5Pro Webhooks - enable"
        if [ -z "$NODE_WEBHOOKS_ENDPOINT" ]; then
            log_e "Parameter NODE_WEBHOOKS_ENDPOINT is empty. EXIT."
            exit 1
        fi
        echo "webhooks.endpoint=$NODE_WEBHOOKS_ENDPOINT" >> $RED5_HOME/webapps/live/WEB-INF/red5-web.properties
    fi
    ### Red5Pro Round-trip-auth
    if [[ "$NODE_ROUND_TRIP_AUTH_ENABLE" == "true" ]]; then
        log_i "Red5Pro Round-trip-auth - enable"
        if [ -z "$NODE_ROUND_TRIP_AUTH_HOST" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_HOST is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_PORT" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_PORT is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_PROTOCOL" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_PROTOCOL is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE is empty. EXIT."
            exit 1
        fi
        if [ -z "$NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE" ]; then
            log_e "Parameter NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE is empty. EXIT."
            exit 1
        fi

        log_i "Configuration Live App red5-web.properties with MOCK Round trip server ..."
        {
            echo "server.validateCredentialsEndPoint=${NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE}"
            echo "server.invalidateCredentialsEndPoint=${NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE}"
            echo "server.host=${NODE_ROUND_TRIP_AUTH_HOST}"
            echo "server.port=${NODE_ROUND_TRIP_AUTH_PORT}"
            echo "server.protocol=${NODE_ROUND_TRIP_AUTH_PROTOCOL}://"
        } >> $RED5_HOME/webapps/live/WEB-INF/red5-web.properties

        log_i "Uncomment Round trip auth in the Live app: red5-web.xml"
        # Delete line with <!-- after pattern <!-- uncomment below for Round Trip Authentication-->
        sed -i '/uncomment below for Round Trip Authentication/{n;d;}' "$RED5_HOME/webapps/live/WEB-INF/red5-web.xml"
        # Delete line with --> before pattern <!-- uncomment above for Round Trip Authentication-->
        sed -i '$!N;/\n.*uncomment above for Round Trip Authentication/!P;D' "$RED5_HOME/webapps/live/WEB-INF/red5-web.xml"
    else
        log_d "Red5Pro Round-trip-auth - disable"
    fi
}

config_conference_message_svc() {
    log_i "Configuration ConferenceMessageService bean in ${RED5_HOME}/conf/red5pro-activation.xml"

    sed -i '/<!-- Uncomment to enable conferenceMessageService start/d' "${RED5_HOME}/conf/red5pro-activation.xml"
    sed -i '/Uncomment to enable conferenceMessageService end -->/d' "${RED5_HOME}/conf/red5pro-activation.xml"
}

config_kafka_hosts() {
    log_i "Configure Kafka Host in ${RED5_HOME}/conf/red5pro-activation.xml"

    local def_kafka_host='<property name="address" value="localhost:9092"/>'
    local def_kafka_host_new='<property name="address" value="'${KAFKA_HOST}':9092"/>'

    sed -i -e "s|$def_kafka_host|$def_kafka_host_new|" "${RED5_HOME}/conf/red5pro-activation.xml"
}

if [[ "$R5P_WEBINAR_ENABLE" == "true" ]]; then
    if [ -z "$KAFKA_HOST" ]; then
        log_w "Variable KAFKA_HOST is empty."
        var_error=1
    fi
    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"
        exit 1
    fi
    config_node_apps_plugins
    config_conference_message_svc
    config_kafka_hosts
else
    config_node_apps_plugins
fi