# VBDog Pro — AI Prompt 创作者社区（鸿蒙版）

基于 HarmonyOS ArkTS 的 AI Prompt 创作者社区平台。

**独立后端 Supabase + ApiProvider 抽象层，可随时替换后端。**

---

## 当前进度

### 已完成 ✅

| 模块 | 状态 |
|---|---|
| 14 页完整 UI | Index/Feed/Login/PostDetail/Profile/Create/Search/Notifications/Admin/Messages/Settings/EditProfile/UserPage/CollectionPage |
| 用户系统 | 手机号注册/登录、Profile、Level/Exp、关注/粉丝 |
| Feed 流 | 6 分类筛选、最新/最热排序、搜索（历史+热门标签）、无限滚动分页 |
| 社交互动 | 点赞/收藏/评论/关注/私信/通知 |
| 管理后台 | 4 Tab（帖子/评论/用户/举报）、统计卡片、CRUD |
| 暗黑模式 | 14 页全局接入、SettingsPage 开关联动 |
| 图片上传 | DB images 列 + Supabase Storage + CreatePage 选择器 + PostDetailPage 展示 |
| API 抽象 | IApiProvider 接口 + SupabaseClient 实现（50+ API） |
| 数据 | 7 用户、9 篇帖子、完整社交交互种子 |

### 进行中 ⚠️

| 项目 | 说明 |
|---|---|
| 举报系统 | 后端完成，前端弹窗/AdminPage 已就位，差 2 个 ArkTS object literal 编译错误 |
| 图片 Feed 展示 | PostCard 封面未完成 |
| Feed 底部加载指示器 | onReachEnd 未插入 |

### 待开始 ⬜

| 优先级 | 项目 |
|---|---|
| P2 | Prompt 在线试玩、创作者激励、话题系统、草稿管理 |
| P3 | Markdown 渲染、创作者看板、推荐算法 |
| P4 | Push Kit、分享、AI 标签推荐 |

---

## 架构

```
Pages → getApi().xxx() → ApiProvider (接口) → SupabaseClient (实现) → Supabase REST API
```

换后端只需实现 `IApiProvider` 接口。

---

## 技术栈

| 层 | 技术 |
|---|---|
| 框架 | HarmonyOS ArkTS / ArkUI |
| IDE | DevEco Studio |
| 后端 | Supabase（PostgreSQL + PostgREST + Storage） |
| Auth | 手机号 + 密码 |
| 架构 | ApiProvider 抽象层 |

---

## 关键配置

| 配置 | 值 |
|---|---|
| Supabase URL | `https://bxecdhlbnpwahwswnqzr.supabase.co` |
| Storage Bucket | `post-images`（公开） |
| 管理员 | 手机号 `00000000000`，密码 `admin123` |
| 测试用户 | `13800000001`~`05`，密码 `123456` |

---

## 开发规范

参见 [CONTRIBUTING.md](/D:/Projects/vbdog-pro/CONTRIBUTING.md)：
- 分支：`feat/xxx` → squash merge → master
- Commit：`feat/fix/docs: 中文描述`
- 编码铁律：**绝不**用 PowerShell 改含中文的 `.ets`，用 `apply_patch` 或 Python `rb`/`wb`
- 推送前检查：编译通过 + commit 历史清晰

---

## 项目结构

```
entry/src/main/ets/
├── common/
│   ├── ApiProvider.ets      # 后端抽象接口（50+ API）
│   ├── SupabaseClient.ets   # Supabase REST 实现
│   ├── Models.ets           # 数据模型
│   ├── Constants.ets        # 全局配置 + 设计 Token
│   ├── UserManager.ets      # 用户状态管理
│   └── OfflineQueue.ets     # 离线操作队列
├── pages/                   # 14 个页面
└── entryability/            # 入口
supabase/migrations/         # 数据库迁移（008 个）
tools/                       # 辅助脚本
CONTRIBUTING.md              # Git & Commit 规范
```
