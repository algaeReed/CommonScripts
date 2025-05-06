#!/bin/bash

# 检查是否传入参数
if [ $# -eq 0 ]; then
    echo "Usage: $0 input.mov [output.gif]"
    exit 1
fi

# 输入文件
input="$1"

# 检查输入文件是否存在
if [ ! -f "$input" ]; then
    echo "Error: Input file '$input' not found!"
    exit 1
fi

# 输出文件名（如果未指定第二个参数，则使用输入文件名+ .gif 后缀）
if [ -z "$2" ]; then
    output="${input%.*}.gif"
else
    output="$2"
fi

# 执行转换
echo "Converting $input to $output ..."
ffmpeg -i "$input" -vf "fps=10,scale=640:-1:flags=lanczos" -c:v gif "$output"

# 检查是否成功
if [ $? -eq 0 ]; then
    echo "Conversion successful! Output file: $output"
else
    echo