# 写给笔者自己看

## Git clone
因为加入了 butterfly 子模块，所以需要递归 clone，否则会找不到 layout 文件。
```
 git clone --recursive -b hexo git@github.com:GG2002/GG2002.github.io.git personal-page
```

## Git clone 静态文件以发布
```
cd personal-page
git clone git@github.com:GG2002/GG2002.github.io.git public
```

## 配环境
```
npm install -g hexo-cli
npm install
``` 
