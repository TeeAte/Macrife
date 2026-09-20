# Macrife v1.0

首个可用版本。

## 下载

| 文件 | 说明 |
|---|---|
| `Macrife-1.0.dmg` | 推荐。挂载后把 Macrife 拖进 Applications |
| `Macrife-1.0.zip` | 备选。解压后把 `Macrife.app` 拖进 Applications |
| `SHA256SUMS.txt` | 校验值 |

## 首次打开

App 未经 Apple 公证，Gatekeeper 会拦一次：
访达里 **右键 → 打开**，或终端执行 `xattr -cr /Applications/Macrife.app`。

## 功能

- 任意目标帧率补帧（不必是 2 的倍数），输出尺寸等于源尺寸
- 码率可调，H.264 / HEVC，VideoToolbox 硬编
- 576p / 1080p / 1440p / 2160p 四档模型，`auto` 按源自动选
- 场景切换检测，硬切处不产生鬼影
- 默认保留原音轨（AAC 等格式直通零重编码），`--noaudio` 可关
- 图形界面（支持拖放）+ 命令行
- 跑完显示性能指标：用时、输出速度、实时倍速、体积

## 要求

Apple Silicon（M1 及以上）+ macOS 15+。

## 已知限制

- Intel Mac 不支持
- 内置档位均为 16:9；竖屏 / 4:3 素材的光流在被拉伸的画面上估算，画质略降
- 硬编不支持 CRF 质量模式，只能用码率控制
