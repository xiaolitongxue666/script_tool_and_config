#Set user name and email
#git config --global user.name "Firstname Lastname"
#git config --global user.email "your_email@example.com"

#Show user name and email
git config user.name
git config user.email

#Set ui color
git config --global color.ui auto

#Set ssh key
ssh-keygen -t rsa -C "your_email@example.com"
#Generating public/private rsa key pair.
#Enter file in which to save the key
#(/Users/your_user_directory/.ssh/id_rsa):  "Press Enter"
#Enter passphrase (empty for no passphrase):  "Input password"
#Enter same passphrase again:  "Input password again"

#Now should show blow txt
#Your identification has been saved in /Users/your_user_directory/.ssh/id_rsa.
#Your public key has been saved in /Users/your_user_directory/.ssh/id_rsa.pub.
#The key fingerprint is:
#fingerprint value your_email@example.com
#The key's randomart image is:
#+--[ RSA 2048]----+
#| .+ + |
#| = o O . |

#Add ssh key
cat ~/.ssh/id_rsa.pub
#ssh-rsa  "Public key" your_email@example.com
ssh -T git@github.com
#The authenticity of host 'github.com (207.97.227.239)' can't be established.
#RSA key fingerprint is fingerprint value .
#Are you sure you want to continue connecting (yes/no)?  Input yes 

#If success will show blow
#Hi hirocastest! You've successfully authenticated, but GitHub does not 
#provide shell access.