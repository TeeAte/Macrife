# Macrife — macOS 原生 AI 视频补帧

把低帧率视频补成高帧率：24fps → 60fps、30fps → 120fps，**任意目标帧率**（不必是 2 的倍数）。

纯原生 Swift 实现，**完全离线运行**，不上传任何数据、不需要账号、不依赖 Python 环境。
推理走 Apple 芯片的 CoreML + 自写 Metal 原生着色器内核，视频编解码走 VideoToolbox 硬件加速。

<div align="center">
  <video src="https://github.com/user-attachments/assets/8a948f65-dd01-45e4-9814-a62f9c027c8b" controls="controls" muted="muted" autoplay="autoplay" loop="loop" width="100%">
    <a href="https://github.com/user-attachments/assets/8a948f65-dd01-45e4-9814-a62f9c027c8b">效果演示：720p60 补帧片段</a>
  </video>
</div>

---

## 一、它能做什么

| 能力 | 说明 |
|---|---|
| 任意目标帧率 | 24→60、30→120、25→50、24→144 都行，非整数倍也支持 |
| 码率可调 | 默认 20 Mbps，滑杆可调，H.264 / HEVC 可选 |
| 最高 4K 原生画质 | 576p / 720p / 1080p / 1440p / 2160p 五档模型，默认按源分辨率自动选 |
| 原分辨率融合 | 光流在模型尺寸计算，Warp 与 Blend 在源分辨率完成，4K 细节无损（锐度保留约95.7%） |
| 异构双擎并发 | 支持 ANE (节能)、GPU (独显)、协同（ANE+GPU 并发） |
| 硬件全场景自适配 | 自动感知 M1~M4 全系芯片（Base/Pro/Max/Ultra）与 8GB/16GB/32GB+ 内存|
| 场景切换检测 | 硬切处自动跳过插值并定格前一帧，防鬼影 |
| 音频自动保留 | 默认把原音轨搬进输出（AAC 直通零重编码，其他格式自动转 AAC），也可关掉 |
| 任务暂停与恢复 | 随时暂停/继续，暂停时不占 CPU/GPU 资源，支持实时取消 |
| 两种用法 | 图形界面（拖进去就能跑，实时 ETA 预估）+ 命令行（支持批处理与硬件画像探查） |



---
实测参考（M1 Pro）：576p 处理精度下导出速度可达 45-55 fps；720p 档位约 20 ~ 25 fps。
## 二、系统要求

| 项目 | 要求 |
|---|---|
| 芯片 | **Apple Silicon**（M1 / M2 / M3 / M4 / M5 / M6 全系列，含 Pro / Max / Ultra）。Intel Mac 不支持 |
| 系统 | macOS 15 Sequoia 或更高 |
| 磁盘 | App 本体约210 MB（含五档完整模型包） |
| 内存 | 建议 8 GB 及以上；4K 素材建议 16 GB 及以上 |
---
实测 M1 Pro 芯片补帧4k24--＞4k60甜点精度为1080p，既能保持较好的效果，速度也 ok（大约20fps）
## 三、下载与安装

### 1. 下载

到本仓库右侧的 **Releases** 页面，下载最新版：

| 文件 | 说明 |
|---|---|
| `Macrife.dmg` | 磁盘镜像。挂载后把 Macrife 拖进 Applications 即可安装 |
| `SHA256SUMS.txt` | 校验值，用于确认下载没被篡改/损坏 |

校验（可选）：

```bash
shasum -a 256 Macrife-1.6.dmg
# 和 SHA256SUMS.txt 里对应的一行比对，一致即可
```

### 2. 安装

双击打开下载的 `Macrife.dmg` → 把 `Macrife` 图标拖到窗口里的 `Applications` 替身上即可完成安装。安装后推出磁盘镜像。

### 3. 首次打开：可能会看到「无法打开」
macOS 的 Gatekeeper 会拦一下。
**这是正常的，不是文件损坏。** 任选一种方式放行：

**方式 A（推荐，一次就好）** —— 在访达里 **右键** 点 `Macrife.app` → 选「打开」→ 弹窗里再点「打开」。之后双击就能正常启动了。

**方式 B** —— 终端里清掉隔离标记：

```bash
xattr -cr /Applications/Macrife.app
```

> 如果看到的是「App 已损坏，无法打开」，也是同一个原因，用上面任一方式即可。

---

## 四、使用方法

### 图形界面

1. 打开 Macrife。
2. 拖一个视频进窗口（也可以拖到 Dock 上的 Macrife 图标，或在访达里右键「打开方式 → Macrife」）。
3. 选目标帧率（默认 60 或 120）、处理精度（默认 auto，日常推荐 576p / 运动大片选 1080p）、算力模式（默认节能 ANE 或双擎并发）。
4. 选码率（默认 20 Mbps）与编码器（默认 H.264，4K 推荐 HEVC）。
5. 需要保留声音就把「复制源视频的音轨」打开（默认开）。
6. 点「开始」，等进度条走完。支持随时暂停与恢复。

输出文件：与源文件**同一目录**，文件名是 `<原名>_interpolated.mp4`。

### 命令行

```bash
/Applications/Macrife.app/Contents/MacOS/Macrife \
    --run --in ~/Movies/a.mp4 --out ~/Movies/b.mp4 --fps 60 --mbps 20 --tier 576p --dual
```

常用参数：
- `--fps`：目标帧率
- `--mbps`：码率 (Mbps)
- `--codec h264|hevc`：编码格式
- `--tier auto|576p|720p|1080p|1440p|2160p`：处理精度档位
- `--mode ane|gpu|dual`：算力模式（节能 / 独显 / 双擎并发）
- `--dual-strategy ane-gpu|ane2-gpu|dual-ane|triple-ane`：双擎调度策略（默认自适应）
- `--hardware`：探查并输出当前宿主机芯片与内存自适应画像
- `--noaudio`：不复制音频
- `--dryrun`：预检输入视频与选档，不执行推理

---

## 五、关于处理精度档位

处理精度是模型的采样尺寸，**不是输出视频的分辨率**（输出永远保持原片尺寸）：

- **576p**：日常/原视频为1080p推荐，速度最快，功耗仅 5W，发热极低；在 120fps 超高刷下表现最稳健。配合原分辨率融合，4K 画面细节无损。
- **720p/1080p**：**甜点档**。光流网格密集度提升，适合运动跟拍、无人机快速平移/原素材4k，需要较高精度光流等场景。
- **1440p / 2160p**：高精度离线渲染档，用于运动极端剧烈、对边缘光流有极高要求的场景，速度会慢，配置和内存要求较高

想用自己导出的模型：放到
```
~/Library/Application Support/Macrife/models/coreml/
```
该目录**存在时会整体覆盖** App 内置模型，请自备对应子目录。

---

## 七、许可

源码不公开（本仓库只用于分发成品）。许可条款见 [LICENSE](LICENSE)。
RIFE 算法结构来自开源社区，感谢原作者团队。
