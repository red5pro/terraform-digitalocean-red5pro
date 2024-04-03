#!/bin/bash
################################################
# Deploy Conference API WebApp to Watchparty SM
################################################

# DB_HOST="localhost"
# DB_PORT="3306"
# DB_USER="smuser"
# DB_PASSWORD="abc123"

current_directory=$(pwd)
RED5_HOME="/usr/local/red5pro"
packages=(mysql-client)

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

mysql_check_variables(){
    log_i "Check DB variables..."
    
    if [ -z "$DB_HOST" ]; then
        log_w "Variable DB_HOST is empty."
        var_error=1
    fi
    if [ -z "$DB_PORT" ]; then
        log_w "Variable DB_PORT is empty."
        var_error=1
    fi
    if [ -z "$DB_USER" ]; then
        log_w "Variable DB_USER is empty."
        var_error=1
    fi
    if [ -z "$DB_PASSWORD" ]; then
        log_w "Variable DB_PASSWORD is empty."
        var_error=1
    fi
    if [ -z "$SMTP_HOST" ]; then
        log_w "Variable SMTP_HOST is empty."
        var_error=1
    fi
    if [ -z "$SMTP_USERNAME" ]; then
        log_w "Variable SMTP_USERNAME is empty."
        var_error=1
    fi
    if [ -z "$SMTP_PASSWORD" ]; then
        log_w "Variable SMTP_PASSWORD is empty."
        var_error=1
    fi
    if [ -z "$FROM_ADDRESS" ]; then
        log_w "Variable FROM_ADDRESS is empty."
        var_error=1
    fi
    if [ -z "$SMTP_PORT" ]; then
        log_w "Variable SMTP_PORT is empty."
        var_error=1
    fi
    if [ -z "$FRONTEND_SERVER" ]; then
        log_w "Variable FRONTEND_SERVER is empty."
        var_error=1
    fi
    if [ -z "$KAFKA_HOST" ]; then
        log_w "Variable KAFKA_HOST is empty."
        var_error=1
    fi
    if [[ "$var_error" == "1" ]]; then
        log_e "One or more variables are empty. EXIT!"
        exit 1
    fi
}

install_pkg(){ 
    for i in {1..5};
    do
        local install_issuse=0;
        apt-get -y update --fix-missing &> /dev/null
        
        for index in ${!packages[*]}
        do
            log_i "Install utility ${packages[$index]}"
            apt-get install -y ${packages[$index]} &> /dev/null
        done
        
        for index in ${!packages[*]}
        do
            PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${packages[$index]}|grep "install ok installed")
            if [ -z "$PKG_OK" ]; then
                log_i "${packages[$index]} utility didn't install, didn't find MIRROR !!! "
                install_issuse=$((${install_issuse}+1));
            else
                log_i "${packages[$index]} utility installed"
            fi
        done
        
        if [ ${install_issuse} -eq 0 ]; then
            break
        fi
        if [ $i -ge 5 ]; then
            log_e "Something wrong with packages installation!!! Exit."
            exit 1
        fi
        sleep 20
    done
}

create_database_schema() {
    log_i "Create Database Schema for Conference API"
    mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p${DB_PASSWORD} -e "CREATE SCHEMA conference DEFAULT CHARACTER SET utf8mb4;"
}

config_conference_api() {

    if [[ -d "$RED5_HOME/webapps/conference-api" ]]; then
        log_i "Conference API webapp already exists $RED5_HOME/webapps/conference-api"
    elif [[ -d "$RED5_HOME/extras/conference-api" ]]; then
        log_i "Conference API webapp is available in $RED5_HOME/extras/conference-api, moving conference-api to $RED5_HOME/webapps"
        mv $RED5_HOME/extras/conference-api $RED5_HOME/webapps/
    else
        log_w "Conference API webapp does not exists in $RED5_HOME build"
    fi

    log_i "Configuration conference API properties in ${RED5_HOME}/webapps/conference-api/WEB-INF/applicationContext.xml"

    ESCAPED_FACEBOOK_APP_TOKEN=$(echo "$FACEBOOK_APP_TOKEN" | sed 's/|/\\|/g')

    local def_facebook_app_token='<property name="facebookAppToken" value=.*'
    local def_facebook_app_token_new="<property name=\"facebookAppToken\" value=\"${ESCAPED_FACEBOOK_APP_TOKEN}\" />"

    local def_db_host='<property name="dbHost" value=.*'
    local def_db_host_new='<property name="dbHost" value="'${DB_HOST}'" />'
    
    local def_db_port='<property name="dbPort" value=.*'
    local def_db_port_new='<property name="dbPort" value="'${DB_PORT}'" />'

    local def_db_user='<property name="dbUsername" value=.*'
    local def_db_user_new='<property name="dbUsername" value="'${DB_USER}'" />'

    local def_db_password='<property name="dbPassword" value=.*'
    local def_db_password_new='<property name="dbPassword" value="'${DB_PASSWORD}'" />'

    local def_smtp_host='<property name="smtpHost" value=.*'
    local def_smtp_host_new='<property name="smtpHost" value="'${SMTP_HOST}'" />'

    local def_smtp_port='<property name="smtpPort" value=.*'
    local def_smtp_port_new='<property name="smtpPort" value="'${SMTP_PORT}'" />'

    local def_smtp_username='<property name="login" value=.*'
    local def_smtp_username_new='<property name="login" value="'${SMTP_USERNAME}'" />'

    local def_smtp_password='<property name="password" value=.*'
    local def_smtp_password_new='<property name="password" value="'${SMTP_PASSWORD}'" />'

    local def_from_address='<property name="fromAddress" value=.*'
    local def_from_address_new='<property name="fromAddress" value="'${FROM_ADDRESS}'" />'	
	
    local def_frontend_server='<property name="frontEndServer" value=.*'
    local def_frontend_server_new='<property name="frontEndServer" value="'${FRONTEND_SERVER}'" />'

    local def_kafka_host='<property name="bootstrapAddress" value=.*'
    local def_kafka_host_new='<property name="bootstrapAddress" value="'${KAFKA_HOST}':9092" />'
		
	sed -i -e "s|$def_facebook_app_token|$def_facebook_app_token_new|" -e "s|$def_db_host|$def_db_host_new|" -e "s|$def_db_port|$def_db_port_new|" -e "s|$def_db_user|$def_db_user_new|" -e "s|$def_db_password|$def_db_password_new|" -e "s|$def_smtp_host|$def_smtp_host_new|" -e "s|$def_smtp_port|$def_smtp_port_new|" -e "s|$def_smtp_username|$def_smtp_username_new|" -e "s|$def_smtp_password|$def_smtp_password_new|" -e "s|$def_from_address|$def_from_address_new|" -e "s|$def_frontend_server|$def_frontend_server_new|" -e "s|$def_kafka_host|$def_kafka_host_new|" "${RED5_HOME}/webapps/conference-api/WEB-INF/applicationContext.xml"

}

config_conference_api_cors() {
    log_i "Configuration conference API CORS in ${RED5_HOME}/webapps/conference-api/WEB-INF/web.xml"

    local def_add_cors_filter_start='<!-- uncomment to add CorsFilter - ->'
    local def_add_cors_filter_start_new='<!-- uncomment to add CorsFilter -->'

    local def_add_cors_filter_end='<!- -  -->'
    local def_add_cors_filter_end_new=''

    sed -i -e "s|$def_add_cors_filter_start|$def_add_cors_filter_start_new|" -e "s|$def_add_cors_filter_end|$def_add_cors_filter_end_new|" "${RED5_HOME}/webapps/conference-api/WEB-INF/web.xml"
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

config_conference_service() {
    log_i "Disable conference service bean in ${RED5_HOME}/conf/red5pro-activation.xml"

    local def_conference_service_bean='<bean name="conferenceService" id="conferenceService" class="com.red5pro.service.conference.ConferenceService">'

    sed -i -e "/${def_conference_service_bean}/,+35d" "${RED5_HOME}/conf/red5pro-activation.xml"
}


if [[ "$R5P_WEBINAR_ENABLE" == true && "$SSL_ENABLE" == true ]]; then
    log_i "R5P_WEBINAR_ENABLE and SSL_ENABLE is set to true, Configuring Red5Pro webinar studio"
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
    mysql_check_variables
    install_pkg
    create_database_schema
    config_conference_api
    config_conference_api_cors
    config_conference_message_svc
    config_kafka_hosts
    config_conference_service
else
    log_d "SKIP Red5 Pro webinar studio configuration. Because 'https_letsencrypt_enable' and 'red5pro_truetime_studio_webinar_enable' is not enabled"
fi