#!/bin/bash
######################################
# Install and configure Kafka Server
######################################

current_directory=$(pwd)
packages=(build-essential openjdk-11-jdk unzip libva2 libva-drm2 libva-x11-2 libvdpau1 jsvc ntp wget)
kafka_log_dir="/var/log/kafka"

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

check_variables(){
    log_i "Check ENV variables..."
    
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

install_kafka() {
    log_i "Installating Kafka package archive version 3.5.2"
    curl -O -s https://dlcdn.apache.org/kafka/3.5.2/kafka_2.13-3.5.2.tgz
    kafka_archive=$(ls ${current_directory}/kafka_*.tgz | xargs -n 1 basename);
    tar -xzvf "${kafka_archive}" -C /usr/local/
    mv /usr/local/kafka_* /usr/local/kafka
    mkdir -p /var/log/kafka
    if [[ -d "/usr/local/kafka" ]]; then
        if [[ -d "/var/log/kafka/kraft-combined-logs" ]]; then
            log_i "Kafka log directory alraedy exists /var/log/kafka/kraft-combined-logs"
            chmod 777 -R /var/log/kafka/kraft-combined-logs
            sed 's/log.dirs=.*$/log.dirs=\/var\/log\/kafka\/kraft-combined-logs/' -i /usr/local/kafka/config/kraft/server.properties
        else
            log_i "Kafka log directory doesn't exists, creating /var/log/kafka/kraft-combined-logs"
            mkdir -p /var/log/kafka/kraft-combined-logs
            chmod 777 -R /var/log/kafka/kraft-combined-logs
            sed 's/log.dirs=.*$/log.dirs=\/var\/log\/kafka\/kraft-combined-logs/' -i /usr/local/kafka/config/kraft/server.properties
        fi

        GUID=`/usr/local/kafka/bin/kafka-storage.sh random-uuid`
        /usr/local/kafka/bin/kafka-storage.sh format -t $GUID -c /usr/local/kafka/config/kraft/server.properties
        
        sed 's/Xmx1G/Xmx2G/' -i /usr/local/kafka/bin/kafka-server-start.sh
        sed 's/Xms1G/Xms2G/' -i /usr/local/kafka/bin/kafka-server-start.sh
        
        sed 's/log.retention.check.interval.ms.*$/log.retention.check.interval.ms=900000/' -i /usr/local/kafka/config/server.properties
        sed 's/log.retention.hours.*$/log.retention.hours=24/' -i /usr/local/kafka/config/server.properties

        sed -i 's/^advertised.listeners/#&/' /usr/local/kafka/config/kraft/server.properties

        local def_kafka_listener='^listeners=.*'
        local def_kafka_listener_new='listeners=PLAINTEXT://'${KAFKA_HOST}':9092,CONTROLLER://:9093'

        sed -i -e "s|$def_kafka_listener|$def_kafka_listener_new|" "/usr/local/kafka/config/kraft/server.properties"

        # Set kafka log location to /var/log/kafka/kafka-logs
        if [[ -d "/var/log/kafka/kafka-logs" ]]; then
            log_i "Kafka log directory alraedy exists /var/log/kafka/kafka-logs"
            chmod 777 -R /var/log/kafka/kafka-logs
            sed 's/log.dirs=.*$/log.dirs=\/var\/log\/kafka\/kafka-logs/' -i /usr/local/kafka/config/server.properties
        else
            log_i "Kafka log directory doesn't exists, creating /var/log/kafka/kafka-logs"
            mkdir -p /var/log/kafka/kafka-logs
            chmod 777 -R /var/log/kafka/kafka-logs
            sed 's/log.dirs=.*$/log.dirs=\/var\/log\/kafka\/kafka-logs/' -i /usr/local/kafka/config/server.properties
        fi
    else
        log_e "Kafka server does not exists at path /usr/local/kafka"
        exit 1
    fi

    if [[ -f "${current_directory}/conf/kafka.service" ]]; then
        log_i "Kafka service file exists, configuring..."
        cp -r "${current_directory}/conf/kafka.service" /etc/systemd/system/kafka.service
    else
        log_e "Kafka service file does not exists"
        exit 1
    fi
}

start_kafka() {
    log_i "Start Kafka service"
    systemctl daemon-reload
    systemctl enable --now kafka.service
    systemctl restart kafka.service
    if [ "0" -eq $? ]; then
        log_i "Kafka service started!"
    else
        log_e "Kafka service didn't started!"
        log_e "Job for kafka.service failed, See systemctl status kafka.service and journalctl -xe for details."
        exit 1
    fi
}

if [[ "$TF_SVC_ENABLE" == true && "$R5P_WEBINAR_ENABLE" == true ]]; then
    log_i "TF_SVC_ENABLE and R5P_WEBINAR_ENABLE is set to true, Installing Red5 Pro Kafka Service on Terraform service server"
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
    install_pkg
    check_variables
    install_kafka
    start_kafka
else
    log_d "SKIP Red5 Pro Kafka Service installation."
fi