TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = Volkswagen
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VolkswagenJB

VolkswagenJB_FILES = Tweak.x
VolkswagenJB_CFLAGS = -fobjc-arc
VolkswagenJB_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
