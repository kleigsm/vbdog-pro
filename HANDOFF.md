# VBDog Pro — 开发交接文档

> 最后更新: 2026-07-19 | 当前 commit: `04ebba1` | 所有改动未提交

---

## 一、项目概览

VBDog Pro — 基于 HarmonyOS ArkTS 的 AI Prompt 创作者社区 App。独立 Supabase 后端。

| 项目 | 值 |
|---|---|
| 仓库 | https://github.com/kleigsm/vbdog-pro |
| Supabase URL | https://bxecdhlbnpwahwswnqzr.supabase.co |
| Anon Key | sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU |
| IDE | DevEco Studio |

### 管理员 & 测试账号

手机号 | 密码 | 角色
00000000000 | admin123 | 管理员
13800000001 | 123456 | 陈言之
13800000002 | 123456 | 林小满
15715929196 | 123456 | 绿豆方糕
19084716744 | 123456 | 草莓方糕
19999999999 | 123456 | 红豆方糕
16666666666 | 123456 | 黄豆方糕

---

## 二、当前进度

> 所有改动在硬盘上但未提交到 git。

### 改但未提交的文件（8个）

| 文件 | 改动 |
|---|---|
| SupabaseClient.ets | 举报全套修复 + 关注系统全套 API |
| ApiProvider.ets | getFollowers/getFollowing/isFollowingUser 接口 |
| PostDetailPage.ets | 分类图标补全、模型标签暗黑适配、标签换行、操作栏布局 |
| AdminPage.ets | 举报列表"查看"按钮 + "删帖"确认弹窗 |
| ProfilePage.ets | onPageShow 自动刷新 + 粉丝/关注数可点击跳转 |
| UserPage.ets | isFollowing + followText + 取消关注确认 + 粉丝/关注可点击 |
| main_pages.json | FollowListPage 注册 |
| Models.ets | Report 接口调整 |

### 新建文件

| 文件 | 说明 |
|---|---|
| FollowListPage.ets | 粉丝/关注列表页 |

---

## 三、已做完的功能

### 举报系统（已修复完成）
- getReports: 加了 post_id → postId 字段映射
- resolveReport: 改用 updateRequest(PUT) 而非 POST
- reportPost: 改用 Record<string,Object> 避免 interface 问题
- markNotificationRead/updateProfile: 改用 updateRequest(PUT)
- 三个请求方法: 加错误信息带响应体 + 空响应处理
- AdminPage: 举报列表"查看"按钮 + "删帖"确认弹窗

### 关注系统（基础完成）
- getFollowers / getFollowing: 查粉丝/关注列表
- isFollowingUser: 查是否已关注
- syncFollowCounts: 自动同步双方计数
- followUser: 关注/取关 + 同步计数 + 通知
- updateRequest: PUT + Prefer:resolution=merge-duplicates
- FollowListPage: 粉丝/关注列表页
- ProfilePage/UserPage: 粉丝/关注数可点击跳转
- UserPage 关注按钮: 真实调 API + followText 切换 + 确认弹窗
- 关注通知: followUser 成功后插 notifications 记录

### 已有基础功能
- 用户系统（登录/注册/等级/关注）
- 内容系统（发帖/图片/分类/Prompt 代码块）
- 社交（点赞/收藏/评论/私信/通知）
- Feed 流 + 搜索
- 管理后台 4 Tab
- 暗黑模式 14 页全覆盖
- 数据库全套表 + RPC + 种子数据

---


## 五、未完成路线图

### P2 — 社区差异化

3. 相互关注标识（FollowListPage 显示标签）
4. 话题系统（标签聚合页）
5. 创作者激励（徽章/排行榜）

### P3 — 内容深度

6. Markdown 渲染 + 代码高亮
7. 创作者看板
8. 推荐算法 v1
9. 搜索用户并关注

### P4 — 增长

10. 鸿蒙 Push Kit
11. 分享（深度链接 + 二维码）
12. AI 标签推荐

---

## 六、关键文件

| 文件 | 说明 |
|---|---|
| common/SupabaseClient.ets | 全量 API 实现（含关注/举报修复） |
| common/ApiProvider.ets | 接口定义 |
| common/Models.ets | 数据模型 |
| pages/FollowListPage.ets | 新建:粉丝/关注列表 |
| pages/PostDetailPage.ets | 帖子详情（已优化） |
| pages/AdminPage.ets | 管理后台（已加查看+确认） |
| pages/UserPage.ets | 用户主页（已加关注） |
| pages/ProfilePage.ets | 个人主页（已加自动刷新） |

---

## 七、开发铁律

- 改.ets(含中文): 只用 apply_patch
- 改.ets(纯ASCII): Python open(fp,rb/wb) BOM-free
- 禁止: PowerShell Set-Content/Out-File 写.ets
- 每次功能做完必须 git add && git commit
- 恢复文件用 git checkout HEAD -- file

### 锁释放后提交命令
```powershell
cd D:\Projects\vbdog-pro
git add -A
git commit -m "feat: full report & follow system with UI fixes, notifications, and FollowListPage"
```
