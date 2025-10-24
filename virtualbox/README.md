# VirtualBox related stuffs

## Setting display memory to 256MB

From GUI,
  1. Enable *3D Acceleration*
  2. Set *Video Memory* to max (256MB)
  3. Save
  4. **Go back** and disable *3D Acceleration*.  Check the video memory is still 256MB.
  5. Save **again**

From command line,
  1. `VBoxManage modifyvm "VM_Name" --vram 256`


## Loading Guest Addition

1. Update to the latest.  Install packages for compiling kernel modules.

    **Debian/Ubuntu**:
    ```
    sudo apt update
    sudo apt dist-upgrade
    sudo apt install build-essential dkms linux-headers-$(uname -r)
    ```

    **Redhat/Fedora**:
    ```
    sudo dnf distro-sync
    sudo dnf install kernel-devel kernel-headers gcc make bzip2 dkms
    ```

    **OpenSUSE**:
    ```
    sudo zypper refresh
    sudo zypper dist-upgrade (or dup)
    sudo zypper install kernel-devel gcc make
    ```

2. Install Guest Additions.  Reboot to use the VirtualBox kernel modules.

   **all**:
   ```
   sudo /.../VBoxLinuxAdditions.run
   sudo reboot
   ```
