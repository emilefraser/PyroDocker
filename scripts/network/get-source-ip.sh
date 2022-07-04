#!/bin/bash

ip route show | grep docker0 | awk '{print }'
