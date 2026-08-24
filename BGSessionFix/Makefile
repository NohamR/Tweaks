TARGET = iphone:latest:15.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = app.bundle.id

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BGSessionFix
BGSessionFix_FILES = Tweak.x
BGSessionFix_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -std=c++11 -x objective-c++
BGSessionFix_CXXFLAGS = -std=c++11
BGSessionFix_FRAMEWORKS = Foundation UIKit
BGSessionFix_LDFLAGS = -lstdc++

include $(THEOS_MAKE_PATH)/tweak.mk