TARGET = appletv:latest:18.3
ARCHS = arm64
INSTALL_TARGET_PROCESSES = Oqee

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OqeePlus

OqeePlus_FILES = Tweak.x
OqeePlus_CFLAGS = -fobjc-arc
OqeePlus_LDFLAGS += $(THEOS)/vendor/lib/appletv/CydiaSubstrate.framework/CydiaSubstrate.tbd

include $(THEOS_MAKE_PATH)/tweak.mk
