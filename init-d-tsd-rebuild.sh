#!/bin/bash
### BEGIN INIT INFO
# Provides: tsdrebuild
# Required-Start: $local_fs $network
# Required-Stop: $local_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: tsdrebuild
# Description: TSD rebuild webhook service
### END INIT INFO
#
# /etc/init.d/tsdrebuild
#
# Control the TSD rebuild webhook service
#
# Install this with
#     sudo ln -s /opt/tsdapp/edudash/init-d-tsd-rebuild.sh /etc/init.d/tsdrebuild
#

APP_NAME="TSD rebuild webhook service"
PROCS_RUNNING=$(ps -ef | grep -v grep | grep -cw "tsdapp.*grunt")

case "$1" in
  start)
    echo -n "Starting $APP_NAME ... "
    if [ $PROCS_RUNNING -ne 0 ]
    then
      echo "maybe already started."
      exit 1
    fi
    cd /opt/tsdapp/edudash-restartable/
    su tsdapp -c 'grunt connect:rebuild &'
    echo "started."
  ;;
  stop)
    echo -n "Stopping $APP_NAME ... "
    su tsdapp -c 'pkill grunt'
    echo "stopped."
  ;;
  restart)
    echo "Restarting $APP_NAME ... "
    $0 stop; $0 start
  ;;
  status)
    echo -n "Status for $APP_NAME ... "
    if [ $PROCS_RUNNING -eq 0 ]
    then
      echo "not running."
    else
      echo "running."
    fi
  ;;
  *)
    echo "Usage: service tsdrebuild start"
    exit 1
  ;;
esac
