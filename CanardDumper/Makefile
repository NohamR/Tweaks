TARGET = iphone:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = fr.lecanardenchaine.app

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CanardDumper
CanardDumper_FILES = Tweak.x
CanardDumper_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -std=c++11 -x objective-c++
CanardDumper_CXXFLAGS = -std=c++11
CanardDumper_FRAMEWORKS = Foundation UIKit
CanardDumper_LDFLAGS = -lstdc++

include $(THEOS_MAKE_PATH)/tweak.mk