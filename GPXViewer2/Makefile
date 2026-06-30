TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = gpxviewer2
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GPXViewer2

GPXViewer2_FILES = Tweak.x
GPXViewer2_CFLAGS = -fobjc-arc
GPXViewer2_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
