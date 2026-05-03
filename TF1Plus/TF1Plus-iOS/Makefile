TARGET = iphone:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = mytf1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TF1Plus

TF1Plus_FILES = Tweak.x
TF1Plus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
