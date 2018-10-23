#! /bin/sh

trap ctrl_c INT
function ctrl_c() {
        echo "** Trapped CTRL-C"
	kill $mdns
}

OS=`uname -s`
if [[ "$OS" == 'Darwin' ]]; then
  dns-sd -R "My Test" _wssensorProv._tcp. local 8266 &
  mdns=$!
elif [[ "$OS" == 'Linux' ]]; then
  avahi-publish  -s "My Test" _wssensorProv._tcp. 8266 &
  mdns=$!
fi

lua luaOTAserver.lua images
