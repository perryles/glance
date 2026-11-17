<h1 align="center">
  <br>
  <a href="https://tryglance.app"><img src="../glance/Assets.xcassets/appicon.imageset/appicon.png" alt="Glance" width="150"></a>
  <br>
  Glance
  <br>
</h1>

<h3 align="center">看一眼，即可解锁 Mac</h3>

<p align="center">
  <a href="../README.md" lang="en">English</a> ·
  <a href="README.zh-CN.md" lang="zh-CN">简体中文</a> ·
  <a href="README.ja.md" lang="ja">日本語</a> ·
  <a href="README.es.md" lang="es">Español</a> ·
  <a href="README.fr.md" lang="fr">Français</a> ·
  <a href="README.de.md" lang="de">Deutsch</a> ·
  <a href="README.pt-BR.md" lang="pt-BR">Português (Brasil)</a> ·
  <a href="README.tr.md" lang="tr">Türkçe</a>
</p>

<p align="center">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-MIT-black.svg" alt="MIT 许可证"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-black.svg" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-black.svg" alt="Swift">
</p>

Glance 将类似 iPhone Face ID 的体验带到 Mac。只需看一眼，即可解锁 Mac，无需输入密码或伸手按下 Touch ID 按键。所有处理均通过 Apple 的 Vision 和 Core ML 框架在设备本地完成，人脸数据和 Mac 密码不会上传到互联网。界面融入 MacBook 的刘海区域，并采用流畅的灵动岛风格动画。

https://github.com/user-attachments/assets/77438826-80a9-4ab2-9fc3-42407a2d0adb

---

> [!WARNING]
> ## 下载前请阅读
> ## Glance 的安全性不及 Apple 的 Face ID 或 Touch ID
>
> MacBook 没有配备让 iPhone Face ID 可靠且安全的深度传感器。iPhone 会构建人脸的三维模型，而 MacBook 摄像头只能获取二维图像。这意味着：
>
> - Glance 能以较高置信度识别并拦截打印照片和手机屏幕上的照片（必须开启高强度活体检测）。
> - Glance 无法可靠地防范使用你的视频进行的欺骗。
> - macOS 没有向第三方应用提供授权登录的 API，因此 Glance 通过在锁屏界面输入已保存的密码来解锁。
>
> Glance 提供的是便利性，而非安全性提升。请在接受这一取舍后再继续使用。

## 安装

**系统要求**

- macOS 15 Sequoia 或更高版本
- 搭载 Apple 芯片或 Intel 处理器的 Mac

<a href="https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/cdb8af97-1ee2-4669-b7cb-dcfb56c9dd61" alt="下载 Mac 版" /></a>

打开 `.dmg` 文件，将 Glance 拖入 `/Applications`，然后启动应用。

## 权限

| 权限 | 用途 |
|---|---|
| **摄像头** | 用于识别人脸。画面帧在内存中处理，绝不会写入磁盘。 |
| **辅助功能** | 用于在锁屏界面输入密码。 |
| **Touch ID** | 控制对加密人脸数据和密码所用密钥的访问。 |

## 工作原理

1. 启动应用，按照引导录入人脸。Glance 会引导你朝九个方向转动头部并采集人脸。每一帧都会转换为包含 512 个数值的*特征向量*，相当于数学形式的人脸指纹，随后丢弃原始图像。
2. 输入一次 Mac 密码，密码会经过加密，并受到 Touch ID 保护。
3. 当 Mac 锁定或从睡眠中唤醒时，刘海区域会出现动画并开始寻找人脸。
4. 如果识别结果与你匹配，且通过活体检测，Glance 就会输入密码并解锁。

## 功能

| 功能 | 说明 |
|---|---|
| **人脸解锁** | 可在唤醒、锁屏或在锁屏界面按空格键时触发，支持任意组合。 |
| **多个身份** | 可录入多个人，或录入自己在戴眼镜、留胡须、不同光线下的多个版本。可单独停用任一身份，无需删除。 |
| **活体检测** | 通过动作和反射等线索区分真人与照片。支持低强度、高强度或关闭。 |
| **刘海界面** | 收起时呈胶囊形，展开后显示扫描动画，并提供成功与失败状态。悬停即可重试，也可完全关闭动画，让 Glance 隐藏运行。 |
| **摄像头与显示器** | 可选择使用的摄像头，并为内置显示器和外接显示器分别设置。 |
| **会话自动锁定** | Touch ID 授权会话会在你设定的空闲时间后重新锁定，避免无人看管的 Mac 一直保持授权。 |
| **触控板触觉反馈** | 将指针悬停在刘海区域时触发触觉反馈。 |
| **支持无刘海 Mac** | 在没有刘海的 Mac 上显示胶囊形的灵动岛风格界面。 |
| **自主掌控数据** | 随时编辑或删除已录入的人脸或已保存的密码。相应加密文件会立即移除。 |

---

# 隐私与安全

Glance 旨在将生物识别数据和凭据保留在设备本地。

### 人脸数据

Glance 从不保存摄像头图像。录入时，应用通过基于 ArcFace 的 Core ML 模型，将每张采集到的人脸转换为 **512 维特征向量**，随后丢弃原始画面帧。

特征向量存储在本地，并使用 **AES-GCM** 加密。

### 凭据

Mac 密码以加密数据形式保存，绝不会以明文写入磁盘。加密密钥是一个**存储在 macOS 钥匙串中的 256 位 AES 密钥**，受 `userPresence` 保护，访问时需要通过 Touch ID 或设备密码验证。

只有在 Glance 授权会话处于活动状态时，密钥才会保留在内存中。

### 解锁流程

Glance 只有在以下条件全部满足时才会输入密码：

1. 存在有效且已获授权的 Glance 会话。
2. Mac 确实处于锁屏界面。
3. 某个已启用身份的匹配度超过设定的相似度阈值。
4. 检测到的人脸通过活体检测。
5. 已获得用于输入密码的辅助功能权限。

人脸识别与活体检测独立运行，两者均成功后才会输入密码。

### 本地处理

人脸识别、人脸录入和活体检测完全通过 Vision 和 Core ML 在设备本地运行。Glance 不会将人脸数据、摄像头画面帧或凭据发送到服务器。

### 如何区分真人与照片

检测会在约 2 秒的滚动时间窗口内分析五种独立线索，分为两类：

- **否决线索**用于发现欺骗迹象，包括屏幕反光，以及围住人脸的设备形状矩形。任一线索出现都会直接判定扫描失败，并覆盖其他检测结果。
- **确认线索**用于判断是否为真人，包括面部特征点的平面与三维几何差异、转头时的鼻部视差以及眨眼。任一线索即可确认，缺少这些线索本身不会导致失败，因为真人也可能保持静止且不眨眼。

低强度检测仅使用否决线索。高强度检测同时使用否决线索和确认线索。

### Face Lab

Face Lab 是一个隐藏的调试控制台，可通过实际数值测试人脸识别和活体检测。

打开方式为进入设置 → 关于，然后连续点击应用图标 5 次。侧边栏中会出现调试栏目。

---

## 从源码构建

### 前置要求

- macOS 15+
- Xcode 26+
- Python 3.9+ 和 Git，首次下载依赖时需要网络连接

### 构建步骤

1. 克隆本分支并打开项目。

   ```bash
   git clone https://github.com/perryles/glance.git
   cd glance
   open glance.xcodeproj
   ```

2. 选择 `glance` target 和 scheme。在 **Signing & Capabilities** 中选择你自己的 Apple 开发团队，并启用自动签名。使用 `glance/glance.entitlements` 配置摄像头和受保护钥匙串权限。

3. 运行目标选择 **My Mac**，按 `Cmd + R`。首次签名构建会下载固定版本的 libusb/libuvc 源码，并自动打包红外辅助程序。

需要单独安装开发版本时，可使用自己的 Bundle Identifier。凭据和人脸录入数据按 Bundle Identifier 隔离，自定义 Bundle Identifier 的版本会停用自动更新。

红外功能设置及构建选项（包括 `GLANCE_ENABLE_INFRARED=NO`）请参阅红外指南。 [IR](../tools/infrared/README.md)

## 参与贡献

欢迎通过 PR 贡献问题修复、新功能、翻译和文档。请向 `perryles/glance` 的 `main` 分支提交，并说明改动内容和验证方式。 [提交 Pull Request](https://github.com/perryles/glance/compare)

问题反馈和功能建议请提交到 GitHub Issues。 [问题反馈](https://github.com/perryles/glance/issues)

## 致谢

- 感谢 Jonathan Zhou 及上游 Glance 贡献者开发原始应用。 [jonnyoo/glance](https://github.com/jonnyoo/glance)
- 感谢 JediBrooker 在 PR #50 中提供 BRIO 红外实现。 [PR #50](https://github.com/jonnyoo/glance/pull/50)
- **[The Boring Notch](https://github.com/TheBoredTeam/boring.notch)** 提供了刘海窗口的物理动效参考。
- **[InsightFace](https://github.com/deepinsight/insightface)** 提供了用于识别的 ArcFace 模型。
- **[Alcove](https://tryalcove.com)** 带来了重要的设计灵感。
- 感谢 Sparkle 提供应用更新框架。 [Sparkle](https://github.com/sparkle-project/Sparkle)
- 感谢 libusb 和 libuvc 提供 USB 红外采集支持。 [libusb](https://github.com/libusb/libusb), [libuvc](https://github.com/libuvc/libuvc)

## 许可证

项目源码采用 MIT 许可证。原始作品 © 2026 Jonathan Zhou，本分支贡献 © 2026 perryles 及贡献者。 [MIT](../LICENSE)

第三方库和模型权重遵循各自的许可条款。InsightFace 对其预训练模型规定了非商业研究用途的许可。 [InsightFace 许可说明](https://github.com/deepinsight/insightface#license)

签名红外构建在 `Contents/Resources/InfraredLicenses` 中附带原生依赖许可证，在 `Contents/Resources/InfraredSources.zip` 中附带源码及重新链接材料。
