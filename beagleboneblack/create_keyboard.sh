#!/bin/sh
#
# William Park <opengeometry@yahoo.ca>
# 2018-2025
#
# This script creates a USB HID keyboard device on BBB.  The original script
# (create-hid.sh) was written by Phil Polstra:
#	- media.defcon.org/DEF CON 23/DEF CON 23 presentations/DEFCON-23-Phil-Polstra-Extras.rar
#	- github.com/ppolstra/UDeck/
#
case $1 in
    start)
	echo "$0 $*" 1>&2	# print to stderr for logging
	;;
    stop)
	echo "$0 $*" 1>&2	# print to stderr for logging
	exit 0		# nothing to do
	;;
    *)	
	echo "Usage:  sudo $(basename $0) {start|stop}"
	exit 2
	;;
esac

mkdir_cd()
{
    mkdir $1 && cd $1
}

sync_sleep()
{
    sync && sleep $1
}

send_report_descriptor_kb_bin()
{
    xxd -r -p <<EOF
	05 01 09 06 a1 01 05 07 19 e0 29 e7 15 00 25 01
	75 01 95 08 81 02 95 01 75 08 81 01 95 05 75 01
	05 08 19 01 29 05 91 02 95 01 75 03 91 01 95 06
	75 08 15 00 26 ff 00 05 07 19 00 2a ff 00 81 00
	c0
EOF
}

#
# Debian 7.5, 7.9, 7.11:
# ----------------------
# - g_multi	-- can't remove it, can't blacklist it.
# - g_hid	-- can't load it.
#
# Debian 8.3, 8.7:
# ----------------
#modprobe usb_f_hid
#
# /etc/modprobe.d/bbb-blacklist.conf:
#	blacklist usb_f_acm
#
# Debian 9.5, 9.9, 10.3, 10.13:
# -----------------------------
modprobe usb_f_hid
#
# /etc/modprobe.d/bbb-blacklist.conf:
#	blacklist usb_f_acm
#
# /etc/default/bb-boot:
#	USB_IMAGE_FILE_DISABLED=yes
#	USB_NETWORK_DISABLED=yes
#	USB_CONFIGURATION=no
#	USB1_ENABLE=no
#
#
# Debian 11.7, 12.12, 13.1:
# -------------------------
# Factory images don't work, because most USB Gadget modules are built into the
# kernels.  You have to recompile, and move 'usb_f_acm' and 'usb_f_serial' to
# modules and blacklist them.  Kernels
#	- 5.10.168
#	- 6.12.55
#	- 6.17.5
#	- 6.17.7
# have been recompiled and confirmed to work.
#
# /etc/modprobe.d/bbb-blacklist.conf:
#	blacklist usb_f_acm
#	blacklist usb_f_serial
#

sync_sleep 3

# Mount configfs, if it's not already mounted.
if ! mountpoint -q /sys/kernel/config ; then
    mount -t configfs none /sys/kernel/config
    sync_sleep 3
fi

KB_DIR=/sys/kernel/config/usb_gadget/kb

if mkdir_cd $KB_DIR; then
    # echo 0x1337 > idVendor
    # echo 0x1337 > idProduct
    echo 0x1d6b > idVendor	# Linux Foundation
    echo 0x0104 > idProduct	# Multifunction Composite Gadget
    echo 0x0100 > bcdDevice	# v1.0.0
    echo 0x0110 > bcdUSB	# 0x0110=USB1.1, 0x0200=USB2
    sync_sleep 3
fi

if mkdir_cd $KB_DIR/functions/hid.usb0; then
    echo 1 > protocol		# Keyboard
    echo 1 > subclass
    echo 8 > report_length
    #cp report_descriptor_kb.bin report_desc
    send_report_descriptor_kb_bin > report_desc 
    sync_sleep 3
fi

if mkdir_cd $KB_DIR/configs/c.1; then
    echo 500 > MaxPower
    ln -sf $KB_DIR/functions/hid.usb0
    sync_sleep 3
fi

# Activate keyboard device.
#
if cd $KB_DIR; then
    basename -a /sys/class/udc/musb-hdrc.* > UDC
    sync_sleep 3
fi
