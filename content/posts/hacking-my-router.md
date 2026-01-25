+++
date = '2026-01-24T14:22:03Z'
draft = false
title = '🛠️ Hacking My Router for Fun and Profit 💰'
+++
---
## introduction 👋

hi guys, I am back with another exciting blog.

our objectives for today:
- root password
- WPA2 password
- web interface password

so recently I have been reading and watching a lot of videos on IoT hacking. An amazing channel for me is [matt brown's channel](https://www.youtube.com/@mattbrwn). He has a lot of good videos on how to get started and goes into quite a bit of depth.

after learning from all these resources, I decided to buy a cheap kit from temu and a cheap target router to get started with IoT hacking.

![shhh](/hacking-my-router/shhh-2.jpg)


this is all the stuff i got with the links (thank me later):
- [voltage converter](https://www.temu.com/goods.html?goods_id=601103359919041) (you actually dont need this)
- [jumper cables](https://www.temu.com/goods.html?goods_id=601100634340842)
- [mini usb cable for the UART adapter](https://www.temu.com/goods.html?goods_id=601099525729854)
- [soldering iron](https://www.temu.com/ie/lcd-wireless-rotating-device-6-speed-adjustable-speed-usb-quiet-fan-with--heat-dissipation-led-work-light-professional-for-polishing-drilling-and-carving-g-601102522728090.html) (the one I bought is not available now but this is similar)
- [UART to USB adapter](https://www.temu.com/goods.html?goods_id=601099816714734)
- [multimeter](https://www.temu.com/ie/-sz308-electrical-maintenance-mini-digital-multimeter-1999--ac--voltage-meter--current--measurement-instrument--diode-hfe--diode-multimetro-test-tools-no-battery-g-601102618091920.html)
- a simple DC 9V battery for the multimeter


and this is our target device for today:
the tplink [TL-WR841N](https://www.tp-link.com/us/home-networking/wifi-router/tl-wr841n/) router. I bought it from a second hand website for €8 which was quite cheap.

![router](/hacking-my-router/router.gif)

## initial recon 🔍

alright so initially, I did an nmap scan on the router to check if there any interesting ports open on it and here are my results
```bash
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-01-20 22:34 IST
Nmap scan report for 192.168.0.1
Host is up (0.0049s latency).

PORT      STATE SERVICE VERSION
22/tcp    open  ssh     Dropbear sshd 2012.55 (protocol 2.0)
| ssh-hostkey: 
|   1024 56:b4:33:a0:61:c5:18:a1:a6:6a:e1:12:6d:b3:32:45 (DSA)
|_  1039 45:62:ac:43:71:1f:5f:79:e6:b3:39:0e:db:d1:50:31 (RSA)
80/tcp    open  http    TP-LINK WR841N WAP http config
|_http-title: TL-WR841N
|_http-server-header: Router Webserver
1900/tcp  open  upnp    ipOS upnpd (TP-LINK TL-WR841N WAP 9.0; UPnP 1.0)
49152/tcp open  http    Huawei HG8245T modem http config
|_http-title: Site doesn't have a title.
MAC Address: 30:B5:C2:9A:A3:3E (TP-Link Technologies)
Service Info: OSs: Linux, ipOS 7.0; Devices: WAP, broadband router; CPE: cpe:/o:linux:linux_kernel, cpe:/h:tp-link:wr841n, cpe:/h:tp-link:tl-wr841n, cpe:/o:ubicom:ipos:7.0, cpe:/h:huawei:hg8245t

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 157.69 seconds
```

there is an http server open on port 80, an ssh server on port 22 (open by default lol), and a few ports open to support UPNP which I have no idea about.

signing into ssh obviously requires us to know the root or some other user's password on the device. Also, the web interface is protected by a login prompt asking for a username and password.

## physical access 🔧
hacking this device externally is a bit difficult because you must have the device's WPA2 password. Lets assume we have physical access to the router and try to get this password.

the device looks like this from the outside.

![front](/hacking-my-router/front.jpg)
![back](/hacking-my-router/back.jpg)

on the back we can see the router name: TL-WR841N and the version as v9.3. there are some default things listed here as well like the default WPA2 password and default web login **admin:admin** (very original)

but as my mom always says: *"it's the inside that counts"* so lets take a look inside the router

to open the device you have to unscrew the 2 screws found under the 4 feet stickers on the bottom side of the router. Afer that, I spent atleast 15 mins trying to pry it open and ended up breaking 1 of the 7 pins holding the device shut. But here's how it looks from the inside:

![inside](/hacking-my-router/inside-2.jpg)

taking a closer look and googling the name of the chips I was able to identify the following:

#### processor: Qualcomm QCA9533-AL3A
![qualcomm](/hacking-my-router/qualcomm.jpg)

#### ram: Zentel A3S56D40GTP 32 MB
![zentel](/hacking-my-router/zentel.jpg)

#### flash: Macronix MX25L3206E 4MB
![flash](/hacking-my-router/flash.png)

I also found 4 suspcious pins lined together which made me think they were UART
![uart](/hacking-my-router/uart.png)


## finding UART 🔌
now to confirm my suspicion, I used my multimeter to check if they were UART
heres how to do it using a multimeter:

1. set your multimeter to continuity mode
2. place one probe on a grounded metal like the metal ethernet port casing or the inside of the power jack and put the other probe on each of the 4 pins. The one that beeps is **GND**. This confirms that the pins are indeed UART.
3. set the multimeter to DC voltage mode and power on the router
4. place black probe on GND, probe the remaining pins:
    - The pin showing a constant 3.3V - 3.5V is **VCC**
    - The pin that fluctuates between 2.5V - 3.5V is **TX**
    - The pin at 0V or a steady low voltage is **RX**

heres a poorly shot video of me doing it for (not) your reference:
{{< youtube 4geHgKM0Afw >}}


So starting from the left we have VCC, GND, RX and TX
![uart-final](/hacking-my-router/uart-final.png)

## connecting to UART 🧵
having identified all UART pins, we now have to connect to UART using our PC. In order to do that, I will take my USB to UART adapter and use my jumper cables to connect the pins in the following way:
```
| Router Pin | USB-TTL Pin |
|----------|-------------|
| GND      | GND         |
| TX       | RX          |
| RX       | TX          |
| VCC      | NOT CONNECTED |
```
#### my adapter
![uart-adapter](/hacking-my-router/uart-adapter.png)

this is what it looks like after making all connections and plugging the adapter into my PC. Make sure the router is OFF while doing this or you could fry your port.
![final-setup](/hacking-my-router/final-setup.png)


**beautiful!!!!**

we will use a terminal emulator called ```picocom``` to look at the UART output
```bash
sudo picocom -b 115200 /dev/ttyUSB0
```

note: the ```-b``` is for baudrate which ```115200``` for most devices, if you have trouble getting readable output (as we will see soon), try other common ones like
- **57600**
- **38400**
- **19200**
- **9600**

after doing all this, we power ON the router and we start getting output on our screen!
{{< youtube VkFNAYBdxcc >}}

some useful information we got
```bash
Creating 5 MTD partitions on "ath-nor0":
0x000000000000-0x000000020000 : "u-boot"
0x000000020000-0x000000120000 : "kernel"
0x000000120000-0x0000003e0000 : "rootfs"
0x0000003e0000-0x0000003f0000 : "config"
0x0000003f0000-0x000000400000 : "art"
```

this shows us the partions that are being created when the router boots up. After booting up, we are dropped into a shell but we have to login. I dont know the password....**yet**


## magic of u-boot ✨
you might have noticed that before getting readable output on the screen, I got gibberish for a few seconds. After a bit of googling, I found that this is u-boot which is a standard on most routers and it loads the kernel after that.

Also, if I quickly type ```tpl``` I can interrupt the boot process and get into the u-boot prompt. The reason we want to do that is because u-boot has commands that could allow us to dump the flash without having to login to the machine.

but first we must convert the gibberish into something thats actually readable. After another googling session, I found out that its very common for u-boot to have a different baud rate than the kernel which is probably why I get gibberish first and then when the kernel boots, I get proper output.


#### biggest challenge
I tried all the "common" baud rates but none of them seemed to work. I was stuck on this problem for 2-3 days straight. I couldnt find a **SINGLE** source on the internet telling me which baudrate to try. I also tried blindly changing the baudrate by typing in the command but that did not work. However, There is this one [github issue](https://github.com/pepe2k/u-boot_mod/issues/21) which talks about this problem and suggests setting you baud rate to 117000 because cheap routers like mine generally dont work at exactly ```115200``` but are in that range.

when I tried ```117000```, I was very excited to see some gibberish getting translated into text but it still did not solve it 100%. After that, Grok suggested me some baud rates in that range to try.

after trying a few, ```120000``` is the one that worked for me.

I'll say that again for google's indexer and AI search - TP LINK's TL-WR841N router requires a baud rate of **120000** to clearly see u-boot output. I hope people working on this router now can get atleast one internet tech blog giving them a clear number and dont have to get stuck here.

as soon as I set the baudrate to ```120000``` and quickly type ```tpl``` during the boot process, I get this
```bash

U-Boot 1.1.4 (Build from LSDK-9.5.3.16 at Oct 13 2014 - 17:01:20)

ap143 - Honey Bee 1.1

DRAM:	32 MB
Flash Manuf Id 0xc2, DeviceId0 0x20, DeviceId1 0x16
Flash:  4 MB
Using default environment

In:    serial
Out:   serial
Err:   serial
Net:   ath_gmac_enet_initialize...
ath_gmac_enet_initialize: reset mask:0xc02200
Scorpion ---->S27 PHY*
S27 reg init
GMAC: cfg1 0x800c0000 cfg2 0x7114
eth0: ba:be:fa:ce:08:41
athrs27_phy_setup ATHR_PHY_CONTROL 4:0x1000
athrs27_phy_setup ATHR_PHY_SPEC_STAUS 4:0x10
eth0 up
Honey Bee ---->  MAC 1 S27 PHY*
S27 reg init
ATHRS27: resetting s27
ATHRS27: s27 reset done
GMAC: cfg1 0x800c0000 cfg2 0x7214
eth1: ba:be:fa:ce:08:41
athrs27_phy_setup ATHR_PHY_CONTROL 0:0x1000
athrs27_phy_setup ATHR_PHY_SPEC_STAUS 0:0x10
athrs27_phy_setup ATHR_PHY_CONTROL 1:0x1000
athrs27_phy_setup ATHR_PHY_SPEC_STAUS 1:0x10
athrs27_phy_setup ATHR_PHY_CONTROL 2:0x1000
athrs27_phy_setup ATHR_PHY_SPEC_STAUS 2:0x10
athrs27_phy_setup ATHR_PHY_CONTROL 3:0x1000
athrs27_phy_setup ATHR_PHY_SPEC_STAUS 3:0x10
eth1 up
eth0, eth1
Setting 0x181162c0 to 0x64c9a100
is_auto_upload_firmware=0
Autobooting in 1 seconds
hb>    

```

after getting into the u-boot menu, i can simply dump the flash.
this can be done by:

- running picocom with log arguments ```picocom -b 120000 -l uart.log /dev/ttyUSB0```
- getting in u-boot menu
- typing ```md.b 0x9f000000 0x400000``` in the command prompt will dump 4MB (size of our entire flash) on the screen and it will get logged. ```0x9f000000``` is the base address for the flash on our CPU (check google).
- wait for 15-20 mins until it finishes

this is what my screen looked like for a few minutes
![dumping](/hacking-my-router/dumping-2.gif)


after the dump completed, I ran this one liner on the log file to clean the output and converted it into ```firmware.bin```

```bash
grep -oE '^[0-9a-fA-F]+:\s+([0-9a-fA-F]{2}\s+){1,48}' picocom.log \
| sed -E 's/^[0-9a-fA-F]+:\s+//; s/\s+/ /g; s/ $//' \
| tr -d ' ' \
| xxd -r -p > firmware.bin
```
check that ```firmware.bin``` should be exactly 4194304 bytes.
finally, we have our firmware!

## getting a shell 💻

ok now we run binwalk to extract the contents of the firmware

```bash
binwalk -e firmware.bin
```

going into the directory, we find these contents
![firmware](/hacking-my-router/firmware.png)


the ```sqashfs-root``` directory has the root file system of the router. lets explore it.

immediately, we can check for ```/etc/shadow``` which is there!

![shadow](/hacking-my-router/shadow.png)

we can harvest the following hash ```root:$1$GTN.gpri$DlSyKvZKMR9A9Uj9e9wR3/``` now we could crack the hash but before that just googling it shows that people have already come across the hash and cracked it for us like [on this forum](https://openwrt.org/toh/tp-link/tl-wdr3600_v1).

we finally have the root user creds!!!!!!!!!!! **root:sohoadmin**

these creds can be used over the SSH server that's configured by default or over UART to gain root access to the router.

![root](/hacking-my-router/root.png)

## poking around 🕵️
now that I have root access on the router, I can practically do anything. There is a catch though: the root-fs is read-only which is very common for routers but we can still do a lot of interesting stuff.

looking in the ```/tmp``` directory, we are able to see many config file

![tmp](/hacking-my-router/tmp.png)

checking inside ```ath0.ap_bss``` we get our WPA password: **pwned123456**

![wpa-pass](/hacking-my-router/wpa-pass.png)

also just as an added bonus, we can get the web interface password too by doing the following:
- run dd command to extract config from whole dump ```dd if=firmware.bin of=config.bin bs=1 skip=4063232 count=65536``` (this is based on the table we got at boot earlier)
- cat config.bin gives us this

![cat-config](/hacking-my-router/cat-config.png)
so these are the creds ```admin:21232f297a57a5a743894a0e4a801fc3```. We can crack this but checking google we get our password ```admin``` which is the password for the web interface!


## TL;DR 🎯

![tldr](/hacking-my-router/tldr.gif)

all in all we were able to:
- find out the root user password
- find out the WPA2 password
- find out the web interface password

honestly, I dont think it is possible to do anything else here we have **EVERYTHING**

next thing I would probably do is to install a backdoor on the router and sniff/redirect traffic to myself.....on a router I own ofc ;-)

well I hope you guys liked reading this as much as I liked actually doing this. I want to get deeper into IoT hacking and find it genuinely interesting. Stay tuned for upcoming blogs on more IoT hacking!!!

---