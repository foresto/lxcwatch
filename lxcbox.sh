#!/bin/sh

# Todo:
# ? rename -s to -f (fail)
# - by default, stop container only if we started it (and last instance)
# - option -S: stop container even if we did not start it (and last instance)
# - add nixwine and find_wine_prefix to this or lxcwatch project
#   - nixwine: if container was not already running with no lock, stop on exit

CONTAINER=$(basename "$0" .sh)
LOCKPATH="/var/lock/$(whoami).lxc.$CONTAINER.runlock"
RUNASUSER=ubuntu

usage() {
    echo "usage: $(basename "$0") [-s|-x|-t] [<command>]" >&2
    echo >&2
    echo "  Run a command (or shell) in lxc container '$CONTAINER'." >&2
    echo "  By default, the container will be started if necessary, and" >&2
    echo "  stopped afterward by the last active instance of this script." >&2
    echo >&2
    echo "  Options:" >&2
    echo "  -s Stop the container only if <command> fails." >&2
    echo "  -x Do not start or stop the container." >&2
    echo "  -t Test for another instance of this script. Ignore <command>." >&2
    echo >&2
    echo "  Script instances coordinate via flock $LOCKPATH" >&2
}

STARTSTOP=true
while getopts "n:sxXth" opt; do
    case $opt in
        n) CONTAINER="$OPTARG";;
        s) STARTSTOP=onfail;;
        x) STARTSTOP=;;
        X) COPYXAUTH=1;;
        t) ! flock --nonblock --exclusive "$LOCKPATH" true; exit;;
        ?) usage; exit 1;;
    esac
done
shift "$((OPTIND - 1))"

# Execute a command in the container, with X display support
run_in_container() {
  lxc-attach -n "$CONTAINER" --clear-env --keep-var TERM --keep-var DISPLAY -- \
    sudo -u $RUNASUSER -i "$@"
}

wait_for_container_services() {
    for _ in $(seq 1 9); do
        sleep 0.5
        if lxc-attach -n "$CONTAINER" -- hostname -I > /dev/null
            then break
        fi
    done
}

# Open a lock file with a chosen descriptor, and lock it in shared
# mode via that descriptor.  (It will close when this script exits.)
exec 8>"$LOCKPATH"
if ! flock --wait 5 --shared 8; then
    echo "Failed to lock $LOCKPATH. Is another instance exiting?" >&2
    exit 1
fi

if [ "$STARTSTOP" ]; then
    if ! lxc-wait -n "$CONTAINER" -s RUNNING -t 0; then
        printf "Starting %s..." "$CONTAINER" >&2
        lxc-start -n "$CONTAINER" -d || exit 1
        lxc-wait -n "$CONTAINER" -s RUNNING
        wait_for_container_services
        echo >&2
    fi
fi

if [ -n "$COPYXAUTH" ]; then
    xauth list "$DISPLAY" | sed 's/^.*\//add /' | run_in_container xauth
fi
run_in_container "$@"
RESULT="$?"

if [ "$STARTSTOP" = onfail ] && [ "$RESULT" = 0 ]; then
    echo "Command succeeded. Leaving $CONTAINER running." >&2
elif [ "$STARTSTOP" ]; then
    # Upgrade the lock to exclusive mode and stop the container.
    if flock --nonblock --exclusive 8; then
        printf "Stopping %s..." "$CONTAINER" >&2
        lxc-stop -n "$CONTAINER" -t 10
        rm "$LOCKPATH"
        echo >&2
    else
        echo "$CONTAINER is still in use. Leaving it running." >&2
    fi
fi

exit "$RESULT"
