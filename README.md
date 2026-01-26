# 星知（StarKnow）

一个面向儿童的通识教育 App Demo，围绕“趣味内容 + AI 助手 + 知识擂台 + 成长激励”构建完整体验闭环。

## 主要功能
- 学习流：可搜索、可筛选的图文/视频内容瀑布流
- AI 助手：支持文本问答与图片识别的聊天式界面（本地演示）
- 知识擂台：单人答题流程 + 排行榜
- 社群：话题瀑布流、评论输入、个人主页访问
- 成长：每日提醒、打卡任务、成长档案与个人主页

## 技术栈
- Flutter（跨平台）
- 本地 JSON 数据驱动
- 本地存储（shared_preferences）
- 外链打开（url_launcher）

## 环境设置

### 安装 Flutter

**方法 1: 使用 Homebrew（推荐）**
```bash
brew install --cask flutter
```

**方法 2: 使用安装脚本**
```bash
chmod +x scripts/setup_flutter.sh
./scripts/setup_flutter.sh
```

**方法 3: 手动安装**
```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"
```

详细说明请查看 [Flutter 环境设置指南](docs/FLUTTER_SETUP.md)

### 验证安装
```bash
flutter --version
flutter doctor
```

## 运行

### 1. 安装项目依赖
```sh
flutter pub get
```

### 2. 运行项目
```sh
# Web 平台（推荐用于快速开发）
flutter run -d chrome

# iOS 平台（需要 Xcode）
flutter run -d ios

# Android 平台（需要 Android Studio）
flutter run -d android

# 查看所有可用设备
flutter devices
```

## 说明
这是一个可演示 Demo，内容与社交功能目前以本地数据和占位交互为主，后续可接入真实内容与后端服务。
