---
title: 智能指针之说
date: 2025-04-27 16:45:10
tags: 
    - C++
    - 智能指针
---

## RAII 与 unique_ptr
资源取得时机就是初始化时机（Resource Acquisition Is Intiallization，RAII）是 C++ 内存管理的第一课。

auto_ptr 自 C++98 提出，直到 C++17 被标准抛弃。后续被 unique_ptr 代替。auto_ptr 是历史遗留问题，是 C++ 的一处败笔，当然现在也已经被摈弃。

auto_ptr 对拷贝的处理方式是：隐式转移所有权。这不好，C++ 又不是有 GC 的语言，这种隐式容易导致程序员丧失对资源生命周期的掌控。

unique_ptr 自 C++11 提出，代替 auto_ptr，有效解决隐式转移所有权导致悬空的问题。对拷贝的处理方式是：不允许隐式转移所有权，必须显式移动语句才能转移所有权。

unique_ptr 在现代编译器的优化下基本是零开销（Zero Cost）的，换言之使用 unique_ptr 不仅可以享受到编译器单一所有权检查的功能，使用开销更是与裸指针无异。

### unique_ptr 有什么特性，底层实现是怎样的，是怎么保证无法赋值构造的

## shared_ptr 与 weak_ptr

GC 算法中的引用计数法效率远高于其他算法，但会带来无法解决的问题即循环引用。C++ 使用 shared_ptr 与 weak_ptr 解决此问题。

weak_ptr 不增加引用资源的引用计数不管理资源的生命周期，正确使用场景是那些资源如果可能就使用，如果不可使用则不用的场景，它不参与资源的生命周期管理。例如，网络分层结构中，Session 对象（会话对象）利用 Connection 对象（连接对象）提供的服务工作，但是 Session 对象不管理 Connection 对象的生命周期，Session 管理 Connection 的生命周期是不合理的，因为网络底层出错会导致 Connection 对象被销毁，此时 Session 对象如果强行持有 Connection 对象与事实矛盾。

### shared_ptr 是否线程安全

`std::shared_ptr`的操作并非完全线程安全。具体来说：
- 单独的对象（实例）上的操作（例如解引用操作`*`和箭头操作符`->`）是线程安全的。
- 对同一个`shared_ptr`实例进行写操作（例如修改引用计数）需要同步机制来保证线程安全。
- 不同的`shared_ptr`实例即使它们共享相同的控制块也是线程安全的，因为引用计数的增加和减少是原子操作。

第 2 点的具体体现是在多线程中将某个 shared_ptr 以**引用**的方式传递给多个线程，这样 shared_ptr 的引用计数为 1，任一线程都可能导致 shared_ptr 被释放。而第 3 点则是将某个 shared_ptr 以**值复制**的方式传递给多个线程，这样 shared_ptr 的引用计数为 N，这也是线程安全的。

> 参考 [当我们谈论 shared_ptr 的线程安全性时，我们在谈论什么](https://zhuanlan.zhihu.com/p/416289479)

### shared_ptr 有什么特性，底层实现是怎样的

## make_shared、make_unique 与 new
### 优点
#### 效率更高
内存只需分配一次，减少内存碎片且效率更高。
| Before                                                                                    | After                                                                                                     |
| ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| ![new 分配 shared 指针](https://gg2002.github.io/img/smart-pointer/new分配shared指针.png) | ![make_shared 分配 shared 指针](https://gg2002.github.io/img/smart-pointer/make_shared分配shared指针.png) |

#### 异常安全
```C++
void F(const std::shared_ptr<Lhs>& lhs, const std::shared_ptr<Rhs>& rhs) {
    /* ... */
}

F(std::shared_ptr<Lhs>(new Lhs("foo")), std::shared_ptr<Rhs>(new Rhs("bar")));
```
上述代码不安全，因为 C++ 是不保证参数求值顺序以及内部表达式的求值顺序的，所以可能的执行顺序如下：
1. new Lhs(“foo”))
2. new Rhs(“bar”))
3. std::shared_ptr
4. std::shared_ptr

现在假设在第 2 步的时候，抛出了一个异常 (比如 out of memory, 总之，Rhs 的构造函数异常了), 那么第一步申请的 Lhs 对象内存泄露了。

这个问题的核心在于，shared_ptr 没有立即获得裸指针。可以用如下方式来修复这个问题：
```C++
auto lhs = std::shared_ptr<Lhs>(new Lhs("foo"));
auto rhs = std::shared_ptr<Rhs>(new Rhs("bar"));
F(lhs, rhs);
```
当然，推荐的做法是使用 `make_shared` 来代替：
```C++
F(std::make_shared<Lhs>("foo"), std::make_shared<Rhs>("bar"));
```

### 缺点
#### 构造函数是保护或私有时，无法使用 make_shared
make_shared 虽好，但也存在一些问题，比如，当想要创建的对象没有公有的构造函数时，make_shared 就无法使用了，当然可以使用一些小技巧来解决这个问题，比如这里 [How do I call ::std::make_shared on a class with only protected or private constructors?](https://stackoverflow.com/questions/8147027/how-do-i-call-stdmake-shared-on-a-class-with-only-protected-or-private-const?rq=1)

#### 对象的内存可能无法及时回收
weak_ptr 本身需要**保持控制块 (强引用，以及弱引用的信息) 的生命周期**以确保其它线程知道资源是否被释放，否则其他线程直接使用 weak_ptr 会导致不安全行为，这是前提。

make_shared 只分配一次内存，减少了内存分配的开销，这很好。但一次性分配的内存会导致 weak_ptr **连带着保持了对象分配的内存**（正如下图所示），只有最后一个 weak_ptr 离开作用域时，内存才会被释放。
![make_shared 分配 shared 指针](https://gg2002.github.io/img/smart-pointer/make_shared分配shared指针.png)

原本强引用减为 0 时就可以释放的内存，现在变为了强引用与弱引用都减为 0 时才能释放，意外的延迟了内存释放的时间。这对于内存要求高的场景来说，是一个需要注意的问题。关于这个问题可以看这里 [make_shared, almost a silver bullet](https://lanzkron.wordpress.com/2012/04/22/make_shared-almost-a-silver-bullet/)

## 智能指针实现

[C++ 实现 shared_ptr/weak_ptr/enable_shared_from_this](https://zhuanlan.zhihu.com/p/680068428)

[C++ 内存管理：shared_ptr/weak_ptr 源码（长文预警）](https://zhuanlan.zhihu.com/p/532215950)

### shared_ptr 怎么实现的，引用计数是什么数据格式，引用计数的线程安全怎么保证的，底层怎么实现
![shared_ptr 布局](https://gg2002.github.io/img/smart-pointer/shared_ptr布局.jpg)


### 如何实现一个类，在父类没有虚析构函数的情况下，通过父类指针析构子类对象？
> 引入：在父类没有（忘记加）虚析构函数的情况下，父类的裸指针指向子类时，直接 delete 裸指针无法触发子类的析构函数，这是显然易见的。但是 `shared_ptr<A> ptr(new B);` 则会触发子类的析构函数，询问如何实现这个功能。
>
> [C++ 面试真题！如何实现一个类，在父类没有虚析构函数的情况下，通过父类指针析构子类对象？](https://zhuanlan.zhihu.com/p/662637642)

使用 `managet_ptr<B>` 与 `_shared_ptr<A>`，B 继承于 A，实现：
```C++
#include <iostream>
using namespace std;

class A
{
public:
    ~A() { cout << "A" << endl; }
};

class B : public A
{
public:
    ~B() { cout << "B" << endl; }
};


class manager
{
public:
    virtual ~manager() {}
};

template <class T>
class manager_ptr : public manager
{
public:
    manager_ptr(T p): ptr(p) {}
    ~manager_ptr() { delete ptr; }
private:
    T ptr;
};

template <class T>
class _shared_ptr
{
public:
    template<class Y>
    _shared_ptr(Y* p) { ptr_manager = new manager_ptr<Y*>(p); }
    ~_shared_ptr() { delete ptr_manager; }
private:
    manager* ptr_manager;
};

int main() {
    _shared_ptr<A> ptr(new B);
    return 0;
}
```

更简洁的，通过 `std::function` 包装保存类型信息：
```C++
template <typename T>
class MySharedV2
{
public:
    template <typename T2>
    MySharedV2(T2 *p)
    {
        data_ = p;
        deleter_ = [p](){ delete p;};
    }
    ~MySharedV2()
    {
        deleter_();
    }
    T* operator->()
    {
        return data_;
    }
private:
    std::function<void()> deleter_;
    T* data_ = nullptr;
};
```

## 面经问答题
### 在循环引用中，两个节点，如果一个用 shared_ptr 指向另一个，另一个用 weak_ptr 回指。根据什么来判断什么对象该使用 shared_ptr 以及 weak_ptr？

### unique_ptr move 到 shared_ptr 会发生什么
当你将一个`std::unique_ptr`通过移动语义传递给`std::shared_ptr`时，所有权从`unique_ptr`转移到`shared_ptr`。这意味着：
- `unique_ptr`放弃对资源的所有权，并且之后不能再使用它来访问资源，因为它不再拥有该资源。
- `shared_ptr`接管资源并开始管理它。现在可以有多个`shared_ptr`共享同一资源，直到最后一个`shared_ptr`被销毁或重置，这时才会释放资源。

## weak_ptr 使用场景
### 资源语义
这里有一个所谓约定俗成的语义，使用 weak_ptr 是不会干涉对象的生命周期的。换言之良好的代码设计可以让人看出资源的从属关系，要是 shared_ptr 一把梭，循环引用问题不说，资源从属也不是很明确。举例有：

1. 网络分层结构中，Session 对象（会话对象）利用 Connection 对象（连接对象）提供的服务工作，但是 Session 对象不管理 Connection 对象的生命周期，Session 管理 Connection 的生命周期是不合理的，因为网络底层出错会导致 Connection 对象被销毁，此时 Session 对象如果强行持有 Connection 对象的 shared_ptr 与事实矛盾。

2. 对于 Cache 类，总是希望 Cache 类拥有某种手段指向资源，这样可以方便地从 Cache 中获取这个资源复用它。但一旦资源不被其他功能需要，应当让它自动被驱逐出去，这时 Cache 持有 shared_ptr 就不行了（或者说，其实 Cache 定期扫描 shared_ptr 计数是否为 1 也行，但有性能损失以及语义不明确的问题），使用 weak_ptr 获取资源有效性即可。

### 探查内存空间是否有效
以往使用老的方法，判断一个指针是否是 NULL，但是如果这段内存已经被释放却没有赋一个 NULL，那么就会引发未知错误，这需要程序员手动赋值，而且出问题还很难排查。有了 weak_ptr，就方便多了，直接使用其 expired() 方法看下就行了。

参考 [When is std::weak_ptr useful?](https://stackoverflow.com/questions/12030650/when-is-stdweak-ptr-useful)，本例子说明 weak_ptr 可以用来解决 dangling pointer 的问题，
```C++
#include <iostream>
#include <memory>

int main()
{
    // OLD, problem with dangling pointer
    // PROBLEM: ref will point to undefined data!
    int* ptr = new int(10);
    int* ref = ptr;
    delete ptr;

    // NEW
    // SOLUTION: check expired() or lock() to determine if pointer is valid
    // empty definition
    std::shared_ptr<int> sptr;

    // takes ownership of pointer
    sptr.reset(new int);
    *sptr = 10;

    // get pointer to data without taking ownership
    std::weak_ptr<int> weak1 = sptr;

    // deletes managed object, acquires new pointer
    sptr.reset(new int);
    *sptr = 5;

    // get pointer to new data without taking ownership
    std::weak_ptr<int> weak2 = sptr;

    // weak1 is expired!
    if (weak1.expired())
    {
        std::cout << "weak1 is expired\n";
    } else {
        auto temp = weak1.lock();
        std::cout << "value (weak1 point to): "<< *temp << '\n';
    }
        
    // weak2 points to new data (5)
    if (weak2.expired())
    {
        std::cout << "weak2 is expired\n";
    } else {
        auto temp = weak2.lock();
        std::cout << "value (weak2 point to): "<< *temp << '\n';
    }
}
```

代码中 weak1 先是和 sptr 指向相同的内存空间，后面 sptr 释放了那段内存空间然后指向新的内存空间，此时通过 weak1 的 expired() 方法就可以知道本来指向的那段内存空间已经被释放。
