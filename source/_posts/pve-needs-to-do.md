---
title: 关于 PVE 你不得不做的几件事（雾）
date: 2024-09-24 11:46:58
tags:
 - PVE
 - 虚拟机
---
记载一下笔者在自己的 PVE 上做了什么防止忘记。

## PVE 版本
```shell
root@pve:~# neofetch
         .://:`              `://:.            root@pve 
       `hMMMMMMd/          /dMMMMMMh`          -------- 
        `sMMMMMMMd:      :mMMMMMMMs`           OS: Proxmox VE 8.2.2 x86_64 
`-/+oo+/:`.yMMMMMMMh-  -hMMMMMMMy.`:/+oo+/-`   Kernel: 6.8.4-2-pve 
`:oooooooo/`-hMMMMMMMyyMMMMMMMh-`/oooooooo:`   Uptime: 14 mins 
  `/oooooooo:`:mMMMMMMMMMMMMm:`:oooooooo/`     Packages: 792 (dpkg) 
    ./ooooooo+- +NMMMMMMMMN+ -+ooooooo/.       Shell: bash 5.2.15 
      .+ooooooo+-`oNMMMMNo`-+ooooooo+.         Terminal: /dev/pts/0 
        -+ooooooo/.`sMMs`./ooooooo+-           CPU: Intel Xeon E5-2680 v4 (28) @ 2.401GHz 
          :oooooooo/`..`/oooooooo:             GPU: AMD ATI Radeon HD 5000/6000/7350/8350 Series 
          :oooooooo/`..`/oooooooo:             GPU: AMD ATI Radeon RX 7900 XT/7900 XTX 
        -+ooooooo/.`sMMs`./ooooooo+-           Memory: 13256MiB / 128714MiB 
      .+ooooooo+-`oNMMMMNo`-+ooooooo+.
    ./ooooooo+- +NMMMMMMMMN+ -+ooooooo/.                               
  `/oooooooo:`:mMMMMMMMMMMMMm:`:oooooooo/`                             
`:oooooooo/`-hMMMMMMMyyMMMMMMMh-`/oooooooo:`
`-/+oo+/:`.yMMMMMMMh-  -hMMMMMMMy.`:/+oo+/-`
        `sMMMMMMMm:      :dMMMMMMMs`
       `hMMMMMMd/          /dMMMMMMh`
         `://:`              `://:`
```

## 显卡直通
### 开启 IOMMU 和硬件直通功能
1. 修改 `/etc/default/grub` 的 `GRUB_CMDLINE_LINUX_DEFAULT` 那一行：
```shell
root@pve:~# nano /etc/default/grub
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg.
# For full documentation of the options in this file, see:
#   info -f grub -n 'Simple configuration'

GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_pstate=disable intel_iommu=on iommu=pt initcall_blacklist=sysfb_init pcie_acs_override=downstream"
GRUB_CMDLINE_LINUX=""
```
2. 修改 `/etc/modules`：
```shell
root@pve:~# nano /etc/modules
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.
# Parameters can be specified after the module name.

coretemp
nct6775
vfio
vfio_iommu_type1
vfio_pci
# fvio_virqfd
```
3. 允许不安全 IOMMU 中断重映射：
```shell
root@pve:~# nano /etc/modprobe.d/iommu_unsafe_interrupts.conf 
options vfio_iommu_type1 allow_unsafe_interrupts=1
```

这 3 步完成后，应当验证是否 `启用IOMMU`，即：
```shell
root@pve:~# dmesg | grep -e DMAR -e IOMMU
[    0.000000] Warning: PCIe ACS overrides enabled; This may allow non-IOMMU protected peer-to-peer DMA
[    0.010536] ACPI: DMAR 0x000000007A22BC50 0000DC (v01 ALASKA A M I    00000001 INTL 20091013)
[    0.010562] ACPI: Reserving DMAR table memory at [mem 0x7a22bc50-0x7a22bd2b]
[    0.272257] DMAR: IOMMU enabled
[    0.727171] DMAR: Host address width 46
[    0.727173] DMAR: DRHD base: 0x000000fbffd000 flags: 0x0
[    0.727183] DMAR: dmar0: reg_base_addr fbffd000 ver 1:0 cap 8d2008c10ef0466 ecap f0205b
[    0.727186] DMAR: DRHD base: 0x000000fbffc000 flags: 0x1
[    0.727191] DMAR: dmar1: reg_base_addr fbffc000 ver 1:0 cap 8d2078c106f0466 ecap f020df
[    0.727193] DMAR: RMRR base: 0x0000007b3ee000 end: 0x0000007b3fefff
[    0.727198] DMAR: ATSR flags: 0x0
[    0.727200] DMAR: RHSA base: 0x000000fbffc000 proximity domain: 0x0
[    0.727203] DMAR-IR: IOAPIC id 1 under DRHD base  0xfbffc000 IOMMU 1
[    0.727205] DMAR-IR: IOAPIC id 2 under DRHD base  0xfbffc000 IOMMU 1
[    0.727206] DMAR-IR: HPET id 0 under DRHD base 0xfbffc000
[    0.727207] DMAR-IR: Queued invalidation will be enabled to support x2apic and Intr-remapping.
[    0.727848] DMAR-IR: Enabled IRQ remapping in x2apic mode
[    1.059916] DMAR: No SATC found
[    1.059918] DMAR: IOMMU feature sc_support inconsistent
[    1.059919] DMAR: IOMMU feature dev_iotlb_support inconsistent
[    1.059920] DMAR: dmar0: Using Queued invalidation
[    1.059924] DMAR: dmar1: Using Queued invalidation
[    1.063715] DMAR: Intel(R) Virtualization Technology for Directed I/O
```
出现上述信息就算成功（总之不能有什么表示否定的词语）。

需要注意的是，`remapping` 这个功能需要主板 Bios 支持，成功就是这段：
```shell
[    0.727206] DMAR-IR: HPET id 0 under DRHD base 0xfbffc000
[    0.727207] DMAR-IR: Queued invalidation will be enabled to support x2apic and Intr-remapping.
```
不成功就是这段：
```shell
root@pve:~# dmesg | grep -e DMAR -e IOMMU
[ 0.038236] DMAR: IOMMU enabled
root@pve:~# dmesg | grep 'remapping'
[ 0.105871] x2apic: IRQ remapping doesn't support X2APIC mode
```
笔者之前以为自己的主板 Bios 已经开启了这些些选项所以没有在意这个报错，导致排查了很久才发现其实根本没开。详情见：[国光的 PVE 环境搭建教程：BIOS 设置](https://pve.sqlsec.com/2/1/)，尤其注意最后一条 `x2APIC` 选项，笔者看下图的两个选项差不多就全选了，
![x99 主板 Bios 截图](/img/pve/x99_bios_x2apic.png)
然后重启数次还是开启不了 `X2APIC mode`，因此切记切记，**只能开启第一个选项，第二个不能开**。

上面这些操作即使不成功也不会影响你检查显卡驱动是否被屏蔽，但是绝对会导致你显卡直通失败。所以在进行下一步前，确保上面没有报错，否则你要同时考虑上下两步是不是都做错了。

### 屏蔽显卡驱动
1. 编辑 `/etc/modprobe.d/pve-blacklist.conf`：
```shell
root@pve:~# nano /etc/modprobe.d/pve-blacklist.conf 
# This file contains a list of modules which are not supported by Proxmox VE 

# nvidiafb see bugreport https://bugzilla.proxmox.com/show_bug.cgi?id=701
blacklist nvidiafb
blacklist nvidia
blacklist nouveau

blacklist snd_hda_intel

blacklist radeon
blacklist amdgpu
```
2. 忽略显卡警告（NV 专属）：
```shell
root@pve:~# nano /etc/modprobe.d/kvm.conf 
options kvm ignore_msrs=1 report_ignored_msrs=0
```
3. 配置 VFIO：
    1. 查看显卡 PCI ID：
    ```shell
    root@pve:~# lspci -nn | grep VGA
    01:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cedar [Radeon HD 5000/6000/7350/8350 Series] [1002:68f9]
    05:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XT/7900 XTX] [1002:744c] (rev c8)
    ```
    这里笔者有两张显卡，一张亮机卡一张 7900xtx，记住你要直通的显卡 ID 就好

    2. 获取设备 ID 和音频 ID：
    ```shell
    root@pve:~# lspci -n -s 05:00
    05:00.0 0300: 1002:744c (rev c8)
    05:00.1 0403: 1002:ab30
    ```
    3. 编辑 `/etc/modprobe.d/vfio.conf`：
    ```shell
    root@pve:~# cat /etc/modprobe.d/vfio.conf
    options vfio-pci ids=10de:2204,10de:1aef,1002:744c,1002:ab30 disable_vga=1
    ```
    注意这里笔者放了四个设备 ID，因为笔者还尝试了 3090 矿卡，笔者之前还担心假如屏蔽的设备 ID 不存在会不会导致 PVE 启动失败，现在的结论是**不会**。但会有另一个问题导致局域网连接失败，见[固定网卡名字](#固定网卡名字)

检查 `vfio-pci` 是否应用成功，输入 `lspci -nnk` 并找到显卡那一行，如果得到类似以下结果，为成功：
```shell
05:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [Radeon RX 7900 XT/7900 XTX] [1002:744c] (rev c8)
        Subsystem: XFX Limited RX-79XMERCB9 [SPEEDSTER MERC 310 RX 7900 XTX] [1eae:7901]
        Kernel driver in use: vfio-pci
        Kernel modules: amdgpu
05:00.1 Audio device [0403]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 HDMI/DP Audio [1002:ab30]
        Subsystem: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 HDMI/DP Audio [1002:ab30]
        Kernel driver in use: vfio-pci
        Kernel modules: snd_hda_intel
```
即 `Kernel driver in use: vfio-pci`，失败的话一般会是 `Kernel driver in use: amdgpu` 或者 `Kernel driver in use: nouveau` 等等。

然后更新内核、重启等操作不再赘述。

最后的 `/etc/modprobe.d/` 会有这些文件：
```shell
root@pve:~# ll /etc/modprobe.d/
total 24K
drwxr-xr-x  2 root root 4.0K Sep 24 19:35 .
drwxr-xr-x 97 root root 4.0K Sep 24 19:51 ..
-rw-r--r--  1 root root   51 Sep  8 16:44 iommu_unsafe_interrupts.conf
-rw-r--r--  1 root root   48 Sep  8 15:02 kvm.conf
-rw-r--r--  1 root root  267 Sep 24 19:01 pve-blacklist.conf
-rw-r--r--  1 root root   75 Sep 24 19:35 vfio.conf
```

参考文献：
> [PVE 直通显卡 & Intel SRIOV](https://www.cnblogs.com/MAENESA/p/18005241)
> 
> [华南金牌 x99 系列主板打开 SR-IOV 和 VTD 设置方法](https://www.bilibili.com/video/BV1nc411s7GD/?vd_source=adeeff5f832295895c40fcf9edff2111)
> 
> [国光的 PVE 环境搭建教程：BIOS 设置](https://pve.sqlsec.com/2/1/)

## 固定网卡名字
事情发生在笔者想到 3090 矿卡在 PVE 上真挂了也就是 `nvidia-smi` 检测不到该设备，但是它平时也会这样，不好判断能不能找店家换货。

同时笔者发现一个有意思的项目：[exo: Run your own AI cluster at home with everyday devices.](https://github.com/exo-explore/exo)，大家都知道 Rocm 在 windows 支持不太好（也就是 24 年 6 月份才开始支持的），而 CUDA 则是 windows 也支持的很好，所以笔者决定把 7900xtx 放到 PVE 上，3090 放日常电脑上，这样说不定就能两两联合跑 `qwen2.5:72b` 了，假如此法可行，还能把室友的 4070 拉进来一起组算力集群。

因此笔者把 3090 拔了插 7900xtx。结果 PVE 开机自检过了但是网口灯没亮。笔者本来猜测是 PCI 设备冲突等等原因不想管，但找不到事做所以又开始排查原因。

将 PVE 接上屏幕后笔者惊讶地发现有显卡输出信号且正常开机了，只是网卡处于 `Down` 的状态，再一排查发现网卡名字从 `enp6s0` 被顶成了 `enp8s0`，所以系统无法自动开启网卡。

手动开启网卡后再重启网口灯就恢复正常了。但这样显然不利于笔者后续折腾，所以要固定网卡名字。

1. 首先获取本机网卡的 MAC 地址：
```shell
root@pve:~# ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp8s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master vmbr0 state UP mode DEFAULT group default qlen 1000
    link/ether 0a:e0:af:c6:02:f6 brd ff:ff:ff:ff:ff:ff
3: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 0a:e0:af:c6:02:f6 brd ff:ff:ff:ff:ff:ff
4: tap100i0: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master vmbr0 state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 26:b5:e0:95:74:c9 brd ff:ff:ff:ff:ff:ff
```
凭经验来看，`enp8s0`是物理网卡，其 MAC 地址是`0a:e0:af:c6:02:f6`。

2. 然后在目录 `/etc/udev/rules.d/` 下新建文件 `50-custom-net.rules`，格式如下：
```shell
root@pve:~# nano /etc/udev/rules.d/50-custom-net.rules 
ATTR{address}=="0a:e0:af:c6:02:f6", NAME="eth0"
```
这意味着开机后网卡名称会自动命名为 `eth0`。

3. 修改 `/etc/network/interfaces`：
```shell
root@pve:~# nano /etc/network/interfaces
auto lo
iface lo inet loopback

iface eth0 inet manual

auto vmbr0
iface vmbr0 inet static
        address 192.168.100.125/24
        gateway 192.168.100.1
        bridge-ports eth0
        bridge-stp off
        bridge-fd 0

source /etc/network/interfaces.d/*
```
把 `iface` 和 `bridge-ports` 都改成 `eth0` 即可。

参考文献：
> [在 Proxmox 中固定网卡名字](https://blog.csdn.net/fcymk2/article/details/132994055)