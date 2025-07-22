---
title: 操作系统串记
date: 2025-03-30 15:44:40
tags:
    - 操作系统
    - 笔记
---
# 进程间通信方式
> ## IPC Benchmark
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

## Unix Signals
Unix 信号是一种基本的 IPC 机制，主要用于通知进程系统发生的特定事件。尽管它在某些场景下非常有用，但从表中可以看出，对于 100 字节和 1K 字节的消息传输，这种方式是“--broken--”，意味着它不适合用于高效的数据传输。

## ZeroMQ (TCP)
ZeroMQ 是一种为可扩展的分布式或并行应用程序设计的高级消息队列库。它可以利用 TCP 协议进行通信。根据数据，ZeroMQ 能够处理 24,901 条每秒 100 字节的消息以及 22,679 条每秒 1K 字节的消息，显示出它在处理中等规模数据传输时的良好性能。

> [RabbitMQ，ZeroMQ，Kafka 是一个层级的东西吗？相互之间有哪些优缺点？](https://www.zhihu.com/question/22480085)
>
> 省流，并非 MQ（Message Queue），详情以后有机会再看看。

## Internet sockets (TCP)
互联网套接字，使用 TCP 协议，是网络编程中最常用的通信方法之一。该表显示其能处理 70,221 条每秒 100 字节的消息和 67,901 条每秒 1K 字节的消息，这表明它比 ZeroMQ 有更高的消息吞吐量，适用于需要高效率和可靠性的应用。

### Socket 通信双方建立连接的函数调用过程
在使用 socket 进行网络通信时，客户端和服务端需要经历一系列步骤来建立连接。以下是典型的函数调用过程：
1. **服务端**
   - 调用 `socket()` 创建一个新的套接字。
   - 使用 `bind()` 函数将套接字绑定到一个特定的 IP 地址和端口上。
   - 调用 `listen()` 函数使套接字进入监听状态，等待客户端连接请求。
   - 当收到客户端连接请求后，服务端通过 `accept()` 接受该连接，这会创建一个新的套接字用于与该客户端进行通信。
2. **客户端**
   - 同样从调用 `socket()` 创建一个新的套接字开始。
   - 使用 `connect()` 函数尝试与服务端建立连接，提供目标服务器的 IP 地址和端口号作为参数。

### 三次握手发生在 Socket 建立连接的哪个步骤
![Socket 通信过程](https://gg2002.github.io/img/interview-exp-os/socket通信过程.png)
三次握手发生在客户端调用 `connect()` 和服务端调用 `accept()` 的过程中。具体来说，当客户端发起连接请求（SYN），服务端响应（SYN-ACK），然后客户端确认（ACK）这个序列就构成了 TCP 协议中的三次握手过程。这一过程确保了双方都能发送和接收数据，并且协商了一些关键参数如序列号等，从而为后续的数据传输做好准备。

### Socket 怎么通信？Socket 是文件，read 和 write
虽然 sockets 在很多操作系统中被抽象成类似于文件的接口，但它们并不是传统意义上的文件。sockets 提供了面向流（stream-oriented）或面向消息（message-oriented）的通信机制，具体取决于所使用的协议类型（如 TCP 或 UDP）。对于基于 TCP 的 sockets，你可以使用标准的文件操作函数如 `read()` 和 `write()` 来读取和写入数据，这是因为 TCP 提供了一个连续的字节流而不是单独的消息。然而，在底层，这些调用实际上是由网络栈处理的，涉及复杂的协议行为和网络 I/O 操作。
- **`read()`**：从 socket 中读取数据，直到指定的字节数目被读取或遇到错误、连接关闭为止。
- **`write()`**：向 socket 写入数据，试图发送指定数量的字节，但这并不保证所有字节都会立即发送出去；可能只是部分发送，剩余的部分可能会被缓冲并随后发送。

因此，尽管可以像操作普通文件一样对 socket 使用 `read()` 和 `write()`，但考虑到网络环境的不确定性和复杂性，实际编程时通常还需要处理诸如超时、非阻塞 I/O、部分发送等问题。

## Domain sockets
域套接字提供了一种在同一主机上不同进程之间进行高效通信的方法。相较于互联网套接字，它们提供了更好的性能，能够达到 130,372 条每秒 100 字节的消息和 127,582 条每秒 1K 字节的消息。

**虽然 Domain sockets 和 webserver 里的 sockets 都叫 sockets，但并不是同一个东西。** 使用 Golang 可以很明显地区分开。

```Golang
// Create a Unix domain socket
socket, _ := net.Listen("unix", "/tmp/mysocket.sock")
// Create a TCP socket
socket, _ := net.Listen("tcp", ":8080")
```


## Pipes
管道（Pipes）允许进程以一种简单的方式进行单向通信。从表中可以看到，它的性能优于域套接字，能够支持 162,441 条每秒 100 字节的消息和 155,404 条每秒 1K 字节的消息。

## FIFOs (named pipes)
FIFOs，或者命名管道，提供了一种在不相关进程之间通过路径名进行通信的方式。

## Message Queues
消息队列提供了一个存储和转发机制，使得进程可以通过发送和接收消息来进行通信。它展示了很高的效率，可以处理 232,253 条每秒 100 字节的消息和 213,796 条每秒 1K 字节的消息。

## Shared Memory 与 Memory-Mapped Files
共享内存允许两个或多个进程共享一块内存区域，有两种方式，即 `shm`（Shared Memory）和 `mmap`（Memory-Mapped File）。

共享内存是最快的 IPC 形式。一旦这样的内存映射到共享它的进程的地址空间，这些进程间数据传递不再涉及到内核，换句话说是进程不再通过执行进入内核的系统调用来传递彼此的数据。

| 用管道或者消息队列传递数据                                           | 用共享内存传递数据                                                   |
| -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| ![消息队列传递数据](https://gg2002.github.io/img/interview-exp-os/消息队列传递数据.png) | ![共享内存传递数据](https://gg2002.github.io/img/interview-exp-os/共享内存传递数据.png) |

内存映射文件允许一个文件或文件的一部分被映射到进程的地址空间中，从而实现高效的文件 I/O 操作。它是所有方法中性能最高的，特别是对于小消息，能够达到 5,338,860 msg/s，而对于1K字节的消息则为1,701,759 msg/s。

> [io_uring 性能被 mmap 吊打，真相竟然是……](https://zhuanlan.zhihu.com/p/348225926)
>
> 不知道塞哪，就放这里。