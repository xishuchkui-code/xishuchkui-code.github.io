---
title: PortSwigger-JWT
createTime: 2026/04/03 14:57:21
permalink: /posts/portswigger-jwt/
description: 记录 PortSwigger JWT 相关实验的解题过程、关键请求和验证思路。
cover: /assets/img/PortSwigger-JWT/PortSwigger-JWT-1774871623935.png
excerpt: 以 PortSwigger JWT 靶场为线索，复盘未验证签名、算法混淆、kid 注入等认证绕过场景。
sticky: 30
categories:
  - Web 安全
  - 认证与会话
  - 靶场复盘
tags:
  - JWT
  - PortSwigger
  - Burp Suite
---
# Lab 1: JWT authentication bypass via unverified signature
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774871623935.png)

在开始这个实验前先看一下提示上关于 `JWT` 的实验讲解
```
https://portswigger.net/burp/documentation/desktop/testing-workflow/vulnerabilities/session-management/jwts
```
我们在 `buep` 下一个 JWT 编辑器
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774872155730.png)
进入靶场，登录后查看相关的包，可以发现其标绿了
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774872451453.png)
发送到重发器，其相关的 `JWT` 在 `cookie` 里
```
Cookie: session=eyJraWQiOiJjY2QwNmVhNi00MjFhLTQ0NzgtOWRmNC04ZmM2ZjE4NzIyOTkiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJwb3J0c3dpZ2dlciIsImV4cCI6MTc3NDg3NTk2OCwic3ViIjoid2llbmVyIn0.WNSGnSzxm68GLbf5u0XurEUW9JcgnHqhqcAhRyvBvX5H8BzVPzFuagaBZNjJ83F0SosPoMziwJl8X6NQTv643SNia9Riz_vbKZUMcUSFeF5YF6lXtltBNUMs1U11dSo34h4joS3LHVmgFEJfoVl_gWkxHk1M07u2lySOswODSAxGGEeT7aF7GBj8UMTZjiV_WjjFD9ZKnvgJnOq8nxQzd0P7NzU6mQZX3ekSSjFThOKpW-X_rhPfWkMiBErWCiiiJSLZSMWGL1ebsLXcxvRHn0WJlQ-l_vSwBwQXOFhwhsi09czuSbNS3FmrMbshC4-gtspEYQh2vvR4oOEhjuRy2w
```
JWT 本质上就是一组字串，通过（`.`）切分成三个为 Base 64 编码的部分：
Header、Payload 和 Signature
我们主要关注 `Payload` 部分，也就是
```
eyJpc3MiOiJwb3J0c3dpZ2dlciIsImV4cCI6MTc3NDg3NTk2OCwic3ViIjoid2llbmVyIn0
```
通过插件，可以发现选中相关字符串右边会有解码
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774872725473.png)
我们根据实验说明把路径换成 `/admin` 
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774873486363.png)
提示说要 `administrator`
将 `sub` 的值换成 `administrator` , 可以发现左边的值也发生了变化
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774873607009.png)
应用更改，下面点击发送，跟踪重定向
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774873638501.png)
成功进入 `admin`
找到删除用户 `carlos` 的相关代码
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774873695722.png)
成功删除
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1774873737451.png)



# Lab 2: JWT authentication bypass via flawed signature verification
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775009165385.png)
进实验室，登录抓包
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775009354501.png)
根据要求修改路径为 `/admin` 看看先
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775009329939.png)
那根据指引修改 `sub` 为 `administrator`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775009532649.png)
点击发送发现不行
把 `JWT` 拿出来，尝试把头部的算法去除
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775010349251.png)
网站：`https://www.jwt.io/`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775010510390.png)
成功绕过，下面删除 `carlos` 即可
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775010599441.png)
跟随重定向
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775010704334.png)



# Lab 3: JWT authentication bypass via weak signing key
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775010968053.png)
说是弱口令密钥，`JWT` 的签名方式是
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret)
```
但算法不一定是 `HS256` 还是要看具体头部
这里根据官方给的提示用 `hashcat` 来破解
```
hashcat -a 0 -m 16500 token /password.txt
```
这里的 `-a` 指定破解模式，`0` 为暴力破解，`-m` 为指定哈希类型，jwt 哈希 ` id` 为 `16500`，之后跟 `token` 以及密码本
先准备密码本，可以用 `kali` 的 `rockyou.txt`
```
hashcat -a 0 -m 16500 eyJraWQiOiJmNTA3NjAyYy04YWUwLTQ3NDUtYmVkYy1iMDk2N2Y0MGJmN2QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwb3J0c3dpZ2dlciIsImV4cCI6MTc3NTAyMjExNCwic3ViIjoid2llbmVyIn0.KzLuminHlo9YoPWLvpL15tj7Mp1IgGYsi6ybh7k810o rockyou.txt
```
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775019511851.png)
得到密钥是 `secret1`
网站是
```
https://www.jwt.io/
```
这里改成 `administrator` 是因为在没改变 `JWT` 时把路径换成 `/admin` 所提示的
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775019700954.png)
路径改成 `/admin` 就可以看到进入管理页面
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775019749599.png)
最后删除用户，发送，跟随重定向
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775019888891.png)


# Lab 4: JWT authentication bypass via jwk header injection
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775032827084.png)
抓包去把路径改为 `/admin`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034211643.png)
`JWT` 的安全性依赖于签名验证，而 `JWK` 头注入攻击正是利用了服务器错误地信任来自 `Token` 自身的密钥信息这一漏洞
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775036947476.png)

我们通过 `burp` 生成，先去 `header` 头部的 `id`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034525651.png)
去 `JWT` 编辑器生成（没有的先去扩展页的 `BAPP` 下载）
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034579800.png)
返回重发器点上面的 `JSON Web Token` 修改 `sub`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034661037.png)
点下面攻击，选择 `Embedded JWK`, 然后发送
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034772082.png)
成功进入管理页面，下面删除用户即可
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034858141.png)
跟随重定向
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034894010.png)


# Lab 5: JWT authentication bypass via jku header injection
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775034993811.png)
`JKU` 注入与 `JWK` 嵌入注入的核心区别在于：攻击者不是把公钥直接塞进 `Header`，而是塞进一个**URL**，让服务器去外部拉取密钥——而这个 URL 指向的是攻击者自己控制的服务器
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775037707060.png)
抓包登录，先获取 `JWT` 里的 `kid`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775037906117.png)
继续去 `JWT` 编辑器生成一对密钥
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775037999022.png)
把密钥按照下面格式放进 `exploit server` 里
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046284625.png)
```
{
    "keys": [
        {
            "kty": "RSA",
            "e": "AQAB",
            "kid": "6aa448c0-a54c-4865-9911-14c19e11e90d",
            "n": "zKbY0Mxsht6hIejRQKTXNOCy3j3sXrffPUhFLO5swS_iAgyuAf6YbKAtuG3WtVNcG-t2geXmyY1kBmXKABYEXm7z_244pdEelnOGRZ9IbKFUMTU341Nz9SGdZph1EFNnjwslJd3iXz2OqCZxyNp4QD0HkW7S63zftoy76fFPlrmyuDz617ZkOHG0nFbfNAddY3SglYeQM_aIgU3Eur-23QDP4KfxCRDJw5_SZ5kJIXEICVVF1Yd6AytQT8G3twcMuAiO1bgydFMKkD1H7QejHq1GBD3yTOj1Ku-S6kTyYQeT4aIDkdFD3vI6p75pUQBh1fi1yw6MW8iiC5StLR7ehQ"
        }
    ]
}
```
其中的 `kid` 和 `n` 换成 `JWT` 编辑器生成的
后在 `JSON Web Token` 放入 `jku` 和修改 `sub`
```
{
  "kid": "6aa448c0-a54c-4865-9911-14c19e11e90d",
  "jku": "https://exploit-0afa00c003da0f1880aa9dca01620029.exploit-server.net/exploit",
  "alg": "RS256"
}
```
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046500972.png)
```
{
  "iss": "portswigger",
  "exp": 1775048049,
  "sub": "administrator"
}
```
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046646302.png)
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046786970.png)
这就是生成的 `JWT`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046859252.png)
发送，成功进入管理页面
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046224951.png)
找到删除用户路径 `/delete?username=carlos` 即可
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775046599245.png)


# Lab 6: JWT authentication bypass via kid header path traversal
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775542559829.png)
通过头部的 `kid` 遍历本地的签名文件来作为 jwt 的签名  
攻击者可以通过使用 `../../` 使服务器读取其他目录的文件,进行签名,然后服务器根目录 `/dev/null` 会返回空  
即可以使用这个来用空来==验签==,我们用空来==签名==

使用 `jwt editor` 生成 `symmetric key`
将生成的 `k 属性值` 替换为一个 Base 64 编码的空字节（`AA==`）
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775543973301.png)

将 kid 改成 `../../../../../../../dev/null`,跳出到根目录的 `/dev/null`, `sub` 改成 `administrator`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775543707379.png)

![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775543804741.png)
后面发现成功进入管理页面，找到删除用户的 `button`
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775543762558.png)
成功
![](/assets/img/PortSwigger-JWT/PortSwigger-JWT-1775543849424.png)
