#!/bin/sh
set -e
rm -rf usb/iso
mkdir -p usb/iso/boot/grub
cp sistema.bin disco.img usb/iso/boot/
printf 'FALPENDRIVE1\n' > usb/iso/boot/guardado.img
truncate -s 36864 usb/iso/boot/guardado.img
cp usb/grub.cfg usb/iso/boot/grub/
grub-mkrescue "$@" -o falos.iso usb/iso
rm -rf usb/iso
