---
title: "Tunnels! Best Way to Access your Home Network from Outside 🚇🏠🌍"
date: 2025-08-11T16:40:19+00:00
summary: "One of my most cherished memories is the day I realized that my cousin, sitting in his house, could not connect to my minecraft server even after I gave him my IP address and port number! I remember thinking that all those youtube tutorials fooled me into..."
draft: false
---

### Traditional Methods 🏠

One of my most cherished memories is the day I realized that my cousin, sitting in his house, could not connect to my minecraft server even after I gave him my IP address and port number! I remember thinking that all those youtube tutorials fooled me into thinking that I could play minecraft with my cousin without him coming to my place. It was just too good to be true! Now I realise that those tutorials were only for people playing on the same network.

NAT (to know more about NAT, click [here](https://www.youtube.com/watch?v=FTUV0t6JaDA&ab_channel=PowerCertAnimatedVideos)) makes it impossible for someone to connect to your minecraft server even if they have your public IP and the port number on which the minecraft server is running on your computer. This is because in a NATed network, when a packet is coming into the network from outside, the router does not know where to route that packet to. Is it device 1? or device 2? or device 3? because each of these devices is designated a different private IP address which is different from the destination IP contained in the incoming packet. Let’s discuss some solutions to this problem.

![nat](/tunnels/nat.png)

### Dynamic DNS + Port Forwarding 🌐🔀

#### Port Forwarding 🎯➡️

This is one of the traditional techniques which would allow you to access your internal network from outside. In Port Forwarding, you explicitly tell the router to route any incoming traffic to a specific port to your machine. Therefore, if there is an incoming packet to the network, the router knows which internal device and port the packet needs to be routed to which enables a successful connection.

![port-forwarding](/tunnels/port-forwarding.jpg)

#### Dynamic DNS 🌍🔑

After setting up port forwarding successfully, we can directly connect to a minecraft server (or any other service) by using the public ip and port number. But what if we could use a domain name instead of having to remember an IP?

This is where Dynamic DNS comes in. It maps your home network’s public IP to a domain name which can easily be remembered. It is Dynamic in nature because for most ISPs the home network’s IP is not static and keeps changing so the DNS record has to be updated regularly. [DuckDNS](https://www.duckdns.org/) is an excellent service for Dynamic DNS and is completely free.

#### Combining The Two ⚡🤝

Watch this video on how to implement Port Forwarding + DuckDNS on your network to be able to access it from outside:

{{< youtube 0CQIwDH3yTo >}}

### Pros and Cons of Port Forwarding + Dynamic DNS ✅❌

#### Pros

- Simple to setup
- No need to setup a cloud instance
- Free
- Low latency

#### Cons

- Some ISPs may not allow you to configure firewall fully and may also block all incoming connections (due to [CGNAT](https://en.wikipedia.org/wiki/Carrier-grade_NAT)) making this option useless
- Exposes services directly to the internet which increases your attack surface
- Need to poke holes in the firewall
- You are in charge of encryption

### Tunnels 🚇

Now coming to the main topic of this article, Tunnels! They are the best way to get around this problem. With tunneling, there is no need to poke holes in your home network’s firewall to allow incoming traffic since an outbound connection is established first and then the traffic is moved through it. The different types can be broadly classified into 2 categories:

- VPN based tunneling
- Reverse tunneling

![tunnels](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExd3VrYTBiY3puZWE5OTd2MGJpNHk0ajBudWJ1ZDNubXRhcWZmdG0ybiZlcD12MV9naWZzX3NlYXJjaCZjdD1n/GpLmqwmHWGc5G/giphy.gif)

### VPN Based Tunneling 🔒🛜

This kind of tunneling allows you to create a VPN which basically emulates a LAN connection and you can access all the services within the network as if you are inside your home network. For example, if you have a media server running at 192.168.1.3:8080 in your home network, you can connect to your network using the VPN solution and access the media server at 192.168.1.3:8080. WireGuard, OpenVPN, Twingate are some examples of services that can be used to setup a VPN.

### Pros and Cons of VPN Based Tunneling ✅❌

#### Pros

- Creates an encrypted tunnel all the way which prevents snooping
- VPN services allow granular control over traffic which makes it excellent in terms of security
- Works even if ISP does not allow incoming connections or changes public IP of your router

#### Cons

- Not suitable for services meant to be publicly accessible
- Needs a VPN server and VPN client
- You need to open your client and connect to the vpn server every time you need to connect to home network
- Overkill if only a couple of services need to be exposed

### Reverse Tunneling 🔄🛰️

This type of tunneling allows you to do to setup a new connection from inside the network to an outside third party (could be a CDN like Cloudlflare or your self hosted server in the cloud). Once the connection is established, you can “tunnel” all your traffic through that connection. The server acts as a proxy between you and your home network and since there is already an established tunnel between your home network and the proxy server, all your traffic moves through it. Take a look at the diagrams given below.

![tunnels](/tunnels/image.png)
![tunnels](/tunnels/ssh-reverse-tunnelling.jpg)

Cloudflare Tunnel, Tailscale Funnel, Ngrok and Pangolin are some examples of services that allow you to setup reverse tunneling.

### Pros and Cons of Reverse Tunneling ✅❌

#### Pros

- No port forwarding or poking holes in your firewall required
- Easier to setup encryption (sometimes also handled by third-party like cloudflare)
- Very easy to setup
- Can be fine-tuned easily

#### Cons

- Requires reliance on third-party (unless self-hosted)
- Free tiers have restrictions (unless self-hosted)
- Latency issues because a proxy is involved

### TL;DR 📌

**Use Tunnels! They’re really good!**

### My Favorite - Reverse tunneling with [Pangolin](https://github.com/fosrl/pangolin) 🐧🚀

I have been using pangolin and cloudflare tunnels for my media server setup (on a raspberry pi) and I am very happy with both. Pangolin is free and open source however you do require your own cloud instance to set it up. On the other hand, Cloudlfare tunnel is free up to a certain bandwidth and costs money to buy extra bandwidth but you dont need to setup a cloud instance.

Here is a video that shows you how to setup pangolin for your home network:

{{< youtube id="g5qOpxhhS7M" start=560 >}}

There are various other tunneling tools available [here](https://github.com/anderspitman/awesome-tunneling)
