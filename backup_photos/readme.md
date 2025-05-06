# 手机照片备份工具文档

## 功能概述

这是一个用于从安卓设备备份照片到本地计算机的 Bash 脚本工具，具有以下功能：

- 自动扫描设备上的照片文件
- 支持多种图片格式（JPG/PNG/GIF/HEIC 等）
- 可自定义白名单和黑名单目录
- 支持按日期范围筛选照片
- 详细的日志记录和进度显示
- 保留原始目录结构

## 系统要求

- Linux/macOS 系统（或 Windows 的 WSL）
- ADB 工具（Android Debug Bridge）
- 已启用 USB 调试的安卓设备

## 安装方法

1. 将脚本保存为 `backup_photos.sh`
2. 添加可执行权限：
   ```bash
   chmod +x backup_photos.sh
   ```
3. 确保 ADB 已安装并配置

## 使用说明

### 基本用法

```bash
./backup_photos.sh
```

默认将照片备份到当前目录下的 `phone_photos` 文件夹

### 命令行选项

| 选项                      | 说明                   | 示例                                         |
| ------------------------- | ---------------------- | -------------------------------------------- |
| `--output=DIR`            | 指定输出目录           | `--output=~/backups/photos`                  |
| `--whitelist=DIR1,DIR2`   | 添加白名单目录         | `--whitelist=/sdcard/DCIM,/sdcard/Pictures`  |
| `--blacklist=DIR1,DIR2`   | 添加黑名单目录         | `--blacklist=/sdcard/Android,/sdcard/.trash` |
| `--start-date=YYYY-MM-DD` | 只备份此日期之后的照片 | `--start-date=2023-01-01`                    |
| `--end-date=YYYY-MM-DD`   | 只备份此日期之前的照片 | `--end-date=2023-12-31`                      |
| `--log=FILE`              | 指定日志文件位置       | `--log=backup.log`                           |
| `--help`                  | 显示帮助信息           | `--help`                                     |

### 高级用法示例

1. 备份 2023 年全年的照片到指定目录：

   ```bash
   ./backup_photos.sh --output=~/photos_2023 --start-date=2023-01-01 --end-date=2023-12-31
   ```

2. 只备份 DCIM 和 WhatsApp 目录，排除缓存目录：

   ```bash
   ./backup_photos.sh --whitelist=/sdcard/DCIM,/sdcard/WhatsApp --blacklist=/sdcard/Android
   ```

3. 自定义日志位置并显示详细进度：
   ```bash
   ./backup_photos.sh --log=~/photo_backup.log
   ```

## 技术细节

### 支持的文件格式

- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- BMP (.bmp)
- WebP (.webp)
- HEIC/HEIF (.heic)

### 默认目录设置

**白名单目录（默认包含）**:

- /sdcard/DCIM
- /sdcard/Pictures
- /sdcard/WhatsApp/Media

**黑名单目录（默认排除）**:

- /sdcard/Android
- /sdcard/.thumbnails
- /sdcard/.trash

### 日志文件格式

日志文件包含以下信息：

- 备份开始/结束时间
- 处理的目录列表
- 每个文件的状态（成功/失败/跳过）
- 统计摘要

示例日志条目：

```
2023-11-15 14:30:45 [INFO] 正在处理目录: /sdcard/DCIM/Camera
2023-11-15 14:30:47 [INFO] [1/25] 正在下载: /sdcard/DCIM/Camera/IMG_20230101.jpg
2023-11-15 14:30:48 [INFO] [2/25] 跳过已存在文件: /sdcard/DCIM/Camera/IMG_20230102.jpg
```

## 常见问题

**Q: 脚本报错"adb 未找到"**
A: 请先安装 Android SDK Platform-Tools 包，确保 adb 在系统 PATH 中

**Q: 设备连接但脚本检测不到**
A: 确认：

1. 已启用 USB 调试模式
2. 设备已授权此计算机
3. 使用`adb devices`确认设备列表

**Q: 某些照片无法下载**
A: 可能是权限问题，尝试：

1. 在设备上授权文件访问权限
2. 检查文件是否被其他应用锁定
3. 查看日志文件了解具体错误

**Q: 备份速度很慢**
A: 可以：

1. 使用更具体的白名单减少扫描范围
2. 排除大文件目录（如视频文件夹）
3. 确保使用 USB 3.0+连接

## 注意事项

1. 首次使用需要在安卓设备上授权 ADB 访问
2. 建议连接稳定的 USB 线缆
3. 备份大量文件可能需要较长时间
4. 系统目录和隐藏目录默认会被排除

## 许可协议

本项目使用 MIT 许可证。详细信息请查看随附的 LICENSE 文件。

## 反馈与贡献

欢迎通过 GitHub 提交问题和改进建议。
