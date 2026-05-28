TARGET = appletv:latest:18.3
ARCHS = arm64
INSTALL_TARGET_PROCESSES = mytf1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TF1Plus

TF1Plus_FILES = Tweak.x
TF1Plus_CFLAGS = -fobjc-arc
TF1Plus_LDFLAGS += $(THEOS)/vendor/lib/appletv/CydiaSubstrate.framework/CydiaSubstrate.tbd

include $(THEOS_MAKE_PATH)/tweak.mk
