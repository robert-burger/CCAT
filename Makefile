KDIR ?= /lib/modules/$(shell uname -r)/build
obj-m += ccat.o ccat_netdev.o ccat_gpio.o ccat_sram.o ccat_systemtime.o ccat_update.o ccat_esc.o ccat_irq.o
ccat-y := module.o
ccat_netdev-y := netdev.o
ccat_gpio-y := gpio.o
ccat_sram-y := sram.o
ccat_systemtime-y := systemtime.o
ccat_update-y := update.o
ccat_esc-y := esc.o
ccat_irq-y := irq.o
#ccflags-y := -DDEBUG
ccflags-y += -D__CHECK_ENDIAN__

DEV_PREFIX=/dev/ccat_

all:
	make -C $(KDIR) M=$(CURDIR) modules

install:
	- rmmod ccat_update
	- rmmod ccat_systemtime
	- rmmod ccat_sram
	- rmmod ccat_gpio
	- rmmod ccat_netdev
	- rmmod ccat
	make -C $(KDIR) M=$(CURDIR) modules_install
	cp etc/modprobe.d/ccat.conf /etc/modprobe.d/
	cp etc/udev/rules.d/991-ccat.rules /etc/udev/rules.d/
	depmod -a
	modprobe ccat
	modprobe ccat_esc
	modprobe ccat_irq
	modprobe ccat_netdev
	modprobe ccat_gpio
	modprobe ccat_sram
	modprobe ccat_systemtime
	modprobe ccat_update

clean:
	make -C $(KDIR) M=$(CURDIR) clean
	rm -f *.c~ *.h~ *.bin

# indent the source files with the kernels Lindent script
indent: *.h *.c
	$(KDIR)/scripts/Lindent $?
	$(CURDIR)/tools/shfmt -w $(CURDIR)/scripts $(CURDIR)/unittest

unittest:
	sudo chmod g+r ${DEV_PREFIX}*
	sudo chmod g+w ${DEV_PREFIX}*
	sudo chgrp ccat ${DEV_PREFIX}*

	cd unittest && ./test-rw_cdev.sh sram 131072
	cd unittest && ./test-update.sh

.PHONY: clean indent unittest
