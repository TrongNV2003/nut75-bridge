#!/bin/sh
# Install (or with "uninstall", remove) the nut75-bridge systemd service.
set -eu
cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
    echo "run as root: sudo $0 $*" >&2
    exit 1
fi

if [ "${1:-}" = "uninstall" ]; then
    systemctl disable --now nut75-bridge.service || true
    rm -f /usr/local/bin/nut75-bridge /etc/systemd/system/nut75-bridge.service
    systemctl daemon-reload
    echo "nut75-bridge removed"
    exit 0
fi

install -m 0755 nut75-bridge /usr/local/bin/nut75-bridge
install -m 0644 nut75-bridge.service /etc/systemd/system/nut75-bridge.service
systemctl daemon-reload
systemctl enable nut75-bridge.service
systemctl restart nut75-bridge.service
systemctl --no-pager status nut75-bridge.service | head -n 5
echo "logs: journalctl -u nut75-bridge -f"
