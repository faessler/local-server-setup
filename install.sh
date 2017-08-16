#!/usr/bin/env bash

#
# ╦  ╔═╗╔═╗╔═╗╦    ╔═╗╔═╗╦═╗╦  ╦╔═╗╦═╗  ╔═╗╔═╗╔╦╗╦ ╦╔═╗
# ║  ║ ║║  ╠═╣║    ╚═╗║╣ ╠╦╝╚╗╔╝║╣ ╠╦╝  ╚═╗║╣  ║ ║ ║╠═╝
# ╩═╝╚═╝╚═╝╩ ╩╩═╝  ╚═╝╚═╝╩╚═ ╚╝ ╚═╝╩╚═  ╚═╝╚═╝ ╩ ╚═╝╩
#
# © 2017 BY JAN FÄSSLER
#



# ================================= #
# VARIABLES
# ================================= #
# FONT STYLES
n=`tput sgr0` # normal
b=`tput bold` # bold
u=`tput smul` # underline

# TIMESTAMP
ts=`date "+%d.%m.%Y-%H:%M:%S"`

# USERNAME
usr=$USER



# ================================= #
# INSTALLING DEPENDENCIES
# ================================= #
# XCODE
xcode-select --install
echo Follow the Xcode guide and hit enter after installing it
read

# CHECK IF HOMEBREW IS INSTALLED
if ! which brew &>/dev/null
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# UPDATE HOMEBREW
brew update
brew upgrade
brew cleanup

# HOMEBREW TAPS
brew tap Homebrew/bundle
brew tap homebrew/apache
brew tap homebrew/homebrew-php

# JQ COMMAND FOR FILTERING JSON FILES
brew install jq



# ================================= #
# APACHE INSTALLATION
# ================================= #
# SHUTDOWN AND STOP SYSTEM DELIVERED APACHE SERVER FROM AUTO-START
sudo apachectl stop
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null

# INSTALL APACHE WITH HTTPD24
brew install httpd24 --with-privileged-ports --with-nghttp2

# GET INSTALLED APACHE VERSION
apacheV=`brew info --json=v1 httpd24 | jq -r ".[] | .installed | .[] | .version"`

# SETUP HOMEBREW APACHE AUTO-START WITH PRIVILEGED ACCOUNT
sudo cp -v /usr/local/Cellar/httpd24/$apacheV/homebrew.mxcl.httpd24.plist /Library/LaunchDaemons
sudo chown -v root:wheel /Library/LaunchDaemons/homebrew.mxcl.httpd24.plist
sudo chmod -v 644 /Library/LaunchDaemons/homebrew.mxcl.httpd24.plist
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.httpd24.plist



# ================================= #
# MYSERVER STRUCTURE SETUP
# ================================= #
# CREATING MYSERVER DIR
mkdir -p /Users/$usr/Documents/MyServer

# ADDING & LINKING SITES
mkdir -p /Users/$usr/Sites
ln -sf /Users/$usr/Sites /Users/$usr/Documents/MyServer/Sites

# CREATING APACHE2 DIR
mkdir -p /Users/$usr/Documents/MyServer/apache2

# ADDING CUSTOM HTTPD CONF FILE
touch /Users/$usr/Documents/MyServer/apache2/httpd.conf

# INCLUDING CUSTOM OVERRIDE HTTPD CONF
if ! grep -q "Include /Users/$usr/Documents/MyServer/apache2/httpd.conf" /usr/local/etc/apache2/2.4/httpd.conf; then
    echo -e "\n\n# Including custom conf file\nInclude /Users/$usr/Documents/MyServer/apache2/httpd.conf\n\n\n" >> /usr/local/etc/apache2/2.4/httpd.conf
fi

# CREATING PHP DIR
mkdir -p /Users/$usr/Documents/MyServer/php



# ================================= #
# APACHE CONFIGURATION / OVERRIDE
# ================================= #
# SET DOCUMENT ROOT TO SITES
cat <<EOF >> /Users/$usr/Documents/MyServer/apache2/httpd.conf
#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
DocumentRoot /Users/$usr/Sites
<Directory /Users/$usr/Sites>
    #
    # Possible values for the Options directive are "None", "All",
    # or any combination of:
    #   Indexes Includes FollowSymLinks SymLinksifOwnerMatch ExecCGI MultiViews
    #
    # Note that "MultiViews" must be named *explicitly* --- "Options All"
    # doesn't give it to you.
    #
    # The Options directive is both complicated and important.  Please see
    # http://httpd.apache.org/docs/2.4/mod/core.html#options
    # for more information.
    #
    Options Indexes FollowSymLinks

    #
    # AllowOverride controls what directives may be placed in .htaccess files.
    # It can be "All", "None", or any combination of the keywords:
    #   AllowOverride FileInfo AuthConfig Limit
    #
    AllowOverride All

    #
    # Controls who can get stuff from this server.
    #
    Require all granted
</Directory>



EOF

# OVERRIDE DIRECTORY INDEXES FOR PHP
cat <<EOF >> /Users/$usr/Documents/MyServer/apache2/httpd.conf
#
# DirectoryIndex: sets the file that Apache will serve if a directory
# is requested.
#
<IfModule dir_module>
    DirectoryIndex index.html index.php
</IfModule>
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>



EOF

# LOAD MODULES
cat <<EOF >> /Users/$usr/Documents/MyServer/apache2/httpd.conf
#
# Dynamic Shared Object (DSO) Support
#
# To be able to use the functionality of a module which was built as a DSO you
# have to place corresponding LoadModule lines at this location so the
# directives contained in it are actually available _before_ they are used.
# Statically compiled modules (those listed by httpd -l) do not need
# to be loaded here.
#
# Example:
# LoadModule foo_module modules/mod_foo.so
#
LoadModule rewrite_module libexec/mod_rewrite.so



EOF

# SET USER AND GROUP
cat <<EOF >> /Users/$usr/Documents/MyServer/apache2/httpd.conf
#
# If you wish httpd to run as a different user or group, you must run
# httpd as root initially and it will switch.
#
# User/Group: The name (or #number) of the user/group to run httpd as.
# It is usually good practice to create a dedicated user and group for
# running httpd, as with most system services.
#
User $usr
Group staff



EOF

# SET SERVERNAME TO LOCALHOST
cat <<EOF >> /Users/$usr/Documents/MyServer/apache2/httpd.conf
#
# ServerName gives the name and port that the server uses to identify itself.
# This can often be determined automatically, but we recommend you specify
# it explicitly to prevent problems during startup.
#
# If your host doesn't have a registered DNS name, enter its IP address here.
#
ServerName localhost:80



EOF



# ================================= #
# PHP INSTALLATION
# ================================= #
# SET PHP VERSIONS TO INSTALL
phpVersions=("55" "56" "70" "71")

# UNLINK EXISTING PHP
brew unlink php53 2>/dev/null
brew unlink php54 2>/dev/null
brew unlink php55 2>/dev/null
brew unlink php56 2>/dev/null
brew unlink php70 2>/dev/null
brew unlink php71 2>/dev/null

# INSTALL PHP VERSION FROM ARRAY
for i in "${phpVersions[@]}"
do
	if ! [ "$(brew ls --versions php$i)" ];
	then
	    if [ $i == ${phpVersions[${#phpVersions[@]}-1]} ]
	    then
	        brew install php$i --with-httpd24
        else
            brew install php$i --with-httpd24
            brew unlink php$i
	    fi
    else
        if [ $i == ${phpVersions[${#phpVersions[@]}-1]} ]
        then
            brew reinstall php$i --with-httpd24
        else
            brew reinstall php$i --with-httpd24
            brew unlink php$i
        fi
	fi
done



# ================================= #
# APACHE PHP SETUP
# ================================= #
# REMOVE LOAD PHP MODULES
for i in "${phpVersions[@]}"
do
    phpVersion=`brew info --json=v1 php$i | jq ".[] | .installed | .[] | .version" | tr -d '"'`
    sed -ie 's|LoadModule php'${i:0:1}'_module        /usr/local/Cellar/php'$i'/'$phpVersion'/libexec/apache2/libphp'${i:0:1}'.so||g' /usr/local/etc/apache2/2.4/httpd.conf
done



# ================================= #
# PHP SWITCHER
# ================================= #
# INSTALLING SPHP
curl -L https://gist.github.com/w00fz/142b6b19750ea6979137b963df959d11/raw > /usr/local/bin/sphp
chmod +x /usr/local/bin/sphp

# TODO: CHECK YOUR PATH
# $ echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
# export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# APACHE PHP SETUP FOR SPHP
if ! grep -q "# Brew PHP LoadModule for \`sphp\` switcher" /usr/local/etc/apache2/2.4/httpd.conf; then
cat <<EOF >> /usr/local/etc/apache2/2.4/httpd.conf
# Brew PHP LoadModule for \`sphp\` switcher
LoadModule php5_module /usr/local/lib/libphp5.so
#LoadModule php7_module /usr/local/lib/libphp7.so



EOF
fi

# SWITCHING PHP
sphp ${phpVersions[${#phpVersions[@]}-1]}



# ================================= #
# INSTALLING PHP OPCACHE AND APCU
# ================================= #
for i in "${phpVersions[@]}"
do
    sphp $i
    if ! [ "$(brew ls --versions php$i-opcache)" ];
    then
	    brew install php$i-opcache
    else
        brew reinstall php$i-opcache
	fi
	if ! [ "$(brew ls --versions php$i-apcu)" ];
    then
	    brew install php$i-apcu
    else
        brew reinstall php$i-apcu
	fi
done



# ================================= #
# MYSQL
# ================================= #
# STOP RUNNING MYSQL SERVER
sudo mysqld stop
sudo mysql.server stop

# REMOVE DEFAULT MAC PORTS
sudo launchctl unload -w /Library/LaunchDaemons/org.macports.mysql.plist
sudo launchctl load -w /Library/LaunchDaemons/org.macports.mysql.plist

# INSTALL MYSQL
brew install mysql

# SET HOMEBREW MYSQL AS DEFAULT
ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist

# SECURE MYSQL INSTALLATION
mysql_secure_installation

# START MYSQL SERVER
mysql.server start



# ================================= #
# PHPMYADMIN
# ================================= #
# INSTALL PHPMYADMIN
mkdir /Users/$usr/Documents/MyServer/phpMyAdmin
wget -P /Users/$usr/Documents/MyServer/phpMyAdmin/ https://files.phpmyadmin.net/phpMyAdmin/4.7.3/phpMyAdmin-4.7.3-all-languages.tar.gz
tar -xvf /Users/$usr/Documents/MyServer/phpMyAdmin/phpMyAdmin-4.7.3-all-languages.tar.gz -C /Users/$usr/Documents/MyServer/phpMyAdmin/ --strip-components=1
rm /Users/$usr/Documents/MyServer/phpMyAdmin/phpMyAdmin-4.7.3-all-languages.tar.gz

# CREATE LINK FROM SITES
ln -s /Users/$usr/Documents/MyServer/phpMyAdmin /Users/$usr/Sites/_phpMyAdmin

# CREATE VHOST FOR PHPMYADMIN
# TODO