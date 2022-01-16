#!/bin/bash

export RESTIC_TAG
export RESTIC_FORGET_ARGS
export MAILX_ON_ERROR
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export RESTIC_REPOSITORY
export RESTIC_PASSWORD_COMMAND
export RESTIC_JOB_ARGS
export MAILX_ARGS

# *** These variables can be edited ***
RESTIC_TAG="MACBOOK_WERK"
RESTIC_FORGET_ARGS="--prune --keep-hourly 24 --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 10"
MAILX_ON_ERROR="OFF"

# *** Please don't edit these variables ***
AWS_ACCESS_KEY_ID="$(security find-generic-password -s backup-restic-aws-access-key-id -w)"
AWS_SECRET_ACCESS_KEY="$(security find-generic-password -s backup-restic-aws-secret-access-key -w)"
RESTIC_REPOSITORY="$(security find-generic-password -s backup-restic-repository-remote -w)"
RESTIC_PASSWORD_COMMAND='security find-generic-password -s backup-restic-password-repository -w'
RESTIC_JOB_ARGS="--files-from $HOME/restic/config/backup.conf"
MAILX_ARGS=""

lastLogfile="$HOME/restic/log/backup-last.log"
lasterrorlogfile="$HOME/restic/log/backup-error-last.log"
lastMailLogfile="$HOME/restic/log/mail-last.log"
timestampfile="$HOME/restic/.restic_backup_remote_timestamp"

copyErrorLog() {
  cp "${lastLogfile}" "${lasterrorlogfile}"
}

logLast() {
  echo "$1" >> "${lastLogfile}"
}

if [[ $(networksetup -getairportnetwork en0 | grep -E "You are not associated with an AirPort network") != "" ]]; then
  echo "$(date +"%Y-%m-%d %T") Not connected to WIFI network."
  exit 201
fi

if [[ $(pmset -g ps | head -1) =~ "Battery" ]]; then
  echo "$(date +"%Y-%m-%d %T") Computer is not connected to the power source."
  exit 202
fi

if [ -f "${timestampfile}" ]; then
  time_run=$(cat "${timestampfile}")
  current_time=$(date +"%s")

  if [ "${current_time}" -lt "${time_run}" ]; then
    exit 203
  fi
fi

cd "$HOME" || exit 1

if [ -f "$HOME/restic/config/email.conf" ]; then

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ -z "${MAILX_ARGS}" ]; then
            MAILX_ARGS=${line}
        else
            MAILX_ARGS="${MAILX_ARGS} ${line}"
        fi
    done < "$HOME/restic/config/email.conf"
fi

if [ -f "$HOME/restic/hooks/pre-backup.sh" ]; then
    echo "Starting pre-backup script ..."
    "$HOME/restic/hooks/pre-backup.sh"
else
    echo "Pre-backup script not found ..."
fi

start=$(date +%s)
rm -f "${lastLogfile}" "${lastMailLogfile}"
echo "Starting Backup at $(date +"%Y-%m-%d %H:%M:%S")"
echo "Starting Backup at $(date)" >> "${lastLogfile}"
logLast "RESTIC_TAG: ${RESTIC_TAG}"
logLast "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
logLast "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"
logLast "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
logLast "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"

# Do not save full backup log to logfile but to backup-last.log
/usr/local/bin/restic backup ${RESTIC_JOB_ARGS} --tag=${RESTIC_TAG?"Missing environment variable RESTIC_TAG"} >> "${lastLogfile}" 2>&1
backupRC=$?
logLast "Finished backup at $(date)"
if [[ $backupRC == 0 ]]; then
    echo "Backup Successful"
    date -v +6H +"%s" > "${timestampfile}"
else
    echo "Backup Failed with Status ${backupRC}"
    /usr/local/bin/restic unlock
    copyErrorLog
fi

if [[ $backupRC == 0 ]] && [ -n "${RESTIC_FORGET_ARGS}" ]; then
    echo "Forget about old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"
    /usr/local/bin/restic forget ${RESTIC_FORGET_ARGS} >> "${lastLogfile}" 2>&1
    rc=$?
    logLast "Finished forget at $(date)"
    if [[ $rc == 0 ]]; then
        echo "Forget Successful"
    else
        echo "Forget Failed with Status ${rc}"
        /usr/local/bin/restic unlock
        copyErrorLog
    fi
fi

end=$(date +%s)
echo "Finished Backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if { [ -n "${MAILX_ARGS}" ] && [ "${MAILX_ON_ERROR}" == "ON" ] && [[ $backupRC != 0 ]] ;} || { [ -n "${MAILX_ARGS}" ] && [ "${MAILX_ON_ERROR}" != "ON" ] ;}; then
    if sh -c "cat ${lastLogfile} | mail -v -s 'Result of the last ${HOSTNAME} backup run on ${RESTIC_REPOSITORY}' ${MAILX_ARGS} > ${lastMailLogfile} 2>&1" == 0 ; then
        echo "Mail notification successfully sent."
    else
        echo "Sending mail notification FAILED. Check ${lastMailLogfile} for further information."
    fi
fi

if [ -f "$HOME/restic/hooks/post-backup.sh" ]; then
    echo "Starting post-backup script ..."
    "$HOME/restic/hooks/post-backup.sh" $backupRC
else
    echo "Post-backup script not found ..."
fi
