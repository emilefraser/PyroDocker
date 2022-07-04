#!/bin/bash
# openssl rsa -in privkey.pem -outform PVK -pvk-none -out yourdomain.pvk
openssl rsa -in PEM_KEY_FILE -outform PVK -pvk-strong -out PVK_FILE
openssl rsa -in privkey.pem -outform PVK -pvk-none -out yourdomain.pvk
