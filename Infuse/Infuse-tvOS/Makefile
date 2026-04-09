TARGET = appletv:latest:18.3
ARCHS = arm64
INSTALL_TARGET_PROCESSES = infuse
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Infuse

Infuse_FILES = Tweak.x
Infuse_CFLAGS = -fobjc-arc
Infuse_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
test-print:
	@echo "ARCH is $(THEOS_PACKAGE_ARCH)"
	@echo "CONTROL is $(_THEOS_DEB_PACKAGE_CONTROL_PATH)"
