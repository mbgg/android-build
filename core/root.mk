# Component Path Configuration
export TARGET_PRODUCT
export ANDROID_INSTALL_DIR := $(patsubst %/,%, $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
export ANDROID_FS_DIR := $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/android_rootfs
export SYSLINK_INSTALL_DIR := $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/syslink_2_00_00_78
export IPC_INSTALL_DIR := $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/ipc_1_23_01_26
export IPC_DIR := $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/ipc_1_23_01_26
export PATH :=$(PATH):$(ANDROID_INSTALL_DIR)/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin

kernel_not_configured := $(wildcard kernel/.config)

ifeq ($(TARGET_PRODUCT), ti814xevm)
export SYSLINK_VARIANT_NAME := TI814X
CLEAN_RULE := syslink_clean sgx_clean kernel_clean clean
rowboat: sgx
else
ifeq ($(TARGET_PRODUCT), ti816xevm)
export SYSLINK_VARIANT_NAME := TI816X
CLEAN_RULE := syslink_clean sgx_clean kernel_clean clean
rowboat: sgx
else
ifeq ($(TARGET_PRODUCT), omap3evm)
rowboat: sgx wl12xx_compat
CLEAN_RULE = wl12xx_compat_clean sgx_clean kernel_clean clean
else
ifeq ($(TARGET_PRODUCT), beagleboard)
rowboat: sgx
CLEAN_RULE = sgx_clean kernel_clean clean
else
ifeq ($(TARGET_PRODUCT), flashboard)
rowboat: sgx
CLEAN_RULE = sgx_clean kernel_clean clean
else
ifeq ($(TARGET_PRODUCT), am335xevm)
rowboat: sgx
CLEAN_RULE = sgx_clean kernel_clean clean
else
rowboat: kernel_build
endif
endif
endif
endif
endif
endif

kernel_build: droid
ifeq ($(strip $(kernel_not_configured)),)
ifeq ($(TARGET_PRODUCT), omap3evm)
	$(MAKE) -C kernel ARCH=arm omap3_evm_android_defconfig
endif
ifeq ($(TARGET_PRODUCT), beagleboard)
	$(MAKE) -C kernel ARCH=arm omap3_beagle_android_defconfig
endif
ifeq ($(TARGET_PRODUCT), flashboard)
	$(MAKE) -C kernel ARCH=arm flashboard_android_defconfig
endif
ifeq ($(TARGET_PRODUCT), ti814xevm)
	$(MAKE) -C kernel ARCH=arm ti8148_evm_android_defconfig
endif
ifeq ($(TARGET_PRODUCT), ti816xevm)
	$(MAKE) -C kernel ARCH=arm ti8168_evm_android_defconfig
endif
ifeq ($(TARGET_PRODUCT), am335xevm)
	$(MAKE) -C kernel ARCH=arm am335x_evm_android_defconfig
endif
endif
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=arm-eabi- uImage

kernel_clean:
	$(MAKE) -C kernel ARCH=arm  distclean

### DO NOT EDIT THIS FILE ###
include build/core/main.mk
### DO NOT EDIT THIS FILE ###

ifeq ($(TARGET_PRODUCT), ti814xevm)
sgx: kernel_build ti81xx_kernel_modules
else
ifeq ($(TARGET_PRODUCT), ti816xevm)
sgx: kernel_build ti81xx_kernel_modules
else
sgx: kernel_build
endif
endif
	@echo "SGX build ......................................................"
	$(MAKE) -C hardware/ti/sgx ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR)
	$(MAKE) -C hardware/ti/sgx ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) install

sgx_clean:
	$(MAKE) -C hardware/ti/sgx ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) clean

wl12xx_compat: kernel_build
	$(MAKE) -C hardware/ti/wlan/mac80211/compat ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) CROSS_COMPILE=arm-eabi- ARCH=arm install

wl12xx_compat_clean:
	$(MAKE) -C hardware/ti/wlan/mac80211/compat ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) CROSS_COMPILE=arm-eabi- ARCH=arm clean


# Build Syslink
syslink:
	@echo "syslink build ......................................................"
	$(MAKE) -C $(SYSLINK_INSTALL_DIR) clean
	$(MAKE) -C $(SYSLINK_INSTALL_DIR) ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) syslink_driver
	$(MAKE) -C $(SYSLINK_INSTALL_DIR) ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) syslink_hlos

	$(MAKE) -C $(SYSLINK_INSTALL_DIR)/packages/ti/syslink/samples/hlos/common/usr/Linux/ ARCH=arm CROSS_COMPILE=arm-eabi- SYSLINK_PLATFORM=TI81XX ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) SYSLINK_ROOT=$(SYSLINK_INSTALL_DIR)/packages IPC_DIR=$(IPC_INSTALL_DIR)/packages  SYSLINK_VARIANT=$(SYSLINK_VARIANT_NAME) clean

	$(MAKE) -C $(SYSLINK_INSTALL_DIR)/packages/ti/syslink/samples/hlos/common/usr/Linux/ ARCH=arm CROSS_COMPILE=arm-eabi- SYSLINK_PLATFORM=TI81XX ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) SYSLINK_ROOT=$(SYSLINK_INSTALL_DIR)/packages IPC_DIR=$(IPC_INSTALL_DIR)/packages SYSLINK_VARIANT=$(SYSLINK_VARIANT_NAME)

	$(MAKE) -C $(SYSLINK_INSTALL_DIR)/packages/ti/syslink/samples/hlos/slaveLoader/usr/Linux ARCH=arm CROSS_COMPILE=arm-eabi- SYSLINK_PLATFORM=TI81XX ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) SYSLINK_ROOT=$(SYSLINK_INSTALL_DIR)/packages IPC_DIR=$(IPC_INSTALL_DIR)/packages SYSLINK_VARIANT=$(SYSLINK_VARIANT_NAME)  clean

	$(MAKE) -C $(SYSLINK_INSTALL_DIR)/packages/ti/syslink/samples/hlos/slaveLoader/usr/Linux ARCH=arm CROSS_COMPILE=arm-eabi- SYSLINK_PLATFORM=TI81XX ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) SYSLINK_ROOT=$(SYSLINK_INSTALL_DIR)/packages IPC_DIR=$(IPC_INSTALL_DIR)/packages SYSLINK_VARIANT=$(SYSLINK_VARIANT_NAME)

	cp -r $(ANDROID_INSTALL_DIR)/device/ti/$(TARGET_PRODUCT)/syslink $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/bin

	cp -r $(SYSLINK_INSTALL_DIR)/packages/ti/syslink/bin/$(SYSLINK_VARIANT_NAME)/syslink.ko $(SYSLINK_INSTALL_DIR)/packages/ti/syslink/bin/$(SYSLINK_VARIANT_NAME)/samples/slaveloader_release $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/hdvpss/$(SYSLINK_VARIANT_NAME)/* $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/bin/syslink/


# Build VPSS / HDMI modules
ti81xx_kernel_modules: syslink
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=arm-eabi- KBUILD_EXTRA_SYMBOLS=$(SYSLINK_INSTALL_DIR)/packages/ti/syslink/utils/hlos/knl/Linux/Module.symvers SYSLINK_ROOT=$(SYSLINK_INSTALL_DIR)/packages IPC_DIR=$(IPC_INSTALL_DIR)/packages modules
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=arm-eabi- KBUILD_EXTRA_SYMBOLS=$(SYSLINK_INSTALL_DIR)/packages/ti/syslink/utils/hlos/knl/Linux/Module.symvers SYSLINK_ROOT=$(SYSLINK_INSTALL_DIR)/packages IPC_DIR=$(IPC_INSTALL_DIR)/packages INSTALL_MOD_PATH=$(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/ modules_install

# Make a tarball for the filesystem
fs_tarball:
	rm -rf $(ANDROID_FS_DIR)
	mkdir $(ANDROID_FS_DIR)
	cp -r $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/root/* $(ANDROID_FS_DIR)
	cp -r $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/ $(ANDROID_FS_DIR)
	(cd $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT); \
	 ../../../../build/tools/mktarball.sh ../../../host/linux-x86/bin/fs_get_stats android_rootfs . rootfs rootfs.tar.bz2)

rowboat_clean: $(CLEAN_RULE)
