# restic-backup-helper-macos

## SETUP

### /bin/sh "full disk access"

* Open the Finder
* In the menu select GO -> Go To Folder...
* Enter /bin
* Then open System preferences of your Mac
* Open "Security and Privacy"
* Select the padlock bottomleft and unlock it
* Select "Full Disk Access" from the left pane
* Then drag and drop "sh" from the FInder to the right pane in "Full Disk Access"

![Drag And Drop /bin/sh](https://github.com/marc0janssen/restic-backup-helper-macos/blob/main/media/full_disk_access_sh.gif?raw=true "Drag And Drop /bin/sh")

### Install 'flock'

```shell
brew tap discoteq/discoteq
brew install flock
```

### Install 'restic'

``` shell
brew install restic
```

### Config 'Postfix'

Step 1. Edit Postfix config file

``` shell
sudo vi /etc/postfix/main.cf
```

Now add the following lines at the very end of the file:
(note: You can use any mailprovider you want, here an example with Gmail)

```shell
#Gmail SMTP
relayhost=smtp.gmail.com:587
# Enable SASL authentication in the Postfix SMTP client.
smtp_sasl_auth_enable=yes
smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options=noanonymous
smtp_sasl_mechanism_filter=plain
# Enable Transport Layer Security (TLS), i.e. SSL.
smtp_use_tls=yes
smtp_tls_security_level=encrypt
tls_random_source=dev:/dev/urandom
```

Step 2. Create the sasl_passwd file

```shell
sudo vi /etc/postfix/sasl_passwd
smtp.gmail.com:587 your_email@gmail.com:your_password
sudo postmap /etc/postfix/sasl_passwd
```

Step 3. Restart Postfix

```shell
sudo postfix reload
```

Step 4. Turn on less secure apps (Only Gmail)

```shell
SASL authentication failed
```

Step 5. Test it!

```shell
date | mail -s testing your_email@gmail.com
mailq
tail -f /var/log/mail.log
```

### Install 'Restic Backup Helper MacOS'

Step 1.\
Download this package to your download directory on your Mac

Step 2.\
Unzip the package

Step 3.\
Edit nl.mjanssen.restic_backup_remote.plist and nl.mjanssen.restic_check_remote.plist to match your HOME directory

Step 4.\
Edit backup.conf and email.conf to your liking.\
email.conf hold the addresses with receive the backlog\
backup.conf holds the subdirectories from your $HOME to get backuped

Step 5.\
Set up the variables in "restic_backup_remote.sh" and "restic_check_remote,sh" to your liking

Step 6.\
Run the 'install.sh' script

step 7.\
Fill out the 4 questions asked from the script

step 8.\
**All Systems Are Go Go GO**

## Acknowledgements

[https://szymonkrajewski.pl/macos-backup-restic/](https://szymonkrajewski.pl/macos-backup-restic/)\
[https://github.com/lobaro/restic-backup-docker](https://github.com/lobaro/restic-backup-docker)\
[https://www.developerfiles.com/how-to-send-emails-from-localhost-mac-os-x-el-capitan/](https://www.developerfiles.com/how-to-send-emails-from-localhost-mac-os-x-el-capitan/)
