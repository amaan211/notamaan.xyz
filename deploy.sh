#!/bin/bash
rm -rf public/
hugo --minify
sudo systemctl restart nginx
