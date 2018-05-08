#!/bin/bash

(
echo o; echo y # create GPT
echo n; echo ; echo ; echo +254970; echo ; #create 1 partition
echo n; echo ; echo ; echo +254970; echo ; #create 2 partition
echo n; echo ; echo ; echo +254970; echo ; #create 3 partition
echo n; echo ; echo ; echo +254970; echo ; #create 4 partition
echo n; echo ; echo ; echo +254970; echo ; #create 5 partition
echo w; echo y #save change
) | sudo gdisk /dev/md0
