TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = infuse
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Infuse

Infuse_FILES = Tweak.x
Infuse_CFLAGS = -fobjc-arc
Infuse_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
