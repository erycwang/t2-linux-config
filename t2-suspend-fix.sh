#!/bin/bash
# /etc/systemd/system-sleep/t2-suspend-fix.sh
#
# Suspend/resume fix for 2020 13" MacBook Pro (Touch Bar) running Linux.
# Targets the Apple T2 security chip and BCM4364 WiFi hardware.
#
# The T2 chip exposes internal devices (keyboard, trackpad, touch bar,
# audio) via the apple-bce driver over a virtual PCIe bus. Without
# unloading these modules before sleep, the system hangs on suspend.
# brcmfmac (Broadcom WiFi) must also be unloaded to prevent PCIe D3
# state transition failures that cause a ~19s delay entering S3.
# brcmfmac_wcc must be removed before brcmfmac, as it holds a reference.
#
# This is a systemd-sleep hook — runs as a direct subprocess of
# systemd-sleep, after all systemd unit ordering is complete, with
# "pre" before the kernel enters S3 and "post" after it wakes.
#
# Install:
#   cp t2-suspend-fix.sh /etc/systemd/system-sleep/t2-suspend-fix.sh
#   chmod +x /etc/systemd/system-sleep/t2-suspend-fix.sh

case "$1" in
    pre)
        # Stop networking before touching modules
        systemctl stop NetworkManager
        systemctl stop iwd
        rfkill block wifi
        ip link set wlan0 down

        # Remove brcmfmac_wcc first — it holds a reference on brcmfmac
        modprobe -r brcmfmac_wcc
        modprobe -r brcmfmac

        # Remove touch bar and apple-bce modules
        rmmod hid_appletb_kbd hid_appletb_bl
        rmmod apple-bce
        ;;

    post)
        # Reload apple-bce first — touch bar and keyboard depend on it
        modprobe apple-bce
        sleep 1
        modprobe hid_appletb_bl
        modprobe hid_appletb_kbd

        # Reload WiFi
        rfkill unblock wifi
        modprobe brcmfmac
        modprobe brcmfmac_wcc

        # Restart networking
        sleep 1
        systemctl start iwd
        sleep 1
        systemctl start NetworkManager
        ;;
esac
