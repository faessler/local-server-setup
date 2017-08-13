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

# HOMEBREW TAPS
brew tap Homebrew/bundle
brew tap homebrew/apache
brew tap homebrew/homebrew-php

# JQ COMMAND FOR FILTERING JSON FILES
brew install jq



# ============================= #
# INSTALLING APACHE (HTTPD24)
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