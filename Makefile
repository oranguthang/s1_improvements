.PHONY: build

ifeq ($(OS),Windows_NT)
LUA ?= build_tools/lua/lua.exe
else
LUA ?= lua
endif

# Symbols stay enabled for release builds. Use SYMBOLS=0 to omit them.
SYMBOLS ?= 1
ifeq ($(SYMBOLS),0)
SYMBOL_FLAGS := --no-symbols
else ifneq ($(SYMBOLS),1)
$(error SYMBOLS must be 0 or 1)
endif

build:
	"$(LUA)" build.lua $(SYMBOL_FLAGS)
