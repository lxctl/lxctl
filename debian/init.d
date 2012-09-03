#!/bin/bash
# lxc containers starter script
# based on skeleton from Debian GNU/Linux
### BEGIN INIT INFO
# Provides:          lxc
# Required-Start:    $syslog $remote_fs mdadm
# Required-Stop:     $syslog $remote_fs mdadm
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Linux Containers
# Description:       Linux Containers
### END INIT INFO

NAME=lxc
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
DESC="LXC containers"

SCRIPTNAME="/etc/init.d/lxc"

. /lib/lsb/init-functions

if [ -f /etc/default/$NAME ] ; then
  . /etc/default/$NAME
fi

if [ "x$RUN" != "xyes" ] ; then
  log_success_msg "$NAME init script disabled; edit /etc/default/$NAME"
  exit 0
fi

start_one() {
  name=$1
  if [ -f "$CONF_DIR/$name/config" ]; then
    exec 12<&-
    if [[ $(grep autostart /etc/lxctl/"$name".yaml | awk '{print $2}') == 1 ]]; then
      lxctl start $name 
    fi
  else
    log_failure_msg "Can't find config file $CONF_DIR/$name.conf"
  fi
}

action_all() {
  action=$1
  nolog=$2
  for i in $(lxctl list --noheader --columns name | xargs); do
    [ -n "$nolog" ] || log_progress_msg "$i"
    $action $i
  done
  [ -n "$nolog" ] || log_end_msg 0
}

case "$1" in
  start)
    log_daemon_msg "Starting $DESC"
    action_all start_one
    ;;
  stop)
    log_daemon_msg "Stopping $DESC"
    action_all "lxctl stop"
    ;;
  restart|force-reload)
    log_daemon_msg "Restarting $DESC"
    action_all "lxctl stop"
    action_all start_one
    ;;
  destroy)
    log_daemon_msg "Destroying $DESC"
    action_all "lxc-destroy -n"
    ;;
  freeze)
    log_daemon_msg "Freezing $DESC"
    action_all "lxc-freeze -n"
    ;;
  unfreeze)
    log_daemon_msg "Unfreezing $DESC"
    action_all "lxc-unfreeze -n"
    ;;
  info)
    log_daemon_msg "Info on $DESC" "$NAME"
    log_end_msg 0
    action_all "lxc-info -n" "nolog"
    ;;
  *)
    log_success_msg "Usage: $SCRIPTNAME {start|stop|force-reload|restart|destroy|freeze|unfreeze|info}"
    exit 1
    ;;
esac

exit 0
