# VBDog Pro — AI Prompt 创作者社区

> 基于 HarmonyOS ArkTS 的 AI Prompt 创作者社区平台 · 独立 Supabase 后端 · ApiProvider 抽象层支持随时替换后端

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-ArkTS-blue)](https://developer.huawei.com/consumer/cn/harmonyos/)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-green)](https://supabase.com/)
[![License](https://img.shields.io/badge/license-MIT-orange)](LICENSE)

---

## 项目简介

VBDog Pro 是一个面向 AI Prompt 创作者的社区应用，运行于 HarmonyOS 鸿蒙操作系统。用户可以在平台上发布和分享 AI Prompt 模板、交流使用技巧、互相关注并积累创作等级。

### 核心特性

- **Prompt 创作与分享** — 多分类（Prompt / Skill / VibeCoding / 教程 / 工具）、多模型标签（Claude / ChatGPT / DeepSeek 等）、Markdown 渲染 + 代码块高亮
- **完整社交系统** — 点赞、收藏、评论、关注 / 粉丝、私信、通知
- **创作者成长体系** — 等级与经验值，从初学者到传奇创作者
- **内容发现** — 分类筛选、最热 / 最新排序、全文搜索（帖子和用户）、热门标签
- **管理后台** — 帖子 / 评论 / 用户管理、举报处理、数据统计
- **暗黑模式** — 14 页全局覆盖，SettingsPage 开关联动
- **离线容错** — OfflineQueue 离线操作队列，网络恢复后自动同步

### 技术亮点

- **ApiProvider 抽象层** — 50+ API 接口定义，更换后端只需实现 IApiProvider
- **乐观更新 + 回滚** — 关注 / 点赞 / 收藏即时反馈 UI，失败自动回滚
- **SECURITY DEFINER RPC** — 绕过 Supabase RLS 限制执行敏感操作
- **自研 Markdown 引擎** — 支持标题、粗体、斜体、行内代码、围栏代码块

---

## 测试账号

| 角色 | 手机号 | 密码 | 昵称 |
|------|--------|------|------|
| 管理员 | 00000000000 | *** | VBDog 社区 |
| 用户 | 13800000001 | *** | 陈言之 |
| 用户 | 13800000002 | *** | 林小满 |
| 用户 | 15715929196 | *** | 绿豆方糕 |
| 用户 | 19084716744 | *** | 草莓方糕 |
| 用户 | 19999999999 | *** | 红豆方糕 |
| 用户 | 16666666666 | *** | 黄豆方糕 |

> 密码均为 123456，参赛评委可向仓库提交者索取。

---

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端框架 | HarmonyOS ArkTS / ArkUI | 华为鸿蒙原生 UI 框架 |
| 开发工具 | DevEco Studio 5.0 | 官方 IDE |
| 后端服务 | Supabase | 开源 Firebase 替代方案 |
| 数据库 | PostgreSQL 15 | 通过 PostgREST 暴露 REST API |
| 文件存储 | Supabase Storage | 用户上传图片 |
| 认证方式 | 手机号 + 密码 + RPC | 自定义认证 |
| 架构模式 | ApiProvider 抽象层 | 接口 - 实现分离，后端可替换 |

---

## 项目结构

`
entry/src/main/ets/
  common/
    ApiProvider.ets          后端抽象接口 (50+ API)
    SupabaseClient.ets       Supabase REST 实现 (核心逻辑)
    MarkdownParser.ets        Markdown 解析器
    MarkdownView.ets          Markdown 渲染组件
    Models.ets                数据模型
    Constants.ets             全局常量、设计 Token
    UserManager.ets           用户状态管理
    OfflineQueue.ets          离线操作队列

  pages/                      14 个页面
    Index.ets                 主页 (Tab 导航)
    FeedPage.ets              发现页 (双列瀑布流)
    SearchPage.ets            搜索页 (帖子 + 用户)
    CreatePage.ets            发布页
    PostDetailPage.ets        帖子详情 (Markdown 渲染)
    ProfilePage.ets           个人主页
    UserPage.ets              他人主页
    FollowListPage.ets        粉丝 / 关注列表
    MessagesPage.ets          私信页
    NotificationsPage.ets     通知页
    AdminPage.ets             管理后台
    LoginPage.ets             登录页
    EditProfilePage.ets       编辑资料
    SettingsPage.ets          设置页
    CollectionPage.ets        收藏页

supabase/migrations/          10 个 SQL 迁移文件
tools/                        辅助脚本
docs/                         项目文档 (报告 + 代码指南)
`

---

## 许可证

MIT License

## 联系方式

- 仓库: [github.com/kleigsm/vbdog-pro](https://github.com/kleigsm/vbdog-pro)
- Supabase: [bxecdhlbnpwahwswnqzr.supabase.co](https://bxecdhlbnpwahwswnqzr.supabase.co)
