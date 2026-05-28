TARGET = appletv:latest:18.3
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = infuse

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Infuse

Infuse_FILES = Tweak.x
Infuse_CFLAGS = -fobjc-arc
Infuse_FRAMEWORKS = Foundation UIKit
Infuse_LDFLAGS += $(THEOS)/vendor/lib/appletv/CydiaSubstrate.framework/CydiaSubstrate.tbd

include $(THEOS_MAKE_PATH)/tweak.mk
