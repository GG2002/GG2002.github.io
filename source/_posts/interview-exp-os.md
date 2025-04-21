---
title: 操作系统串记
date: 2025-03-30 15:44:40
tags:
    - 操作系统
    - 笔记
---
## 进程间通信方式
> | Method                 | 100 Byte Messages | 1 Kilo Byte Messages |
> | ---------------------- | ----------------: | -------------------: |
> | Unix Signals           |        --broken-- |           --broken-- |
> | ZeroMQ (TCP)           |      24,901 msg/s |         22,679 msg/s |
> | Internet sockets (TCP) |      70,221 msg/s |         67,901 msg/s |
> | Domain sockets         |     130,372 msg/s |        127,582 msg/s |
> | Pipes                  |     162,441 msg/s |        155,404 msg/s |
> | Message Queues         |     232,253 msg/s |        213,796 msg/s |
> | FIFOs (named pipes)    |     265,823 msg/s |        254,880 msg/s |
> | Shared Memory          |   4,702,557 msg/s |      1,659,291 msg/s |
> | Memory-Mapped Files    |   5,338,860 msg/s |      1,701,759 msg/s |
> 
> [goldsborough/ipc-bench](https://github.com/goldsborough/ipc-bench)

### Unix Signals
Unix 信号是一种基本的 IPC 机制，主要用于通知进程系统发生的特定事件。尽管它在某些场景下非常有用，但从表中可以看出，对于 100 字节和 1K 字节的消息传输，这种方式是“--broken--”，意味着它不适合用于高效的数据传输。

### ZeroMQ (TCP)
ZeroMQ 是一种为可扩展的分布式或并行应用程序设计的高级消息队列库。它可以利用 TCP 协议进行通信。根据数据，ZeroMQ 能够处理 24,901 条每秒 100 字节的消息以及 22,679 条每秒 1K 字节的消息，显示出它在处理中等规模数据传输时的良好性能。

> [RabbitMQ，ZeroMQ，Kafka 是一个层级的东西吗？相互之间有哪些优缺点？](https://www.zhihu.com/question/22480085)
>
> 省流，并非 MQ（Message Queue），详情以后有机会再看看。

### Internet sockets (TCP)
互联网套接字，使用 TCP 协议，是网络编程中最常用的通信方法之一。该表显示其能处理 70,221 条每秒 100 字节的消息和 67,901 条每秒 1K 字节的消息，这表明它比 ZeroMQ 有更高的消息吞吐量，适用于需要高效率和可靠性的应用。

### Domain sockets
域套接字提供了一种在同一主机上不同进程之间进行高效通信的方法。相较于互联网套接字，它们提供了更好的性能，能够达到 130,372 条每秒 100 字节的消息和 127,582 条每秒 1K 字节的消息。

**虽然 Domain sockets 和 webserver 里的 sockets 都叫 sockets，但并不是同一个东西。** 使用 Golang 可以很明显地区分开。

```Golang
// Create a Unix domain socket
socket, _ := net.Listen("unix", "/tmp/mysocket.sock")
// Create a TCP socket
socket, _ := net.Listen("tcp", ":8080")
```


### Pipes
管道（Pipes）允许进程以一种简单的方式进行单向通信。从表中可以看到，它的性能优于域套接字，能够支持 162,441 条每秒 100 字节的消息和 155,404 条每秒 1K 字节的消息。

### Message Queues
消息队列提供了一个存储和转发机制，使得进程可以通过发送和接收消息来进行通信。它展示了很高的效率，可以处理 232,253 条每秒 100 字节的消息和 213,796 条每秒 1K 字节的消息。

### FIFOs (named pipes)
FIFOs，或者命名管道，提供了一种在不相关进程之间通过路径名进行通信的方式。

### Shared Memory
共享内存允许两个或多个进程共享一块内存区域，从而实现快速的数据交换。对于 100 字节的消息能达到 4,702,557 msg/s，对于1K字节的消息则为1,659,291 msg/s。

### Memory-Mapped Files
内存映射文件允许一个文件或文件的一部分被映射到进程的地址空间中，从而实现高效的文件 I/O 操作。它是所有方法中性能最高的，特别是对于小消息，能够达到 5,338,860 msg/s，而对于1K字节的消息则为1,701,759 msg/s。

> [io_uring 性能被 mmap 吊打，真相竟然是……](https://zhuanlan.zhihu.com/p/348225926)
>
> 不知道塞哪，就放这里。