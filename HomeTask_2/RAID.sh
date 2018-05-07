#!/bin/bash

sudo mdadm --create /dev/md0 -l 5 -n 6 /dev/sd{b,c,d,e,f,g} #create RAID5