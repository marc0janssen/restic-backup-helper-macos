#!/bin/sh

echo "***************************************************"
echo "*** Setting up Restic Buckup Helper MacOS 1.0.0 ***"
echo "***************************************************"
echo
echo "Set restic repository remote eg. s3:https://s3.eu-central-1.wasabisys.com/bucket"
security add-generic-password -s backup-restic-repository-remote -a restic_backup -w
echo
echo "Set restic repository password eg. my_super_duper_strong_password_2022!"
security add-generic-password -s backup-restic-password-repository -a restic_backup -w
echo
echo "Set restic aws-access-key-id eg. 9MJVEJ5XN2O1F8X3EWDE"
security add-generic-password -s backup-restic-aws-access-key-id -a restic_backup -w
echo
echo "Set restic aws-secret-access-key eg. wnW1fWn1zD4SrSqDvthaz3QdgWfffijKImUTD6i"
security add-generic-password -s backup-restic-aws-secret-access-key -a restic_backup -w

echo "Creating directories"
mkdir -p  ~/restic/log ~/restic/hooks ~/restic/config 

cp -R ./* ~/restic/

cp ~/restic/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/nl.mjanssen.restic_backup_remote.plist
launchctl load ~/Library/LaunchAgents/nl.mjanssen.restic_check_remote.plist
