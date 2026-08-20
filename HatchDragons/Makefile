TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = com.runawayplay.dragons
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HatchDragons

HatchDragons_FILES = Tweak.x
HatchDragons_CFLAGS = -fobjc-arc
HatchDragons_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk