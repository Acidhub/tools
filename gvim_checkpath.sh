#!/bin/bash
#
# Distributed under GPL-3, See: <http://www.gnu.org/licenses/gpl.html>
#
# Copyright (C) 2012~2014 Lara Maia <dev@lara.click>
#                         Fernando Manfredi <contact@acidhub.click>
#
# Versão: 3.2

### Global Variables ###
declare -r CONFIG="$HOME"/.config/$(basename $0).user
declare -r USER_SOCKET="gvim --servername GVIM_CHECKPATH"
declare -r ROOT_SOCKET="gvim --servername GVIM_ROOT_CHECKPATH"

function user_not_found() {
    echo -e '\nConfiguration file not found.'
    echo -e 'It is need for access files with root permissions.\n'
    read -s -p "Write your password: " pass
    echo "confUser=$USER" > "$CONFIG"
    echo "confPassword=$pass" >> "$CONFIG"
    echo -e "\n\nConfiguration Saved for your user\n"
    exit 0
}

function root_open() { #(pass, file)
(echo $1 | sudo -S -- bash -c eval\ "'$ROOT_SOCKET --remote-tab $2'")&>/dev/null
if [ $? != 0 ]; then
    echo -e "\nIncorrect password!\n"
    if [ -n "$confDebug" ]; then
        echo "[DEBUG] Config File:"
        echo $(cat "$CONFIG")
        echo "[DEBUG] pass: $confPassword"
    fi
    echo -e "Run again to fix this.\n"
    rm -f "$CONFIG"
    exit 1
fi
}

function check_server() { #(type, pass)
    if [ "$1" == "root" ]; then
        pgrep -U root -fx $ROOT_SOCKET >/dev/null 2>&1
        if [ $? != 0 ]; then
            if [ "$2" == "bypass" ]; then
                (eval $ROOT_SOCKET)&>/dev/null
            else
                (echo $2 | sudo -S -- bash -c eval\ "'$ROOT_SOCKET'")&>/dev/null
            fi
        fi
    else
        pgrep -U $USER -fx $USER_SOCKET >/dev/null 2>&1
        if [ $? != 0 ]; then
            (eval $USER_SOCKET) &
        fi
    fi
    # wait server start
    while true; do
        if [ "$1" == "root" ]; then
            gvim --serverlist | grep ${ROOT_SOCKET:18} >/dev/null 2>&1
            local ret=$?
        else
            gvim --serverlist | grep ${USER_SOCKET:18} >/dev/null 2>&1
            local ret=$?
        fi

        if [ $ret == 0 ]; then break; fi
        sleep .5
    done
}

# Fix Paths with spaces
IFS=$(echo -en "\n\b")

# Load Configuration (bypass if user is root)
if [ `id -u` != 0 ]; then
    source "$CONFIG" >/dev/null 2>&1 || user_not_found
fi

# Check and open files
for file in ${@}; do
    # if not is an absolute path, make it be
    test ${file:0:1} != "/" && file="$PWD/$file"

    owner=$(stat -c '%U' $file)

    if [ -n "$confDebug" ]; then
        echo "[DEBUG] owner: $owner ->> $file"
    fi

    # if already login with root user, use
    #the root socket and bypass sudo command
    if [ `id -u` == 0 ]; then
        check_server root bypass
        (eval $ROOT_SOCKET --remote-tab "$file") &
    # if file owner is root, use root socket
    elif [ "$owner" == 'root' ]; then
        check_server root $confPassword
        (root_open $confPassword "$file") &
    else
        check_server user $confPassword
        (eval $USER_SOCKET --remote-tab "$file") &
    fi

    sleep .3 # I/O Delay
done

exit 0

