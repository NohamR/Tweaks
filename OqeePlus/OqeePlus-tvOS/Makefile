TARGET = appletv:latest:18.3
ARCHS = arm64
INSTALL_TARGET_PROCESSES = Oqee
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OqeePlus

OqeePlus_FILES = Tweak.x
OqeePlus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
