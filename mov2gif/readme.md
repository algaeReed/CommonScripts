# `mov2gif.sh` - MOV 转 GIF 转换脚本

一个简单的 Bash 脚本，使用 `ffmpeg` 将 MOV 视频文件转换为 GIF 动画。

## 功能

- 将 MOV 文件转换为 GIF 格式
- 自动调整帧率（10fps）和分辨率（宽度 640px，高度按比例缩放）
- 支持自定义输出文件名

## 依赖

- `ffmpeg`（必须安装）

## 安装

```bash
chmod +x mov2gif.sh
```

## 使用方法

```bash
./mov2gif.sh <input.mov> [output.gif]
```

### 参数说明

| 参数         | 说明                                          |
| ------------ | --------------------------------------------- |
| `input.mov`  | 输入的 MOV 视频文件（必需）                   |
| `output.gif` | 输出的 GIF 文件名（可选，默认使用输入文件名） |

## 示例

1. 基本转换（输出 `video.gif`）：

   ```bash
   ./mov2gif.sh video.mov
   ```

2. 指定输出文件名：
   ```bash
   ./mov2gif.sh input.mov output.gif
   ```
