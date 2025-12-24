# BeagleBone Black (BBB) related stuffs

  - [make_keyboard.sh](make_keyboard.sh) --- creates USB Gadget devices
  - [send_functions.sh](send_functions.sh) --- collection of shell functions
  - [send_line.sh](send_line.sh) --- sends string arguments, separated by a space and terminated by newline.


----
## 1. BBB as scriptable keyboard, mouse, and touch screen
----
Using USB Gadget driver, you can make BBB into a scriptable keyboard, mouse, and touchscreen
device.  This means, for an example, you can send out "key presses" from USB device port
(mini-USB).  From USB host side (usually PC), it appears just like another keyboard.

Original work on keyboard emulation for BBB was done by Phil Polstra (@ppolstra)
  - [DEFCON-23-Phil-Polstra-Extras.rar](https://media.defcon.org/DEF%20CON%2023/DEF%20CON%2023%20presentations/DEF%20CON%2023%20-%20Phil-Polstra-Extras.rar)
  - [UDeck](https://github.com/ppolstra/UDeck)

It works for older images (Debian 8.7, 9.9, 10.13), but doesn't work for newer images 
(Debian 11.7, 12.12, 13.1, Kernel 5.x, 6.x).  Also, original scripts were written in Python2
which is no longer available in repository for BBB.

My work here 
  - solves these problems for newer BBB images with newer kernels, and
  - includes the emulation of keyboard, mouse, and touchscreen (absolute mouse).


### Creating/Removing USB Gadget devices

1. `sudo ./make_keyboard.sh start [keyboary mouse screen]` --- will create 3 USB Gadget devices
    - `/dev/hidg0` --- regular keyboard
    - `/dev/hidg1` --- regular mouse, with relative motion
    - `/dev/hidg2` --- screen or absolute mouse, a basic one-finger touchscreen

   You can specify 0, 1, 2, or all 3 devices, and it will start creating from `/dev/hidg0` and up.
   If you specify 0 device, then it will simply activate (ie. turn on) devices previously deactivated with
   `stop` action.
  
3. `sudo ./make_keyboard.sh stop` --- deactivates (ie. turn off) devices created with previously `start` action.

4. `sudo ./make_keyboard.sh clean` --- removes and cleans up all devices previously created with
   `start` action.  You will have to recreate them, later.

5. `sudo ./make_keyboard.sh stopall` --- deactivates all USB Gadget devices found in the system.

6. `sudo ./make_keyboard.sh list` --- lists all USB Gadget devices found in the system.


### Sending text strings as "keyboard"

```bash
./send_line.sh {A..Z} {a..z} > /dev/hidg0
```
will send the alphabets, separated by a space and terminated by newline,
to `/dev/hidg0`.  It's as though you typed the line on a real keyboard.  Internally,
it will load shell functions from `send_functions.sh` which is rewrite of
[udeckHid.py](https://github.com/ppolstra/UDeck/blob/master/udeckHid.py) in Shell.

`send_line.sh` is just frontend.  You probably want to use functions in `send_functions.sh`
directly, eg.
```bash
. send_functions.sh
sendWindowKey d
```
which are the same as pressing Windows+D (show desktop) key.


### Sending mouse click and movement as "mouse"

```bash
printf %b '\x01\x00\x00' > /dev/hidg1
printf %b '\x00\x00\x00' > /dev/hidg1
printf %b '\x00\x7f\x00' > /dev/hidg1 
```
will simulate mouse button1 clicked (press and release), and then moving 127 to right.


### Moving mouse as "touch screen"

```bash
printf %b '\x00\x00\x40\x00\x40' > /dev/hidg2
```
will move mouse to the centre of screen, no matter where it was.  The X,Y ranges are 
scaled from 1 to 32767 or 0x7fff.  So, (1, 1) is top left corner, (0x7fff, 0x7fff)
is bottom right corner, and the screen centre is exactly (0x4000, 0x4000).

This is very useful for "automated QA testing".


----
## 2. Compiling a new kernel
----
It's similiar to compiling a kernel on PC, except you also need to install **.dtb**.
You can compile on BBB (slooow) or cross-compile on PC (faster, recommended).
It would go like
```bash
sudo apt install libssl-dev gcc-arm-linux-gnueabihf

export KBUILD_OUTPUT=5.10.168-kb
export LOCALVERSION=-kb
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

make kernelversion
make olddefconfig
make kernelrelease

make all
make zinstall        INSTALL_PATH=boot_install
make dtbs_install    INSTALL_PATH=boot_install
make modules_install INSTALL_MOD_PATH=modules_install
make headers_install INSTALL_HDR_PATH=headers_install
```
You now have a new kernel and stuffs.
On Fedora, for some reason, `make zinstall` line doen't work, so you have to do that step manually.
Finally, make tarballs of the 3 installed locations.
```bash
cd $KBUILD_OUTPUT
    tar -cJf boot-$KBUILD_OUTPUT.tar.xz    boot_install
    tar -cJf modules-$KBUILD_OUTPUT.tar.xz modules_install
    tar -cJf headers-$KBUILD_OUTPUT.tar.xz headers_install
```


### Installing kernel

Copy the tarballs to BBB, and install them to
  - /boot
  - /boot/dtbs
  - /lib/modules

My BBB boots okay without *initrd.img*, but you may want to generate it for completeness.
```bash
export KBUILD_OUTPUT=5.10.168-kb

tar -xJf boot-$KBUILD_OUTPUT.tar.xz    --strip-components=1 --no-same-owner --no-same-permissions -C /boot
tar -xJf modules-$KBUILD_OUTPUT.tar.xz --strip-components=3 --no-same-owner --no-same-permissions -C /lib/modules

depmod $KBUILD_OUTPUT
mkinitramfs -o initrd.img-$KBUILD_OUTPUT $KBUILD_OUTPUT
cp initrd.img-$KBUILD_OUTPUT /boot
```


### Configuring /boot/uEnv.txt

```
#uname_r=5.10.168-ti-r83
uname_r=5.10.168-kb
```
When BBB boots, it will look for relevant files in `/boot`, `/boot/dtbs`, and `/lib/modules`.


----
## 3. Controlling builtin LEDs via SYSFS
----
BBB has 4 builtin LEDs:

LED | default trigger | /sys/class/leds
--- | --------------- | ---------------
0   | heartbeat       | beaglebone:green:usr0
1   | mmc0            | beaglebone:green:usr1
2   | cpu0            | beaglebone:green:usr2
3   | mmc1            | beaglebone:green:usr3

They can be accessed via SYSFS, `/sys/class/leds/beaglebone:green:usr[0123]`.  Eg.
```bash
$ cd /sys/class/leds/beaglebone:green:usr0
$ ls
brightness  device  invert  max_brightness  power  subsystem  trigger  uevent
$ cat trigger
... [heartbeat] ...
```

1. To turn on/off LED manually,
   ```bash
   echo none > trigger    # disable trigger
   echo 1 > brightness    # on
   echo 0 > brightness    # off
   ```
2. To turn on/off LED using `timer` trigger,
   ```bash
   echo timer > trigger
   echo 1000 > delay_on     # on 1000ms
   echo 1000 > delay_off    # off 1000ms
   ```
3. To turn on LED once using `oneshot` trigger,
   ```bash
   echo oneshot > trigger
   echo 1000 > delay_on    # on 1000ms
   echo 1 > shot
   ```
4. To restore default trigger,
   ```bash
   echo default > trigger
   ```
   or for older kernel, one of
   ```bash
   echo heartbeat > trigger
   echo mmc0 > trigger
   echo cpu0 > trigger
   echo mmc1 > trigger
   ```


----
## 4. GPIO (General Purpose Input Output)
----

### Controlling GPIO via SYSFS

You can access GPIO pins via SYSFS, `/sys/class/gpio`.  Eg
```bash
$ cd /sys/class/gpio
$ ls
export  gpiochip0  gpiochip32  gpiochip64  gpiochip96  unexport
$ echo 7 > export
$ ls
export  gpio7  gpiochip0  gpiochip32  gpiochip64  gpiochip96  unexport
$ cd gpio7
$ ls
active_low  device  direction  edge  label  power  subsystem  uevent  value
```

1. To read GPIO pin,
   ```bash
   echo in > direction
   cat value
   ```

2. To turn on/off GPIO,
   ```bash
   echo out > direction
   echo 1 > value
   echo 0 > value  
   ```

To remove access to GPIO,
```bash
$ echo 7 > unexport
$ ls
export  gpiochip0  gpiochip32  gpiochip64  gpiochip96  unexport
```
so that `gpio7` is removed or unexported.


### Controlling GPIO via `gpioset, gpioget`

You can also access GPIO pins via `gpioinfo, gpioget, gpioset` utilities.  Eg.
```bash
$ gpioinfo | grep -e chip -e P9_12
gpiochip0 - 32 lines:
gpiochip1 - 32 lines:
        line  28:       "P9_12"                 input
gpiochip2 - 32 lines:
gpiochip3 - 32 lines:
```
tells you that pin P9_12 is internally `chip=1, line=28`, also named GPIO60 (1*32 + 28 = 60).

1. To read GPIO pin,
   ```bash
   gpioget -c1 28
   gpioget --by-name P9_12
   ```

2. To turn on/off GPIO pin,
   ```bash
   gpioset -c1 28=on              # on, 1, active
   gpioset --by-name P9_12=off    # off, 0, inactive
   ```


----
## 5. ADC (Analog to Digital Converter)
----
BBB has 7 ADC inputs:

pin   | ADC  | pin   | ADC
---   | ---  | ---   | --- 
.     | .    | P9_32 | VDD_ADC, 1.8V
P9_33 | AIN4 | P9_34 | GND_ADC 
P9_35 | AIN6 | P9_36 | AIN5 
P9_37 | AIN2 | P9_38 | AIN3 
P9_39 | AIN0 | P9_40 | AIN1   

which are accessed via `/sys/bus/iio/devices/iio:device[0123456]`.
They are 12-bit (0 to 4095), and voltage range is 0V to 1.8V.

To read the ADC,
```bash
cat /sys/bus/iio/devices/iio:device0/in_voltage0_raw
```


----
## 6. PWM (Pulse Width Modulation)
----
BBB has 3 PWM modules:

pwm   | a     | b
----- | ----- | -----
0     | P9_31 | P9_29
1     | P9_14 | P9_16
2     | P8_19 | P8_13

To access them, you have to load relevant "device tree" modules in `/boot/uEnv.txt`:
```
enable_uboot_overlays=1

uboot_overlay_addr4=BB-EHRPWM1-P9_14-P9_16.dtbo

disable_uboot_overlay_video=1
disable_uboot_overlay_audio=1
```
To use it, you set `period`, `duty_cycle`, and then `enable` it, eg.
```bash
cd /dev/bone/pwm/1/a
    echo $((2*1000*1000)) > period        # 2ms = 500Hz
    echo $((1*1000*1000)) > duty_cycle    # 1ms = 50%
    echo 1 > enable
```


----
## 7. eQEP (enhanced Quadrature Encoder Pulse)
----
BBB has 3 eQEP modules:

eQEP | a      | b     | index  | strobe
---- | ---    | ---   | -----  | ------
0    | P9_42B | P9_27 | P9_41B | P9_25
1    | P8_35  | P8_33 | P8_31  | P8_32
2    | P8_41  | P8_42 | P8_39  | P8_40

Of these, I'm only interested in eQEP0, in order to count input pulses.
To access them, you have to load relevant "device tree" modules in `/boot/uEnv.txt`:
```
enable_uboot_overlays=1

uboot_overlay_addr5=BB-EQEP0.dtso

disable_uboot_overlay_video=1
disable_uboot_overlay_audio=1
```

To simply count input pulses,
```bash
cd /dev/bone/counter/0/count0
    echo 100 > ceiling
    echo increase > function
    echo 1 > enable
    cat count
```
And, it will count on both rising/falling edges, so `count` is 2x the input pulses.
