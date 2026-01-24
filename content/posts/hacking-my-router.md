+++
date = '2026-01-24T14:22:03Z'
draft = false
title = 'Hacking my Router to Steal Credentials'
+++
---
## introduction

hi guys, I am back with another exciting blog.

so recently I have been reading and watching a lot of videos on IoT hacking. An amazing channel for me is [matt brown's channel](https://www.youtube.com/@mattbrwn). He has a lot of good videos on how to get started and goes into quite a bit of depth.

after learning from all these resources, I decided to buy a cheap kit from temu and a cheap target router to get started with my IoT hacking journey.

this is all the stuff i got with the links (thank me later):
- [voltage converter](https://www.temu.com/goods.html?goods_id=601103359919041) (you actually dont need this)
- [jumper cables](https://www.temu.com/goods.html?goods_id=601100634340842)
- [mini usb cable for the UART adapter](https://www.temu.com/goods.html?goods_id=601099525729854)
- [soldering iron](https://www.temu.com/ie/lcd-wireless-rotating-device-6-speed-adjustable-speed-usb-quiet-fan-with--heat-dissipation-led-work-light-professional-for-polishing-drilling-and-carving-g-601102522728090.html) (the one I bought is not available now but this is similar)
- [UART to USB adapter](https://www.temu.com/goods.html?goods_id=601099816714734)
- [multimeter](https://www.temu.com/ie/-sz308-electrical-maintenance-mini-digital-multimeter-1999--ac--voltage-meter--current--measurement-instrument--diode-hfe--diode-multimetro-test-tools-no-battery-g-601102618091920.html)
- a simple DC 9V battery for the multimeter


and this is our target device for today:
the tplink (TL-WR841N)[https://www.tp-link.com/us/home-networking/wifi-router/tl-wr841n/] router. I bought it from a second hand website for €8 which was quite cheap.

and our objective is to learn how UART works and use it to find credentials for our router.

## initial recon

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

there is an http server open, an ssh server on port 22 (open by default lol), and a few ports open to support UPNP which I have no idea about.

signing into ssh obviously requires us to know the root or some other user's password on the device. Also, the web interface is protected by a login prompt asking for a username and password.

## finding UART
hacking this device externally is a bit difficult because you must have the device's WPA2 password. Lets assume we have physical access to the router and try to get this password.

the device looks like this from the outside.

![front](/hacking-my-router/front.jpg)
![back](/hacking-my-router/back.jpg)

on the back we can see the router name: TL-WR841N and the version as v9.3. there are some default things listed here as well like the default WPA2 password and default web login admin:admin (very original)

but as my mom always says: "it's the inside that counts" so lets take a look inside the router

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
