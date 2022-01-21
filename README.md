# restic-backup-helper-macos

## SETUP

### Give /bin/sh "full disk access"

* Open the Finder
* In the menu select GO -> Go To Folder...
* Enter /bin
* Then open System preferences of your Mac
* Open "Security and Privacy"
* Select the padlock bottomleft and unlock it
* Select "Full Disk Access" from the left pane
* Then drag and drop "sh" from the FInder to the right pane in "Full Disk Access"

[![drag and drop /bin/sh](https://github.com/marc0janssen/restic-backup-helper-macos/blob/main/media/full_disk_access_sh.gif?raw=true)][(https://github.com/marc0janssen/restic-backup-helper-macos/media/full_disk_access_sh.gif](https://github.com/marc0janssen/restic-backup-helper-macos/blob/main/media/full_disk_access_sh.gif?raw=true))
 

ADD /bin/sh ==> full disk access

brew tap discoteq/discoteq
brew install flock

brew install restic


Step 1. Edit Postfix config file

sudo vi /etc/postfix/main.cf

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

Step 2. Create the sasl_passwd file
sudo vi /etc/postfix/sasl_passwd
smtp.gmail.com:587 your_email@gmail.com:your_password
sudo postmap /etc/postfix/sasl_passwd

Step 3. Restart Postfix
sudo postfix reload

Step 4. Turn on less secure apps (Only Gmail)
SASL authentication failed

Step 5. Test it!
date | mail -s testing your_email@gmail.com
mailq
tail -f /var/log/mail.log


Acknowledgements:
https://szymonkrajewski.pl/macos-backup-restic/
https://github.com/lobaro/restic-backup-docker
https://www.developerfiles.com/how-to-send-emails-from-localhost-mac-os-x-el-capitan/
