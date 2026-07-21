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
