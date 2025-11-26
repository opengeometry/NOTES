# Odroid related stuffs

I have an old **Odroid U3+** that is out of production and support.  The last distro was Ubuntu 18.04.
But, I was able to upgrade to Ubuntu 24.04 and kernel 6.17.9.

----
## 1. Odroid as scriptable keyboard, mouse, and screen
----

### Compiling kernel

USB Gadget driver works only with **4.16.x** kernels (4.16.0 to 4.16.18).  And, you need to recompile the kernel
with USB Gadget modules.  The process is the same as compiling for 
[BeagleBone Black](https://opengeometry.github.io/NOTES/beagleboneblack/#2-compiling-a-new-kernel).


### Generating uIintrd

First, build **initrd.img** as usual.  Then, convert to **uInitrd** used by U-Boot.
```
export KR=4.16.0-odroid

mkinitramfs -o initrd.img-$KR  $KR
mkimage -A arm -O linux -T ramdisk -C none -n "initrd.img-$KR" -d initrd.img-$KR uInitrd-$KR
cp uInitrd-$KR   /media/boot
cp vmlinuz-$KR   /media/boot
cp /boot/dtbs/$KR/exynos4412-odroidu3.dtb /media/boot
```


### Generating boot.scr

**boot.scr** is just **uInitrd** generated from **boot.ini**.

**boot.ini**:
```
...
setenv KR "4.16.0-odroid"
setenv bootcmd "fatload mmc 0:1 0x40008000 vmlinuz-${KR}; fatload mmc 0:1 0x42000000 uInitrd-${KR}; fatload mmc 0:1 0x44000000 exynos4412-odroidu3.dtb-${KR}; bootz 0x40008000 0x42000000 0x44000000"
...
```
Note the 3 files:
  - `vmlinuz-${KR}` --- kernel
  - `uInitrd-${KR}` --- generated from `initrd.img-$KR`
  - `exynos4412-odroidu3.dtb-${KR}` --- copied from `/boot/dtbs/$KR`

Then, generate **boot.scr** just like **uInitrd** above.
```
sudo mkimage -A arm -O linux -T script -C none -n "boot.ini-$KR" -d boot.ini-$KR boot.scr-$KR
sudo cp boot.ini-$KR  /media/boot/
sudo cp boot.ini-$KR  /media/boot/boot.ini
sudo cp boot.scr-$KR  /media/boot/
sudo cp boot.scr-$KR  /media/boot/boot.scr
```

