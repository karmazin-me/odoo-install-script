#!/bin/bash

# Made in NYC <3
# Author Eugene Karmazin
# ekarmazin@b2bsoft.com

# Odoo Enterprise installation script based on idea of
# https://github.com/Yenthe666/InstallScript/blob/12.0/odoo_install.sh
# Optimized for Systemd on Ubuntu 18.04 and Debian Stretch

###############################################################################
#### Please customize per your needs this part only, rest should be untouched #
###############################################################################
# User to run Odoo Server
OE_USER="odoo"

# Odoo admin login password
OE_SUPERADMIN="admin"

# Path to Odoo files installation. By FHS it should be located in /opt folder
OE_HOME="/opt/$OE_USER"

# Update in case you need to have a different version in a different directory
OE_HOME_EXT="${OE_HOME}/${OE_USER}-server"

# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"

# Choose the Odoo version which you want to install. For example: 12.0, 11.0, 10.0 or saas-18. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 12.0
OE_VERSION="12.0"

# Name of the config file. Default is suggested.
OE_CONFIG="${OE_USER}-server"

###############################################################################
#### All set. Stop editing here. Save and run the script with sudo ############
###############################################################################

### DO NOT EDIT THE SCRIPT BEHIND THIS LINE, LET MAGIC TO DO THE JOB FOR YOU ##
###############################################################################
# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
# file logfile.tx will be created with stdout and sdterr messages
exec > >(tee -i odoo-install-log.txt)
exec 2>&1
###############################################################################

# Check if the tput is presented in system
# Set variables to control color in the output messages
if [ $(find /usr/bin -type f -name 'tput') ]; then
    red=`tput setaf 1`
    green=`tput setaf 2`
    yellow=`tput setaf 3`
    white_bg=`tput setab 7`
    reset=`tput sgr0`
else
    red=""
    green=""
    yellow=""
    white_bg=""
    reset=""
fi

# The script must be executed with sudo, otherwise root (not recommended)
if [ $EUID != 0 ]; then
    echo -ne "\t\t${red}${white_bg}  WARNING!!!  ${reset}\n"
    echo -ne "\n${red}  Please re-run this script with sudo or as root ${reset} \n\n"
    exit 1
fi

echo -ne "\n \t ${yellow}Welcome to the Odoo Enterprise v${OE_VERSION} installation script!  ${reset}\n\n"

# Get the OS flavor and set corresponding variable or stop execution
if [ $(uname -a | egrep -io 'debian|ubuntu') ]; then
    # Check if installation designed for Ubuntu or Debian
    if [ $(uname -a | grep -io 'debian') ]; then
        IS_IT_UBUNTU=false
    else
        IS_IT_UBUNTU=true
    fi
else
  echo -ne "\n \t ${red}${white_bg} !!! ERROR !!! ERROR !!! ERROR !!! ${reset}\n"
  echo -ne "\n ${red} This operating system is not supported yet! Please run this script on ${green}Ubuntu 18.04 or Debian Stretch ${reset}\n\n"
  exit 1
fi
################################################################################

# User input is covered here
#
echo -ne "\n ${green}Answer these questions to begin installation process \n${reset}"
echo -ne "\n ${green}Answering time is ${red}${white_bg}30 seconds${reset}${green}, otherwise defaults will be selected ${reset}\n"
echo -ne "\n TIP: press CTRL + C to interrupt the installation process at any time \n\n"

# WKHTMLTOPDF installation
read -t 40 -e -p "${yellow}Do you want to install WKHTMLTOPDF? (y/n): ${reset}" -i "yes" WKHTMLTOPDF_ANSWER

case ${WKHTMLTOPDF_ANSWER:0:1} in
      [nN] )
              echo -ne "\n ${red} WKHTMLTOPDF will NOT be installed ${reset}\n\n"
              INSTALL_WKHTMLTOPDF=false
              ;;
        * )
              echo -ne "\n ${green} OK, WKHTMLTOPDF will be installed ${reset}\n\n"
              INSTALL_WKHTMLTOPDF=true
              ;;
esac

# Enterprise or Community edition installation. By default this script is designed for the Enterprise verison.
read -t 30 -e -p "${yellow}Do you want to install Odoo Enterprise edition? (y/n): ${reset}" -i "yes" ENTERPRISE_ANSWER

case ${ENTERPRISE_ANSWER:0:1} in
        [nN] )
                echo -ne "\n ${red} OK, Community edition will be installed ${reset}\n\n"
                IS_ENTERPRISE=false
                ;;
        * )
                echo -ne "\n ${green} OK, Enterprise edition will be installed ${reset}\n\n"
                IS_ENTERPRISE=true
                ;;
esac

# Install full PostgreSQL server on local host or just a client to connec to remote database
# In case with client only installation, the database host must be specified in the Odoo config file
read -t 30 -e -p "${yellow}Do you want to install PostgreSQL locally? (y/n): ${reset}" -i "no" POSTGRES_ANSWER

case ${POSTGRES_ANSWER:0:1} in
        [yY] )
                echo -ne "\n ${green} OK, PostgreSQL will be installed locally ${reset}\n\n"
                INSTALL_POSTGRES=true
                ;;
        * )
                echo -ne "\n ${green} PostgreSQL Client will be installed instead ${reset}\n\n"
                INSTALL_POSTGRES=false
                ;;
esac

# Additional tools like Webmin
read -t 30 -e -p "${yellow}Do you want to install Webmin? (y/n): ${reset}" -i "no" WEBMIN_ANSWER

case ${WEBMIN_ANSWER:0:1} in
        [yY] )
                echo -ne "\n ${green} OK, Webmin will be installed locally ${reset}\n\n"
                WEBMIN=true
                ;;
        * )
                echo -ne "\n ${red} Skipping Webmin installation ${reset}\n\n"
                WEBMIN=false
                ;;
esac

# Additional and custom derictories to make
read -t 30 -e -p "${yellow}Do you want to add custom directories? (y/n): ${reset}" -i "no" DIR_ANSWER

case ${DIR_ANSWER:0:1} in
        [yY] )
                echo -ne "\n ${green} Custom derictories selection. Default is: $OE_HOME/custom/addons ${reset}\n\n"
                read -e -p "${yellow}Enter full path to dirs (separate multiple paths by a single space)${reset}:" -i "$OE_HOME/themes " ADD_DIR_PATH
                ;;
        * )
                echo -ne "\n ${red} OK, default one at $OE_HOME/custom/addons will be created ${reset}\n\n"
                ;;
esac

###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64  === (for other distributions please replace these two links,
	if ${IS_IT_UBUNTU};
		then
			WKHTMLTOX_X64=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
		else
			WKHTMLTOX_X64=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
	fi

# WEBMIN tool to install at the end of the script
if ${WEBMIN}; then

### Install Webmin Dependencies
echo -e "\n ${green} ---- Installing Webmin dependencies----${reset}\n"
cat <<EOF > /etc/apt/sources.list.d/webmin.list
deb http://download.webmin.com/download/repository sarge contrib
deb http://download.webmin.com/download/repository sarge contrib
EOF
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
  INSTALL_WEBMIN=`apt-get -qq update  && apt-get -qq install webmin  > /dev/null`
fi

#--------------------------------------------------
# Update apt database
#--------------------------------------------------
echo -ne "\n${green} ---- Update apt database---- ${reset}\n"

# universe package is for Ubuntu 18.x
if ${IS_IT_UBUNTU}; then
	add-apt-repository universe
fi

apt-get -qq update ;
apt-get -qq upgrade

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
if ${INSTALL_POSTGRES}; then
  echo -ne "\n${green}---- Install PostgreSQL Server ---- ${reset}\n\n"
  apt-get -qq install postgresql
  echo -ne "\n${green}---- Creating the ODOO PostgreSQL User  ---- ${reset}\n\n"
  su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true
else
# Install latest postgresql-client
  echo -ne "\n${green}---- Installing PostgreSQL Client---- ${reset}\n\n"
  touch /etc/apt/sources.list.d/pgdg.list
  bash -c 'echo '\''deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main'\'' > /etc/apt/sources.list.d/pgdg.list'
  export GNUPGHOME="$(mktemp -d)"
  repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}"
  gpg --armor --export "${repokey}" | apt-key add -
  gpgconf --kill all
  rm -rf "$GNUPGHOME"
  apt-get -qq update;
  apt-get -qq install  postgresql-client
fi

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -ne "\n${green}--- Installing Python + pip --${reset}\n\n"
apt-get -qq update ;
apt-get -qq install ibjpeg-dev curl wget git python-pip gdebi-core python-dev libxml2-dev libxslt1-dev zlib1g-dev libldap2-dev libsasl2-dev node-clean-css node-less python-gevent
apt-get -qq install python3 python3-pip

echo -ne "\n${green}---- Install tool packages ----${reset}\n\n"
apt-get -qq install wget git bzr python-pip gdebi-core ca-certificates curl dirmngr fonts-noto-cjk gnupg libssl1.0-dev xz-utils

echo -ne "\n${green}---- Install python packages ----${reset}\n\n"
apt-get -qq install libxml2-dev libxslt1-dev zlib1g-dev
apt-get -qq install libsasl2-dev libldap2-dev libssl-dev

# Install official recommendations.txt from here: https://raw.githubusercontent.com/odoo/odoo/12.0/requirements.txt
curl -O https://raw.githubusercontent.com/odoo/odoo/12.0/requirements.txt;
pip3 install -q -r requirements.txt

# Add rest python modules widely used
apt-get -qq install python-openid python-libxslt1 python-pil python-pychart python3-suds python-yaml python-zsi python-webdav
pip3 install gdata ninja2 paramiko psycogreen pysftp pyyaml simplejson tz unittest2 -q

echo -ne "\n${green}---- Install python libraries ----${reset}\n\n"

echo -ne "\n${green}--- Install other required packages ----${reset}\n\n"
apt-get -qq install node-clean-css
apt-get -qq install node-less
apt-get -qq install python-gevent



#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if $INSTALL_WKHTMLTOPDF; then
  echo -ne "\n${green} ---- Install wkhtml and place shortcuts on correct place for ODOO 12 ---- ${reset}\n"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  wget $_url
  gdebi --n `basename $_url`
  ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "\n${red}Wkhtmltopdf isn't installed due to the choice of the user! ${reset}\n"
fi

# Addind system user/group with home at /opt dir
echo -ne "\n${green}---- Create ODOO system user ---- ${reset}\n"
adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

#The user should also be added to the sudo'ers group.
adduser $OE_USER sudo

echo -ne "\n${green}---- Create Log directory ---- ${reset}\n"
mkdir /var/log/$OE_USER
chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -ne "\n${green} ==== Installing ODOO Server ==== ${reset}\n"
git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if ${IS_ENTERPRISE}; then
    # Odoo Enterprise install!
    echo -ne "\n--- Create symlink for node ---- ${reset}\n"
    ln -s /usr/bin/nodejs /usr/bin/node
    su $OE_USER -c "mkdir -p $OE_HOME/enterprise"
    su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n ${red}${white_bg} ------------------------WARNING------------------------------${reset}\n"
        echo "${red}Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " ${reset}\n"
        GITHUB_RESPONSE=$(git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -ne "\n${green}---- Added Enterprise code under $OE_HOME/enterprise/addons ---- ${reset}\n"
    echo -ne "\n${green}---- Installing Enterprise specific libraries ---- ${reset}\n"
    pip3 install num2words ofxparse
    curl -sL https://deb.nodesource.com/setup_10.x | bash -
    apt-get -qq install nodejs npm
    npm install -g less
	npm install -g rtlcss
    npm install -g less-plugin-clean-css
fi

# Creating directories and custom directories form user input
# Making default ones with sub directories
echo -ne "${green}\n---- Create module directory ----${reset}\n"
su $OE_USER -c "mkdir -p $OE_HOME/custom/addons"

# Check if any in the user input are presented, if yes - make them
# ADD_DIR_PATH is a variable from user input
if [ ${#ADD_DIR_PATH[@]} -ne 0 ]; then
      for i in $ADD_DIR_PATH; do
        echo -ne "${green}\n ---- Create a custom dir $i ---- \n${reset}"
        mkdir -p $i
      done
fi

echo -ne "${green}\n ---- Setting permissions on Odoo folder ---- \n${reset}"
chown -R $OE_USER:$OE_USER $OE_HOME/*

# Basic config file, you can add/remove additional stuff later after installation
echo -ne "\n${green} ---- Create server config file ----${reset}\n"

# Create a dummy config file with abiluty to connect ot external PostgreSQL
mkdir -p /etc/odoo;
touch /etc/odoo/${OE_CONFIG}.conf
echo -ne "${green} Creating server config file"
su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/odoo/${OE_CONFIG}.conf"

su root -c "printf ';db_host = \n' >> /etc/odoo/${OE_CONFIG}.conf"
su root -c "printf ';db_user = \n' >> /etc/odoo/${OE_CONFIG}.conf"
su root -c "printf ';db_password = \n' >> /etc/odoo/${OE_CONFIG}.conf"
su root -c "printf 'db_port = 5432\n' >> /etc/odoo/${OE_CONFIG}.conf"
su root -c "printf ';db_sslmode = prefer' >> /etc/odoo/${OE_CONFIG}.conf"
su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/odoo/${OE_CONFIG}.conf"
su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/odoo/${OE_CONFIG}.conf"

su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/odoo/${OE_CONFIG}.conf"

if ${IS_ENTERPRISE}; then
  # Check if user made an input for additional directories
  if [ ${#ADD_DIR_PATH[@]} -ne 0 ]; then
    su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons,${ADD_DIR_PATH// /,}\n' >> /etc/odoo/${OE_CONFIG}.conf"
  else
    su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons\n' >> /etc/odoo/${OE_CONFIG}.conf"
  fi
else
    # For plain Community Edition
    if [ ${#ADD_DIR_PATH[@]} -ne 0 ]; then
      su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons,${ADD_DIR_PATH// /,}\n' >> /etc/odoo/${OE_CONFIG}.conf"
    else
      su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> /etc/odoo/${OE_CONFIG}.conf"
    fi
fi
chown ${OE_USER}:${OE_USER} /etc/${OE_CONFIG}.conf
chmod 640 /etc/${OE_CONFIG}.conf

echo -ne "\n${green} Create startup file ${reset}\n"
su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/openerp-server --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (Systemd unit)
#--------------------------------------------------

echo -e " Create a Systemd unit file"
cat <<EOF > ~/$OE_CONFIG
[Unit]
Description=Odoo Open Source ERP and CRM
After=network.target

[Service]
Type=simple
User=${OE_USER}
Group=${OE_USER}
ExecStart=${OE_HOME_EXT}/odoo-bin --config /etc/odoo/${OE_CONFIG}.conf --logfile /var/log/odoo/${OE_CONFIG}.log
KillMode=mixed

[Install]
WantedBy=multi-user.target

EOF

mv ~/${OE_CONFIG} /lib/systemd/system/${OE_CONFIG}.service
ln -s  /system/multi-user.target.wants/${OE_CONFIG}.service /etc/systemd/system/multi-user.target.wants/${OE_CONFIG}.service
chmod 644 /lib/systemd/system/${OE_CONFIG}.service
chown root:root /lib/systemd/system/${OE_CONFIG}.service

echo -e "* Start ODOO on Startup"
systemctl enable odoo-server.service

echo -e "Systemd is Starting Odoo Service"
systemctl start odoo-server.service

echo -ne "\n${green}-----------------------------------------------------------${reset}\n"
echo -e "${green}Done! The Odoo server is up and running. Specifications:${reset}\n\n"
echo -e "${green}Port: $OE_PORT ${reset}"
echo -e "${green}User service: $OE_USER ${reset}"
echo -e "${green}User PostgreSQL: $OE_USER ${reset}"
echo -e "${green}Code location: $OE_USER ${reset}"
echo -e "${green}Addons folder: $OE_USER/$OE_CONFIG/addons/ ${reset}"
echo -e "${yellow}Start Odoo service: sudo systemctl start $OE_CONFIG ${reset}"
echo -e "${yellow}Stop Odoo service: sudo systemctl stop $OE_CONFIG  ${reset}"
echo -e "${yellow}Restart Odoo service: sudo systemctl restart $OE_CONFIG  ${reset}"

${INSTALL_WEBMIN}

exit 0
