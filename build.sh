#!/bin/bash
# ============================================
# 打卡日历 App 一键构建脚本
# ============================================
# 使用方法:
#   1. 确保已安装 Xcode 16.x
#   2. 确保已安装 XcodeGen: brew install xcodegen
#   3. 运行: chmod +x build.sh && ./build.sh
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🏗️  打卡日历 - 开始构建..."
echo ""

# 步骤 1: 检查 Xcode
echo "📋 步骤 1: 检查 Xcode..."
if ! xcodebuild -version &>/dev/null; then
    echo "❌ 错误: 未找到 Xcode。请先安装 Xcode。"
    echo "   从 https://developer.apple.com/download/all/ 下载 Xcode 16.x"
    exit 1
fi
XCODE_VERSION=$(xcodebuild -version | head -1)
echo "   ✅ 已检测到: $XCODE_VERSION"
echo ""

# 步骤 2: 检查/安装 XcodeGen
echo "📋 步骤 2: 检查 XcodeGen..."
if ! command -v xcodegen &>/dev/null; then
    echo "   ⚠️  XcodeGen 未安装，正在通过 Homebrew 安装..."
    if ! command -v brew &>/dev/null; then
        echo "❌ 错误: 需要 Homebrew。请先安装: https://brew.sh"
        exit 1
    fi
    brew install xcodegen
fi
echo "   ✅ XcodeGen 已就绪"
echo ""

# 步骤 3: 生成 Xcode 项目
echo "📋 步骤 3: 生成 Xcode 项目..."
xcodegen generate
echo "   ✅ CheckInApp.xcodeproj 已生成"
echo ""

# 步骤 4: 编译项目
echo "📋 步骤 4: 编译项目..."
xcodebuild \
    -project CheckInApp.xcodeproj \
    -scheme CheckInApp \
    -configuration Debug \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tail -20

echo ""

# 步骤 5: 查找并复制到 Applications
BUILD_APP="./build/Build/Products/Debug/CheckInApp.app"
if [ -d "$BUILD_APP" ]; then
    echo "✅ 构建成功！"
    echo ""
    echo "📍 App 位置: $BUILD_APP"
    echo ""
    echo "🚀 你可以:"
    echo "   1. 双击打开 App: open \"$BUILD_APP\""
    echo "   2. 复制到应用程序文件夹: cp -R \"$BUILD_APP\" /Applications/"
    echo "   3. 在通知中心添加小组件: 右键桌面 → 编辑小组件 → 搜索\"打卡日历\""
    echo ""

    # 自动打开 App
    read -p "是否现在打开 App？(y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$BUILD_APP"
    fi
else
    echo "❌ 构建失败，未找到输出 App"
    echo "   请检查上方的错误信息"
    exit 1
fi
