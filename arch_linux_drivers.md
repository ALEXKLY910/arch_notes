1. Enable `multilib` repository so that you can install 32 bit software using `pacman`:
   - open up `pacman`'s configuration file:

     > `sudo nano /etc/pacman.conf`

   - uncomment the `[multilib]` section. Save the changes and close the file:

     > [multilib]  
     > Include = /etc/pacman.d/mirrorlist

   - update the package databases to enable the changes. The following command will also update the installed packages to be up-to-date:

     > `sudo pacman -Syu`

## The following section is for Intel GPUs

2.  Install **Mesa** _userspace driver stack_. Without it the system would render graphics using CPU which is ineffective in all the possible ways.
    1. Install `mesa`, `lib32-mesa` and `mesa-utils` packages. The `lib32-mesa` is required for 32 bit applications to use **Mesa**. The `mesa-utils` will be needed for checking that the drivers are working:

       > `sudo pacman -S mesa lib32-mesa mesa-utils`

    2. To verify the installation, run:

       > `eglinfo -B > eglinfo.txt`

       Open up the file and look for something like this:

       > OpenGL core profile vendor: **Intel**  
       > OpenGL core profile renderer: **Mesa Intel(R) HD Graphics 620 (KBL GT2)**

       That is, the core profile renderer is your GPU, and not something like `llvmpipe` - the default CPU renderer.

       Note though, that it will list `llvmpipe` as the fallback renderer somewhere. It would probably be listed under the last device.

3.  Install **Vulkan** _userspace driver stack_. Without it apps that need Vulkan won't work at all.
    1. Install the packages:

       > `sudo pacman -S vulkan-icd-loader vulkan-intel lib32-vulkan-icd-loader lib32-vulkan-intel vulkan-tools`

    2. To verify that **Vulkan** support is up, run:

       > `vulkaninfo > vulkaninfo.txt`

       Open up the file and look for info about your graphics card. Look for `GPU0` and check out the `deviceName`. It should be the name of your actual GPU.

4.  Configure video acceleration. I'll use **VA-API**.
    1. For even vaguely modern systems, install `intel-media-driver`. Also install `libva-utils` for checking that it works:

       > `sudo pacman -S intel-media-driver libva-utils`

    2. To verify that it works, run:

       > `vainfo > vainfo.txt`

       If it prints stuff like this, you're good. If it prints some kind of error, there are issues:

       ```
       Trying display: wayland

       Trying display: x11
       Trying display: drm
       vainfo: VA-API version: 1.22 (libva 2.22.0)
       vainfo: Driver version: Intel iHD driver for Intel(R) Gen Graphics - 25.3.4 ()
       vainfo: Supported profile and entrypoints
       VAProfileNone : VAEntrypointVideoProc
       VAProfileNone : VAEntrypointStats
       VAProfileMPEG2Simple : VAEntrypointVLD
       VAProfileMPEG2Simple : VAEntrypointEncSlice
       VAProfileMPEG2Main : VAEntrypointVLD
       VAProfileMPEG2Main : VAEntrypointEncSlice
       VAProfileH264Main : VAEntrypointVLD
       VAProfileH264Main : VAEntrypointEncSlice
       VAProfileH264Main : VAEntrypointFEI
       VAProfileH264Main : VAEntrypointEncSliceLP
       VAProfileH264High : VAEntrypointVLD
       VAProfileH264High : VAEntrypointEncSlice
       VAProfileH264High : VAEntrypointFEI
       VAProfileH264High : VAEntrypointEncSliceLP
       VAProfileVC1Simple : VAEntrypointVLD
       VAProfileVC1Main : VAEntrypointVLD
       VAProfileVC1Advanced : VAEntrypointVLD
       VAProfileJPEGBaseline : VAEntrypointVLD
       VAProfileJPEGBaseline : VAEntrypointEncPicture
       VAProfileH264ConstrainedBaseline: VAEntrypointVLD
       VAProfileH264ConstrainedBaseline: VAEntrypointEncSlice
       VAProfileH264ConstrainedBaseline: VAEntrypointFEI
       VAProfileH264ConstrainedBaseline: VAEntrypointEncSliceLP
       VAProfileVP8Version0_3 : VAEntrypointVLD
       VAProfileVP8Version0_3 : VAEntrypointEncSlice
       VAProfileHEVCMain : VAEntrypointVLD
       VAProfileHEVCMain : VAEntrypointEncSlice
       VAProfileHEVCMain : VAEntrypointFEI
       VAProfileHEVCMain10 : VAEntrypointVLD
       VAProfileHEVCMain10 : VAEntrypointEncSlice
       VAProfileVP9Profile0 : VAEntrypointVLD
       VAProfileVP9Profile2 : VAEntrypointVLD
       ```

## End of the section

5. Sound drivers. We'll install the default **PipeWire** stack.
   1. Run this to install:

      > `sudo pacman -S pipewire wireplumber pipewire-pulse pipewire-alsa`

   2. Run this to enable the drivers on every boot and also right now for this user session (it's meant to run in user sessions):

      > `systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service`

      If you have multiple users at once and want to enable this for all of them at the same time, change `--user` flag to `--global`.

   3. To check that the apps are now talking to **Pulse Audio**, run:

      > `pactl info`

      And look for the entry `Server Name: PulseAudio (on Pipewire ...)`
