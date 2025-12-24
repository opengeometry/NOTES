#!/bin/bash

./send_line.sh {A..Z} {a..z} {0..9} > /dev/hidg0

sleep 1

printf %b '\x00\x00\x40\x00\x40'  > /dev/hidg2
sleep 1
printf %b '\x00\x00\x30\x00\x30'  > /dev/hidg2

sleep 1

printf %b '\x00\x7f\x00' > /dev/hidg1
sleep 1
printf %b '\x00\x81\x00' > /dev/hidg1

