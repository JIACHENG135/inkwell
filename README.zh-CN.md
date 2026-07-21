<p align="right"><a href="./README.md">English</a></p>

# inkwell

[![Latest release](https://img.shields.io/github/v/release/jiachliu666/inkwell)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jiachliu666/inkwell/total)](../../releases)
[![Platform](https://img.shields.io/badge/platform-reMarkable%202%20%7C%20Paper%20Pro-blue)](../../releases)
[![License](https://img.shields.io/github/license/jiachliu666/inkwell)](./LICENSE)

**rm-agent** 让你的 reMarkable 平板变成一台能"回信"的平板。

用笔点一下页面的角落，它就能回答你手写的问题，或者按你的要求画一幅画 ——
直接驱动平板自己的笔尖，回复看起来、摸起来都跟真墨水写的一样，而不是导入的图片。
现在同时支持 **reMarkable 2** 和 **reMarkable Paper Pro**。

## 功能

- **点击提问** — 点击角落图标，手写的问题会被自动识别并回答。
- **真实笔迹，非导入** — 回复以真实的笔尖事件回放，从你上次落笔的位置开始书写，呈现为原生墨迹。
- **有上下文感知，又不用每次重读整页** — 每一轮都会把新截图和上一次回复刚画完时的截图做对比，
  发给 Gemini 的是**整页截图 + 红框圈出新增内容**，既保留了页面其余部分的上下文
  （比如新问题引用的某个图表），又不会让已经回答过的旧内容稀释掉提示词。擦除的内容会被忽略，
  所以清理旧笔记不会干扰这个对比逻辑。
- **无需电脑、无需数据线** — 完全在设备本地以后台服务运行，不用同步到电脑，也不需要任何导入步骤。
- **开机自启** — 以 systemd 服务安装，随 reMarkable 系统自身界面启动后运行，崩溃后自动重启；
  设备连续开机好几天也没关系，登录状态会在过期时自动刷新。
- **【实验性】三指划词翻译** *(仅 reMarkable 2)* — 圈一个词、画一条下划线、或者框选一整段话，
  三指点一下屏幕，翻译结果会直接弹窗显示在页面上；如果标记的是单词/短语还会附带一个例句。
  详见[下文](#实验性功能三指划词翻译-remarkable-2) —— 这个功能是基于第三方框架实现的，
  有一些需要了解的风险，安装前请务必阅读完整说明。

## 演示

![演示](./demo.gif)

观看 rm-agent 回答手写问题、以及按要求画图，两种效果都是用平板自己的笔迹"写"回页面的（录制自 reMarkable 2）。

## 下载

这个仓库不包含任何源代码，只有编译好的 `rm-agent` 二进制文件。前往
[Releases](../../releases) 页面下载适合你设备的版本：

| 设备 | 二进制文件 | 还需要的文件 |
| --- | --- | --- |
| reMarkable 2 | `rm-agent-*-armv7-unknown-linux-musleabihf` | `rm-agent.service`、`rm-agent.env.example` |
| reMarkable Paper Pro | `rm-agent-*-aarch64-unknown-linux-musl` | `rm-agent-paperpro.service`、`goMarkableStream.service`、`rm-agent.env.example` |

## 安装教程 — reMarkable 2

这个二进制文件是专门给 reMarkable 2 本身编译的（ARM 架构、musl libc）——
**不能**直接在你的 Mac 或 PC 上运行。先在电脑上下载好，再通过 SSH 拷贝到平板上，
设置成后台服务运行。

开始之前：

- 在 reMarkable 上开启 SSH：**设置 → 关于本机 → Copyrights and licenses**
  页面会显示设备的 root 密码。同时在 **设置 → 关于本机 → 通用** 里记下设备的
  IP 地址（或者去路由器管理页面查）。
- 准备一个能访问图像生成模型的 [Gemini API key](https://aistudio.google.com/apikey)。

### macOS 下

```sh
# 1. 把二进制和服务文件拷贝到设备上
scp rm-agent-*-armv7-unknown-linux-musleabihf remarkable:/home/root/rm-agent
scp rm-agent.service remarkable:/etc/systemd/system/rm-agent.service
scp rm-agent.env.example remarkable:/home/root/.config/rm-agent.env

# （如果没有配置过 `remarkable` 这个 SSH 别名，就用 root@<设备IP> 代替）

# 2. 加执行权限，并填入你的 API key
ssh remarkable 'chmod +x /home/root/rm-agent'
ssh remarkable 'vi /home/root/.config/rm-agent.env'   # 填写 GEMINI_API_KEY

# 3. 启用并启动服务
ssh remarkable 'systemctl daemon-reload && systemctl enable --now rm-agent.service'
```

### Windows 下

Windows 10/11 自带 OpenSSH 客户端，所以在 PowerShell 里同样可以用
`scp`/`ssh` 命令 —— 只是要把设备 IP 地址代替 SSH 别名（除非你在
`~/.ssh/config` 里配置过别名）：

```powershell
# 1. 把二进制和服务文件拷贝到设备上
scp rm-agent-*-armv7-unknown-linux-musleabihf root@<设备IP>:/home/root/rm-agent
scp rm-agent.service root@<设备IP>:/etc/systemd/system/rm-agent.service
scp rm-agent.env.example root@<设备IP>:/home/root/.config/rm-agent.env

# 2. 加执行权限，并填入你的 API key
ssh root@<设备IP> "chmod +x /home/root/rm-agent"
ssh root@<设备IP> "vi /home/root/.config/rm-agent.env"   # 填写 GEMINI_API_KEY

# 3. 启用并启动服务
ssh root@<设备IP> "systemctl daemon-reload && systemctl enable --now rm-agent.service"
```

如果 `scp`/`ssh` 命令提示找不到，去 **设置 → 应用 → 可选功能 → OpenSSH 客户端**
里启用，或者改用 WinSCP 这类 SFTP 工具来传文件。

### 验证是否运行成功

```sh
ssh remarkable 'systemctl status rm-agent'
ssh remarkable 'journalctl -u rm-agent -f'
```

之后用笔点一下屏幕左下角的图标提问。

## 安装教程 — reMarkable Paper Pro

Paper Pro 需要两个 reMarkable 2 不需要的东西：

- **[goMarkableStream](https://github.com/owulveryck/goMarkableStream)** ——
  一个第三方工具，rm-agent 靠它提供截图/登录 API（xochitl 自己没有原生提供这个接口）。
  去它的 [releases 页面](https://github.com/owulveryck/goMarkableStream/releases)
  下载 `gomarkablestream-RMPRO` 这个文件。
- 一套不一样的"开机自启持久化"方式。Paper Pro 上的 `/etc` 是一个**易失**的
  overlay 文件系统，每次重启都会被清空——放进 `/etc/systemd/system` 里的东西重启就没了。
  service 文件得放到 `/lib/systemd/system`（跟 xochitl 自己的文件同一个位置），
  这意味着需要临时把平时只读的根文件系统改成可读写来安装。

开始之前：

- 打开开发者模式：**设置 → 通用 → Paper Tablet → 软件 → 高级 → 开发者模式**
  （这会重置设备，需要重新走一遍开机引导流程）。
- 获取 root 密码：**设置 → 通用 → 帮助 → 关于 → 版权和许可**，翻到 GPLv3
  Compliance 部分。
- 默认只能通过 USB 连接 SSH。先用 USB 连接，SSH 到 `10.11.99.1`，用上面的密码登录。
  进去之后跑一下 `rm-ssh-over-wlan on`，之后就能走 WiFi SSH 了，后面的步骤会方便很多。
- 准备一个能访问图像生成模型的 [Gemini API key](https://aistudio.google.com/apikey)。

### 1. 安装 goMarkableStream

```sh
scp gomarkablestream-RMPRO root@<设备IP>:/home/root/goMarkableStream
scp goMarkableStream.service root@<设备IP>:/lib/systemd/system/goMarkableStream.service
ssh root@<设备IP> 'chmod +x /home/root/goMarkableStream'
```

### 2. 安装 rm-agent

```sh
scp rm-agent-*-aarch64-unknown-linux-musl root@<设备IP>:/home/root/rm-agent
scp rm-agent-paperpro.service root@<设备IP>:/lib/systemd/system/rm-agent.service
scp rm-agent.env.example root@<设备IP>:/home/root/.config/rm-agent.env
ssh root@<设备IP> 'chmod +x /home/root/rm-agent'
ssh root@<设备IP> 'vi /home/root/.config/rm-agent.env'   # 填写 GEMINI_API_KEY
```

### 3. 让两个服务开机自启

这一步是跟 reMarkable 2 不一样的地方：开机启用的软链接必须放在**持久化**的文件系统里，
所以放在 `/lib` 下的 `xochitl.service.wants/` 目录，而不是常规的 `/etc` 路径。

```sh
ssh root@<设备IP> '
mount -o remount,rw /
mkdir -p /lib/systemd/system/xochitl.service.wants
ln -sf /lib/systemd/system/goMarkableStream.service /lib/systemd/system/xochitl.service.wants/goMarkableStream.service
ln -sf /lib/systemd/system/rm-agent.service /lib/systemd/system/xochitl.service.wants/rm-agent.service
mount -o remount,ro /
systemctl daemon-reload
systemctl enable --now goMarkableStream.service
systemctl enable --now rm-agent.service
'
```

### 验证是否运行成功

```sh
ssh root@<设备IP> 'systemctl status goMarkableStream rm-agent'
ssh root@<设备IP> 'journalctl -u rm-agent -f'
```

两个服务都应该显示 `active (running)`。第一次装好后建议实际重启验证一下——
`ssh root@<设备IP> reboot`，等它重新联网后再跑一遍上面的状态检查命令。

之后用笔点一下页面上的角落图标提问。

## 【实验性功能】三指划词翻译 (reMarkable 2)

圈一个词、画一条下划线、或者框选一整段话，然后三指点一下屏幕——弹窗会显示中文翻译
（如果标记的是单个单词/短语，还会附带一个例句，目标词在中英文里都会加粗；如果标记的是
一整句话或一整段，就直接给出完整翻译）。弹窗可以随意拖动到屏幕任意位置，点弹窗以外的
地方或者等几秒会自动关闭。

**安装前请务必读完这一整节。** 跟 rm-agent 本体不一样（它只是在 xochitl 旁边独立运行，
完全不改动 xochitl 本身），这个功能是靠 **[XOVI](https://github.com/asivery/rm-xovi-extensions)**
这个非官方的、社区开发的 hook 框架，直接对 xochitl 正在运行的 QML 界面打补丁实现的——
reMarkable 官方不支持也不提供这个框架。这意味着有一些实实在在的、具体的风险：

- **补丁写错会导致 xochitl 陷入崩溃循环。** 开发过程中就踩过一次坑：一个 QML 属性名写错了，
  导致 xochitl 每次启动都立刻退出——平板看起来就像卡在"正在重启"死循环里出不来了，
  直到把补丁撤掉才恢复。下面的安装步骤里专门加了一步安全验证
  （`xovi/debug`，前台运行，出问题随时 Ctrl-C 中断）,在切换到常驻模式之前一定要先跑这一步——
  **千万别跳过**，动手之前也先记住一键回滚的命令（`xovi/stock`）。
- **补丁是跟固件版本绑死的。** XOVI 把 QML 里的属性名/类型名换成了根据你设备*具体*
  xochitl 版本生成的数字哈希；这里只提供了一份预先哈希好的补丁，是针对
  **固件 3.27.3.0** 构建和测试的。如果你的设备是别的固件版本，需要自己重新生成哈希表、
  重新给补丁做哈希（步骤见下文）——用错哈希表生成的补丁，轻则"完全不生效"，
  重则复现上面说的崩溃循环，所以不管你是哪个固件版本，`xovi/debug` 这步验证都不能跳过。
- **目前只支持 reMarkable 2。** 还没适配 Paper Pro。
- **`xovi/start` 不会自动在重启后生效**（它用的是 tmpfs 挂载）——下面的安装步骤加了一个
  很小的 systemd 单元（`xovi-start.service`），让它在每次开机时自动重新执行一遍，
  所以不需要你手动记得做这件事，但确实是多了一个每次开机都会跑的东西。

如果这些风险对你的平板来说顾虑太大，可以跳过这一节——上面的 rm-agent 核心功能完全不需要这些。

### 这个文件夹里有什么

| 文件 | 作用 |
| --- | --- |
| `translate-daemon-v0.1.0-armv7-unknown-linux-musleabihf` | 配套的后台服务——负责截图、对比截图找出你标记的内容，并调用 Gemini 翻译。复用了 rm-agent 本体同一套截图接口。 |
| `three_finger_translate.rm2-fw3.27.3.0.qmd` | XOVI 补丁，已经针对固件 3.27.3.0 哈希好——给 xochitl 的文档视图加上手势识别和弹窗界面。 |
| `three_finger_translate.source.qmd` | 同一份补丁的明文可读版本（未针对任何固件哈希）——如果你的固件版本不一样，从这份文件开始重新哈希。 |
| `NotoSansSC.ttf`、`NotoSansSC-Bold.ttf` | 弹窗用的中文字体——reMarkable 2 自带字体只有拉丁字符，不装这两个字体中文会显示成方块。 |
| `xovi-start.service` | 每次开机自动重跑一遍 `xovi/start`（见上面关于重启持久化的说明）。 |
| `translate-daemon.service`、`goMarkableStream.service`、`rm-agent.service` | systemd 单元，启动顺序上特意排在"XOVI 给 xochitl 打完补丁"之后（这个顺序修复了一个真实存在的 bug：如果不这样排序，goMarkableStream 有可能抢在 XOVI 重启 xochitl *之前*就先记录了 xochitl 的进程号，之后每次截图都会失败并返回 500 错误，得手动重启才能恢复）。**这里的 `goMarkableStream.service`/`rm-agent.service` 会覆盖掉上面基础安装用的那两个版本**——如果你已经装过核心功能，装这个功能的时候会把它们覆盖掉。 |

### 前置条件

- 已经装好并且能正常工作的 rm-agent 核心功能（见上文）——这个功能复用它的 Gemini API key
  和截图登录逻辑。
- 能 SSH 连上平板（跟上面一样）。

### 1. 安装 XOVI 框架

如果设备上已经有 `/home/root/xovi` 了，跳过这步。

```sh
# 在你的电脑上 —— 下载最新的 armv7 版 XOVI
curl -sL -o xovi-arm32.tar.gz "$(curl -sL https://api.github.com/repos/asivery/rm-xovi-extensions/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*xovi-arm32[^"]*"' | head -1 | sed -E 's/.*"(https[^"]+)"/\1/')"
mkdir xovi && tar -xzf xovi-arm32.tar.gz -C xovi --strip-components=1
scp -r xovi root@<设备IP>:/home/root/xovi

# scp 没法跟随的两个符号链接会被跳过传输——在设备上手动补上
ssh root@<设备IP> '
ln -sf /home/root/xovi/extensions.d /home/root/xovi/services/xochitl.service/extensions.d
ln -sf /home/root/xovi/exthome /home/root/xovi/services/xochitl.service/exthome
'
```

激活这个功能需要的两个扩展：

```sh
ssh root@<设备IP> '
mv /home/root/xovi/inactive-extensions/qt-resource-rebuilder.so /home/root/xovi/extensions.d/ 2>/dev/null
mv /home/root/xovi/inactive-extensions/qt-command-executor.so /home/root/xovi/extensions.d/ 2>/dev/null
ls /home/root/xovi/extensions.d/
'
```

### 2. 获取适配你固件版本的哈希表

先查一下固件版本：

```sh
ssh root@<设备IP> "grep REMARKABLE_RELEASE_VERSION /usr/share/remarkable/update.conf"
```

**如果显示的是 `3.27.3.0`**，直接跳到第 3 步——这个文件夹里的
`three_finger_translate.rm2-fw3.27.3.0.qmd` 已经是对应版本了。

**如果是其他版本**，需要针对你的固件生成哈希表，然后重新给
`three_finger_translate.source.qmd` 做哈希：

```sh
# 这一步会运行一次 xochitl，过程中需要在平板上输入一次开机密码——
# 运行期间会停掉 xochitl 以及依赖它的所有服务
ssh -t root@<设备IP> '/home/root/xovi/rebuild_hashtable'
scp root@<设备IP>:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab ./hashtab
ssh root@<设备IP> 'systemctl start xochitl'   # 恢复运行

# 编译 qmldiff（需要 Rust 工具链：https://rustup.rs）
git clone --depth 1 https://github.com/asivery/qmldiff.git
(cd qmldiff && cargo build --release)

# 用你的哈希表给补丁做哈希（会原地修改这个文件）
cp three_finger_translate.source.qmd my-translate.qmd
./qmldiff/target/release/qmldiff hash-diffs ./hashtab my-translate.qmd
```

接下来的步骤里，把 `three_finger_translate.rm2-fw3.27.3.0.qmd` 换成你自己生成的
`my-translate.qmd` 即可。

### 3. 安装补丁、字体和后台服务

```sh
ssh root@<设备IP> 'mkdir -p /home/root/xovi/exthome/translate'
scp three_finger_translate.rm2-fw3.27.3.0.qmd \
    root@<设备IP>:/home/root/xovi/exthome/qt-resource-rebuilder/three_finger_translate.qmd
scp NotoSansSC.ttf NotoSansSC-Bold.ttf root@<设备IP>:/home/root/xovi/exthome/translate/

scp translate-daemon-v0.1.0-armv7-unknown-linux-musleabihf root@<设备IP>:/home/root/translate_daemon
ssh root@<设备IP> 'chmod +x /home/root/translate_daemon'

scp xovi-start.service translate-daemon.service goMarkableStream.service rm-agent.service \
    root@<设备IP>:/etc/systemd/system/
ssh root@<设备IP> 'systemctl daemon-reload'
```

### 4. 切换常驻模式之前，先用 `xovi/debug` 验证——这步不能跳过

`xovi/debug` 会在前台运行打了补丁的 xochitl，一旦有问题能立刻看到，
直接 Ctrl-C 中断就行——这个阶段还没有任何改动会持久化。

```sh
ssh root@<设备IP> 'systemctl stop xochitl'
ssh root@<设备IP> '/home/root/xovi/debug'
```

留意输出内容。如果看到类似 `Cannot assign to non-existent property` 或者
`Type ... unavailable` 这样的报错，说明有问题（最可能是哈希表用错了）——按 Ctrl-C 中断，
然后执行 `ssh root@<设备IP> '/home/root/xovi/stock'` 确保 xochitl 恢复成正常未打补丁的状态，
先别继续第 5 步。如果平板界面看起来一切正常，就 Ctrl-C 退出这个 SSH 会话
（这会停掉刚才在前台启动的 xochitl），然后继续往下走。

### 5. 切换到常驻模式

```sh
ssh root@<设备IP> '
/home/root/xovi/start
systemctl enable xovi-start.service goMarkableStream.service rm-agent.service translate-daemon.service
systemctl restart goMarkableStream rm-agent translate-daemon
systemctl is-active xochitl goMarkableStream rm-agent translate-daemon xovi-start
'
```

五个服务应该都显示 `active`。第一次装好后建议实际重启验证一下，跟基础安装那步一样。

### 使用方法

打开一篇笔记，用笔圈/画线/框选想翻译的内容，然后在页面任意位置三指点一下
（**先标记，再点按**——三指点按触发的是"翻译上次以来新增的标记"，顺序反了会翻译不到东西）。
几秒钟内弹窗就会出现翻译结果；可以随意拖动弹窗位置，点弹窗以外的地方或者点右上角
的 **×** 可以提前关闭它。

### 遇到问题怎么办

- **平板卡在"正在重启"、xochitl 起不来**：立刻执行
  `ssh root@<设备IP> '/home/root/xovi/stock'`，马上恢复成正常未打补丁的 xochitl——
  命令跑完平板就安全了。
- **截图请求返回 500 错误**：执行 `ssh root@<设备IP> 'systemctl restart goMarkableStream'`——
  如果它在 XOVI 打完补丁之前就抢先记录了 xochitl 的进程号，就需要重启一下才能恢复。
- **弹窗里中文显示成方块**：字体没传到 `/home/root/xovi/exthome/translate/`，
  重新执行一遍第 3 步里的 `scp` 命令。
