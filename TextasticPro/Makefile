TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = Textastic
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TextasticPro

TextasticPro_FILES = Tweak.x
TextasticPro_CFLAGS = -fobjc-arc
TextasticPro_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
