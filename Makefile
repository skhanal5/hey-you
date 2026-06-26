APP_NAME := HeyYou
BUILD_DIR := .build
BUNDLE_DIR := $(BUILD_DIR)/$(APP_NAME).app

.PHONY: all build test clean run bundle

all: build

build:
	swift build

test:
	swift test

clean:
	swift package clean
	rm -rf $(BUILD_DIR)

run:
	swift run

bundle: build
	mkdir -p $(BUNDLE_DIR)/Contents/MacOS
	mkdir -p $(BUNDLE_DIR)/Contents/Resources
	cp Resources/Info.plist $(BUNDLE_DIR)/Contents/
	cp $(BUILD_DIR)/debug/$(APP_NAME) $(BUNDLE_DIR)/Contents/MacOS/
	codesign --force --sign - $(BUNDLE_DIR)
	@echo "Bundle created at $(BUNDLE_DIR)"
