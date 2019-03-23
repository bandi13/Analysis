#!/bin/bash

if [ ! -e ~/.docker_createUserBashrc ]; then
	echo "export PATH=$PATH:/usr/local/share/ghaas/bin" >> ~/.bash_login
	touch ~/.docker_createUserBashrc
fi
