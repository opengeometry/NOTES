# VirtualBox related stuffs

## Setting Video Memory, Base Memory, and CPU

- For **Video Memory**, normal maximum is 128MB.
- If you turn on/off **3D Acceleration**, you can set to 256MB max.
- Sometimes, you need to change **Base Memory** and **CPU**, depending on your system load.

From command line,
```
VBoxManage modifyvm "VM_Name" --vram 256 --memory=4096 --cpus=2
```


## Loading Guest Addition

1. Update to the latest.  Install packages for compiling kernel modules.

    **Ubuntu**:
    ```
    sudo apt update
    sudo apt dist-upgrade
    sudo apt install build-essential dkms
    ```

    **Fedora**:
    ```
    sudo dnf distro-sync
    sudo dnf install kernel-devel kernel-headers dkms
    ```

    **OpenSUSE**:
    ```
    sudo zypper refresh
    sudo zypper dist-upgrade
    sudo zypper install kernel-devel
    ```

2. Install Guest Additions.  Add user to group **vboxsf** if you've configured "Shared Folders".
   ```
   sudo /.../VBoxLinuxAdditions.run
   sudo usermod -a -G vboxsf "user"
   ```

4. Reboot to pickup new kernel modules and new group id.
   ```
   sudo reboot
   ```


## Compacting disk (not for BTRFS):

1. Remove all **snapshots** of the VM.

2. From guest OS, fill all available disk space with zeros.
   ```
   cp /dev/zero z; sync    # fill with zeros
   rm z; sync              # leaving the zeros on disk
   poweroff
   ```

3. From host OS, compact the disk.
   ```
   VBoxManage modifymedium "file.vdi" --compact
   ```
