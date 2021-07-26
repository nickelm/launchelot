# Launchelot: A Launcher for Dark Age of Camelot

Launchelot is a launcher and toon management tool for the MMO Dark of Age of Camelot (DAoC)! Launchelot was created by Madgrim Laeknir in response to the venerable Mojo launcher being closed down. Launchelot is built using AutoHotKey (AHK) and enables you to easily manage your accounts and toons (and eventually teams), and to launch them.

## Installing Launchelot
To install Launchelot, follow the below steps:
1. Download the script and put it in a separate folder.
2. Make sure you have AutoHotKey installed (there is also a standalone version that does not require AutoHotKey).
3. Run the script by double-clicking (you may need to right-click and run as administrator).
4. If this is the first time you are running Launchelot, you will be asked to pinpoint the DAoC game folder on your hard drive.

Running Launchelot for the first time will create a database file called launchelot.ini in the same folder. This file will contain your character and account information (including passwords, but encoded).

## Running Launchelot
Launchelot has a simple interface similar to the now-defunct Mojo launcher. On the Toons tab, you can add, edit, and delete your toons, as well as double-click them to launch the game. On the Accounts screen, you can accordingly add, edit, and delete your game accounts from the launchelot.ini file. On the Teams screen, you manage your teams (note that Launchelot itself does not contain multibox functionality).

You can also configure Launchelot to automatically run an AHK script when booting your toon; merely add the script name in the toon information (see the "Script" column in the screenshot above). Currently, Launchelot assumes that your script file resides in the same folder as the Launchelot utility itself.

## Feedback and Bug Reports

Please get in touch with me as BelomarFleetfoot#0319 on Discord (Madgrim on the Official DAoC Discord). Please note that this utility is provided as-is and with no guarantees; use at your own risk.

## Frequently Asked Questions
### Q: Are my passwords secure?

A: Your passwords are encoded using the Windows encode64/decode64 functions, which means that the passwords are never stored in clear text. (Note that this is not encryption; merely obfuscation.) There is no Launchelot server that is receiving any data from your computer. Your passwords are quite safe, at least from the perspective of Launchelot.

### Q: Does Launchelot support multiboxing?

A: Currently no, but I have other AHK scripts under development to replicate a lot of Mojo's multiboxing functionality. I eventually hope to be able to provide all of the features of Mojo's multiboxing, as well as some innovations. However, this will likely be separate from Launchelot itself, as multiboxing really is conceptually different from launching toons. 

### Q: I have a bug report or suggestion for Launchelot. Where do I send it?

A: Contact me on Discord as BelomarFleetfoot#0319.

### Q: Will Launchelot patch DAoC for me?

A: It will not, and it will not even notice if the game needs patching. You will have to run the standard DAoC patcher once in order to patch the game before you can launch toons again.

## Credits
Thanks to Teehehe for help in developing this script.
