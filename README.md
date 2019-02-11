# [Odoo](https://www.odoo.com/documentation/12.0/setup/install.html#source-install "Odoo's Docs") v12 installation script
##### Tested on Ubuntu 18.04 (Bionic beaver) and Debian 9 (Stretch)

Script is based on https://github.com/Yenthe666/InstallScript but remastered and added couple features that I was missing in original one.

### List of new features added:
- Installation log output to stdout and file: odoo-install-log.txt
- User interaction as well as unattended setup
- Ability to add custom folders for modules, themes, etc
- Remastered to work with SystemD instead of SystemV
- OS flavor autodetect (Ubuntu or Debian but not the release number)
- Colored output in stdout
- Additional python3 modules added 

## How to use

##### 1. Download the script:
```
wget  https://raw.githubusercontent.com/Yenthe666/InstallScript/12.0/odoo_install.sh
```
or see releases for .tar or .zip sources
##### 2. Carfully modify parameters at the top section.
```
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
```

#### 3. Make the script executable
```
sudo chmod +x odoo_install_v12.sh
```
##### 4. Execute the script:
```
sudo ./odoo_install.sh
```
#### 5. Verify if any errors appear in the logfile 
```
cat odoo-install-log.txt | less
```
#### 6. Update Odoo config file to connect to Postgresql host or adjsut other options
```
sudo vi /etc/odoo/odoo-server.conf
```
