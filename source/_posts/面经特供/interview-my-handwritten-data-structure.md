---
title: 为面试疯狂，C++ 面试手写数据结构大全
date: 2025-04-30 04:54:48
tags:
---
## 前言
> ### 校招 C++ 大概学习到什么程度
>
> 写明白下面这几个代码 +能讲明白几个 C++11/14/17 的特性
> 
> - MyString
> - MyVector
> - MyLRU
> - MySingleton
> - MyHashTable
> - MySharedPtr
> - MyUniquePtr
> - MyWeakPtr
> - MyThreadPool
> - MyRingbuffer
> - MyReadWriteMutex
> - MyForward
> - MyMove

## MyString

<details>
<summary>展开代码</summary>

```cpp
class MyString {
private:
    char* data;
    size_t len;

public:
    // 默认构造函数
    MyString() : data(nullptr), len(0) {}

    // 构造函数
    MyString(const char* str) {
        len = std::strlen(str);
        data = new char[len + 1];
        std::strcpy(data, str);
    }

    // 拷贝构造函数（深拷贝）
    MyString(const MyString& other) {
        len = other.len;
        data = new char[len + 1];
        std::strcpy(data, other.data);
    }

    // 移动构造函数
    MyString(MyString&& other) noexcept {
        data = other.data;
        len = other.len;
        other.data = nullptr;
        other.len = 0;
    }

    // 拷贝赋值运算符（使用拷贝交换技术）
    MyString& operator=(MyString other) {
        swap(*this, other);
        return *this;
    }

    // 移动赋值运算符
    MyString& operator=(MyString&& other) noexcept {
        if (this != &other) {
            delete[] data;
            data = other.data;
            len = other.len;
            other.data = nullptr;
            other.len = 0;
        }
        return *this;
    }

    // 析构函数
    ~MyString() {
        delete[] data;
    }

    // 友元函数用于交换两个对象
    friend void swap(MyString& first, MyString& second) noexcept {
        using std::swap;
        swap(first.data, second.data);
        swap(first.len, second.len);
    }

    // 其他常用操作
    const char* c_str() const { return data; }
    size_t length() const { return len; }
};
```
</details>

这个实现展示了 C++ 中字符串类的基本实现，包括：

1. 深拷贝构造函数：确保对象之间的独立性
2. 移动构造函数和移动赋值：利用 C++11 特性提高性能
3. 拷贝赋值运算符使用"拷贝交换"技术保证异常安全
4. 析构函数正确释放资源
5. 使用友元函数实现交换操作，
6. 提供基本的字符串访问方法 c_str() 和 length()

## MyVector

<details>
<summary>展开代码</summary>

```cpp
template <typename T>
class MyVector {
private:
    T* elements;
    size_t capacity;
    size_t size;

public:
    // 默认构造函数
    MyVector() : elements(nullptr), capacity(0), size(0) {}

    // 构造函数指定初始大小
    explicit MyVector(size_t initialSize) 
        : elements(new T[initialSize]), capacity(initialSize), size(initialSize) {}

    // 拷贝构造函数
    MyVector(const MyVector& other) {
        capacity = other.capacity;
        size = other.size;
        elements = new T[capacity];
        for (size_t i = 0; i < size; ++i) {
            elements[i] = other.elements[i];
        }
    }

    // 移动构造函数
    MyVector(MyVector&& other) noexcept {
        elements = other.elements;
        capacity = other.capacity;
        size = other.size;
        other.elements = nullptr;
        other.capacity = 0;
        other.size = 0;
    }

    // 析构函数
    ~MyVector() {
        delete[] elements;
    }

    // 拷贝赋值运算符
    MyVector& operator=(const MyVector& other) {
        if (this != &other) {
            T* newElements = new T[other.capacity];
            for (size_t i = 0; i < other.size; ++i) {
                newElements[i] = other.elements[i];
            }
            
            delete[] elements;
            elements = newElements;
            capacity = other.capacity;
            size = other.size;
        }
        return *this;
    }

    // 移动赋值运算符
    MyVector& operator=(MyVector&& other) noexcept {
        if (this != &other) {
            delete[] elements;
            elements = other.elements;
            capacity = other.capacity;
            size = other.size;
            other.elements = nullptr;
            other.capacity = 0;
            other.size = 0;
        }
        return *this;
    }

    // 添加元素
    void push_back(const T& value) {
        if (size == capacity) {
            reserve(capacity == 0 ? 1 : capacity * 2);
        }
        elements[size++] = value;
    }

    // 获取元素
    T& operator[](size_t index) {
        return elements[index];
    }

    // 获取常量元素
    const T& operator[](size_t index) const {
        return elements[index];
    }

    // 获取大小
    size_t get_size() const {
        return size;
    }

    // 获取容量
    size_t get_capacity() const {
        return capacity;
    }

private:
    // 预留空间
    void reserve(size_t newCapacity) {
        if (newCapacity > capacity) {
            T* newElements = new T[newCapacity];
            for (size_t i = 0; i < size; ++i) {
                newElements[i] = elements[i];
            }
            
            delete[] elements;
            elements = newElements;
            capacity = newCapacity;
        }
    }
};
```
</details>

这个自定义 vector 实现了标准库 vector 的核心功能：

1. 动态扩容：当空间不足时自动将容量翻倍
2. 深拷贝构造和赋值：确保对象独立性
3. 移动语义：利用 C++11 特性提升性能
4. 下标访问运算符：提供便捷的元素访问方式
5. 基本的内存管理：包括构造、析构、复制和移动操作
6. 常用操作如 push_back 和 reserve

该实现展示了对内存管理、资源所有权转移以及现代 C++ 特性的理解。

## MyLRU
### 经典 LRU
```C++
#include <iostream>
#include <list>
#include <unordered_map>

template <typename K, typename V>
class LRUCache {
private:
    size_t capacity;
    std::list<std::pair<K, V>> cache;
    std::unordered_map<K, typename std::list<std::pair<K, V>>::iterator> map;

public:
    LRUCache(size_t cap) : capacity(cap) {}

    bool get(const K& key, V& value) {
        auto it = map.find(key);
        if (it == map.end()) return false;
        cache.splice(cache.begin(), cache, it->second);
        value = it->second->second;
        return true;
    }

    void put(const K& key, const V& value) {
        if (auto it = map.find(key); it != map.end()) {
            cache.erase(it->second);
        }
        cache.push_front({key, value});
        map[key] = cache.begin();

        if (map.size() > capacity) {
            auto last = cache.back();
            map.erase(last.first);
            cache.pop_back();
        }
    }

    void print() {
        for (auto& p : cache) {
            std::cout << "{" << p.first << ": " << p.second << "} ";
        }
        std::cout << std::endl;
    }
};
```

### 带过期时间的 LRU（TTL-LRU）
```C++
#include <iostream>
#include <list>
#include <unordered_map>
#include <chrono>

template <typename K, typename V>
class TTL_LRUCache {
private:
    using TimePoint = std::chrono::steady_clock::time_point;
    struct CacheNode {
        K key;
        V value;
        TimePoint expiry;
        CacheNode(const K& k, const V& v, int ttl_sec)
            : key(k), value(v), expiry(std::chrono::steady_clock::now() + std::chrono::seconds(ttl_sec)) {}
    };

    size_t capacity;
    std::list<CacheNode> cache;
    std::unordered_map<K, typename std::list<CacheNode>::iterator> map;

    bool isExpired(const CacheNode& node) {
        return std::chrono::steady_clock::now() > node.expiry;
    }

public:
    TTL_LRUCache(size_t cap) : capacity(cap) {}

    bool get(const K& key, V& value) {
        auto it = map.find(key);
        if (it == map.end()) return false;
        if (isExpired(*it->second)) {
            cache.erase(it->second);
            map.erase(it);
            return false;
        }
        cache.splice(cache.begin(), cache, it->second);
        value = it->second->value;
        return true;
    }

    void put(const K& key, const V& value, int ttl_sec) {
        if (auto it = map.find(key); it != map.end()) {
            cache.erase(it->second);
        }
        cache.push_front(CacheNode(key, value, ttl_sec));
        map[key] = cache.begin();

        if (map.size() > capacity) {
            auto last = cache.back();
            map.erase(last.key);
            cache.pop_back();
        }
    }

    void print() {
        for (auto& node : cache) {
            std::cout << "{" << node.key << ": " << node.value << "} ";
        }
        std::cout << std::endl;
    }
};
```

### LRU-K

## MySingleton

```cpp
#include <mutex>
#include <memory>

// 单例模式的经典实现
class Singleton {
private:
    static Singleton* instance_;
    static std::mutex mutex_;
    
    // 私有构造函数，防止外部创建实例
    Singleton() {}
    
    // 禁止拷贝构造和赋值
    Singleton(const Singleton&) = delete;
    Singleton& operator=(const Singleton&) = delete;

public:
    // 获取单例对象的方法
    static Singleton* GetInstance() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (instance_ == nullptr) {
            instance_ = new Singleton();
        }
        return instance_;
    }
    
    // 可选：提供一个静态方法用于显式销毁实例
    static void DestroyInstance() {
        std::lock_guard<std::mutex> lock(mutex_);
        delete instance_;
        instance_ = nullptr;
    }
    
    // 示例方法
    void DoSomething() {
        std::cout << "Singleton instance is doing something." << std::endl;
    }
};

// 静态成员变量初始化
Singleton* Singleton::instance_ = nullptr;
std::mutex Singleton::mutex_;
```

这是一个线程安全的单例模式实现，包含以下关键点：

1. 私有构造函数：防止外部创建多个实例
2. 删除拷贝构造函数和赋值运算符：防止对象被复制
3. 静态获取实例方法：提供全局访问点
4. 懒汉式加载：在第一次调用 GetInstance() 时才创建实例
5. 线程安全：通过 std::mutex 和 std::lock_guard 保证多线程环境下的安全性
6. 手动内存管理：需要显式调用 DestroyInstance() 来释放内存

更高级的变体可能使用 std::call_once 或局部静态变量实现更简洁的线程安全版本：

```cpp
static Singleton& GetInstance() {
    static Singleton instance;
    return instance;
}
```

## MyHashTable

<details>
<summary>展开代码</summary>

```cpp
#include <vector>
#include <list>
#include <utility>
#include <functional>
#include <stdexcept>

template <typename KeyType, typename ValueType, typename Hash = std::hash<KeyType>>
class HashTable {
private:
    using KeyValuePair = std::pair<KeyType, ValueType>;
    using BucketType = std::list<KeyValuePair>;
    
    std::vector<BucketType> buckets_;
    size_t size_;
    Hash hash_function_;
    
    // 扩容阈值因子
    static constexpr double MAX_LOAD_FACTOR = 0.75;

    // 根据键获取对应的桶索引
    size_t getBucketIndex(const KeyType& key) const {
        return hash_function_(key) % buckets_.size();
    }
    
    // 重新散列
    void rehash() {
        std::vector<BucketType> oldBuckets = std::move(buckets_);
        buckets_.resize(oldBuckets.size() * 2);
        
        for (auto& bucket : oldBuckets) {
            for (auto& pair : bucket) {
                size_t newIndex = hash_function_(pair.first) % buckets_.size();
                buckets_[newIndex].push_back(std::move(pair));
            }
        }
    }

public:
    // 构造函数，默认初始化 16 个桶
    HashTable(size_t initialCapacity = 16) 
        : buckets_(initialCapacity), size_(0) {}
    
    // 插入键值对
    bool insert(const KeyType& key, const ValueType& value) {
        if (static_cast<double>(size_) / buckets_.size() >= MAX_LOAD_FACTOR) {
            rehash();
        }
        
        size_t index = getBucketIndex(key);
        BucketType& bucket = buckets_[index];
        
        // 检查是否已经存在相同的键
        for (auto& pair : bucket) {
            if (pair.first == key) {
                return false; // 键已存在，不插入
            }
        }
        
        bucket.emplace_back(key, value);
        ++size_;
        return true;
    }
    
    // 查找特定键的值
    bool find(const KeyType& key, ValueType& outValue) const {
        size_t index = getBucketIndex(key);
        const BucketType& bucket = buckets_[index];
        
        for (const auto& pair : bucket) {
            if (pair.first == key) {
                outValue = pair.second;
                return true;
            }
        }
        
        return false;
    }
    
    // 删除指定键
    bool remove(const KeyType& key) {
        size_t index = getBucketIndex(key);
        BucketType& bucket = buckets_[index];
        
        for (auto it = bucket.begin(); it != bucket.end(); ++it) {
            if (it->first == key) {
                bucket.erase(it);
                --size_;
                return true;
            }
        }
        
        return false;
    }
    
    // 更新指定键的值
    bool update(const KeyType& key, const ValueType& newValue) {
        size_t index = getBucketIndex(key);
        BucketType& bucket = buckets_[index];
        
        for (auto& pair : bucket) {
            if (pair.first == key) {
                pair.second = newValue;
                return true;
            }
        }
        
        return false;
    }
    
    // 获取当前元素数量
    size_t size() const {
        return size_;
    }
    
    // 检查是否为空
    bool empty() const {
        return size_ == 0;
    }
};
```
</details>

这个哈希表实现展示了以下几个核心概念：

1. 开放地址法 vs 分离链接法：这里使用的是分离链接法，每个桶是一个链表，用来处理哈希冲突
2. 哈希函数：默认使用 std::hash，允许用户自定义哈希函数
3. 负载因子与动态扩容：当负载因子超过阈值 (0.75) 时，进行 rehash 操作
4. 时间复杂度：理想情况下，插入、查找、删除的时间复杂度都是 O(1)
5. 多种操作支持：包括 insert、find、remove、update 等常用操作

实现特点：
- 使用 vector 存储桶，每个桶是链表 (list)，可以有效处理哈希冲突
- 动态扩容机制保证了平均性能
- 支持自定义哈希函数，提高了灵活性
- 完整的错误处理和返回状态码

这个实现体现了对哈希表原理、冲突解决策略以及性能优化的深入理解。

## MySharedPtr

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>
#include <atomic>

template <typename T>
class SharedPtr {
private:
    T* ptr_;
    std::atomic<int>* ref_count_;

public:
    // 默认构造函数
    SharedPtr() : ptr_(nullptr), ref_count_(new std::atomic<int>(0)) {}

    // 显式构造函数
    explicit SharedPtr(T* ptr) : ptr_(ptr), ref_count_(new std::atomic<int>(1)) {}

    // 拷贝构造函数
    SharedPtr(const SharedPtr<T>& other) : ptr_(other.ptr_), ref_count_(other.ref_count_) {
        if (ptr_) {
            (*ref_count_)++;
        }
    }

    // 移动构造函数
    SharedPtr(SharedPtr<T>&&& other) noexcept 
        : ptr_(other.ptr_), ref_count_(other.ref_count_) {
        other.ptr_ = nullptr;
        other.ref_count_ = nullptr;
    }

    // 拷贝赋值运算符
    SharedPtr<T>& operator=(const SharedPtr<T>& other) {
        if (this != &other) {
            reset();
            ptr_ = other.ptr_;
            ref_count_ = other.ref_count_;
            if (ptr_) {
                (*ref_count_)++;
            }
        }
        return *this;
    }

    // 移动赋值运算符
    SharedPtr<T>& operator=(SharedPtr<T>&& other) noexcept {
        if (this != &other) {
            reset();
            ptr_ = other.ptr_;
            ref_count_ = other.ref_count_;
            other.ptr_ = nullptr;
            other.ref_count_ = nullptr;
        }
        return *this;
    }

    // 析构函数
    ~SharedPtr() {
        reset();
    }

    // 重置智能指针
    void reset() {
        if (ref_count_ && --(*ref_count_) == 0) {
            delete ptr_;
            delete ref_count_;
        }
        ptr_ = nullptr;
        ref_count_ = nullptr;
    }

    // 重置智能指针并分配新内存
    void reset(T* ptr) {
        reset();
        ptr_ = ptr;
        ref_count_ = new std::atomic<int>(1);
    }

    // 获取原始指针
    T* get() const {
        return ptr_;
    }

    // 获取引用计数
    int use_count() const {
        return ref_count_ ? ref_count_->load() : 0;
    }

    // 解引用操作符
    T& operator*() const {
        return *ptr_;
    }

    // 成员访问操作符
    T* operator->() const {
        return ptr_;
    }

    // 布尔转换
    explicit operator bool() const {
        return ptr_ != nullptr;
    }
};
```
</details>

这个 shared_ptr 实现展示了几个关键概念：

1. 引用计数：使用原子变量 std::atomic<int>来跟踪有多少个 shared_ptr 共享同一个对象
2. 深拷贝 vs 浅拷贝：拷贝构造函数和赋值运算符增加引用计数而不是复制实际对象
3. 移动语义：利用 C++11 的移动特性高效地转移所有权
4. RAII 原则：在析构函数中自动释放资源
5. 内存泄漏预防：确保在所有情况下都正确释放资源
6. 安全布尔转换：避免隐式类型转换带来的问题

主要特性：
- 支持 get() 获取原始指针
- 支持 use_count() 查询引用计数
- 支持 reset() 手动释放资源
- 重载了解引用和成员访问操作符，使其行为像普通指针
- 提供了 bool 转换以检查有效性

这个实现体现了对智能指针设计原理、内存管理和并发控制的理解。

## MyUniquePtr

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>

template <typename T>
class UniquePtr {
private:
    T* ptr_;

public:
    // 显式构造函数
    explicit UniquePtr(T* ptr = nullptr) : ptr_(ptr) {}

    // 禁止拷贝构造
    UniquePtr(const UniquePtr<T>& other) = delete;

    // 禁止拷贝赋值
    UniquePtr<T>& operator=(const UniquePtr<T>& other) = delete;

    // 移动构造函数
    UniquePtr(UniquePtr<T>&& other) noexcept : ptr_(other.ptr_) {
        other.ptr_ = nullptr;
    }

    // 移动赋值运算符
    template <typename U>
    UniquePtr<T>& operator=(UniquePtr<U>&& other) noexcept {
        if (static_cast<void*>(this) != reinterpret_cast<void*>(&other)) {
            delete ptr_;
            ptr_ = other.ptr_;
            other.ptr_ = nullptr;
        }
        return *this;
    }

    // 析构函数
    ~UniquePtr() {
        delete ptr_;
    }

    // 解引用操作符
    T& operator*() const {
        return *ptr_;
    }

    // 成员访问操作符
    T* operator->() const {
        return ptr_;
    }

    // 获取原始指针
    T* get() const {
        return ptr_;
    }

    // 释放所有权
    T* release() {
        T* temp = ptr_;
        ptr_ = nullptr;
        return temp;
    }

    // 重置指针
    void reset(T* other = nullptr) {
        if (ptr_ != other) {
            delete ptr_;
            ptr_ = other;
        }
    }

    // 布尔转换
    explicit operator bool() const {
        return ptr_ != nullptr;
    }

    // 交换
    void swap(UniquePtr<T>& other) noexcept {
        std::swap(ptr_, other.ptr_);
    }
};
```
</details>

这个 unique_ptr 实现展示了以下几个关键概念：

1. 独占所有权：禁止拷贝构造和拷贝赋值，只能通过移动语义转移所有权
2. RAII 原则：在析构函数中自动释放资源
3. 移动语义：利用 C++11 的移动特性高效地转移所有权
4. 安全布尔转换：避免隐式类型转换带来的问题
5. 明确的资源转移机制：通过 release() 和 reset() 方法控制资源的所有权

主要特性：
- 支持 get() 获取原始指针
- 支持 release() 放弃所有权并返回原始指针
- 支持 reset() 替换托管对象
- 重载了解引用和成员访问操作符，使其行为像普通指针
- 提供了 swap 方法交换两个 unique_ptr 的内容

这个实现体现了对独占式资源管理的理解，以及如何通过删除拷贝操作确保单一所有权模型。

## MyWeakPtr

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>

template <typename T>
class WeakPtr;

template <typename T>
class SharedPtr {
private:
    T* ptr_;
    int* ref_count_;
    friend class WeakPtr<T>;

public:
    // 默认构造函数
    SharedPtr() : ptr_(nullptr), ref_count_(new int(0)) {}

    // 显式构造函数
    explicit SharedPtr(T* ptr) : ptr_(ptr), ref_count_(new int(1)) {}

    // 拷贝构造函数
    SharedPtr(const SharedPtr<T>& other) : ptr_(other.ptr_), ref_count_(other.ref_count_) {
        if (ptr_) {
            (*ref_count_)++;
        }
    }

    // 移动构造函数
    SharedPtr(SharedPtr<T>&& other) noexcept {
        ptr_ = other.ptr_;
        ref_count_ = other.ref_count_;
        other.ptr_ = nullptr;
        other.ref_count_ = nullptr;
    }

    // 拷贝赋值运算符
    SharedPtr<T>& operator=(const SharedPtr<T>& other) {
        if (this != &other) {
            reset();
            ptr_ = other.ptr_;
            ref_count_ = other.ref_count_;
            if (ptr_) {
                (*ref_count_)++;
            }
        }
        return *this;
    }

    // 移动赋值运算符
    SharedPtr<T>& operator=(SharedPtr<T>&& other) noexcept {
        if (this != &other) {
            reset();
            ptr_ = other.ptr_;
            ref_count_ = other.ref_count_;
            other.ptr_ = nullptr;
            other.ref_count_ = nullptr;
        }
        return *this;
    }

    // 析构函数
    ~SharedPtr() {
        reset();
    }

    // 重置智能指针
    void reset() {
        if (ref_count_) {
            (*ref_count_)--;
            if (*ref_count_ == 0) {
                delete ptr_;
                delete ref_count_;
            }
        }
        ptr_ = nullptr;
        ref_count_ = nullptr;
    }

    // 重置智能指针并分配新内存
    void reset(T* ptr) {
        reset();
        ptr_ = ptr;
        ref_count_ = new int(1);
    }

    // 获取原始指针
    T* get() const {
        return ptr_;
    }

    // 获取引用计数
    int use_count() const {
        return ref_count_ ? *ref_count_ : 0;
    }

    // 解引用操作符
    T& operator*() const {
        return *ptr_;
    }

    // 成员访问操作符
    T* operator->() const {
        return ptr_;
    }

    // 布尔转换
    explicit operator bool() const {
        return ptr_ != nullptr;
    }
};

template <typename T>
class WeakPtr {
private:
    T* ptr_;
    int* ref_count_;

public:
    // 默认构造函数
    WeakPtr() : ptr_(nullptr), ref_count_(nullptr) {}

    // 从 SharedPtr 构造
    WeakPtr(const SharedPtr<T>& sp) : ptr_(sp.ptr_), ref_count_(sp.ref_count_) {
        if (ptr_) {
            (*ref_count_)++;
        }
    }

    // 拷贝构造函数
    WeakPtr(const WeakPtr<T>& other) : ptr_(other.ptr_), ref_count_(other.ref_count_) {
        if (ptr_) {
            (*ref_count_)++;
        }
    }

    // 移动构造函数
    WeakPtr(WeakPtr<T>&& other) noexcept {
        ptr_ = other.ptr_;
        ref_count_ = other.ref_count_;
        other.ptr_ = nullptr;
        other.ref_count_ = nullptr;
    }

    // 拷贝赋值运算符
    WeakPtr<T>& operator=(const WeakPtr<T>& other) {
        if (this != &other) {
            release();
            ptr_ = other.ptr_;
            ref_count_ = other.ref_count_;
            if (ptr_) {
                (*ref_count_)++;
            }
        }
        return *this;
    }

    // 移动赋值运算符
    WeakPtr<T>& operator=(WeakPtr<T>&& other) noexcept {
        if (this != &other) {
            release();
            ptr_ = other.ptr_;
            ref_count_ = other.ref_count_;
            other.ptr_ = nullptr;
            other.ref_count_ = nullptr;
        }
        return *this;
    }

    // 从 SharedPtr 赋值
    WeakPtr<T>& operator=(const SharedPtr<T>& sp) {
        release();
        ptr_ = sp.ptr_;
        ref_count_ = sp.ref_count_;
        if (ptr_) {
            (*ref_count_)++;
        }
        return *this;
    }

    // 析构函数
    ~WeakPtr() {
        release();
    }

    // 释放资源
    void release() {
        if (ref_count_) {
            (*ref_count_)--;
            if (*ref_count_ == 0) {
                delete ptr_;
                delete ref_count_;
            }
        }
        ptr_ = nullptr;
        ref_count_ = nullptr;
    }

    // 判断所管理的对象是否已删除
    bool expired() const {
        return ref_count_ == nullptr || *ref_count_ == 0;
    }

    // 获取对应的 shared_ptr
    SharedPtr<T> lock() const {
        if (expired()) {
            return SharedPtr<T>();
        }
        return SharedPtr<T>(ptr_, ref_count_);
    }

    // 交换内容
    void swap(WeakPtr<T>& other) {
        std::swap(ptr_, other.ptr_);
        std::swap(ref_count_, other.ref_count_);
    }

    // 获取原始指针
    T* get() const {
        if (expired()) {
            return nullptr;
        }
        return ptr_;
    }
};
```
</details>

这个 weak_ptr 实现展示了以下几个关键概念：

1. 与 shared_ptr 配合使用：weak_ptr 不会增加强引用计数，而是通过观察 shared_ptr 管理的对象
2. 循环引用解决方案：通过弱引用来打破循环引用，避免内存泄漏
3. 引用计数的管理：除了强引用计数外，还需要维护弱引用计数
4. 资源安全访问：通过 lock() 方法获取一个 shared_ptr 来确保对象的有效期

主要特性：
- 支持从 shared_ptr 构造
- 支持 expired() 检查对象是否已经被释放
- 支持 lock() 获取临时的 shared_ptr
- 正确处理引用计数的增减
- 实现了完整的拷贝、移动构造和赋值操作

这个实现体现了对资源生命周期管理、引用计数机制和循环引用问题的理解。

## MyThreadPool

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <thread>
#include <functional>
#include <mutex>
#include <condition_variable>
#include <future>
#include <atomic>

class ThreadPool {
public:
    // 工作线程数量
    explicit ThreadPool(size_t numThreads) {
        start(numThreads);
    }

    // 析构函数
    ~ThreadPool() {
        stop();
    }

    // 提交任务给线程池
    template<typename T>
    std::future<typename std::result_of<T()>::type> submit(T task) {
        // 包装任务
        using result_type = typename std::result_of<T()>::type;
        auto packagedTask = std::make_shared<std::packaged_task<result_type()>>(std::move(task));
        
        // 将任务封装成通用的函数形式
        Task work = [packagedTask]() {
            (*packagedTask)();
        };
        
        // 添加任务到队列
        {
            std::unique_lock<std::mutex> lock(queueMutex_);
            tasks_.push(std::move(work));
        }
        
        // 通知工作线程
        condition_.notify_one();
        
        return packagedTask->get_future();
    }

private:
    // 工作线程运行的函数
    void workerThread() {
        while (true) {
            Task task;
            
            {
                std::unique_lock<std::mutex> lock(queueMutex_);
                
                // 等待直到有任务可用或者线程池停止
                condition_.wait(lock, [this]() {
                    return !running_ || !tasks_.empty();
                });
                
                // 如果线程池停止且没有任务，退出
                if (!running_ && tasks_.empty()) {
                    return;
                }
                
                // 获取任务
                task = std::move(tasks_.front());
                tasks_.pop();
            }
            
            // 执行任务
            task();
        }
    }

    // 启动线程池
    void start(size_t numThreads) {
        running_ = true;
        workers_.reserve(numThreads);
        
        for (size_t i = 0; i < numThreads; ++i) {
            workers_.emplace_back(&ThreadPool::workerThread, this);
        }
    }

    // 停止线程池
    void stop() {
        {
            std::unique_lock<std::mutex> lock(queueMutex_);
            running_ = false;
        }
        
        condition_.notify_all();
        
        for (std::thread& worker : workers_) {
            if (worker.joinable()) {
                worker.join();
            }
        }
    }

    // 类型定义
    using Task = std::function<void()>;
    
    // 成员变量
    std::vector<std::thread> workers_;      // 工作线程
    std::queue<Task> tasks_;               // 任务队列
    
    std::mutex queueMutex_;                // 队列互斥锁
    std::condition_variable condition_;    // 条件变量用于任务通知
    std::atomic<bool> running_;            // 运行标志
};
```
</details>

这个线程池实现展示了以下几个关键概念：

1. 线程管理：启动固定数量的工作线程并在析构时优雅关闭
2. 任务队列：使用线程安全的队列存储待执行的任务
3. 异步执行：通过 future 返回任务结果
4. 条件同步：使用条件变量避免忙等待，提高效率
5. 资源回收：确保所有工作线程在析构时正确结束

主要特性：
- 支持提交任意可调用对象作为任务
- 返回 std::future 以便获取任务结果
- 使用 std::packaged_task 包装任务，简化异步执行逻辑
- 支持优雅的启动和停止流程
- 线程安全的设计，使用互斥锁保护共享资源

这个实现体现了对多线程编程、并发控制和异步任务处理的理解。

## MyRingbuffer

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>
#include <vector>
#include <mutex>
#include <condition_variable>
#include <stdexcept>

template <typename T>
class RingBuffer {
public:
    // 构造函数，初始化指定大小的环形缓冲区
    explicit RingBuffer(size_t capacity) : buffer_(capacity), capacity_(capacity), head_(0), tail_(0), full_(false) {}

    // 向缓冲区写入数据
    void write(const T& item) {
        std::lock_guard<std::mutex> lock(mutex_);

        // 如果缓冲区已满，覆盖旧数据
        if (full_) {
            // 移动 head 到下一个位置
            head_ = (head_ + 1) % capacity_;
        }

        // 写入数据
        buffer_[tail_] = item;
        tail_ = (tail_ + 1) % capacity_;

        // 更新 full_状态
        full_ = (tail_ == head_);

        // 通知可能等待读取的线程
        not_empty_condition_.notify_one();
    }

    // 从缓冲区读取数据
    T read() {
        std::unique_lock<std::mutex> lock(mutex_);

        // 等待直到缓冲区非空
        not_empty_condition_.wait(lock, [this]() {
            return !empty();
        });

        // 读取数据
        T item = buffer_[head_];
        head_ = (head_ + 1) % capacity_;
        full_ = false;

        return item;
    }

    // 尝试读取数据，如果缓冲区为空则返回 false
    bool try_read(T& item) {
        std::lock_guard<std::mutex> lock(mutex_);

        if (empty()) {
            return false;
        }

        item = buffer_[head_];
        head_ = (head_ + 1) % capacity_;
        full_ = false;

        return true;
    }

    // 检查缓冲区是否为空
    bool empty() const {
        return (!full_ && (head_ == tail_));
    }

    // 检查缓冲区是否已满
    bool full() const {
        return full_;
    }

    // 获取当前缓冲区中元素的数量
    size_t size() const {
        if (full_) {
            return capacity_;
        } else if (head_ <= tail_) {
            return tail_ - head_;
        } else {
            return capacity_ - head_ + tail_;
        }
    }

    // 获取缓冲区的最大容量
    size_t capacity() const {
        return capacity_;
    }

    // 重置缓冲区
    void reset() {
        std::lock_guard<std::mutex> lock(mutex_);
        head_ = 0;
        tail_ = 0;
        full_ = false;
    }

private:
    std::vector<T> buffer_;       // 存储数据的底层容器
    const size_t capacity_;       // 缓冲区容量
    size_t head_;                 // 读取指针
    size_t tail_;                 // 写入指针
    bool full_;                   // 缓冲区是否已满的标志

    mutable std::mutex mutex_;              // 互斥锁用于线程安全
    std::condition_variable not_empty_condition_; // 条件变量用于线程同步
};
```
</details>

这个环形缓冲区 (Ring Buffer) 实现展示了以下几个关键概念：

1. 环形结构：使用数组实现的先进先出 (FIFO) 缓冲区
2. 指针管理：通过 head 和 tail 指针追踪读写位置
3. 线程安全：使用互斥锁和条件变量保证多线程环境下的安全性
4. 数据覆盖策略：当缓冲区满时可以选择覆盖旧数据
5. 阻塞与非阻塞操作：提供阻塞的 read() 和非阻塞的 try_read()

主要特性：
- 支持线程安全的读写操作
- 提供检查缓冲区状态的方法 (empty(), full(), size())
- 支持尝试读取和阻塞读取两种模式
- 可以重置缓冲区
- 使用条件变量实现生产者 - 消费者模式

这个实现体现了对并发编程、缓冲区管理和系统级同步原语的理解。

## MyReadWriteMutex

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <vector>

class ReadWriteMutex {
public:
    ReadWriteMutex() : readers_count_(0), writers_waiting_(0), writer_active_(false) {}

    // 读者加锁
    void lock_read() {
        std::unique_lock<std::mutex> lock(mutex_);
        
        // 等待直到没有活动的写者
        reader_condition_.wait(lock, [this]() {
            return !writer_active_;                             // 读优先
            return !writer_active_ && writers_waiting_ == 0;    // 写优先
        });
        readers_count_++;
    }

    // 读者解锁
    void unlock_read() {
        std::unique_lock<std::mutex> lock(mutex_);
        readers_count_--;
        
        // 如果没有读者了，并且有等待的写者，唤醒一个写者
        if (readers_count_ == 0 && writers_waiting_ > 0) {
            writer_condition_.notify_one();
        }
    }

    // 写者加锁
    void lock_write() {
        std::unique_lock<std::mutex> lock(mutex_);
        writers_waiting_++;
        
        // 等待直到没有读者和写者
        writer_condition_.wait(lock, [this]() {
            return readers_count_ == 0 && !writer_active_;
        });
        
        writers_waiting_--;
        writer_active_ = true;
    }

    // 写者解锁
    void unlock_write() {
        std::unique_lock<std::mutex> lock(mutex_);
        writer_active_ = false;
        
        // 如果有等待的写者优先唤醒写者，否则唤醒所有读者
        if (writers_waiting_ > 0) {
            writer_condition_.notify_one();
        } else {
            reader_condition_.notify_all();
        }
    }

private:
    mutable std::mutex mutex_;          // 互斥锁保护内部状态
    std::condition_variable reader_condition_;  // 读者等待条件
    std::condition_variable writer_condition_;  // 写者等待条件
    
    unsigned int readers_count_;        // 当前活跃的读者数量
    unsigned int writers_waiting_;      // 当前等待的写者数量
    bool writer_active_;                // 是否有活动的写者
};
```
</details>

这个读写锁实现展示了以下几个关键概念：

1. 读者 - 写者问题：允许多个读者同时访问，但只允许一个写者访问
2. 优先级策略：采用写者优先策略，一旦有写者等待，后续的读者必须等待
3. 条件同步：使用条件变量等待适当的时机获得锁
4. 状态管理：跟踪读者数量、写者等待状态和写者活动状态

主要特性：
- 支持读者加锁和解锁
- 支持写者加锁和解锁
- 保证写者的优先级高于读者
- 在适当的时候唤醒等待的线程（写者优先）

这个实现体现了对并发控制、条件同步和资源竞争问题的理解。

## MyForward

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>
#include <utility>

// 辅助类，用于完美转发
template <typename T>
struct MyRemoveReference {
    using type = T;
};

template <typename T>
struct MyRemoveReference<T&> {
    using type = T;
};

template <typename T>
struct MyRemoveReference<T&&> {
    using type = T;
};

template <typename T>
using MyRemoveReference_t = typename MyRemoveReference<T>::type;

// 自定义 forward 函数
template <typename T>
T&& my_forward(MyRemoveReference_t<T>& arg) noexcept {
    return static_cast<T&&>(arg);
}

// 测试函数模板，展示完美转发的效果
template <typename T>
void wrapper(T&& arg) {
    // 使用 my_forward 进行完美转发
    call(my_forward<T>(arg));
}

// 不同的重载函数展示转发效果
void call(int& x) {
    std::cout << "lvalue reference called: " << x << std::endl;
}

void call(int&& x) {
    std::cout << "rvalue reference called: " << x << std::endl;
}

int main() {
    int a = 42;
    
    // 直接调用测试
    call(a);              // 输出：lvalue reference called: 42
    call(43);             // 输出：rvalue reference called: 43
    
    // 通过 wrapper 调用
    wrapper(a);           // 输出：lvalue reference called: 42
    wrapper(44);          // 输出：rvalue reference called: 44
    
    return 0;
}
```
</details>

这个实现展示了 std::forward 的核心原理：

1. 引用折叠规则：理解 T&&在不同情况下的含义
2. 类型擦除：使用自定义的 MyRemoveReference 来去除引用属性
3. 完美转发：保持参数的左值/右值属性传递给另一个函数

实现要点：
- MyRemoveReference 模板用于获取原始类型
- my_forward 函数使用 static_cast<T&&>进行强制转换
- 在模板函数 wrapper 中使用 my_forward 实现完美转发

这个例子还展示了完美转发的实际应用场景，通过测试函数验证了转发的正确性。

完美转发对于编写泛型代码非常重要，特别是在实现工厂函数、容器的 emplace 系列方法等场景下非常有用。

## MyMove

<details>
<summary>展开代码</summary>

```cpp
#include <iostream>
#include <type_traits>

// 自定义 remove_reference 实现
template <class T>
struct my_remove_reference {
    using type = T;
};

template <class T>
struct my_remove_reference<T&> {
    using type = T;
};

template <class T>
struct my_remove_reference<T&&> {
    using type = T;
};

template <class T>
using my_remove_reference_t = typename my_remove_reference<T>::type;

// 自定义 move 实现
template <class T>
my_remove_reference_t<T>&& my_move(T&& obj) noexcept {
    return static_cast<my_remove_reference_t<T>&&>(obj);
}

// 用于测试的简单类
class MyClass {
public:
    MyClass() { std::cout << "Constructor\n"; }
    
    MyClass(const MyClass&) { std::cout << "Copy constructor\n"; }
    
    MyClass(MyClass&&) noexcept { std::cout << "Move constructor\n"; }
    
    MyClass& operator=(const MyClass&) {
        std::cout << "Copy assignment\n";
        return *this;
    }
    
    MyClass& operator=(MyClass&&) noexcept {
        std::cout << "Move assignment\n";
        return *this;
    }
};

int main() {
    int x = 42;
    
    // 使用 my_move 将 x 转为右值
    MyClass obj1;
    MyClass obj2(obj1);             // 调用拷贝构造函数
    MyClass obj3(my_move(obj1));   // 调用移动构造函数
    
    MyClass obj4;
    MyClass obj5 = obj4;            // 调用拷贝构造函数
    MyClass obj6 = my_move(obj4);  // 调用移动构造函数
    
    return 0;
}
```
</details>

这个实现展示了 std::move 的核心原理：

1. 引用消除：通过自定义的 my_remove_reference 模板来去除类型的引用属性
2. 右值转换：将输入的参数转换为其去除引用后的右值引用类型
3. 类型擦除：保留原始类型的语义，仅改变其引用属性

实现要点：
- my_remove_reference 处理各种引用类型（左值引用、右值引用）
- my_move 函数使用 static_cast 将对象转换为右值引用
- 保持 noexcept 属性，符合移动操作的异常规范

示例中的 MyClass 演示了 std::move 在实际使用中的效果，显示了何时调用拷贝构造函数，何时调用移动构造函数。

std::move 是 C++11 引入的重要特性之一，它使得移动语义和完美转发成为可能，极大地提升了 C++ 程序的性能。

## 用 C++ 实现一个日志系统，可以被调用，要求性能最好。先思考三分钟，说一下思路，伪代码实现。
设计一个高性能的日志系统，需要考虑几个关键点：
- 线程安全
- 最小化日志记录对主程序性能的影响
- 灵活的日志级别支持
- 易于扩展和维护。

以下是实现这样一个系统的思路：
### 思路

1. **日志级别**：定义不同的日志级别（如 DEBUG、INFO、WARNING、ERROR），让用户能够根据需要控制输出的详细程度。

2. **异步日志记录**：为了避免在记录日志时阻塞主线程，采用生产者 - 消费者模式，使用队列来缓存日志消息，并在一个单独的线程中处理这些消息。

3. **高效写入**：为了提高写入效率，可以将多个日志条目批量写入到文件中，减少磁盘 I/O 操作次数。

4. **线程安全**：确保多线程环境下的安全性，特别是当有多个线程同时尝试记录日志时。

5. **格式化与过滤**：提供灵活的日志格式化选项和过滤机制，允许用户自定义哪些级别的日志应当被记录下来。

<details>
<summary>伪代码实现</summary>

```cpp
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <string>
#include <vector>

enum LogLevel {
    DEBUG, INFO, WARNING, ERROR
};

class LogMessage {
public:
    LogLevel level;
    std::string content;
    // 构造函数等
};

class Logger {
private:
    std::queue<LogMessage> logQueue;
    std::mutex queueMutex;
    std::condition_variable cv;
    std::thread workerThread;
    bool running = true;

    void worker() {
        while (running || !logQueue.empty()) {
            std::unique_lock<std::mutex> lock(queueMutex);
            cv.wait(lock, [this] { return !running || !logQueue.empty(); });
            while (!logQueue.empty()) {
                auto logMsg = logQueue.front();
                logQueue.pop();
                // 批量处理并写入日志
                writeToFile(logMsg);
            }
        }
    }

    void writeToFile(const LogMessage& msg) {
        // 实现具体的写入逻辑
    }

public:
    Logger() {
        workerThread = std::thread(&Logger::worker, this);
    }

    ~Logger() {
        {
            std::lock_guard<std::mutex> lock(queueMutex);
            running = false;
        }
        cv.notify_all();
        workerThread.join();
    }

    void log(LogLevel level, const std::string& message) {
        if (level >= currentLevel) {
            std::lock_guard<std::mutex> lock(queueMutex);
            logQueue.emplace(LogMessage{level, message});
            cv.notify_one();
        }
    }

    LogLevel currentLevel = INFO; // 默认日志级别
};

// 使用示例
Logger logger;
logger.log(INFO, "This is an info message.");
```
</details>

这个伪代码展示了如何创建一个简单的异步日志系统。实际应用中可能还需要增加更多的功能，比如配置文件的支持、多种输出目标（文件、控制台等）、更复杂的格式化选项等。此外，还可以通过调整队列大小、批量写入策略等方式进一步优化性能。

## 多线程打印奇偶数
[三线程依次打印 1~100](https://gg2002.github.io/2025/04/21/Program%20Language%20Design/os-and-pl-mutex/)

## 实现一个支持 TTL（Time To Live）和支持任意类型值的 K-V 存储数据库。
> 解决方案包括：map + 自定义 entry + 懒惰删除 + 定期任务 + 线程池。

## 参考文献
[校招 C++ 大概学习到什么程度](https://www.zhihu.com/question/290102232/answer/14904708697)

