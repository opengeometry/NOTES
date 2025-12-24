# Raspberry Pi (Zero 2W) related stuffs

Zero 2W has 2 micro USB ports.  One for power only, and another for USB dual-role port.


## 1. Serial debug

/boot/firmware/config.txt:
```
[all]
enable_uart=1
```


## 2. Scriptable keyboard, mouse, and screen

[make_keyboard.sh](../beagleboneblack/make_keyboard.sh) works on Raspberry Pi Zero 2W, as well.
But, you have to set the microUSB port as "otg" or "peripherial" mode in /boot/firmware/config.txt.
```
[all]
dtoverlay=dwc2
```


## 3. GPIO

GPIO pins can be accessed by
1. `/sys/class/gpio`
   ```bash
   cd /sys/class/gpio
       echo $((512+26)) > export
       cd gpio538
           echo out > direction
           echo 1 > value
           echo 0 > value
   ```
   and to reset the pin,
   ```bash
   cd /sys/class/gpio
       echo 538 > unexport
   ```

2. `gpioget, gpioset`
   ```bash
   gpioget -c0 26
   gpioset -c0 26=on
   gpioset -c0 26=off
   ```

## 4. PWM (Pulse Width Modulaton)

Zero 2W has 2 PWM channels:

pwm  | pin   | gpio   | func | mode
---  | ---   | ----   | ---- | ----
PWM0 | PIN32 | GPIO12 | 4    | Alt0
PWM1 | PIN33 | GPIO13 | 4    | Alt0

There are many ways to produce PWM from Zero 2W.  

1. **GPIO PWM**  --- Use `-t` option of `gpioset`:
   - `gpioset -t1,1 -c0 26=on` --- turn on 1ms, turn off 1ms, and repeat.  About 500Hz with 50% duty cycle, but not accurate.

2. **Software PWM** --- Any GPIO pin can be used as "software PWM".  It needs "device tree" modules in /boot/firmware/config.txt:
   - `dtoverlay=pwm-gpio,gpio=16` --- Accessing software PWM is the same as hardware PWM.
     ```bash
     cd /sys/class/pwm/pwmchip0
         echo 0 > export      # --> pwm0
         cd pwm0
             echo $((2*1000*1000)) > period          # 2ms = 500Hz
             echo $((1*1000*1000)) > duty_cycle      # 1ms = 50%
             echo 1 > enable
     ```

3. **Hardware PWM (single channel)** --- One of PWM0 or PWM1, but not both.  It needs "device tree" modules in /boot/firmware/config.txt:
   - `dtoverlay=pwm,pin=12,func=4` --- will enable only PWM0.
     ```bash
     echo 0 > /sys/class/pwm/pwmchip0/export    # --> pwm0
     ```
   - `dtoverlay=pwm,pin=13,func=4` --- will enable only PWM1.
     ```bash
     echo 1 > /sys/class/pwm/pwmchip0/export    # --> pwm1
     ```
    
4. **Hardware PWM (dual channel)** --- Both PWM0 and PWM1 can be used.
   - `dtoverlay=pwm-2chan,pin=12,func=4,pin2=13,func2=4`
     ```bash
     echo 0 > /sys/class/pwm/pwmchip0/export    # --> pwm0
     echo 1 > /sys/class/pwm/pwmchip0/export    # --> pwm1
     ```

5. After using the pins as "input", to revert the pin back to PWM pins,
   ```bash
   pinctrl set 12,13 a0    # --> a0 = Alt0
   ```
