# GRAVITY SYNC BY VMSTAN #####################
# gs-smart.sh ################################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Smart Task
function task_smart {
    TASKTYPE='SMART'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good
    
    show_target
    validate_gs_folders
    validate_ph_folders
    validate_sqlite3
    validate_os_sshpass
    
    smart_gs
    exit
}

## Smart Sync Function
function smart_gs {
    MESSAGE="Starting ${TASKTYPE} Analysis"
    echo_info
    
    previous_md5
    md5_compare
    backup_settime
    
    PRIDBCHANGE="0"
    SECDBCHANGE="0"
    PRICLCHANGE="0"
    SECCLCHANGE="0"
    
    if [ "${primaryDBMD5}" != "${last_primaryDBMD5}" ]
    then
        PRIDBCHANGE="1"
    fi
    
    if [ "${secondDBMD5}" != "${last_secondDBMD5}" ]
    then
        SECDBCHANGE="1"
    fi
    
    if [ "${PRIDBCHANGE}" == "${SECDBCHANGE}" ]
    then
        if [ "${PRIDBCHANGE}" != "0" ]
        then
            MESSAGE="Both ${GRAVITY_FI} Have Changed"
            echo_warn
            
            PRIDBDATE=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "stat -c %Y ${RIHOLE_DIR}/${GRAVITY_FI}")
            SECDBDATE=$(stat -c %Y ${PIHOLE_DIR}/${GRAVITY_FI})
            
            if (( "$PRIDBDATE" >= "$SECDBDATE" ))
            then
                MESSAGE="Primary ${GRAVITY_FI} Last Changed"
                echo_warn
                
                pull_gs_grav
                PULLRESTART="1"
            else
                MESSAGE="Secondary ${GRAVITY_FI} Last Changed"
                echo_warn
                
                push_gs_grav
                PUSHRESTART="1"
            fi
        fi
    else
        if [ "${PRIDBCHANGE}" != "0" ]
        then
            pull_gs_grav
            PULLRESTART="1"
        elif [ "${SECDBCHANGE}" != "0" ]
        then
            push_gs_grav
            PUSHRESTART="1"
        fi
    fi
    
    if [ "${primaryCLMD5}" != "${last_primaryCLMD5}" ]
    then
        PRICLCHANGE="1"
    fi
    
    if [ "${secondCLMD5}" != "${last_secondCLMD5}" ]
    then
        SECCLCHANGE="1"
    fi
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        
        if [ -f "${PIHOLE_DIR}/${CUSTOM_DNS}" ]
        then
            
            if [ "${PRICLCHANGE}" == "${SECCLCHANGE}" ]
            then
                if [ "${PRICLCHANGE}" != "0" ]
                then
                    MESSAGE="Both ${CUSTOM_DNS} Have Changed"
                    echo_warn
                    
                    PRICLDATE=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "stat -c %Y ${RIHOLE_DIR}/${CUSTOM_DNS}")
                    SECCLDATE=$(stat -c %Y ${PIHOLE_DIR}/${CUSTOM_DNS})
                    
                    if (( "$PRICLDATE" >= "$SECCLDATE" ))
                    then
                        MESSAGE="Primary ${CUSTOM_DNS} Last Changed"
                        echo_warn
                        
                        pull_gs_cust
                        PULLRESTART="1"
                    else
                        MESSAGE="Secondary ${CUSTOM_DNS} Last Changed"
                        echo_warn
                        
                        push_gs_cust
                        PUSHRESTART="1"
                    fi
                fi
            else
                if [ "${PRICLCHANGE}" != "0" ]
                then
                    pull_gs_cust
                    PULLRESTART="1"
                elif [ "${SECCLCHANGE}" != "0" ]
                then
                    push_gs_cust
                    PUSHRESTART="1"
                fi
            fi
        else
            pull_gs_cust
            PULLRESTART="1"
        fi
    fi
    
    if [ "$PULLRESTART" == "1" ]
    then
        pull_gs_reload
    fi
    
    if [ "$PUSHRESTART" == "1" ]
    then
        push_gs_reload
    fi
    
    md5_recheck
    
    logs_export
    exit_withchange
}