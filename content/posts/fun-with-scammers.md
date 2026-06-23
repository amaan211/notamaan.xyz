+++
date = '2026-06-20T13:11:29Z'
draft = false
title = '😈 Scamming Scammers (Gone Wrong!) 😱'
+++
---

## introduction 👋

recently I was looking for side hustle opportunities to make some money on the side. During my research, I came across a great way to do this: **online tutoring**. Long story short, I created a profile on [superprof.ie](http://superprof.ie/) and was contacted by scammers. This is what happened next.

![emoji](/fun-with-scammers/emoji.png)

## initial contact 📩

being desperate for money, I created an account on [superprof.ie](http://superprof.ie/) which seemed like a good platform to find students within ireland. After creating the account, did not get any students (no shit) for a while so I gave up and started to look at other avenues to make money.

a few weeks later I got an email from superprof (legit superprof email) saying someone messaged me and wanted to book a session. I was surprised so I decided to check who it was. The email said the person called **"Ireland 🤍"** wanted to book sessions with me. When I accepted her lesson request, I got 2 more messages asking me to accept payment from her BEFORE the lesson (big red flag lol 🚩). The email also had a link for me to **"verify"** myself and accept payment (check screenshots below).

![email-1](/fun-with-scammers/email-1.png)
![email-2](/fun-with-scammers/email-2.png)
![email-3](/fun-with-scammers/email-3.png)

the following domain has been mentioned in the emails: **www.superprof[dot]com.ie@verification[dot]club\95700**

## what makes this a good phishing url 🎣

the url mentioned in the emails which was supposed to give me money was pretty good at doing its job because of the following reasons:

-  the url starts with "www.superprof.com.ie" which is a legitimate domain for the platform. According to RFC 3986, anything placed before the "@" symbol is treated as auth credentials meant to sign into the server which is why this domain name is treated as the username and not the destination domain by the browser and the actual target domain is verification[dot]club

-   the url is long enough that if a user on mobile clicks on the link, the browser might truncate the url to "www.superprof.com.ie....." due to limited screen width.

-   the "\\" character is actually invalid in a url but modern browsers change it to "/" to convert it into a valid url with the added bonus of being able to evade simple spam filters that look for rfc standard urls and ignore malformed ones.


## phishing website 🌐

clicking on the phishing link I was redirected to the following url:

**hxxps://superprof[dot]salesclub[dot]blog/order/CeqSMbwEYXK/**

the webpage looked like this and had a big button saying **"receive payment"**

![website-1](/fun-with-scammers/website-1.png)

you could also select the mode of payment but Paypal and Google Pay were conveniently **"temporarily unavailable"** leaving credit/debit card as the only option (maaaaajor red flag 🚩). I have no clue how you actually receive money using your credit or debit card but I still went ahead.

![website-2](/fun-with-scammers/website-2.png)

clicking on the receive button, we get a page which asks us to enter our bank card details like the card number, name, expiry and CVV. At this point, it is very clear that this is a scam and the scammers are just trying to steal your card details 

![website-3](/fun-with-scammers/website-3.png)

to play along, I tried entering fake card details into the form to see what happens. For the card number, I entered 1111 1111 1111 but it would not let me submit because the card number was not a valid visa or mastercard card number.

#### how to make a fake but valid visa card number?

time for some research, in order to submit the form properly I need to come up with a fake but valid visa card. Searching online, I found the following should be true:

- starts with 4
- length is usually 16 digits (can also be 13, 18, or 19 digits in some cases)
- passes the [luhn algorithm](https://stripe.com/in/resources/more/how-to-use-the-luhn-algorithm-a-guide-in-applications-for-businesses)

i also found credit card numbers for testing [here](https://www.paypalobjects.com/en_GB/vhelp/paypalmanager_help/credit_card_numbers.htm)


## back in business 🔄

using the test credit card numbers, we are able to submit the form

![website-4](/fun-with-scammers/website-4.png)

as bonus, the scammers ask us our current balance in the account to make sure they dont overcharge the account 😆

after entering a number and pressing "Continue" we get the following popup which never goes away

![website-5](/fun-with-scammers/website-5.png)

at this point if you entered your real information, you are **fucked**.


## evil plan 😈

exploring this phishing website was a lot of fun but I wanted to cause some real damage to the scammers as payback for the victims of this scam. An evil thought came in my head: **what if I spammed legit looking credit card details on the website?** that way the scammers wont be able to tell the difference between legit and fake data!

to do this, I opened [caido](https://www.caido.io/) which is a real competitor to burp suite and does not rate limit requests allowing me to spam the website. Setting up caido is very similar to setting up burp for the first time. 

![caido-1](/fun-with-scammers/caido-1.png)

looking at the requests carefully, we can see that they did not even bother to hide the scam lol

![caido-2](/fun-with-scammers/caido-2.png)

digging deeper, we can see the actual form submission POST request to **"/api/submit"**

![caido-3](/fun-with-scammers/caido-3.png)

we can now modify this request and spam multiple form submissions using caido's **"automate"** feature which is similar to burp's **"intruder"**

before that, I used Claude to generate 2 quick scripts to create 100k random names like "john doe" and 100k credit card numbers. Then, I use the output lists as input for automate for specific injection points

![caido-4](/fun-with-scammers/caido-4.png)

after setting everything up, we launch the attack. let the spam begin.


## outsmarted 🧠

initially, the requests were submitting successfully (200 OK) and I was thrilled but after a while I started getting errors.

![caido-5](/fun-with-scammers/caido-5.png)

after running the attack for a few minutes, I started getting errors (429 Too Many Requests) on my requests. Since the website was on cloudflare CDN, it was cloudflare's DoS protection kicking in. I increased the delay between requests to evade it but it did not work

![caido-6](/fun-with-scammers/caido-6.png)

going back to the website now, it showed a "click to continue" button instead of the scam form.

![website-6](/fun-with-scammers/website-6.png)

ofc I clicked it and I immediately jumped out of my seat because of this image popping up on my screen along with jumpscare audio at full volume in my headphones

![website-7](/fun-with-scammers/website-7.png)

"cringe-sound-effect-video.mp3".... really?
![caido-7](/fun-with-scammers/caido-7.png)

the scammers had outsmarted me. They obviously realised what I was doing and either changed the website in real time or already had this feature built into the website to prank me. well played.

the ukrainian text means "hi" or "hello" in english.


at this point, there was not a lot I could do since the website was fronted by cloudflare. The only thing I could do to fight back was to submit a request to cloudflare to take the website off of the CDN which I did.

![cloudflare](/fun-with-scammers/cloudflare.png)


## final words 📝

ok so we did take an L on this one and got outsmarted but it was a lot of fun. Doing things like this just for fun is what I love and maybe I'll be able to outsmart them next time

alright see ya!