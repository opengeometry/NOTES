#!/bin/sh
#
# William Park <opengeometry@yahoo.ca>
# 2018-2025
#
# Usage:  sudo ./create_keyboard.sh {start|stop}
#
# This script creates USB Gadget device (/dev/hidg0), so that it can act as
# USB keyboard.
#
# The original script (create-hid.sh) was written by Phil Polstra:
#	- media.defcon.org/DEF CON 23/DEF CON 23 presentations/DEFCON-23-Phil-Polstra-Extras.rar
#	- github.com/ppolstra/UDeck/
# 
# Rewritten for newer BBB images.
#
# Reference:
# 	https://docs.kernel.org/usb/gadget_configfs.html
# 	https://docs.kernel.org/filesystems/configfs.html
#

KB_DIR=/sys/kernel/config/usb_gadget/kb


mkdir_cd()
{
    mkdir $1 && cd $1
}

# https://www.usb.org/sites/default/files/documents/hid1_11.pdf
#   Firmware Specification 6/27/01
#   Version 1.11
#   E.6 Report Descriptor (Keyboard), p69
#
cat_report_descriptor_keyboard()
{
    xxd -r -p <<EOF
	05 01 09 06 a1 01 05 07  19 e0 29 e7 15 00 25 01
	75 01 95 08 81 02 95 01  75 08 81 01 95 05 75 01
	05 08 19 01 29 05 91 02  95 01 75 03 91 01 95 06
	75 08 15 00 25 65 05 07  19 00 29 65 81 00 c0
EOF

}

# https://docs.kernel.org/usb/gadget-testing.html
# https://docs.kernel.org/usb/gadget_hid.html
#   Two differences:
#	Input (constant)    81 01 | 81 03
#	Output (constant)   91 01 | 91 03
#
cat_report_descriptor_keyboard2()
{
    xxd -r -p <<EOF
	05 01 09 06 a1 01 05 07  19 e0 29 e7 15 00 25 01
	75 01 95 08 81 02 95 01  75 08 81 03 95 05 75 01
	05 08 19 01 29 05 91 02  95 01 75 03 91 03 95 06
	75 08 15 00 25 65 05 07  19 00 29 65 81 00 c0
EOF
}

do_start()
{
    modprobe usb_f_hid

    if mkdir_cd $KB_DIR; then
	echo 0x1d6b > idVendor	    # Linux Foundation
	echo 0x0104 > idProduct	    # Multifunction Composite Gadget
	echo 0x0100 > bcdDevice	    # v1.0.0
	echo 0x0110 > bcdUSB	    # 0x0110=USB1.1, 0x0200=USB2

	if mkdir_cd $KB_DIR/strings/0x409; then	    # 0x409 -- English
	    echo BeagleBoard.org Foundation > manufacturer
	    echo BBB Keyboard               > product
	    echo 0001			    > serialnumber
	fi
    fi

    if mkdir_cd $KB_DIR/functions/hid.usb0; then
	echo 1 > protocol	    # Keyboard
	echo 1 > subclass
	echo 8 > report_length
	cat_report_descriptor_keyboard > report_desc 
    fi

    if mkdir_cd $KB_DIR/configs/c.1; then
	echo 500 > MaxPower
	ln -sf $KB_DIR/functions/hid.usb0

	if mkdir_cd $KB_DIR/configs/c.1/strings/0x409; then	# 0x409 -- English
	    echo Sample Configuration > configuration
	fi
    fi

    # Activate keyboard device.
    if cd $KB_DIR; then
	echo musb-hdrc.0 > UDC
    fi

    sync && sleep 0
}


# Undo what has been done, in reverse order.
#
do_stop()
{
    echo "" > $KB_DIR/UDC	# deactivate

    rm    $KB_DIR/configs/c.1/hid.usb0
    rmdir $KB_DIR/configs/c.1/strings/0x409
    rmdir $KB_DIR/configs/c.1
    rmdir $KB_DIR/functions/hid.usb0
    rmdir $KB_DIR/strings/0x409
    rmdir $KB_DIR

    sync && sleep 0
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
	    echo "$0 $*: /dev/hidg0 is already deactivated."
	fi
	;;

    *)
	echo "Usage:  sudo $0 {start|stop}"
	exit 2
	;;
esac 1>&2	# print to stderr for logging

