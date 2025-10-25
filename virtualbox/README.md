# VirtualBox related stuffs

## Setting display memory to 256MB

From GUI,
  1. Enable **3D Acceleration**
  2. Set **Video Memory** to max (256MB)
  3. Save
  4. Go back and disable **3D Acceleration**.  Check the video memory is still 256MB.
  5. Save again

From command line,
  1. `VBoxManage modifyvm {VM Name} --vram 256`


## Loading Guest Addition

1. Update to the latest.  Install packages for compiling kernel modules.

    **Debian/Ubuntu**:
    ```
    sudo apt update
    sudo apt dist-upgrade
    sudo apt install build-essential dkms linux-headers-$(uname -r)
    ```

    **Fedora**:
    ```
    sudo dnf distro-sync
    sudo dnf install kernel-devel kernel-headers dkms gcc make bzip2
    ```

    **OpenSUSE**:
    ```
    sudo zypper refresh
    sudo zypper dist-upgrade  # or dup
    sudo zypper install kernel-devel gcc make
    ```

2. Install Guest Additions.  Add user to group **vboxsf** if you've configured "Shared Folders".
   ```
   sudo /.../VBoxLinuxAdditions.run
   sudo usermod -a -G vboxsf {user}
   ```

4. Reboot to pickup new kernel modules and new group id.
   ```
   sudo reboot
   ```

## Compacting disk

1. Remove all snapshots linked to the disk.
   
2. From guest OS, fill all available disk space with zeros.
   ```
   sudo dd if=/dev/zero of=z bs=1M     # fill with zeros
   sync
   sudo rm z      # leaving the zeros on disk
   poweroff
   ```

3. From host OS, compact the disk.
   ```
   VBoxManage modifymedium {file}.vdi --compact
   ```
