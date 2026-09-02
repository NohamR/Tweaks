TARGET = iphone:latest:15.0
INSTALL_TARGET_PROCESSES = GoodNotes
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GoodnotesPro

GoodnotesPro_FILES = Tweak.x
GoodnotesPro_CFLAGS = -fobjc-arc
GoodnotesPro_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
