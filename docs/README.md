---
pageLayout: home
config:
  - type: banner
    banner: /assets/img/brand/black-hole.webp
    bannerMask:
      light: 0.34
      dark: 0.48
    hero:
      name: xidumplings
      tagline: Web 安全 · 靶场复盘 · 漏洞笔记
      text: 在黑洞边缘整理攻击面、协议细节和每一次实验留下的线索。
      actions:
        - text: 进入博客
          link: /blog/
          theme: brand
        - text: 查看归档
          link: /blog/archives/
          theme: alt
  - type: features
    title: 研究路线
    description: 把漏洞原理、实验过程和复盘结论收进同一个检索入口。
    features:
      - title: Web 安全笔记
        icon: "lucide:shield-check"
        details: 梳理认证、服务端请求、注入、上传等常见攻击面。
        link: /blog/categories/
        linkText: 查看分类
      - title: PortSwigger 复盘
        icon: "simple-icons:burpsuite"
        details: 记录关键请求、payload 构造、绕过路径和实验截图。
        link: /blog/tags/
        linkText: 查看标签
      - title: CTF Writeup
        icon: "lucide:flag"
        details: 归档 crypto、misc、pwn、reverse、web 的解题过程。
        link: /blog/CTF/writeup.html
        linkText: 阅读 Writeup
      - title: 工具与环境
        icon: "lucide:terminal"
        details: 保存 Burp Suite、脚本、调试环境和复现流程的细节。
        link: /blog/archives/
        linkText: 查看归档
  - type: image-text
    title: 笔记方式
    description: 每篇文章尽量留下可复现的判断链路，而不是只保存结论。
    image:
      dark: /assets/img/brand/black-hole.webp
      light: /assets/img/brand/black-hole.png
      alt: black hole
    list:
      - title: 攻击面先行
        description: 先定位输入、信任边界和后端处理路径。
      - title: 请求证据留痕
        description: 用截图、关键包和参数变化串起实验过程。
      - title: 防护面收束
        description: 在复盘末尾回到修复策略和安全边界。
  - type: profile
    name: xidumplings
    description: Web 安全学习笔记、靶场复盘和工具记录。
    avatar: /assets/img/brand/xiaoye.png
    circle: true
  - type: posts
    collection: blog
---
