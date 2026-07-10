<p align="right"><a href="./README.md">English</a></p>

# inkwell

[![Latest release](https://img.shields.io/github/v/release/jiachliu666/inkwell)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jiachliu666/inkwell/total)](../../releases)
[![Platform](https://img.shields.io/badge/platform-reMarkable%202-blue)](../../releases)
[![License](https://img.shields.io/github/license/jiachliu666/inkwell)](./LICENSE)

**rm-agent** 让你的 reMarkable 2 变成一台能"回信"的平板。

用笔点一下页面的角落，它就能回答你手写的问题，或者按你的要求画一幅画 ——
直接驱动平板自己的笔尖，回复看起来、摸起来都跟真墨水写的一样，而不是导入的图片。

## 功能

- **点击提问** — 点击左下角，手写的问题会被自动识别并回答。
- **点击画图** — 点击右下角，按要求生成一幅简笔画。
- **真实笔迹，非导入** — 回复以真实的笔尖事件回放，从你上次落笔的位置开始书写，呈现为原生墨迹。
- **无需电脑、无需数据线** — 完全在设备本地以后台服务运行，不用同步到电脑，也不需要任何导入步骤。
- **开机自启** — 以 systemd 服务安装，随 reMarkable 系统自身界面启动后运行，崩溃后自动重启。

## 演示

![演示](./demo.gif)

观看 rm-agent 回答手写问题、以及按要求画图，两种效果都是用平板自己的笔迹"写"回页面的。

## 下载

这个仓库不包含任何源代码，只有编译好的 `rm-agent` 二进制文件。前往
[Releases](../../releases) 页面下载最新版本。每个 release 里还附带
`rm-agent.service`（systemd 服务单元）和 `rm-agent.env.example`（配置模板），
这两个也要一起下载。

## 安装教程

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

之后用笔点一下屏幕左下角提问，或者点右下角让它画图。
