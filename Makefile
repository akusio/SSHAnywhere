TARGET := iphone:clang:latest:14.5
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = sshanywhere

sshanywhere_FILES = Tweak.x SSHConnection.m
sshanywhere_CFLAGS = -fobjc-arc
sshanywhere_LDFLAGS += -lssh2.1 -L.

include $(THEOS_MAKE_PATH)/tweak.mk
