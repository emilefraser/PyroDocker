#!/bin/sh

rm -rf example.com
minica --domains example.com,subdomain1.example.com,subdomain2.example.com

rm -rf second-example.com
minica --domains second-example.com,subdomain1.second-example.com