# 打包并安装 PhotoDelete 到真机
# 默认设备：已连接的 iPhone 16（"42"），可用 DEVICE_ID 覆盖
# 用法：
#   make install        # 构建 Debug 包并安装到手机
#   make run            # 安装并启动
#   make build          # 只构建
#   make clean          # 清理 DerivedData
#   make install DEVICE_ID=<udid>   # 装到别的设备（xcrun devicectl list devices 查看）

DEVICE_ID ?= 14EDD430-3B6F-5969-B920-F1C427404CA4
PROJECT := IOSAPP/PhotoDelete.xcodeproj
SCHEME := PhotoDelete
BUNDLE_ID := com.fitz.photo.cleaner
DERIVED_DATA := IOSAPP/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug-iphoneos/$(SCHEME).app

.PHONY: build install run clean

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=iOS,id=$(DEVICE_ID)' \
		-derivedDataPath $(DERIVED_DATA) \
		build

install: build
	xcrun devicectl device install app --device $(DEVICE_ID) "$(APP_PATH)"

run: install
	xcrun devicectl device process launch --device $(DEVICE_ID) $(BUNDLE_ID)

clean:
	rm -rf $(DERIVED_DATA)
