# Glance 1.2.1（build 7）

本版本发布到 [perryles/glance](https://github.com/perryles/glance)，安装包为 **Glance-1.2.1.dmg**，支持 Apple Silicon、macOS 15 及以上。内部版本号从 6 提高到 7，供已有安装识别更新。

以下更新以 [jonnyoo/glance main，b97f521](https://github.com/jonnyoo/glance/tree/b97f521397ec1197ba17768ba797cae1e628848d) 为比较基准。

| 需求 | 相比上游 main 的变化 | 使用方式与范围 |
|---|---|---|
| [中文界面 #59](https://github.com/jonnyoo/glance/issues/59) / [土耳其语 #62](https://github.com/jonnyoo/glance/issues/62) | 补齐设置、首次设置、人脸实验室、权限、错误和新增红外页面的简体中文及土耳其语资源。 | 跟随 macOS 应用语言设置；可在“系统设置 → 通用 → 语言与地区 → 应用程序”指定语言，重启应用生效。 |
| [空格触发 #54](https://github.com/jonnyoo/glance/issues/54) | 输入监听提前建立并贯穿睡眠，处理锁定/唤醒状态切换、按住连发、键盘断开重连及过期回调；仅匹配空格事件。 | 在触发条件中选择“按空格键时”，并授予输入监控权限。尚未在本机完成反复锁屏/睡眠唤醒实测。 |
| [系统人脸验证 #40](https://github.com/jonnyoo/glance/issues/40) | 新增手动触发的系统密码辅助；复用人脸、活体和可选红外检查。验证 Apple 系统代理签名、密码框归属和焦点，并在解密后再次检查授权。 | 在通用设置启用“辅助系统密码提示”；聚焦受支持系统提示的 Mac 登录密码框，按 **Control + Option + Command + F**。验证通过后填写密码，由用户确认系统按钮。仅支持 SecurityAgent / LocalAuthentication UIAgent 的密码回退框，不提供原生 Touch ID / Face ID / 通行密钥认证接口，也不填充网站密码、Apple ID 或任意应用密码框。 |
| [红外支持 #46](https://github.com/jonnyoo/glance/issues/46) | 集成 [JediBrooker 的 PR #50](https://github.com/jonnyoo/glance/pull/50)（e089499），包含 BRIO USB 红外捕获、签名后台辅助程序、三次独立录入和加密模板；将红外要求接入锁屏及系统密码辅助两条路径。 | **实验性、默认关闭**。在红外设置中批准辅助程序、为已有身份录入三次，再启用“要求 BRIO 红外匹配”。开启后必须同时通过彩色身份、重度活体及同一身份的新鲜红外匹配；设备/授权/模板缺失或检测失败时拒绝人脸解锁，继续使用系统密码。 |

另有摄像头切换与红外交接恢复、活体/反光分析优化、逐按键授权和取消处理；保留本分支的识别距离设置。修复钥匙串迁移在读取失败时误删旧条目的问题，核验写入后才清理旧数据。会话变更会使正在进行的识别、红外录入及密码提交失效。PR 带入的登录后自动解锁 Glance 会话选项保持默认关闭。

更新检查、反馈和下载入口使用 perryles 仓库。安装包包含应用、红外辅助程序，以及所用原生依赖的许可证和源码/重新链接材料。红外移植感谢 [JediBrooker](https://github.com/JediBrooker)，完整实现来源与局限见 [PR #50](https://github.com/jonnyoo/glance/pull/50)。

验证：Release 签名构建通过；8 组离线红外/活体回归通过；空格状态、系统密码提示策略、钥匙串迁移、加密存储与会话更替检查通过；红外底层采集逻辑离线检查通过；应用与辅助程序签名、架构、权限配置及中/土语言资源检查通过。

限制：目前没有红外摄像头，因此未完成 BRIO 真机录入、完整解锁和防伪阈值验证。红外匹配不代表达到 Windows Hello 或 Face ID 的安全水平。系统密码框填写及锁屏/唤醒流程仍需本机交互验收。安装包使用 Apple Development 证书签名，未做 Developer ID 公证，其他 Mac 的安装运行可能受系统限制。
