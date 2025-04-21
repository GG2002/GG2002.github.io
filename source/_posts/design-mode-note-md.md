---
title: 设计模式速记
date: 2025-04-20 14:50:40
tags:
---
笔者是从所谓 `组合优于继承` 的 Golang、Rust 以及 Modern C++ 学起的，因此在不知不觉中跳过了 OOP 的相当部分学习，导致笔者在 OOP 的基础几乎不如刚经过期末考的大二学生，比如 OOP 的三大特性笔者就说不上来。

设计模式作为 OOP 的良好实践，笔者在没有学习之前已经看过了不少大型项目代码，因此也许能触类旁通罢。虽然从菜鸟教程来看，设计模式有多达数十种之多，但大家都知道 CS 最会造生词以增加初学者的学习门槛，常用的设计模式不超过十种。

对于 Javaer 的普遍技术水平不能报以太多期望，笔者在此对常用设计模式归纳总结一番以防 SB 面试官偷袭。

## 六大原则
- `开闭原则（Open Closed Principle，OCP）`，不要想着用子类修改父类，要改就用子类继承一套然后重写方法
- `单⼀职责原则（Single Responsibility Principle, SRP）`，一个类里写所有逻辑直接梦回面向过程
- `⾥⽒替换原则（Liskov Substitution Principle，LSP）`，保守的鸭子类型思想
- `依赖倒置原则（Dependency Inversion Principle，DIP）`，本来应该是高级依赖低级，但是现在多出一个 Interface，高级依赖 Interface，低级实现 Interface（它倒置了什么？现在也没变成低级依赖高级哇？）
- `接⼝隔离原则（Interface Segregation Principle，ISP）`，这个跟 SRP 有甚么区别吗？SRP 是 Class 的 Principle，ISP 是 Interface 的 Principle？
- `合成/聚合复⽤原则（Composite/Aggregate Reuse Principle，C/ARP）`，组合优于继承
- `最少知识原则（Least Knowledge Principle，LKP）`或者`迪⽶特法则（Law of Demeter，LOD）`，奥卡姆剃刀秒了

## 单例模式（最有用的一个）

## 工厂模式

## 代理模式与装饰器模式
可以首先声明两个类，可以通过类 B 来调用类 A。

对于装饰器模式，大家期望的装饰器应当是——不需要改动类 A 调用与类 A 实现的源代码，仅需实现类 B，然后通过某种方式（Python 使用注解，Java 不知道使用什么，BYD CSDN 博客没一个讲清楚）就能做到在执行 A 之前先执行 B。

也就是说代码逻辑是调用 A，但是可以加一堆的 B、X、Y 类做某些校验、统计信息等等。

而代理模式则是首先存在一个 Proxy 类 B，可以往里面塞一个类，比如 A、X、Y，反正不管是什么，B 也都是一样的使用。同时 A、X、Y 也完全可以是另一个 Proxy 类，所谓多重代理模式。

也就是说代码逻辑是调用 B，但是视情况可以塞不同 A、X、Y 进去调不同对象（比如连接不同的数据库，当然适配器模式也能用 Interface 做到，只不过代理模式更注重连接前后要做哪些与连接数据库这件事本身不是很有关的操作）。

## 策略模式、适配器模式与责任链模式
三者都是里氏替换原则的衍生物——所有引⽤基类的地⽅必须能透明地使⽤其⼦类的对象——这段话笔者不清楚是不是里氏替换原则，但对于这三者应当是——所有引⽤ **Interface** 的地⽅必须能透明地使⽤ implement 该 Interface 的 Class。

都是运行时多态（Run-Time Polymorphism）的良好实践，不想体会三者的细微区别，总之组合优于继承秒了。

- 策略模式例子为都实现了 `add`、`remove`、`set`、`indexOf` 的容器类。
- 适配器模式例子为 OpenDAL 实现了 `add`、`delete`、`scan` 操作不同存储介质的 Adapter trait，不过这里笔者是望文生义，也许 xuanwo 并不觉得这是适配器模式，只是名字重合了。
- 责任链模式例子为都实现了 `next` 与 `appendNext` 的抽奖活动校验规则，所以数据库的火山模型也是责任链模式是吗？毕竟火山模型更是典中典的 `open`，`next`，`close`，`current_entry` 一应俱全。

任何试图区分这三种模式的面试官鉴定为视野不够宽广（即水平不行）的 Javaer。