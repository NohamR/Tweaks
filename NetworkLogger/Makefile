TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = *
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetworkLogger

NetworkLogger_FILES = Tweak.x
NetworkLogger_CFLAGS = -fobjc-arc
NetworkLogger_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk