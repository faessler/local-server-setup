#!/usr/bin/env bash

#
# ╦  ╔═╗╔═╗╔═╗╦    ╔═╗╔═╗╦═╗╦  ╦╔═╗╦═╗  ╔═╗╔═╗╔╦╗╦ ╦╔═╗
# ║  ║ ║║  ╠═╣║    ╚═╗║╣ ╠╦╝╚╗╔╝║╣ ╠╦╝  ╚═╗║╣  ║ ║ ║╠═╝
# ╩═╝╚═╝╚═╝╩ ╩╩═╝  ╚═╝╚═╝╩╚═ ╚╝ ╚═╝╩╚═  ╚═╝╚═╝ ╩ ╚═╝╩
#
# © 2017 BY JAN FÄSSLER
#



# ============================= #
# VARIABLES
# ============================= #
# FONT STYLES
n=`tput sgr0` # normal
b=`tput bold` # bold
u=`tput smul` # underline

# TIMESTAMP
ts=`date "+%d.%m.%Y-%H:%M:%S"`

# USERNAME
usr=$USER



# ============================= #
# INSTALLING DEPENDENCIES
# ============================= #
# XCODE
xcode-select --install
echo Follow the Xcode guide and hit enter after installing it
read

# CHECK IF HOMEBREW IS INSTALLED
if ! which brew &>/dev/null
then
  echo ERROR: Homebrew is not installed! Please install Homebrew first to run this bashscript.
  exit 1
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



# ============================= #
# APACHE INSTALLATION
# ============================= #
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



# ============================= #
# APACHE CONFIGURATION
# ============================= #
# ADDING SITES DIRECTORY
mkdir ~/Sites/

# CHANGE DOCUMENT ROOT TO SITES
sed -i -e 's|DocumentRoot "/usr/local/var/www/htdocs"|DocumentRoot /Users/'$usr'/Sites|g' /usr/local/etc/apache2/2.4/httpd.conf
sed -i -e 's|<Directory "/usr/local/var/www/htdocs">|<Directory /Users/'$usr'/Sites>|g' /usr/local/etc/apache2/2.4/httpd.conf

# TODO:
# # AllowOverride controls what directives may be placed in .htaccess files.
# # It can be "All", "None", or any combination of the keywords:
# #   AllowOverride FileInfo AuthConfig Limit
# #
# AllowOverride None

# ENABLE MOD REWRITE
sed -i -e 's|#LoadModule rewrite_module libexec/mod_rewrite.so|LoadModule rewrite_module libexec/mod_rewrite.so|g' /usr/local/etc/apache2/2.4/httpd.conf

# USER AND GROUP
sed -i -e 's|User daemon|User '$usr'|g' /usr/local/etc/apache2/2.4/httpd.conf
sed -i -e 's|Group daemon|Group staff|g' /usr/local/etc/apache2/2.4/httpd.conf

# SERVER NAME
sed -i -e 's|#ServerName www.example.com:80|ServerName localhost|g' /usr/local/etc/apache2/2.4/httpd.conf

# SITES FOLDER
mkdir ~/Sites



# ============================= #
# PHP INSTALLATION
# ============================= #
# UNLINK EXISTING PHP
brew unlink php53 2>/dev/null
brew unlink php54 2>/dev/null
brew unlink php55 2>/dev/null
brew unlink php56 2>/dev/null
brew unlink php70 2>/dev/null
brew unlink php71 2>/dev/null

# INSTALL PHP VERSION FROM ARRAY
phpVersions=("55" "56" "70" "71")
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



# ============================= #
# APACHE PHP SETUP - PART 1
# ============================= #
# REMOVE LOAD PHP MODULES
for i in "${phpVersions[@]}"
do
    phpVersion=`brew info --json=v1 php$i | jq ".[] | .installed | .[] | .version" | tr -d '"'`
    sed -i -e 's|LoadModule php'${i:0:1}'_module        /usr/local/Cellar/php'$i'/'$phpVersion'/libexec/apache2/libphp'${i:0:1}'.so||g' /usr/local/etc/apache2/2.4/httpd.conf
done

# DIRECTORY INDEXES FOR PHP
# TODO:
#<IfModule dir_module>
#    DirectoryIndex index.php index.html
#</IfModule>
#
#<FilesMatch \.php$>
#    SetHandler application/x-httpd-php
#</FilesMatch>



# ============================= #
# PHP SWITCHER SCRIPT
# ============================= #
# INSTALLING SPHP
curl -L https://gist.github.com/w00fz/142b6b19750ea6979137b963df959d11/raw > /usr/local/bin/sphp
chmod +x /usr/local/bin/sphp

# TODO: CHECK YOUR PATH
# $ echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
# export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# APACHE PHP SETUP FOR SPHP
# TODO:
## Brew PHP LoadModule for `sphp` switcher
#LoadModule php5_module /usr/local/lib/libphp5.so
##LoadModule php7_module /usr/local/lib/libphp7.so

# SWITCHING PHP
sphp ${phpVersions[${#phpVersions[@]}-1]}