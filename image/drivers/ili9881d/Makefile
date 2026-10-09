# Daaf Wassenaar <contact@daaf.dev>
# Copyright (c) 2026 Daaf Wassenaar

ifndef KERNEL_VERSION
$(error KERNEL_VERSION is not set)
endif

KERNEL_BUILD_DIR := /usr/lib/modules/$(KERNEL_VERSION)/build

obj-m += ili9881d.o

all:
	$(MAKE) -C $(KERNEL_BUILD_DIR) M=$(PWD) modules

install:
	$(MAKE) -C $(KERNEL_BUILD_DIR) M=$(PWD) modules_install

clean:
	$(MAKE) -C $(KERNEL_BUILD_DIR) M=$(PWD) clean