#!/bin/bash

##SERVERIP=192.168.2.50

echo "Dpkg::Progress-Fancy \"1\";" | sudo tee /etc/apt/apt.conf.d/99progressbar

#
# setup ppas
sudo add-apt-repository -y ppa:saiarcot895/myppa
sudo add-apt-repository -y ppa:git-core/ppa

#
# update repo and install prereqs
sudo apt-get update -qq
sudo apt-get install -y di git axel ssh apt-fast vlock tmux

#####################################
# need silent install of apt-fast
#####################################
./clean.sh


#
# update system 
sudo apt-fast dist-upgrade -y


# install hypervisor
sudo apt-fast install -y python-pytimeparse python-yaml ipvsadm meld

sudo mkdir -p /opt/vboxvdi
sudo cp -pr * /opt/vboxvdi
echo "vdiadmin ALL=(ALL) NOPASSWD: /opt/vboxvdi/ipvsadd.sh" to /etc/sudoers


# firewall stuff
sudo ufw enable
sudo ufw allow 3389


#VBOX
echo "deb http://download.virtualbox.org/virtualbox/debian yakkety contrib" | sudo tee /etc/apt/sources.list.d/vbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sudo apt-get update -qq
sudo apt-get install -y virtualbox-5.1


AFLAGS="--allow-overwrite=true --auto-file-renaming=false --conditional-get=true"

aria2c -x 8 -d /tmp http://download.virtualbox.org/virtualbox/LATEST.TXT
version=$(cat /tmp/LATEST.TXT)
aria2c -x 8 $AFLAGS http://download.virtualbox.org/virtualbox/${version}/Oracle_VM_VirtualBox_Extension_Pack-${version}.vbox-extpack

# prompts for passwd
#vboxmanage extpack install Oracle_VM_VirtualBox_Extension_Pack-5.1.18.vbox-extpack


#LYNIS
aria2c -x 8 $AFLAGS https://cisofy.com/files/lynis-2.4.6.tar.gz
sudo tar xvpf lynis-2.4.6.tar.gz -C /opt


aria2c -x 8 $AFLAGS https://releases.hashicorp.com/packer/0.12.3/packer_0.12.3_linux_amd64.zip
unzip packer_0.12.3_linux_amd64.zip


#
# secure system
echo "Securing Logon Screen"
sudo tee -a /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf > /dev/null <<EOF
allow-guest=false
greeter-show-manual-login=true
greeter-hide-users=true    
EOF

# vboxvdi service
echo "Setup service"
sudo -s cp -v vboxvdi.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable vboxvdi
sudo systemctl start vboxvdi
sudo systemctl status vboxvdi

# UFW setup

#
# Create VDI User
vdipass='$6$VULZjok1$8V7YYoddIJ23UCSQYI1Xua63ES1Qs6gJuWjt2HWAZCBmjJPqndQVgWBZfJ1HRosKfYpQE1ZUNqXffaaonj/6g/'
VDI_SSH_HOME=/home/VDI/.ssh
sudo useradd -s /bin/bash -m vdiadmin -p $vdipass

sudo mkdir -v /vdi 
sudo chown vdiadmin:vdiadmin /vdi 

# setup VDI users for sudo
##line=$(grep VDI ${KVMDIR}/hypervisors/sudoers)
##sudo sed  -i "/^root/ a  $line" /etc/sudoers


sudo reboot
