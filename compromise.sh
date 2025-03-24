#!/bin/bash

replace() {
  # 替换图片路径
  find source/_posts -type f -name "*.md" -exec sed -i 's|(\.\./img/|(/img/|g' {} +
  # 替换 C++ 为 C&#43;&#43;
  find source/_posts -type f -name "*.md" -exec sed -i 's/ C++/ C\&#43;\&#43;/Ig' {} +
  # 替换 CPP 为 C&#43;&#43;
  find source/_posts -type f -name "*.md" -exec sed -i 's/ CPP/ C\&#43;\&#43;/Ig' {} +

  echo "替换完成"
}

restore() {
  # 复原图片路径
  find source/_posts -type f -name "*.md" -exec sed -i 's|(/img/|(\.\./img/|g' {} +
  # 复原 C&#43;&#43; 为 C++
  find source/_posts -type f -name "*.md" -exec sed -i 's/ C\&#43;\&#43;/ C++/g' {} +

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