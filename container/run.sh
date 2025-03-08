#!/usr/bin/env bash

set -eux -o pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Check if the script is running as root and set LICENSE_DIR accordingly
if [ "$PGID" -eq 0 ]; then
  LICENSE_DIR=/root/.WolframEngine/Licensing
else
  LICENSE_DIR=/home/wljs/.WolframEngine/Licensing
fi


groupmod -o -g "$PGID" wljs
usermod -o -u "$PUID" wljs

function activate_wolframscript {
  if [ -z ${WOLFRAMID_USERNAME+x} -o -z ${WOLFRAMID_PASSWORD+x} ]; then
    # Manual activation
    su - wljs -c "wolframscript -activate"
    
    if [ $? -ne 0 ]; then
      echo "Activation failed, exiting."
      exit -1
    fi
  else
    su - wljs -c "expect << 'EOF'
    spawn sh -c {wolframscript -activate}
    
    expect \"Wolfram ID:\" {send \"$WOLFRAMID_USERNAME\r\"}
    expect \"Password:\" {send \"$WOLFRAMID_PASSWORD\r\"}
    
    lassign [wait] pid spawnpid os_error_flag value
    
    exit \$value
    EOF"

    if [ $? -ne 0 ]; then
      echo "Activation with provided credentials failed."
      exit -1
    fi
  fi

  if [ -f $LICENSE_DIR/mathpass ]; then
    # Activation success. 
    echo "Success!"
  else
    echo "License file missing after activation."
    exit -1
  fi
}

# Check if license exists else continue
if [ ! -f $LICENSE_DIR/mathpass ]; then
  activate_wolframscript
fi

chown -R wljs:wljs /wljs
chown -R wljs:wljs /home/wljs

nginx
su - wljs -c "wolframscript -f /wljs/Scripts/start.wls host 0.0.0.0 http 4000 ws 4001 ws2 4002 wsprefix ws ws2prefix ws2"
