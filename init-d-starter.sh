#!/bin/sh
#
# Init file for edudash restarter
#
# Install this with
#     sudo ln -s /opt/tsdapp/edudash/init-d-starter.sh /etc/init.d/restarter
#     sudo chkconfig --add restarter
#
# chkconfig: 345 95 05
# description: edudash restarter

. /etc/init.d/functions

case "$1" in
  start)
    echo "restarter is starting..."
    cd /opt/tsdapp/edudash-restartable/
    daemon --user=tsdapp "nohup" "grunt connect:rebuild &"
    success
  ;;
  stop)
    echo "restarter is shutting down..."
    pkill grunt
  ;;
  restart)
    $0 stop
    $0 start
  ;;
  status)
    if [[ ! $(ps -ef | grep -v grep | grep -cw "tsdapp.*grunt") == 0 ]]
    then
      echo $0 is running
    else
      echo $0 is not running
    fi
  ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
  ;;
esac
