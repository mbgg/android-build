# Component Path Configuration
export TARGET_PRODUCT
export ANDROID_INSTALL_DIR := $(patsubst %/,%, $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
export ANDROID_FS_DIR := $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/android_rootfs
export SYSLINK_INSTALL_DIR := $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/syslink_2_00_00_78
export IPC_INSTALL_DIR := $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/ipc_1_23_01_26
export IPC_DIR := $(ANDROID_INSTALL_DIR)/hardware/ti/ti81xx/syslink_vpss/ipc_1_23_01_26
export PATH :=$(PATH):$(ANDROID_INSTALL_DIR)/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin
export WILINK

kernel_not_configured := $(wildcard kernel/.config)
dvsdk_not_installed := $(wildcard external/ti-dsp/already_clean)
#DSP_PATH := $(wildcard external/ti-dsp)

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
ifeq ($(TARGET_PRODUCT), igep00x0)
#rowboat: dvsdk sgx
rowboat: sgx
CLEAN_RULE = sgx_clean kernel_clean igep_x_loader_clean clean
#CLEAN_RULE = dvsdk_clean sgx_clean kernel_clean igep_x_loader_clean clean
else
ifeq ($(TARGET_PRODUCT), flashboard)
rowboat: sgx wl12xx_compat
CLEAN_RULE = wl12xx_compat_clean sgx_clean kernel_clean clean
else
ifeq ($(TARGET_PRODUCT), am335xevm)
rowboat: sgx wl12xx_compat
CLEAN_RULE = wl12xx_compat_clean sgx_clean kernel_clean clean
else
ifeq ($(TARGET_PRODUCT), beaglebone)
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
ifeq ($(TARGET_PRODUCT), igep00x0)
	$(MAKE) -C kernel ARCH=arm igep00x0_android_defconfig
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
ifeq ($(TARGET_PRODUCT), beaglebone)
	$(MAKE) -C kernel ARCH=arm am335x_evm_android_defconfig
endif
endif
ifeq ($(TARGET_PRODUCT), igep00x0)
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=arm-eabi- zImage modules
else
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=arm-eabi- uImage
endif

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
ifeq ($(TARGET_PRODUCT), igep00x0)
sgx: kernel_build igep_x_loader igep_copy_modules
else
sgx: kernel_build
endif
endif
endif
	@echo "SGX build ......................................................"
	$(MAKE) -C hardware/ti/sgx ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR)
	$(MAKE) -C hardware/ti/sgx ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) install

sgx_clean:
	$(MAKE) -C hardware/ti/sgx ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) clean

ifeq ($(WILINK), wl18xx)
wl12xx_compat: kernel_build
	$(MAKE) -C hardware/ti/wlan/mac80211/compat_wilink8 ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) CROSS_COMPILE=arm-eabi- ARCH=arm install

wl12xx_compat_clean:
	$(MAKE) -C hardware/ti/wlan/mac80211/compat_wilink8 ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) CROSS_COMPILE=arm-eabi- ARCH=arm clean
else
wl12xx_compat: kernel_build
	$(MAKE) -C hardware/ti/wlan/mac80211/compat ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) CROSS_COMPILE=arm-eabi- ARCH=arm install

wl12xx_compat_clean:
	$(MAKE) -C hardware/ti/wlan/mac80211/compat ANDROID_ROOT_DIR=$(ANDROID_INSTALL_DIR) CROSS_COMPILE=arm-eabi- ARCH=arm clean
endif

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

igep_x_loader_clean:
	$(MAKE) -C igep-x-loader distclean

igep_x_loader:
	cd igep-x-loader && git checkout 67f8c169484185ba31f3e39119798db761df9803 && cd ..
	$(MAKE) -C igep-x-loader igep00x0_config
	$(MAKE) -C igep-x-loader all &> /dev/null

igep_copy_modules: | kernel_build
	mkdir -p out/target/product/igep00x0/system/bin/libertas/
	cp $(ANDROID_INSTALL_DIR)/kernel/drivers/net/wireless/libertas/*.ko out/target/product/igep00x0/system/bin/libertas/

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

.PHONY: dvsdk
dvsdk: kernel
ifeq ($(strip $(dvsdk_not_installed)),)
	TOOLS_DIR=$(dir `pwd`/$($(combo_target)TOOLS_PREFIX))../ ./external/ti-dsp/get_tidsp.sh
	touch ./external/ti-dsp/already_clean
	make -C external/ti-dsp combo_target=$(combo_target) $(combo_target)TOOLS_PREFIX=$($(combo_target)TOOLS_PREFIX) HOST_PREBUILT_TAG=$(HOST_PREBUILT_TAG) clean
endif
	make -C external/ti-dsp combo_target=$(combo_target) $(combo_target)TOOLS_PREFIX=$($(combo_target)TOOLS_PREFIX) HOST_PREBUILT_TAG=$(HOST_PREBUILT_TAG)
	make -C hardware/ti/omx combo_target=$(combo_target) $(combo_target)TOOLS_PREFIX=$($(combo_target)TOOLS_PREFIX) HOST_PREBUILT_TAG=$(HOST_PREBUILT_TAG)

.PHONY: dvsdk_clean
dvsdk_clean:
	make -C hardware/ti/omx OMAPES=$(OMAPES) clean
	make -C external/ti-dsp combo_target=$(combo_target) $(combo_target)TOOLS_PREFIX=$($(combo_target)TOOLS_PREFIX) HOST_PREBUILT_TAG=$(HOST_PREBUILT_TAG) clean

.PHONY: dvsdk_distclean
dvsdk_distclean:
	make -C hardware/ti/omx OMAPES=$(OMAPES) clean
	make -C external/ti-dsp OMAPES=$(OMAPES) distclean

rowboat_clean: $(CLEAN_RULE)
