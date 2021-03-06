NextionDriver (for MMDVMHost)
=============================

The purpose of this program is to provide additional control for
Nextion display layouts other than the MMDVMHost supplied layouts.
It does this by sitting between MMDVMHost and the Nextion Display.
This program takes the commands, sent by MMDVMHost and translates,
changes, adds or removes these commands.

The program will have to read MMDVM.ini to know the Layout, so it
can set the baudrate accordingly.

The program can take some commandline parameters, but it also is 
possible to set the configuration parameters in the MMDVM configuration
file by adding an extra section [NextionDriver].

The NextionDriver program will change the commands as needed and adds 
extra info (i.e. temperature, TG's info, ...) and sends this to 
the Nextion display.

This program also checks the network interface regularly, and it will
show the most recent IP address, so you can check if the IP address
changed.

When the files 'groups.txt' and 'stripped.csv' are present, user and
talkgroup names will be looked up and sent to the display.  
NOTE1 : both files have to be sorted in ascending ID order !  
NOTE2 : for the user data lookup to work, you MUST switch off 
         the DMRID lookup of MMDVMHost (check README-examples
         in the Nextion subdirectory)

The program also has the ability of receiving commands from the Nextion
display. This way, one can provide buttons on a layout and do something
in the host when such a button is pressed.
One could, for example, make a 'system' page on the Nextion with system
info and buttons to restart MMDVMHost, reboot or poweroff the host, ...

Yes, it is possible (when NextionDriver is running) to start/stop/restart
MMDVMHost with buttons on the Nextion display !


How to use this program ?
=========================

| Pi-Star users : check my website on7lds.net |
| ------------------------------------------- |


after compiling with  
   make

you should have a binary  
   NextionDriver  
  
You can start this program in _debug mode_, then all commands that are sent
to the display, will be printed to stdout.
Or you can start this program in _normal mode_, then it will go to the 
background and do its work quietly (start and stop of the program
will be logged in syslog)  

The most practical way to start is by specifying only one parameter:
 the place of the MMDVMHost configuration file. 
This way, all configuration can be done in the ini file.

./NextionDriver -c /etc/MMDVM.ini

will start NextionDriver from the current directory and read all parameters from
the MMDVMHost ini file.


You can get the necessary changes in your MMDVMHost configuration file by
executing the patch script

./NextionDriver_ConvertConfig <MMDVMHost configuration file>

Then the script will make a backup of your current config and do the changes for you.


In case you want to do it by hand :
In your MMDVMHost configuration file (mostly MMDVM.ini), make a section as below:

```
[NextionDriver]
Port=/dev/ttyAMA0
LogLevel=2
DataFilesPath=/opt/NextionDriver/
GroupsFile=groups.txt
DMRidFile=stripped.csv
```


**IMPORTANT**
In the MMDVM.ini [Nextion] section you have to specify the NextionDriver's
virtual port as the port to connect to :
```
[Nextion]
Port=/dev/ttyNextionDriver
...
```
to tell MMDVMHost to talk to our program an not directly to the display !


Modem-connected displays
========================
As of V1.03 the NextionDriver has support for Nextion displays which are connected to the modem ('Port=modem' in MMDVM.ini)
For this, it is *necessary* to use the MMDVMHost code dated 20180815 or later ((GitID #f0ea25d or later) !

In the MMDVM.ini file, you have at least to enable 'Transparent Data' an it's option 'SendFrameType', i.e. :

[Transparent Data]
Enable=1
RemoteAddress=127.0.0.1
RemotePort=40094
LocalPort=40095
SendFrameType=1

Then you can instruct NextionDriver to use the Transparent Data
to connect to the display. This is done by setting the 'Port' option in
the NextionDriver section of MMDVM.ini to 'modem'

[NextionDriver]
Port=modem
...




How to autostart this program ?
===============================
when systemd is used :
(files are found in /etc/systemd/system being links to
 the real files in /lib/systemd/system/ )

First you alter mmdvmhost.service by adding the 'BindsTo' line
This will tell the service it needs nextion-helper.service
before starting MMDVMHost

mmdvmhost.service
```
[Unit]
Description=MMDVM Host Service
After=syslog.target network.target
BindsTo=nextion-helper.service

[Service]
User=root
WorkingDirectory=/opt/MMDVMHost
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/screen -S MMDVMHost -D -m /opt/MMDVMHost/MMDVMHost /opt/MMDVM.ini
ExecStop=/usr/bin/screen -S MMDVMHost -X quit

[Install]
WantedBy=multi-user.target
```



Then you make a service 'nextion-helper.service'
where you tell it needs to start before MMDVMHost :


nextion-helper.service
```
[Unit]
Description=Nextion Helper Service Service
After=syslog.target network.target
Before= mmdvmhost.service

[Service]
User=root
WorkingDirectory=/opt/MMDVMHost
Type=forking
ExecStart=/opt/NextionDriver/NextionDriver -c /opt/MMDVM.ini
ExecStop=/usr/bin/killall NextionDriver

[Install]
WantedBy=multi-user.target
```

How to change this program to your needs ?
==========================================

The program has a lot of functions included, but those who want to add even 
more could do so.
There are 2 files you could change :

Data to the Nextion Display
---------------------------
the routine process() in processCommands.c

* this routine is called for each command, sent by MMDVMHost. The command
  which is sent, is in RXbuffer (without the trailing 0xFF 0xFF 0xFF).
* the RXbuffer holds a string, so it is not possible to send 0x00 characters
* you can inspect, change or add commands, but keep in mind that at the end of
  the routine the RXbuffer (if not empty) is sent to the Nextion display
  (empty the buffer if you do not want to send something to the display)

Data from the Nextion Display
-----------------------------
the routine processButtons() in processButtons.c

* This routine is called whenever there is an event sent from the display.
  For this you have to make a button on the Nextion display which has in its
  Touch Release Event following code:  
   printh 2A  
   printh (code nr)  
   printh FF  
   printh FF  
   printh FF  

where (code nr) is a number 0x01...0xEF (look sharp: 0xEF NOT 0xFF !)
The command is in the RXbuffer (without the trailing 0xFF 0xFF 0xFF).

Then there are some special codes :

* when there is a command  
   printh 2A  
   printh F0  
   printh (linux command)  
   printh FF  
   printh FF  
   printh FF  
  
the 'linux command' is executed  
  
* When there is a command  
   printh 2A  
   printh F1  
   printh (linux command)  
   printh FF  
   printh FF  
   printh FF  
  
the 'linux command' is executed and the __FIRST__ line of the result
is sent to the display variable 'msg'  

There is an example HMI file included.   
Press on the MMDVM logo on the main screen to go to the 'system' page  
