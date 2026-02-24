TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = Business
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BusinessJB

BusinessJB_FILES = Tweak.x
BusinessJB_CFLAGS = -fobjc-arc
BusinessJB_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
