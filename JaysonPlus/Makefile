TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = Jayson
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = JaysonPlus

JaysonPlus_FILES = Tweak.x
JaysonPlus_CFLAGS = -fobjc-arc
JaysonPlus_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
