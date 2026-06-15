import { viteBundler } from '@vuepress/bundler-vite'
import { defineUserConfig } from 'vuepress'
import { plumeTheme } from 'vuepress-theme-plume'

export default defineUserConfig({
  lang: 'zh-CN',
  title: 'xidumplings',
  description: '记录 Web 安全学习、靶场实验、漏洞原理和工具环境配置。',
  base: '/',
  head: [
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/assets/img/brand/favicon-32.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/assets/img/brand/apple-touch-icon.png' }],
    ['meta', { name: 'theme-color', content: '#121421' }],
    ['meta', { name: 'keywords', content: 'Web 安全,CTF,PortSwigger,JWT,SSRF,文件上传,SQL 注入,漏洞复现' }],
    ['meta', { name: 'author', content: 'xidumplings' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'xidumplings' }],
    ['meta', { property: 'og:description', content: '记录 Web 安全学习、靶场实验、漏洞原理和工具环境配置。' }],
    ['meta', { property: 'og:image', content: 'https://xishuchkui-code.github.io/assets/img/brand/black-hole.png' }],
  ],
  bundler: viteBundler(),
  theme: plumeTheme({
    hostname: 'https://xishuchkui-code.github.io',
    docsRepo: 'xishuchkui-code/xishuchkui-code.github.io',
    docsBranch: 'main',
    docsDir: 'docs',
    editLink: false,
    lastUpdated: true,
    contributors: false,
    autoFrontmatter: false,
    logo: '/assets/img/brand/favicon-32.png',
    logoDark: '/assets/img/brand/favicon-32.png',
    appearance: 'dark',
    outline: 'deep',
    transition: {
      page: true,
      postList: true,
      appearance: 'soft-blur-fade',
    },
    readingTime: {
      wordPerMinute: 300,
    },
    copyCode: {
      showInMobile: true,
      duration: 1600,
    },
    copyright: {
      license: 'CC-BY-NC-SA-4.0',
      author: 'xidumplings',
    },
    search: {
      provider: 'local',
    },
    social: [
      { icon: 'github', link: 'https://github.com/xishuchkui-code' },
    ],
    navbarSocialInclude: ['github'],
    navbar: [
      { text: '首页', link: '/' },
      { text: '博客', link: '/blog/' },
      { text: '分类', link: '/blog/categories/' },
      { text: '标签', link: '/blog/tags/' },
      { text: '归档', link: '/blog/archives/' },
      { text: 'GitHub', link: 'https://github.com/xishuchkui-code' },
    ],
    collections: [
      {
        type: 'post',
        dir: 'blog',
        title: '博客',
        link: '/blog/',
        linkPrefix: '/posts/',
        categories: true,
        categoriesLink: '/blog/categories/',
        categoriesText: '分类',
        categoriesExpand: 'deep',
        tags: true,
        tagsLink: '/blog/tags/',
        tagsText: '标签',
        archives: true,
        archivesLink: '/blog/archives/',
        archivesText: '归档',
        postCover: {
          layout: 'odd-left',
          ratio: '16/9',
          width: 300,
          compact: true,
        },
        profile: {
          name: 'xidumplings',
          description: 'Web 安全学习笔记、靶场复盘和工具记录。',
          avatar: '/assets/img/brand/xiaoye.png',
          circle: true,
          location: 'Asia/Shanghai',
          organization: 'xishuchkui-code',
          layout: 'right',
        },
        social: [
          { icon: 'github', link: 'https://github.com/xishuchkui-code' },
        ],
      },
    ],
    footer: {
      message: 'Powered by VuePress Theme Plume',
      copyright: 'Copyright © 2021-present xidumplings',
    },
  }),
})
