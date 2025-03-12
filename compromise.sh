#!/bin/bash

# 替换 ../img/ 为 /img/
replace() {
  find source/_posts -type f -name "*.md" -exec sed -i 's|(\.\./img/|(/img/|g' {} +
  echo "替换完成"
}

# 复原 /img/ 为 ../img/
restore() {
  find source/_posts -type f -name "*.md" -exec sed -i 's|(/img/|(\.\./img/|g' {} +
  echo "复原完成"
}

# 检查传入的参数
if [ "$1" == "hexo" ]; then
  replace
elif [ "$1" == "vsc" ]; then
  restore
else
  echo "使用方法: $0 {vsc|hexo}"
fi