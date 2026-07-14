# VBDog Pro — AI Prompt 创作者社区（鸿蒙版）

基于 HarmonyOS ArkTS 的 AI Prompt 创作者社区平台，面向 Claude/ChatGPT/Copilot 等 AI 工具用户。

**VBDog 的升级版**：独立后端（Supabase），API 抽象层设计，可随时切换后端。

---

## 与旧版 VBDog 的区别

| | VBDog (旧) | VBDog Pro |
|---|---|---|
| 后端 | 耦合在 Bridge 的 SQLite 里 | 独立 Supabase（可替换） |
| 架构 | 页面直调 WebSocket | ApiProvider 抽象层 |
| 可迁移性 | 绑死 Bridge | 换后端只改一个实现类 |
| 文件存储 | 不支持 | Supabase Storage |
| Auth | 手机号+昵称 | Supabase Auth + 自定义 |

---

## 架构

```
Pages
  ├── FeedPage   ─┐
  ├── SearchPage  ─┤
  ├── CreatePage  ─┤
  ├── ProfilePage ─┼── getApi().getPosts()
  └── ...         ─┘

common/ApiProvider.ets        ← 接口（只定义不实现）
common/SupabaseClient.ets     ← 当前实现（调 Supabase REST API）
                               未来: AgcClient.ets  / CustomClient.ets
```

---

## 快速开始

1. 创建 Supabase 项目，获取 URL + anon key
2. 填入 `common/Constants.ets`
3. DevEco Studio 打开本目录，编译运行

---

## 项目结构

```
entry/src/main/ets/
├── common/
│   ├── ApiProvider.ets      # 后端抽象接口（核心）
│   ├── SupabaseClient.ets   # Supabase REST 实现
│   ├── Models.ets           # 数据模型
│   ├── Constants.ets        # 全局配置
│   └── UserManager.ets      # 用户状态管理
├── entryability/
│   └── EntryAbility.ets     # 入口 + API 初始化
└── pages/
    └── Index.ets            # Tab 容器
```

---

> VBDog Pro · 独立后端 · 可迁移 · 完整的鸿蒙应用
