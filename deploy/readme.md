# Star Service Deploy

在新 Ubuntu x64 机器上一键部署 **Docker** 与 **EasyTier** 的脚本集合。

---

## 目录结构

```
deploy/
├── deploy.sh          # 一键部署脚本
├── easytier.service   # systemd 服务单元文件
└── readme.md          # 本文档
```

---

## 前置条件

| 条件 | 说明 |
|------|------|
| 操作系统 | Ubuntu 20.04 / 22.04 / 24.04 x86_64 |
| 权限 | 需要以 **root** 身份执行（或 `sudo`） |
| 网络 | 需能访问 GitHub 及 Docker 官方源 |

---

## easytier.service 配置说明

部署前请根据实际环境修改 `easytier.service` 中的启动参数。

```ini
[Unit]
Description=easytier client on boot
After=network.target

[Service]
Type=simple
ExecStart=/root/easytier-linux-x86_64/easytier-core \
    --network-name starwork \
    --network-secret 667788 \
    -p tcp://1qg14453321nn.vicp.fun:39525 \
    --ipv4 10.126.126.50 \
    --no-listener
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 关键参数说明

| 参数 | 示例值 | 说明 |
|------|--------|------|
| `ExecStart` 路径 | `/root/easytier-linux-x86_64/easytier-core` | **必须与 `deploy.sh` 的 `<install_dir>` 参数保持一致** |
| `--network-name` | `starwork` | EasyTier 虚拟网络名称 |
| `--network-secret` | `667788` | 网络接入密码，所有节点需相同 |
| `-p` | `tcp://1qg14453321nn.vicp.fun:39525` | 中继服务器（peer）地址 |
| `--ipv4` | `10.126.126.50` | 本机在虚拟网络中的 IP，**每台机器需唯一** |
| `--no-listener` | — | 纯客户端模式，不监听入站连接 |

> ⚠️ **注意**：`ExecStart` 中的二进制路径必须与下方 `deploy.sh` 的 `<install_dir>` 参数完全一致，否则服务无法启动。

---

## deploy.sh 使用方法

### 语法

```bash
sudo ./deploy.sh <install_dir>
```

- `<install_dir>`：EasyTier 二进制文件的解压目标路径，**需与 `easytier.service` 中的路径匹配**。

### 示例

```bash
# 1. 将 deploy/ 目录上传到目标机器（示例使用 scp）
scp -r ./deploy/ root@<server-ip>:~/

# 2. 登录目标机器
ssh root@<server-ip>

# 3. 赋予执行权限
chmod +x ~/deploy/deploy.sh

# 4. 执行部署（install_dir 与 easytier.service 中路径一致）
sudo ~/deploy/deploy.sh /root/easytier-linux-x86_64
```

### 脚本执行流程

```
[1/4] 更新 apt 并安装基础工具（curl、unzip 等）
[2/4] 安装 Docker CE（若已安装则跳过）
[3/4] 下载 EasyTier v2.6.3 并解压至 <install_dir>
[4/4] 复制 easytier.service 至 systemd，启用并启动服务
```

### 验证部署结果

```bash
# 查看服务状态
systemctl status easytier

# 实时查看日志
journalctl -u easytier -f

# 验证 Docker 安装
docker version
```

---

## 常见问题

**Q：服务启动失败，提示二进制文件找不到？**  
A：检查 `easytier.service` 中 `ExecStart` 的路径是否与 `deploy.sh` 传入的 `<install_dir>` 完全一致。

**Q：如何修改节点 IP？**  
A：编辑 `easytier.service` 中的 `--ipv4` 参数，修改后执行：
```bash
systemctl daemon-reload && systemctl restart easytier
```

**Q：如何更新 EasyTier 版本？**  
A：修改 `deploy.sh` 中的 `EASYTIER_VERSION` 变量，重新执行脚本即可。
