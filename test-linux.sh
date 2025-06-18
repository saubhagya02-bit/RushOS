#!/bin/sh

qemu-system-i386 -drive format=raw,file=disk_images/rushos.flp,index=0,if=floppy
