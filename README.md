# renpy-termux-launcher
A RenPy game launcher for Termux, running natively on device architecture without changing RenPy engine version (what JoiPlay does) or emulating (what Winlator does).
>[!WARNING]
> You will need Internet to download RenPy SDK if the engine version is different!<br>
> If you're playing a game that uses the same engine version the downloaded SDK is, then the script will re-use that instead.

<img width="1548" height="720" alt="screenshot" src="https://github.com/user-attachments/assets/ff059a29-8b95-417a-a414-63d9dd1f03be" />

---
<details>
<summary>Why?</summary>
For a while, JoiPlay has been my go-to solution for RenPy games. But it has changed.
Since I want to play on both my phone and PC, I used a USB drive to copy the game into, so I can play the game wherever I go.
But, there is an issue:

<img width="566" height="270" alt="image1" src="https://github.com/user-attachments/assets/e7d26500-c009-420f-b500-462db7fa13a9" />
  
This is caused by using a newer RenPy version save file onto an older one.

After that, I tried Winlator.
The convenience is that the engine version is still the same, so save files will work just fine.
But, for games that has character customization screen (like A Date With Death, Knee Deep in love, ...), the game will just crash (probably due to GPU driver issue).
Also, the game takes 3 minutes just to start up.

Then I thought: "There is RenPy for ARM, why don't I use that instead?"
And this repo is the result.
</details>

## Part 1: Setup
**1. Here is everything you'll need:**
- [Termux](https://github.com/termux/termux-app/releases/latest)
- [Termux:X11](https://github.com/termux/termux-x11/releases/latest)
- [Termux-API](https://github.com/termux/termux-api/releases/latest) (optional, unless you're using USB drive)

**2. Open Termux and setup all the things you will need**
- Run this script:
```bash
bash <(curl -Lf https://raw.githubusercontent.com/sabamdarif/termux-desktop/main/setup-termux-desktop)
```
- When it asks for a destop environment, use `dwm`. It is the lightest one.
- Press `yes` when the script asks about file browser addon/optimization.
- Make sure to enable hardware acceleration according to your device, setup a normal account (using `root` to run games is risky), sound is optional but recommended.
- Select `Skip` for any app installation.
- When asked for Distro containers, use `Debian`.
- Do not select `zsh`! We will be using `bash` for the time being.
- Select `Termux:X11`, `VNC` can also be used but it's really unstable.

- After everything is installed, run this command:
```bash
nano .bashrc
```
- And comment out the following lines (by adding `#`):
```
# Start Termux:X11
# termux_x11_pid=$(pgrep -f com.termux.x11)
# if [ -z "$termux_x11_pid" ]; then
# echo "[0m[32mStarting Termux:x11...[0m"
# tx11start
# fi
```

- Next, login into the Debian container:
```
proot-distro login debian --user ** your username that you setup before **
```
- And install `xfce4`:
```
sudo apt install xfce4
```
- Then exit the container:
```
exit
```

**3: Setup automatic start for Proot**
- Run this command:
```bash
cd ~
wget https://raw.githubusercontent.com/LinuxDroidMaster/Termux-Desktops/main/scripts/proot_debian/startxfce4_debian.sh
nano startxfce4_debian.sh
```
- Replace `droidmaster` with your username, press `Control + X`, then `Y`, then `Enter`.
- Run `nano .bashrc` and add the following lines:
```
# Start Proot
echo "Starting Proot environment..."
sh ~/startxfce4_debian.sh
```

**4: Setup launcher**
- Run this command:
```bash
cd ~
wget https://raw.githubusercontent.com/MinatoIsuki/renpy-termux-launcher/main/launch.sh
nano launch.sh
```
- Modify `USB_PATH` to where you store all your games at (e.g. `~/storage/shared/Games`, depend on how you setup your games library)
- Press `Control + X`, then `Y`, then `Enter`.

**5: Start container and run the launcher**
- Run `sh ~/startxfce4_debian.sh` or restart Termux
- In the container, double tap on the `Home` icon, and click on `home` on the left bar.
- Right-click (or two finger tap) then click on `Open Terminal here`.
- Run:
```
chmod +x launch.sh
./launch.sh
```
- All done! Now select your game and the script will do everything else automatically!

## Part 2: Optization
- Open Termux:X11 preferences (clicking on the cogwheel icon or `Preferences` button on the notification)
  + `Output` > Display resolution mode > custom > 960x540
  + Display filtering mode > bilinear
  + Fullscreen > on
  + `Pointer` > Touchscreen input mode > Simulated touchscreen
  + `Keyboard` > Show additional keyboard > Off (to show the keyboard, do a Back gesture)
- To automatically run the launcher when the container is started:
  + Applications > Settings > Settings Manager
  + Session and Startup (scroll down by sliding down with 2 finger) > Application Autostart
  + Add > Enter Name and Description > Click on the folder next to the `Command` box
  + Navigate to where the `launch.sh` script is at, click on it and press OK.
  + Add the following line in the beginning of the command: `zutty -e` and wrap the file path in double quotes. It should look like:
  ```
  zutty -e "/data/data/com.termux/files/home/launch.sh"
  ```
  + Trigger > on login > OK

## Part 3: Weird quirks
- [Killer Chat](https://rosesrot.itch.io/killer-chat) uses RenPy 8.4.2. What? That version doesn't even exist! How???
  - RenPy 8.4.1 works just fine. To fix this, open `KillerChat-1.4.3-pc/game/script_version.txt` and edit to `(8, 4, 1)`.


# Enjoy!
**Special thanks to:**
- [sabamdarif/termux-desktop](https://github.com/sabamdarif/termux-desktop)
- [LinuxDroidMaster/Termux-Desktops](https://github.com/LinuxDroidMaster/Termux-Desktops/#proot-distro)
