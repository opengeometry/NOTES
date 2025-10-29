#!/bin/bash
#
# William Park <opengeometry@yahoo.ca>
# 2025
#
Usage()
{
    cat << EOF 
Usage:
    1. printat.sh asc... > bin

	If argument is ASCII name/char, then print the ASCII value.  

	If it's decimal [0-9]+, hex [0-9a-fA-F]+h, 0x[0-9a-fA-F]+, or binary
	[01]+b, then print the number in little-endian format.

	If the number is inside word(...), print only the last 2 bytes.  If
	dword(...), print the last 4 bytes.  If a number starts with '
	(apostrophe), treat the number as string, like spreadsheet does.

	Otherwise, it's string, so print it verbatim.

	    printat.sh NUL ESC			# 0x00 0x1b
	    printat.sh 0 48 1bh 0x1b		# NUL 0 ESC ESC
	    printat.sh word(258)		# 0x02 0x01
	    printat.sh dword(0x04030201)	# 0x01 0x02 0x03 0x04
	    printat.sh abcd			# abcd

    2. printat.sh < asc > bin
    
	Same, but read from file instead of command line.  Contents will be
	broken up into whitespace separated words.

    3. printat.sh -r < bin > asc

	If '-r' is the only argument, then do the reverse.  Convert binary to
	ASCII name/char.  Similar to 'od -a' but uppercase ASCII name/char.

    4. printat.sh -h

	Print this.
EOF
}


################################################################################
# Functions

shopt -s extglob

print_number_bin() 	# number [len] > bin
{
    local number=$1 len=${2:-0}
    local n L

    for ((n = 0; 
	len == 0 && (number > 0 || n == 0) || len > 0 && n < len; 
	number /= 256, n++)); do
	    L=$( printf '\\x%02x' $((number % 256)) )
	    printf '%b' "$L"
    done
}

string_to_integer()	# number > int
{
    local number=$1

    case $number in
	0x*) echo $(( 16#${number#0x} )) ;;
	*h) echo $(( 16#${number%h} )) ;;
	*b) echo $(( 2#${number%b} )) ;;	# must be last, because 'b' can be hex.
	*) echo $(( 10#$number )) ;;
    esac
}

print_name_to_bin() 		# name > bin
{
    local name=$1
    local number

    case $name in
	# ASCII name
	NUL) printf '\x00' ;; 
	SOH) printf '\x01' ;;
	STX) printf '\x02' ;;
	ETX) printf '\x03' ;;
	EOT) printf '\x04' ;;
	ENQ) printf '\x05' ;;
	ACK) printf '\x06' ;;
	BEL) printf '\x07' ;;
	BS) printf '\x08' ;;
	HT|TAB) printf '\x09' ;;
	LF) printf '\x0a' ;;
	VT|HOM) printf '\x0b' ;;
	FF|CLR) printf '\x0c' ;;
	CR) printf '\x0d' ;;
	SO) printf '\x0e' ;;
	SI) printf '\x0f' ;;
	DLE) printf '\x10' ;;
	DC1|XON) printf '\x11' ;;
	DC2) printf '\x12' ;;
	DC3|XOFF) printf '\x13' ;;
	DC4) printf '\x14' ;;
	NAK) printf '\x15' ;;
	SYN) printf '\x16' ;;
	ETB) printf '\x17' ;;
	CAN) printf '\x18' ;;
	EM) printf '\x19' ;;
	SUB) printf '\x1a' ;;
	ESC) printf '\x1b' ;;
	FS) printf '\x1c' ;;
	GS) printf '\x1d' ;;
	RS) printf '\x1e' ;;
	US) printf '\x1f' ;;
	SP) printf '\x20' ;;
	DEL) printf '\x7f' ;;

	# single digit -> treat it as number 
	[0-9]) print_number_bin $name 1 ;;

	# ASCII char
	?) echo -n "$name" ;;

	# Number: decimal [0-9]+, hex HHh or 0xHH, binary [01]+b
	+([0-9])		) ;&
	0x+([[:xdigit:]])	) ;&
	+([[:xdigit:]])h	) ;&
	+([01])b		)
	    number=$(string_to_integer $name)
	    print_number_bin $number
	    ;;

	# word(...)
	word\(+([0-9])\)		) ;&
	word\(0x+([[:xdigit:]])\)	) ;&
	word\(+([[:xdigit:]])h\)	) ;&
	word\(+([01])b\)		)
	    number=${name#word\(}
	    number=${number%\)}
	    number=$(string_to_integer $number)
	    print_number_bin $number 2
	    ;;

	# dword(...)
	dword\(+([0-9])\)		) ;&
	dword\(0x+([[:xdigit:]])\)	) ;&
	dword\(+([[:xdigit:]])h\)	) ;&
	dword\(+([01])b\)		)
	    number=${name#dword\(}
	    number=${number%\)}
	    number=$(string_to_integer $number)
	    print_number_bin $number 4
	    ;;

	# Number string, eg. '123
	\'+([0-9])		) ;&
	\'0x+([[:xdigit:]])	) ;&
	\'+([[:xdigit:]])h	) ;&
	\'+([01])b		)
	    echo -n "${name#\'}"
	    ;;

	# String 
	*) echo -n "$name" ;;
    esac
}

print_hex_to_name() 		# hh > name\n
{
    local hh=$1

    case $hh in
	# ASCII name
	00) echo NUL ;; 
	01) echo SOH ;;
	02) echo STX ;;
	03) echo ETX ;;
	04) echo EOT ;;
	05) echo ENQ ;;
	06) echo ACK ;;
	07) echo BEL ;;
	08) echo BS ;;
	09) echo HT ;;	# TAB
	0[aA]) echo LF ;;
	0[bB]) echo VT ;;	# HOM
	0[cC]) echo FF ;;	# CLR
	0[dD]) echo CR ;;
	0[eE]) echo SO ;;
	0[fF]) echo SI ;;
	10) echo DLE ;;
	11) echo DC1 ;;	# XON
	12) echo DC2 ;;
	13) echo DC3 ;;	# XOFF
	14) echo DC4 ;;
	15) echo NAK ;;
	16) echo SYN ;;
	17) echo ETB ;;
	18) echo CAN ;;
	19) echo EM ;;
	1[aA]) echo SUB ;;
	1[bB]) echo ESC ;;
	1[cC]) echo FS ;;
	1[dD]) echo GS ;;
	1[eE]) echo RS ;;
	1[fF]) echo US ;;
	20) echo SP ;;
	7[fF]) echo DEL ;;

	# ASCII char
	[0-7][[:xdigit:]] ) printf '%b\n' \\x$hh ;;

	# high-bit char as hex, unchanged
	[89a-fA-F][[:xdigit:]] ) echo ${hh}h ;;
    esac
}


################################################################################
# Main

case $#:$1 in
    0:)		# printat.sh < esc > bin
	tr -cs '[:graph:]' '\n' | while read i; do
	    # Make sure there is LF at EOF.  Otherwise, "while read" doesn't
	    # read the last line.  
	    print_name_to_bin "$i"
	done
	;;

    1:-r)	# printat.sh -r < bin > esc
	xxd -p | sed 's/../&\n/g' | while read i; do
	    print_hex_to_name "$i"
	done | fmt -u
	;;

    1:-h)	# printat.sh -h
	Usage
	;;

    *)		# printat.sh esc... > bin
	for a; do
	    print_name_to_bin "$a"
	done
	;;
esac
