#!/bin/sh
# Block until goMarkableStream is actually accepting connections on :2001.
#
# goMarkableStream is Type=simple, so systemd calls it "active" the instant it
# is exec'd — but it then scans xochitl's memory for the framebuffer pointer
# and only binds the port once that succeeds, seconds later. rm-agent connects
# on startup and panics if the port is not there yet, so without this wait the
# ordering dependency is a lie and rm-agent burns restarts losing the race.
#
# Port 2001 is 0x07D1; state 0A is LISTEN. Matching the state matters, since
# established connections to :2001 also show that port in the remote column.

port_is_listening() {
    awk '$2 ~ /:07D1$/ && $4 == "0A" { found = 1 } END { exit !found }' \
        /proc/net/tcp /proc/net/tcp6 2>/dev/null
}

i=0
while [ "$i" -lt 60 ]; do
    if port_is_listening; then
        exit 0
    fi
    sleep 2
    i=$((i + 1))
done

echo "wait-for-gomarkable: :2001 never came up after 120s" >&2
exit 1
