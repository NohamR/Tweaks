TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = com.example.cloudquit
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CloudQuit

CloudQuit_FILES = Tweak.x
CloudQuit_CFLAGS = -fobjc-arc
CloudQuit_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk