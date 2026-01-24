# Project Context

## Purpose
打造面向儿童的通识教育 App「星知」的可视化 Demo，重点是高质量 UI 与功能原型展示。

## Tech Stack
- Flutter (Web 优先)
- Dart

## Project Conventions

### Code Style
- UI 组件优先在 `lib/main.dart` 集中管理（后续可拆分）
- 以中文命名页面标题与文案
- 使用 `const` 与不可变数据减少重建

### Architecture Patterns
- 本地 Demo，无后端
- 通过 `assets/data/demo.json` 驱动题库与内容
- 使用 `ValueNotifier` 维护轻量状态

### Testing Strategy
- 当前为 UI Demo，不要求自动化测试

### Git Workflow
- 直接在 main 分支迭代（Demo 阶段）

## Domain Context
- 目标用户：儿童与家庭共学
- 关键功能：学习流、AI 助手、社群、擂台、成长/成就

## Important Constraints
- 仅本地实现，不接后端
- 内容为演示用途，跳转外链即可

## External Dependencies
- Flutter packages: shared_preferences, image_picker, flutter_svg, url_launcher
