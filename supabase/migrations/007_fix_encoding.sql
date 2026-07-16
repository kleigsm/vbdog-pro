-- ============================================
-- 007_fix_encoding.sql
-- 修复数据编码：删除损坏数据 → 重插正确 UTF-8
-- 在 Supabase SQL Editor 中执行
-- ============================================

-- === 清理损坏数据 ===
DELETE FROM notifications;
DELETE FROM messages;
DELETE FROM comments;
DELETE FROM comment_likes;
DELETE FROM collects;
DELETE FROM likes;
DELETE FROM follows;

-- === 重设用户信息 ===
UPDATE users SET nickname = 'VBDog 社区', bio = 'AI Prompt 创作者社区官方账号', avatar_color = '#FF6B35' WHERE phone = '00000000000';
UPDATE users SET nickname = '陈言之', bio = '独立开发者 | building in public', avatar_color = '#5856D6' WHERE phone = '13800000001';
UPDATE users SET nickname = '林小满', bio = 'UI 设计师转 AI 绘画 | Midjourney 重度用户', avatar_color = '#34C759' WHERE phone = '13800000002';

-- === 重新生成交互数据 ===
DO $$
DECLARE
  u_admin UUID; u1 UUID; u2 UUID; u3 UUID; u4 UUID; u5 UUID; u6 UUID;
  post_ids UUID[];
  p1 UUID; p2 UUID; p3 UUID; p4 UUID; p5 UUID; p6 UUID; p7 UUID; p8 UUID; p9 UUID;
BEGIN
  SELECT id INTO u_admin FROM users WHERE phone = '00000000000';
  SELECT id INTO u1 FROM users WHERE phone = '13800000001';
  SELECT id INTO u2 FROM users WHERE phone = '13800000002';
  SELECT id INTO u3 FROM users WHERE phone = '15715929196';
  SELECT id INTO u4 FROM users WHERE phone = '19084716744';
  SELECT id INTO u5 FROM users WHERE phone = '19999999999';
  SELECT id INTO u6 FROM users WHERE phone = '16666666666';

  SELECT array_agg(id ORDER BY created_at) INTO post_ids FROM posts;
  p1:=post_ids[1]; p2:=post_ids[2]; p3:=post_ids[3]; p4:=post_ids[4];
  p5:=post_ids[5]; p6:=post_ids[6]; p7:=post_ids[7]; p8:=post_ids[8]; p9:=post_ids[9];

  -- 关注关系
  INSERT INTO follows (follower_id, following_id) VALUES
    (u1, u2), (u1, u_admin), (u2, u1), (u2, u_admin),
    (u3, u1), (u3, u_admin), (u4, u2), (u4, u_admin),
    (u5, u1), (u5, u2), (u6, u_admin)
  ON CONFLICT DO NOTHING;

  -- 点赞（每篇 2-4 人）
  INSERT INTO likes (user_id, post_id) VALUES
    (u1,p8),(u2,p8),(u4,p8), (u1,p7),(u3,p7),(u5,p7),
    (u2,p6),(u4,p6),(u_admin,p6), (u1,p5),(u3,p5),
    (u2,p4),(u4,p4),(u5,p4), (u1,p3),(u3,p3),(u_admin,p3),
    (u2,p2),(u4,p2),(u6,p2), (u3,p1),(u5,p1),(u_admin,p1),
    (u1,p9),(u2,p9)
  ON CONFLICT DO NOTHING;

  -- 收藏
  INSERT INTO collects (user_id, post_id) VALUES
    (u1,p6),(u1,p3),(u1,p4), (u2,p8),(u2,p7),(u2,p4),
    (u3,p6),(u3,p8), (u4,p3),(u4,p7),
    (u5,p6),(u5,p8),(u5,p1), (u6,p4),(u6,p7)
  ON CONFLICT DO NOTHING;

  -- 评论
  INSERT INTO comments (id, post_id, user_id, content) VALUES
    (uuid_generate_v4(), p6, u4, '全程自然语言写代码也太酷了！我上周试了用 Claude 写一个 CLI 工具，体验确实丝滑'),
    (uuid_generate_v4(), p6, u1, '同意，关键是 Prompt 要写清楚数据结构，不然 AI 容易自己发挥'),
    (uuid_generate_v4(), p6, u2, '请问部署那一步也是用对话完成的吗？'),
    (uuid_generate_v4(), p3, u3, '第7条过度指定格式太真实了，我以前每次都写请用JSON返回'),
    (uuid_generate_v4(), p3, u1, '其实可以用few-shot替代格式约束，让AI看示例比看规则效果好'),
    (uuid_generate_v4(), p3, u_admin, '精华帖置顶！建议配合我们的 Prompt 模板一起使用效果更佳'),
    (uuid_generate_v4(), p8, u5, '拿去审查了我们项目的代码，发现了3个潜在N+1问题'),
    (uuid_generate_v4(), p8, u2, 'N+1问题经典，我在安全审查prompt里加了SQL注入检测'),
    (uuid_generate_v4(), p4, u1, '月省2万太真实了，我们团队用Claude做Code Review'),
    (uuid_generate_v4(), p4, u4, '客服那块能展开讲讲吗？我们也想用AI做客服'),
    (uuid_generate_v4(), p4, u2, '同问！还有设计那块，Midjourney真的能替代设计师吗？'),
    (uuid_generate_v4(), p4, u5, '省下来的钱建议投到Prompt调优上，ROI比外包高多了'),
    (uuid_generate_v4(), p7, u4, '官方教程来了！这个系列能不能出个视频版？光看文章不过瘾'),
    (uuid_generate_v4(), p7, u_admin, '收到建议！视频版已经在计划中了'),
    (uuid_generate_v4(), p7, u3, '跟着教程走了一遍，确实3天做出来了'),
    (uuid_generate_v4(), p1, u5, '刚从ChatGPT切到Claude，这篇文章来得太及时了'),
    (uuid_generate_v4(), p2, u3, '已收藏。我加了请纠正我的发音这个指令，效果也很好'),
    (uuid_generate_v4(), p2, u1, '可以加一个语法点讲解的环节，让AI不只是纠正还解释原因');

  -- 私信对话
  INSERT INTO messages (from_user_id, to_user_id, text) VALUES
    (u1, u3, '你好，看了你的帖子感触很深，想请教一下你是怎么入门的？'),
    (u3, u1, '我是一步步跟着官方教程走的，推荐先从简单的prompt开始'),
    (u1, u3, '好的谢谢！有没有什么推荐的资源？'),
    (u3, u1, '社区里的教程区有很多好内容，我发你几个链接'),
    (u2, u4, '你那个 VibeCoding 的帖子太赞了！我零基础能上手吗？'),
    (u4, u2, '当然能！从做一个个人主页开始，跟AI描述你想要的样子就行'),
    (u2, u4, '好的我试试！有推荐的工具吗？'),
    (u4, u2, '用Claude就行，我整理了个入门prompt合集发你'),
    (u5, u2, '小满，看到你收藏了我好几篇文章，谢谢支持！'),
    (u2, u5, '老K老师！我最近在用AI写设计说明文档，但总觉得AI写得太官方了'),
    (u5, u2, '加一句话就行：请用朋友聊天的方式写，像在咖啡馆跟我说话'),
    (u1, u_admin, '建议社区加一个Prompt模板集市，让大家可以一键fork别人的模板来改'),
    (u_admin, u1, '好建议！我们已经在规划Prompt工坊功能了，敬请期待');

  -- 通知
  INSERT INTO notifications (user_id, from_user_id, type, related_id, content, read, created_at) VALUES
    (u1, u4, 'follow', NULL, '草莓方糕 关注了你', TRUE, NOW() - INTERVAL '7 days'),
    (u2, u1, 'follow', NULL, '陈言之 关注了你', FALSE, NOW() - INTERVAL '3 days'),
    (u_admin, u4, 'like', p6, '草莓方糕 赞了你的帖子', TRUE, NOW() - INTERVAL '3 days'),
    (u1, u3, 'like', p6, '绿豆方糕 赞了你的帖子', FALSE, NOW() - INTERVAL '2 days'),
    (u_admin, u3, 'comment', p3, '绿豆方糕 评论了你的帖子', FALSE, NOW() - INTERVAL '2 days'),
    (u1, u2, 'comment', p6, '林小满 评论了：请问部署那一步...', TRUE, NOW() - INTERVAL '1 day'),
    (u2, u4, 'follow', NULL, '草莓方糕 关注了你', FALSE, NOW() - INTERVAL '5 days'),
    (u3, u1, 'message', NULL, '陈言之 给你发了一条私信', FALSE, NOW() - INTERVAL '4 days'),
    (u4, u2, 'message', NULL, '林小满 给你发了一条私信', FALSE, NOW() - INTERVAL '2 days'),
    (u_admin, u5, 'collect', p6, '红豆方糕 收藏了你的帖子', TRUE, NOW() - INTERVAL '1 day');

END $$;

-- 同步计数器
UPDATE users SET
  following_count = (SELECT COUNT(*) FROM follows WHERE follower_id = users.id),
  follower_count = (SELECT COUNT(*) FROM follows WHERE following_id = users.id),
  post_count = (SELECT COUNT(*) FROM posts WHERE user_id = users.id);

UPDATE posts SET is_hot = TRUE
WHERE id IN (SELECT post_id FROM likes GROUP BY post_id ORDER BY COUNT(*) DESC LIMIT 5);
