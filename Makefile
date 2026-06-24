APP_NAME := HeyYou
BUILD_DIR := .build

.PHONY: all build test clean run

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
