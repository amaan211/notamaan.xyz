---
title: "🕵️ Hunting for Leaked Secrets on Github (I Used AI) 🤖"
date: 2026-01-01T14:22:03+00:00
summary: "The research presented is purely for educational purposes on already-public data and must not be used to attempt unauthorized access."
draft: false
---

## Disclaimer

The research presented is purely for educational purposes on already-public data and must not be used to attempt unauthorized access.

## Introduction

Now that I got you to click on the article by putting **“AI”** in the title, here is what I did.

[Gharchive](https://www.gharchive.org/) is a website that basically creates frequent snapshots of all the public code pushed to github. Think of “[The Wayback Machine](https://web.archive.org/)” from archive.org but for github.

When I first heard about [gharchive](https://www.gharchive.org/), I remember that the first thought that popped into my head was that it was such a cool initiative and could serve as a very useful archive. My second thought was “oh my god we can use it to look for juicy information like credentials and API keys”.

![plan](/github-leaked-credentials/cunning-plan.png)

## The Plan 🧭

### gharchive snapshots can be used for the following:

- see public github events (commits, pushes and issues on public repos)
- diffs in pushes
- comments on public repos etc.

### what we cant see:

- private repos
- deleted commits
- files not in commit diffs (large files)

So the idea was to create a script that would download data for a specific date using the gharchive api and then use the github api to look at the committed code. I then parse this commit to look for leaked credentials using simple regex and write the “hits” to a file.

Problem is, the first time I ran the script, I got like 40k hits for leaked creds most of which (i’d say about 99.9%) were false positives:

- default passwords
- fields like “password:<enter-strong-password-here>”
- locally hosted stuff which cant be accessed from the internet
- etc.

![image-11](/github-leaked-credentials/image-11.png)

sample output:

```json
{
      "sha": "9d4db4e20f23f347821e43458b98f48fd22a110f",
      "repo": "tohasyafingi/SPK-WASPAS",
      "type": "PASSWORD",
      "match": "password: 'user123'",
      "context": "+ +const DEFAULT_USER = { +  username: 'user', +  password: 'user123', +  email: '[email protected]', +  nama_lengkap: 'Re",
      "timestamp": "2025-12-29T15:00:28Z",
      "actor": "tohasyafingi",
      "commit_url": "https://github.com/tohasyafingi/SPK-WASPAS/commit/9d4db4e20f23f347821e43458b98f48fd22a110f",
      "repo_url": "https://github.com/tohasyafingi/SPK-WASPAS",
      "detected_at": "2025-12-29T23:33:37.923075",
      "id": "9d4db4e2_PASSWORD_1767031417.923088",
      "added_to_master": "2025-12-29T23:33:37.923102"
}
```

## The solution 💡

As I mentioned earlier, “AI” seems to be the buzzword nowadays. People are shoving AI into products where it doesnt belong.

**Exhibit A:** This Oral B [toothbrush](https://www.oralb.co.uk/en-gb/product-collections/genius-x) that has fricking AI like what???????? why would anyone want AI in their fucking toothbrush?? But I digress.

In my case, I couldnt have gone through all 40k hits to find out the true positives. The solution? **AI**.

![robot](/github-leaked-credentials/robot.gif)

## The model 🧠

I considered using paid LLMs like Gemini or Claude code to do the filtering but being a broke and unemployed student with a decent-ish laptop, I decided against it and chose to use a self-hosted model.

After a few hours (minutes actually ( ͡° ͜ʖ ͡°)) of ChatGPT-ing I found two contenders:

- Zephyr 7B
- Mistral 7B instruct

these models were good because they could easily work with the 8GB of VRAM on my laptop. After a bit of testing and comparing results, I chose to go with **Zephyr 7B**.

After setting up LM Studio and downloading the model, I wrote a script to feed the 40k hits and gave it the following prompt:

```markdown
You are a cybersecurity expert analyzing GitHub commits for REAL exposed secrets.
Your task: Identify if a finding is a REAL_SECRET (actual production credential) 
or FALSE_POSITIVE (test/example/local).

CRITICAL RULES - FALSE_POSITIVE if ANY of these:
1. LOCALHOST/127.0.0.1: Connections to localhost, 127.0.0.1, ::1
2. DEFAULT PASSWORDS: "password", "admin", "root", "123456", "changeme"
3. TEST/EXAMPLE FILES: test_, spec_, example_, demo_, mock_
4. PLACEHOLDERS: YOUR_, REPLACE_, CHANGEME, TODO_, FIXME_
5. PUBLIC TEST KEYS: pk_test_, sk_test_, sandbox_, staging_
6. DOCS/COMMENTS: In README, comments, documentation
7. CONFIG EXAMPLES: .env.example, config.example, sample.config

REAL_SECRET only if:
1. NO localhost/default/test indicators
2. External services: AWS, Stripe, Google Cloud, production DB
3. Real-looking keys: Proper length/format, not obviously fake
4. Production files: .env, config.yml, settings.py, secrets.json
5. Recent commits (not old tutorial code)

Respond with ONLY: REAL_SECRET or FALSE_POSITIVE
```

### 🚨 The most important bit

I also gave the model **context** (few lines of code before and after the leaked credentials) that would help it judge better. This greatly helped the model understand the context behind the code and reduced FPs massively.

The script wrote the true positives according to the model in a file (around 400) which I could investigate individually.

I also added some extra logic to avoid bots and spam which were messing up my results.

After doing this for a while, here is what I found:

![nuke](/github-leaked-credentials/nuke.png)

## 💣 The bombshell

**I found someone’s phone number, paypal client ID and client secret! all in plaintext!**

![image-1](/github-leaked-credentials/image-1.png)

Judging from the context, It looked like the person was a developer and had integrated paypal to a website they were working on.

## 😱 No Way

Now, Looking at the [Paypal developer API documentation](https://developer.paypal.com/api/rest/), I could have enumerated lot of information like receipts, disputes, products, etc. using the given credentials.

A few sample images taken from a test account I made:

![image-2](/github-leaked-credentials/image-2.png)
![image-3](/github-leaked-credentials/image-3.png)
![image-4](/github-leaked-credentials/image-4.png)
![image-5](/github-leaked-credentials/image-5.png)
![image-6](/github-leaked-credentials/image-6.png)

Since there were write perms to all of this data, creating fake receipts/invoices and adding random products to the account was also a possibility.

Fortunately, the token did not have enough permissions to enumerate or modify customer information like addresses, payment details etc. Still, this is a pretty serious issue that can lead to all sorts of trouble.

sample image:
![image-7](/github-leaked-credentials/image-7.png)

## 🔎 Some other interesting finds

I also found a couple of working google gemini api keys as well but thats not as interesting.
![gemini](/github-leaked-credentials/image-9.png)

## 🛡️ Okay, But How do I prevent stuff like this happening to me?

### just remember to:

- never commit secrets to github
- add pre commit protection like gitleaks
- keep repos private by default
- dont use test creds (even temporary)
- always generate least privilege tokens
- if accidentally leaked, rotate creds ASAP
- if your repo was public (yes even for 1 second) consider it compromised
- use vaults and NEVER hardcode credentials (I know it way more convenient but its wayyyyyy less secure)

AAAAnd that’s it. Thanks for reading my blog and

## 🎉 Wishing you a Happy New Year!!

![new-year](/github-leaked-credentials/new-year.gif)
