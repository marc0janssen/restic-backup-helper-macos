#!/bin/bash

# Name: Restic Backup Helper MacOS
# Coder: Marco Janssen (twitter @marc0janssen)
# date: 2022-01-16 22:43:01
# update: 2022-01-16 22:43:05

export RESTIC_CHECK_ARGS
export MAILX_ON_ERROR
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export RESTIC_REPOSITORY
export RESTIC_PASSWORD_COMMAND
export MAILX_ARGS

# *** These variables can be edited ***
RESTIC_CHECK_ARGS=""
MAILX_ON_ERROR="OFF"

# *** Please don't edit these variables ***
AWS_ACCESS_KEY_ID=$(security find-generic-password -s backup-restic-aws-access-key-id -w)
AWS_SECRET_ACCESS_KEY=$(security find-generic-password -s backup-restic-aws-secret-access-key -w)
RESTIC_REPOSITORY=$(security find-generic-password -s backup-restic-repository-remote -w)
RESTIC_PASSWORD_COMMAND='security find-generic-password -s backup-restic-password-repository -w'
MAILX_ARGS=""

lastcheckLogfile="$HOME/restic/log/check-last.log"
lasterrorchecklogfile="$HOME/restic/log/check-error-last.log"
lastMailLogfile="$HOME/restic/log/mail-last.log"
timestampfile="$HOME/restic/.restic_check_remote_timestamp"

copyErrorLog() {
  cp "${lastcheckLogfile}" "${lasterrorchecklogfile}"
}

logLast() {
  echo "$1" >> "${lastcheckLogfile}"
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

if [ -f "$HOME/restic/config/email.conf" ]; then

    while IFS='' read -r line || [[ -n "$line" ]]; do
        MAILX_ARGS="${MAILX_ARGS} ${line}"
    done < "$HOME/restic/config/email.conf"
fi

start=$(date +%s)
rm -f "${lastcheckLogfile}" "${lastMailLogfile}"

echo "Starting Check at $(date +"%Y-%m-%d %H:%M:%S")"
echo "Starting Check at $(date)" >> "${lastcheckLogfile}"
logLast "RESTIC_CHECK_ARGS: ${RESTIC_CHECK_ARGS}"
logLast "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
logLast "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"

/usr/local/bin/restic check ${RESTIC_CHECK_ARGS} >> "${lastcheckLogfile}" 2>&1
checkRC=$?
logLast "Finished check at $(date)"
if [[ $checkRC == 0 ]]; then
    echo "Check Successful"
    date -v +1m +"%s" > "${timestampfile}"
else
    echo "Check Failed with Status ${checkRC}"
    /usr/local/bin/restic unlock
    copyErrorLog
fi

end=$(date +%s)
echo "Finished check at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if { [ -n "${MAILX_ARGS}" ] && [ "${MAILX_ON_ERROR}" == "ON" ] && [[ $checkRC != 0 ]]; } || { [ -n "${MAILX_ARGS}" ] && [ "${MAILX_ON_ERROR}" != "ON" ]; }; then
    if sh -c "cat ${lastcheckLogfile} | mail -v -s 'Result of the last ${HOSTNAME} check run on ${RESTIC_REPOSITORY}' ${MAILX_ARGS} > ${lastMailLogfile} 2>&1"; then
        echo "Mail notification successfully sent."
    else
        echo "Sending mail notification FAILED. Check ${lastMailLogfile} for further information."
    fi
fi

