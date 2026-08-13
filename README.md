<p align="center">
  <img src="Assets/SoundAnchor-AppIcon-1024-selected.png" width="160" alt="声锚 SoundAnchor 图标">
</p>

<h1 align="center">声锚 SoundAnchor</h1>

<p align="center">
  让蓝牙耳机继续保持高音质。
</p>

<p align="center">
  <a href="https://github.com/xincheng1237/SoundAnchor/releases/latest"><img alt="GitHub release" src="https://img.shields.io/github/v/release/xincheng1237/SoundAnchor?include_prereleases"></a>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple">
  <img alt="Swift 5.10" src="https://img.shields.io/badge/Swift-5.10-F05138?logo=swift&logoColor=white">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

> [English](README_EN.md)

当 macOS 把蓝牙耳机选为麦克风时，蓝牙连接通常会进入 HFP/HSP 通话模式，输出可能降为类似单声道 16 kHz 的低音质。声锚会在蓝牙输出活跃时，自动把默认输入恢复为你指定的 Mac 麦克风。

## 下载

从 [Releases](https://github.com/xincheng1237/SoundAnchor/releases/latest) 下载最新 DMG，打开后将“声锚 SoundAnchor”拖入 Applications。

> [!WARNING]
> 当前 `v0.1.0` 是公开测试版，使用 ad-hoc 签名，尚未完成 Apple Developer ID 签名和公证。首次打开可能需要在访达中右键应用并选择“打开”，或在“系统设置 → 隐私与安全性”中确认。

## 主要功能

- 事件驱动：监听 Core Audio 设备变化，不轮询
- 默认仅在蓝牙输出活跃时保护
- 可选择任意可用输入设备作为“锚定麦克风”
- 支持立即修复、暂停保护和登录时自动运行
- 可隐藏菜单栏图标，后台保护仍然运行
- 完全本地运行，无网络请求、无遥测、不录音
- 支持 Apple Silicon 和 Intel Mac，macOS 13 或更高版本

## 使用

1. 连接蓝牙耳机。
2. 在声锚菜单中打开“启用音质保护”。
3. 在“锚定的输入设备”中选择 Mac 内建麦克风或其他期望的输入。
4. 保持“仅在蓝牙输出时保护”开启，即可避免影响日常录音设备切换。

如果隐藏了菜单栏图标，可从“应用程序”再次打开声锚，在设置窗口中恢复“在菜单栏中显示”。

## 工作原理

声锚监听 macOS 默认输入、默认输出和音频设备列表的 Core Audio 事件。当蓝牙输出活跃且默认输入偏离锚定设备时，它立即恢复指定输入。空闲时不轮询，因此 CPU 开销接近于零。

## 从源码构建

需要 macOS 13+、Xcode Command Line Tools 和 Swift 5.10+。

```bash
git clone https://github.com/xincheng1237/SoundAnchor.git
cd SoundAnchor
swift test
./scripts/build-app.sh
```

构建脚本会生成通用二进制应用和 DMG：

```text
dist/声锚 SoundAnchor.app
dist/SoundAnchor-0.1.0-macOS.dmg
```

## 故障排查

参见 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。提交问题时，请附上 macOS 版本、耳机型号、输入/输出设备名称以及可复现步骤，但不要上传任何私密音频或系统日志。

## 隐私、安全与贡献

- [隐私说明](PRIVACY.md)
- [安全政策](SECURITY.md)
- [贡献指南](CONTRIBUTING.md)
- [发布历史](CHANGELOG.md)

## 许可证

[MIT](LICENSE) © 2026 SoundAnchor contributors
