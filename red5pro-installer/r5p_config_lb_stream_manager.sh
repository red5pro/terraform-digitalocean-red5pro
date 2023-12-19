
# LB_SM_IP

RED5_HOME="/usr/local/red5pro"
CURRENT_DIRECTORY=$(pwd)

log_i() {
    log
    printf "\033[0;32m [INFO]  --- %s \033[0m\n" "${@}"
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

config_sm_properties_do(){
    log_i "Start configuration for Load balancer Stream Manager properties for Digital Ocean (DO)"
    if [ -z "$LB_SM_IP" ]; then
        log_w "Variable LB_SM_IP is empty."
        exit 1
    fi
    
    local streammanager_ip_pattern='streammanager.ip='
    local streammanager_ip_new="streammanager.ip=${LB_SM_IP}"
    
    sed -i -e "s|$streammanager_ip_pattern|$streammanager_ip_new|"  "$RED5_HOME/webapps/streammanager/WEB-INF/red5-web.properties"
    
}

config_sm_properties_do