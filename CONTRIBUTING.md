# VBDog Pro Git & Commit 规范

## 分支策略

```
master ←── 始终可编译、可运行
  │
  ├── feat/dark-mode     ← 一个功能一个分支
  ├── feat/image-upload
  └── feat/report-block
```

- `master` 永不直接 commit，只接受 merge
- 每个功能开 `feat/xxx` 分支，完成后 squash merge 回 master
- 紧急修复开 `fix/xxx`

## Commit 粒度

**一个功能 = 一个 commit**，不要拆散也不要混在一起。

```
✅ feat: 暗黑模式 -- 14 页全局接入 dark token + SettingsPage 开关联动
❌ fix: Index.ets + FeedPage.ets 暗黑模式（BOM-free 字节级替换）  ← 这种应该 amend
```

在分支上反复 commit → 最终 push 前 `git rebase -i HEAD~N` 把所有修复合并成一条干净 commit。

## Commit Message 格式

```
<type>: <简短中文描述>

- 具体改动点
- 具体改动点
```

| type | 场景 |
|---|---|
| `feat` | 新功能 |
| `fix` | 修 bug |
| `refactor` | 重构（不改变行为） |
| `style` | 纯样式/格式化 |
| `docs` | 文档 |
| `migration` | 数据库迁移 |

## 编码安全铁律

**绝不**用 PowerShell 修改含中文的 `.ets` 文件。

| 操作 | 工具 |
|---|---|
| 改 ArkTS 文件 | Python `open(fp, 'rb')` / `open(fp, 'wb')` |
| 改纯 ASCII 的 `.json` `.sql` | 随便 |
| 精确插入/替换（不碰中文行） | `apply_patch` |

## 推送前检查清单

- [ ] `git log --oneline -5` -- 最近 5 条 commit 都说得清是什么功能？
- [ ] 有没有连续 3 条以上的 `fix` 开头的 commit？→ 该 squash 了
- [ ] `git diff origin/master` 和当前分支的改动量是否合理？
- [ ] 编译过了吗？

## 示例

```
feat: 图片上传

- posts 表加 images TEXT[] 列
- CreatePage 系统相册选择 + 缩略图预览
- PostDetailPage 九宫格展示
- Supabase Storage post-images bucket
```
