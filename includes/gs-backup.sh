# GRAVITY SYNC BY VMSTAN #####################
# gs-backup.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Backup Task
function task_backup {
    TASKTYPE='BACKUP'
    MESSAGE="${MESSAGE}: ${TASKTYPE} Requested"
    echo_good
    
    backup_settime
    backup_local_gravity
    backup_local_custom
    backup_cleanup
    
    logs_export
    exit_withchange
}

function backup_settime {
    BACKUPTIMESTAMP=$(date +%F-%H%M%S)
}

function backup_local_gravity {
    MESSAGE="Performing Backup of Local ${GRAVITY_FI}"
    echo_stat
    
    sqlite3 ${PIHOLE_DIR}/${GRAVITY_FI} ".backup '${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${GRAVITY_FI}.backup'"
    error_validate
}

function backup_local_custom {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            MESSAGE="Performing Backup Up Local ${CUSTOM_DNS}"
            echo_stat
            
            cp ${PIHOLE_DIR}/${CUSTOM_DNS} ${LOCAL_FOLDR}/${BACKUP_FOLD}/${BACKUPTIMESTAMP}-${CUSTOM_DNS}.backup
            error_validate
        fi
    fi
}

function backup_remote_gravity {
    MESSAGE="Performing Backup of Remote ${GRAVITY_FI}"
    echo_stat
    
    CMD_TIMEOUT='60'
    CMD_REQUESTED="sudo sqlite3 ${RIHOLE_DIR}/${GRAVITY_FI} \".backup '${RIHOLE_DIR}/${GRAVITY_FI}.backup'\""
    create_sshcmd
}

function backup_remote_custom {
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        MESSAGE="Performing Backup of Remote ${CUSTOM_DNS}"
        echo_stat
        
        CMD_TIMEOUT='15'
        CMD_REQUESTED="sudo cp ${RIHOLE_DIR}/${CUSTOM_DNS} ${RIHOLE_DIR}/${CUSTOM_DNS}.backup"
        create_sshcmd
    fi
}

function backup_cleanup {
    MESSAGE="Cleaning Up Old Backups"
    echo_stat
    
    find ${LOCAL_FOLDR}/${BACKUP_FOLD}/$(date +%Y)*.backup -mtime +${BACKUP_RETAIN} -type f -delete
    error_validate
}