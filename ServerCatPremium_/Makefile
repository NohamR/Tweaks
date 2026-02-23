TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = ServerCat
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ServerCatPremium

ServerCatPremium_FILES = Tweak.x
ServerCatPremium_CFLAGS = -fobjc-arc
ServerCatPremium_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
