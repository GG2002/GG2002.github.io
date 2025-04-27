---
title: Nas 自动化追番系统搭建
date: 2024-06-14 21:41:20
tags: nas
---
来使用 Nas 搭建一个自动化娱乐设备罢。

## 购买背景
由于笔者现在电脑设备有好几台，最近出于优化工作流的想法，想把自己的个人资料和一些工作文件丢到一起方便管理；而且笔者去年买的 1TB 和 2TB 固态剩余空间现在都有些捉襟见肘了，想把一些 galgame 和正经游戏丢到机械硬盘里存起来；再而且，笔者也需要一台 24h 运行的性能还过得去的设备来跑一些百度云下载、自己写的爬虫等等的简单任务。

综上所述，奖励自己一台 2k 元的威联通 Nas TS-464c 情有可原。
![威联通 TS-t464c](https://gg2002.github.io/img/nas-tool/ts-464c.png)

在此之前，笔者有组过 OpenWrt 软路由和使用树莓派 + 外挂硬盘当文件服务器使用的经历。踩的坑太多了，最近也没什么时间捡垃圾回来自组一台 Nas，索性就买一次成品 Nas。

威联通与群晖是 Nas 老牌厂商了，大家对于群晖的评价是简单易用、高价低配，那么威联通自然就是难用、买硬件送软件的性价比代名词。当然，笔者阅读了大量文章后能感觉出威联通所谓的难用也只是对于计算机小白来说的，对于笔者这种软件开发者而言没什么难度，所以威联通很合笔者口味，当即下单。

实际上，笔者想下单之时（2024 年 6 月 2 日）正好遇上国产厂商绿联 DXP4800 发售，看了眼 b 站与什么值得买，评测都是夸好，而且其硬件配置堪称豪华，笔者也很是心动。只是看了更多的评测后，笔者感受到一丝软文的气息，最终还是放弃了绿联 DXP4800，毕竟 nas 那点 cpu 性能，多 10% 少 10% 确实没啥区别，主要还是看各家（基于 linux 的）自研系统调教如何。

然后很有节目效果的是，绿联 6 月 3 日（或者 4 日）就下架了该产品，同时 b 站 nas 区里比较大的 up 主司波图也发了道歉声明（后面好像又删了），因为绿联系统做得实在太烂，大家都纷纷退款。这引得笔者一阵后怕，毕竟 DXP4800 现在还躺在笔者的购物车里，差点又要陷进比自组 Nas 还麻烦的退货扯皮处境了。

### 小抱怨
威联通初始化系统流程自不必多说，笔者第一次买成品的小众电子产品，也是第一次体会到了什么问题都想找也只能找官方客服来解答。

Nas 到的第一天，笔者随意地把它接到一个交换机上然后直连校园网，结果笔者能进访问 web 界面，却死活进不去初始化系统的界面，一直显示 Loading。然后联系客服提工单找技术售后一条龙，当天晚上 10 点技术售后开了一次远程协助后才提醒笔者要先用网线直连 Nas 进行初始化设置，结果果然就能正常进系统了。

这是很令人无语的，nas 的 ip 地址会影响初始化过程就算了，他还不报错，一直显示 Loading，要是直接不能访问，笔者说不定早早地就用网线直连进行测试了。

在解决过程中，笔者在网络上更是找不到一点相关消息。看上去没有人会把它写成博客分享出来的，毕竟都去找客服了，让别人帮忙解决后还写博客分享其中原理的，说实话笔者也不会这么干，也许这就是使用小众闭源系统的缺点罢。

## 环境搭建
自从 b 站倒了（迫真）以后，笔者就很少看番了，一是找资源不方便，二是找到了也没弹幕看，不太习惯。当然科技在手，搜几个盗版网站倒是没什么难度，但是盗版网站质量也是参差不齐，搞不好还天天换域名、弹广告、视频源损坏等等。

但是有了 Nas 后就能一直挂着百度云用着 1Mbit/s 的速度下几十 GB 的文件下个五六天，然后也有配套的跨平台客户端使用手机、平板进行观看。统一平台，对笔者而言很重要。

以下所有环境皆使用 Docker 搭建。有一说一，笔者对于 Nas 易用性的信心有很大部分就来源于 Docker 本身，毕竟自研 os 可以不可靠，可以很难用，但是 Docker 一定是好用的。

### 数据持久化目录创建
在 `File Station` 创建一个 `AppData` 共享文件夹，然后把接下来要用到的所有镜像的配置文件和数据文件都挂载在这里。威联通的盘目前是挂在 `/share` 下：
```
[xxxx@WHUYYC ~]$ ll /share
total 12K
drwxrwxrwt 32 admin administrators  880 2024-06-10 23:21 ./
drwxr-xr-x 23 admin administrators  580 2024-06-13 21:20 ../
lrwxrwxrwx  1 admin administrators   22 2024-06-08 16:12 AppData -> CACHEDEV2_DATA/AppData/
lrwxrwxrwx  1 admin administrators   20 2024-06-08 16:12 Books -> CACHEDEV2_DATA/Books/
lrwxrwxrwx  1 admin administrators   30 2024-06-10 23:21 Browser Station -> CACHEDEV1_DATA/Browser Station/
drwxrwxrwx 39 admin administrators 4.0K 2024-06-14 23:12 CACHEDEV1_DATA/
drwxrwxrwx  9 admin administrators 4.0K 2024-06-09 22:58 CACHEDEV2_DATA/
drwxrwxrwx  5 admin administrators 4.0K 2024-06-06 13:55 CACHEDEV3_DATA/
...
```
从上面可以发现笔者建立的 `AppData` 共享文件夹放在 `CACHEDEV2_DATA`，由于 Nas 挂的盘有点多，而管理界面也没有说明哪个硬盘是哪个文件夹，这一步只能自己进终端看看刚刚创建的 `AppData` 在哪。注意还有几个软链接，这些 `AppData -> CACHEDEV2_DATA/AppData/` 软链接就是 Nas 自己在创建共享文件夹的时候创建的。

威联通管理界面好像没用给终端软件，只能通过 ssh 直连 Nas 来操作一下，这让笔者稍微有点不爽。

这一步就是把种子、资源和各个软件的配置文件都持久化到本地一个地方的预备工作，后续重新创建镜像、备份、迁移机器都可以直接沿用以前的配置文件。
### 下载器 qBittorrent
```docker
version: '3'
services:
  qbittorrent:
    image: linuxserver/qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - WEBUI_PORT=8080
    volumes:
      - /share/CACHEDEV2_DATA/AppData/qbittorrent/config:/config
      - /share/CACHEDEV2_DATA/AppData/sonarr:/data
    ports:
      - 8080:8080
      - 16881:6881
      - 16881:6881/udp
    restart: unless-stopped
    networks:
      macvlan_network:
        ipv4_address: 192.168.1.167 # 同网段 IP
 
networks:
  macvlan_network:
      name: BTNetwork # 之前搞好的 IP
      driver: macvlan
      driver_opts:
        parent: eth1
      ipam:
        driver: default
        config:
          - subnet: 192.168.1.0/24
            ip_range: 192.168.1.0/24
            gateway: 192.168.1.1
```
这里使用了 `linuxserver/qbittorrent` 镜像，同时 `qBittorrent` 配置目录放在了 `/share/CACHEDEV2_DATA/AppData/qbittorrent/config`，下载目录放在了 `/share/CACHEDEV2_DATA/AppData/sonarr/`。其中重要的就是下载目录，笔者把它放在 `sonnar` 下是很多想看的资源都要通过 `sonnar` 搜索到，所以这么放。这一步当然也可以把它放到其他地方去。

这里值得注意的是笔者使用了 `maclan` 方式固定了这个容器的 ip 地址。实际上，因为笔者在软路由上开了科技，所以要是下载器直接走代理流量，笔者的正常工作流量都无法保证了。

为了更细粒度的把 `qBittorrent` 独立出来不走代理，而让其他的种子搜索器、视频播放器能走代理，这里必须使用 `maclan` 方式让 `qBittorrent` 独占一个局域网的 ip 而不是 nas 本身的 ip。这样就能单独禁止 `qBittorrent` 这个 ip 走代理了。至少 [[Feature] nas 里下载器 qb 需要直连，且 nas 其他项目需要代理，有什么好办法么？](https://github.com/vernesong/OpenClash/issues/3259) 这个 issue 里是如此建议的。

> [解决 Docker macvlan 网络与宿主机通讯问题](https://blog.csdn.net/weixin_44907046/article/details/123144254)
> 
> [Docker 使用 macvlan 网络容器与宿主机的通信过程](https://smalloutcome.com/2021/07/18/Docker-%E4%BD%BF%E7%94%A8-macvlan-%E7%BD%91%E7%BB%9C%E5%AE%B9%E5%99%A8%E4%B8%8E%E5%AE%BF%E4%B8%BB%E6%9C%BA%E7%9A%84%E9%80%9A%E4%BF%A1%E8%BF%87%E7%A8%8B/)

描述起来很有一些繁琐，笔者这里参照了上面几篇文章，原理不谈，流程如下：
1. 首先假设**机器的连接路由器的网卡**为 `eth1`，这里网卡的名称完全跟机器有关，而且也必须是连接路由器的那个网卡（端口）
2. docker 需要创建一张虚拟网卡：
   ```docker
   docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 --ip-range=192.168.1.0/24 -o parent=eth1 BTNetwork
   ```
   这里的子网、网关等参数也都跟机器所处的局域网环境相关，看了教程的朋友记得改。这张网卡也可以通过 docker-compose 自动创建，笔者上面给出的 docker-compose 文件就自动创建了。
3. 现在要让 docker 内部可以和宿主机通信
   ```shell
   #宿主机创建一个 macvlan
   ip link add macvlan0-host(一个网络名称) link eth1(你的物理网卡) type macvlan mode bridge 
   #设置 macvlan ip 并启用
   ip addr add 192.168.1.140 dev macvlan0-host                           
   ip link set macvlan0-host up #启用新建网络
   @增加路由表
   ip route add 192.168.1.167(需要建立通讯的 macvlan 容器 ip) dev macvlan0-host(宿主机建立的 macvlan)
   ```
4. 现在启动 `qBittorrent` 应该就能在 nas 终端里 ping 通 192.168.1.167 这个 ip 地址了。

### TV 资源（种子）搜索器 Sonarr + Jackett + Flaresolverr
然后是资源搜索器三件套，docker-compose 如下：
```docker
version: '3'
services:
  sonarr:
    image: linuxserver/sonarr
    ports:
      - 8989:8989
    volumes:
      - /share/CACHEDEV2_DATA/AppData/sonarr/config:/config
      - /share/CACHEDEV2_DATA/AppData/sonarr:/data
      - /etc/localtime:/etc/localtime:ro
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    restart: unless-stopped
  jackett:
    image: linuxserver/jackett
    ports:
      - 9117:9117
    volumes:
      - /share/CACHEDEV2_DATA/AppData/jackett/config:/config
      - /share/CACHEDEV2_DATA/AppData/jackett/downloads:/downloads
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    restart: unless-stopped
  flaresolverr:
    image: flaresolverr/flaresolverr
    environment:
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=${CAPTCHA_SOLVER:-none}
      - TZ=Asia/Shanghai
    ports:
      - 8191:8191
    restart: unless-stopped
```
这遵循与 `qBittorrent` 相同的逻辑，把配置目录和数据目录挂载在 `AppData` 目录下持久化。这些软件有很完善的可搜索资料，笔者不在此赘述，笔者参考的使用教程为 [使用 Sonarr 搭建自动化追番系统](https://reorx.com/blog/track-and-download-shows-automatically-with-sonarr/)~~（该文作者的中文说的和英文一样好）~~。笔者也见过不少开源社区的朋友先写一份中文 blog 再写一遍英文 blog 的，也算能理解。

效果如下：
![sonarr 界面](https://gg2002.github.io/img/nas-tool/sonarr.png)

当然，使用了一段时间后，笔者发现 `sonarr` 用来搜索番剧还是不太行，`Bangumi Moe` 上随手就能搜出来的资源，`sonarr` 必须要手动搜索才行，有时候还要手动填视频资料把他放入相应的位置。原因在于 `sonarr` 使用的全都是 `TVDB` 上的英文名，比如 `憧憬成为魔法少女` 的英文就是 `Gushing Over Magical Girls`，而英文在 `Bangumi Moe` 虽然能搜到资源，但是资源标题里肯定不带英文翻译，所以 `sonarr` 对不上号，只能手动搜索添加。

这时就需要使用更符合中国宝宝体质的 `AutoBangumi` 了。

### 番剧（种子）搜索器 Auto Bangumi
```docker
version: "3"

services:
  ab:
    image: "ghcr.io/estrellaxd/auto_bangumi:latest"
    container_name: "auto_bangumi"
    restart: unless-stopped
    ports:
      - "7892:7892"
    volumes:
      - "/share/CACHEDEV2_DATA/AppData/auto_bangumi/config:/app/config"
      - "/share/CACHEDEV2_DATA/AppData/auto_bangumi/data:/app/data"
    environment:
      - TZ=Asia/Shanghai
      - AB_METHOD=Advance
      - PGID=1000
      - PUID=1000
      - UMASK=022
    network_mode: host
```
挂载思路老一套，这个插件有比较完善的中文资料，毕竟是中国人开发的。[官网在这](https://www.autobangumi.org/deploy/quick-start.html)。

官网建议把 `qBittorrent` 和 `AutoBangumi` 放在一个网络里面，当然笔者没有这么做，所以笔者的 `AutoBangumi` 是以 `host` 方式部署的，这样可以连接到宿主机的局域网 ip。

按官网流程注册账号、选择番剧、开始下载，诸如此类笔者也不再赘述。

这里有个有趣的事情，由于笔者的 Nas 部署在校园网内，上传外网是不可能的，这也是笔者下载的大部分资源的情况，但是笔者下载的当季新番则基本挂满了上传流量，这说明校园网内的 p2p 也是很有活力的（大概）。

效果如下：
![AutoBangumi 界面](https://gg2002.github.io/img/nas-tool/autobangumi.png)

### 播放器 Plex
Plex 简单易用，多端支持（至少手机支持的很好），威联通 App Center 也可以直接下，所以笔者就使用了 Plex 来当播放器。配置也没什么好说的，说到底也是因为上面两个搜索工具会默认把下载完的文件重命名为 Plex 能识别的格式，因此只需要把存有视频文件的文件夹添加进 Plex 让它自动识别就好。

Plex 网页端播放没什么限制，倒是移动端要 1k 大洋开终身会员，或者 40 大洋买取消一分钟播放限制（否则只能观看一分钟自己下的视频），而且都要刀乐支付。笔者倒是想 40 支持一下正版，但实在找不到靠谱的渠道支付，所以还是找了~~盗版~~开心版使用。

最终效果如下：
![Plex 界面](https://gg2002.github.io/img/nas-tool/plex.png)

## Reference
> [解决 Docker macvlan 网络与宿主机通讯问题](https://blog.csdn.net/weixin_44907046/article/details/123144254)
> 
> [Docker 使用 macvlan 网络容器与宿主机的通信过程](https://smalloutcome.com/2021/07/18/Docker-%E4%BD%BF%E7%94%A8-macvlan-%E7%BD%91%E7%BB%9C%E5%AE%B9%E5%99%A8%E4%B8%8E%E5%AE%BF%E4%B8%BB%E6%9C%BA%E7%9A%84%E9%80%9A%E4%BF%A1%E8%BF%87%E7%A8%8B/)
> 
> [使用 Sonarr 搭建自动化追番系统](https://reorx.com/blog/track-and-download-shows-automatically-with-sonarr/)