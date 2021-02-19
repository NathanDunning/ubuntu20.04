# Ubuntu 20.04 Initial Setup

## Update Editor Default
`sudo update-alternatives --config editor`

## Installing Ansisble
`sudo apt install ansible`

### Configuring with Ansible
#### Install Libraries
The playbook `ansible/playbooks/setup.yml` installs the following:
  - Java
  - Node JS
  - Pip
  - Git
  - Docker
  - Docker Compose
  - Terraform
  - AWS CLI
  - Azure CLI
  - gcc
  - g++
  - curl
  - ca-certificates
  - apt-transport-https 
  - gnupg

Run playbook: `ansible-playbook -K ansible/playbooks/setup.yml`

#### Install Apps
The playbook `ansible/playbooks/apps.yml` installs the following applications:
  - Visual Studio Code
  - Brave Browser
  - Spotify
  - Discord
  - Slack
  - VLC
  
Note: VSCode will also require an installation of the 'SettingSync' extension to automatically configure from personal GitHub gist.<br>
  
Run playbook: `ansible-playbook -K ansible/playbooks/apps.yml`

## Configure SSH and GPG Keys
SSH: `ssh-keygen -t rsa -b 4096`
GPG: `gpg --default-new-key-algo rsa4096 --gen-key`

## Configure Git
TODO: Git config/proxy

## Other Applications
Applications downloaded manually through _Ubuntu Software_:
  - Stacer


## Installing i3 Windows Manager
https://kifarunix.com/install-and-setup-i3-windows-manager-on-ubuntu-20-04/
https://www.cyberithub.com/how-to-install-and-use-i3-window-manager-on-ubuntu-20-04/




## Other
https://www.reddit.com/r/linux4noobs/comments/lkbr65/learn_grep_sed_awk_perl_oneliners_with_hundreds/

