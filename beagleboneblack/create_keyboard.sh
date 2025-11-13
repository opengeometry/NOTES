#!/bin/sh
#
# William Park <opengeometry@yahoo.ca>
# 2018-2025
#
# Usage:  sudo ./create_keyboard.sh {start|stop}
#
# This script creates USB Gadget device (/dev/hidg0), so that it can act as USB
# keyboard.
#
# The original script (create-hid.sh) was written by Phil Polstra:
#	- media.defcon.org/DEF CON 23/DEF CON 23 presentations/DEFCON-23-Phil-Polstra-Extras.rar
#	- github.com/ppolstra/UDeck/
# 
# Rewritten for newer BBB images.
#

KB_DIR=/sys/kernel/config/usb_gadget/kb


mkdir_cd()
{
    mkdir $1 && cd $1
}

# https://www.usb.org/sites/default/files/documents/hid1_11.pdf
# E.6 Report Descriptor (Keyboard), p69
#
cat_report_descriptor_keyboard()
{
    xxd -r -p <<EOF
	05 01 09 06 a1 01 05 07 19 e0 29 e7 15 00 25 01
	75 01 95 08 81 02 95 01 75 08 81 01 95 05 75 01
	05 08 19 01 29 05 91 02 95 01 75 03 91 01 95 06
	75 08 15 00 25 65 05 07 19 00 29 65 81 00 c0
EOF
}


# Debian 7.5, 7.9, 7.11:
# ----------------------
# - g_multi	-- can't remove it, can't blacklist it.
# - g_hid	-- can't load it.
#
# Debian 8.3, 8.7:
# ----------------
# modprobe usb_f_hid
#
# /etc/modprobe.d/bbb-blacklist.conf:
#	blacklist usb_f_acm
#
# Debian 9.5, 9.9, 10.3, 10.13:
# -----------------------------
# modprobe usb_f_hid
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
do_start()
{
    modprobe usb_f_hid

    # Mount configfs, if it's not already mounted.
    if ! mountpoint -q /sys/kernel/config ; then
	mount -t configfs none /sys/kernel/config
    fi

    if mkdir_cd $KB_DIR; then
	# echo 0x1337 > idVendor
	# echo 0x1337 > idProduct
	echo 0x1d6b > idVendor	# Linux Foundation
	echo 0x0104 > idProduct	# Multifunction Composite Gadget
	echo 0x0100 > bcdDevice	# v1.0.0
	echo 0x0110 > bcdUSB	# 0x0110=USB1.1, 0x0200=USB2
    fi

    if mkdir_cd $KB_DIR/functions/hid.usb0; then
	echo 1 > protocol		# Keyboard
	echo 1 > subclass
	echo 8 > report_length
	cat_report_descriptor_keyboard > report_desc 
    fi

    if mkdir_cd $KB_DIR/configs/c.1; then
	echo 500 > MaxPower
	ln -sf $KB_DIR/functions/hid.usb0
    fi

    # Activate keyboard device.
    if cd $KB_DIR; then
	basename -a /sys/class/udc/musb-hdrc.* > UDC
    fi

    sync
}


# Undo what has been done, in reverse order.
#
do_stop()
{
    echo "" > $KB_DIR/UDC	# deactivate

    rm $KB_DIR/configs/c.1/hid.usb0
    rmdir $KB_DIR/configs/c.1
    rmdir $KB_DIR/functions/hid.usb0
    rmdir $KB_DIR

    sync
}


case $1 in
    start) 
	if [ -c /dev/hidg0 ]; then
	    echo "$0 $*: /dev/hidg0 is already active."
	else
	    echo "$0 $*"
	    do_start
	fi
	;;

    stop) 
	if [ -c /dev/hidg0 ]; then
	    echo "$0 $*"
	    do_stop
	else
	    echo "$0 $*: /dev/hidg0 is not active."
	fi
	;;

    *)
	echo "Usage:  sudo $0 {start|stop}"
	exit 2
	;;
esac 1>&2	# print to stderr for logging

