TARGET = iphone:latest:14.0
INSTALL_TARGET_PROCESSES = nmb_prod
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CreditAgricoleTweak

CreditAgricoleTweak_FILES = Tweak.x
CreditAgricoleTweak_CFLAGS = -fobjc-arc
CreditAgricoleTweak_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
