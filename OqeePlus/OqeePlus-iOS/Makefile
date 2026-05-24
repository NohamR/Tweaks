TARGET = iphone:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = Oqee

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OqeePlus

OqeePlus_FILES = Tweak.x
OqeePlus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
