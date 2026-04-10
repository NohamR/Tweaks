TARGET = appletv:latest:18.3
ARCHS = arm64
INSTALL_TARGET_PROCESSES = mytf1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TF1Plus

TF1Plus_FILES = Tweak.x
TF1Plus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
