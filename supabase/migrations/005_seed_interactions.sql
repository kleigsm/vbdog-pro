-- ============================================
-- 005_seed_interactions.sql
-- 社区复活计划：真人化用户 + 完整社交交互数据
-- ============================================

-- === 第一步：重命名现有用户为真人风格 ===
UPDATE users SET nickname = 'VBDog 社区', bio = 'AI Prompt 创作者社区官方账号 | 发现 · 分享 · 创造', avatar_color = '#FF6B35'
WHERE phone = '00000000000';

UPDATE users SET nickname = '陈言之', bio = '独立开发者 | building in public | 专注 AI 工具链', avatar_color = '#5856D6'
WHERE phone = '13800000001';

UPDATE users SET nickname = '林小满', bio = 'UI 设计师转 AI 绘画 | 把想象力变成像素 | Midjourney 重度用户', avatar_color = '#34C759'
WHERE phone = '13800000002';

UPDATE users SET nickname = '周默', bio = '后端工程师 | Claude 死忠粉 | talk is cheap, show me the prompt', avatar_color = '#007AFF'
WHERE phone = '13800000003';

UPDATE users SET nickname = '苏晚晴', bio = '产品经理 | VibeCoding 布道者 | 用对话写代码的人', avatar_color = '#AF52DE'
WHERE phone = '13800000004';

UPDATE users SET nickname = '老 K', bio = '自由职业者 | AI 写作教练 | 让 AI 替你写，你只负责想', avatar_color = '#FF9500'
WHERE phone = '13800000005';

-- === 第二步：生成社交交互数据 ===
DO $$
DECLARE
  u_admin UUID; u1 UUID; u2 UUID; u3 UUID; u4 UUID; u5 UUID;
  post_ids UUID[];
  p1 UUID; p2 UUID; p3 UUID; p4 UUID; p5 UUID; p6 UUID; p7 UUID; p8 UUID;
  p9 UUID; p10 UUID; p11 UUID; p12 UUID; p13 UUID; p14 UUID; p15 UUID; p16 UUID;
  p17 UUID; p18 UUID; p19 UUID; p20 UUID;
  c1 UUID; c2 UUID; c3 UUID; c4 UUID; c5 UUID; c6 UUID; c7 UUID; c8 UUID;
  c9 UUID; c10 UUID; c11 UUID; c12 UUID; c13 UUID; c14 UUID; c15 UUID;
BEGIN
  -- Get user IDs
  SELECT id INTO u_admin FROM users WHERE phone = '00000000000';
  SELECT id INTO u1 FROM users WHERE phone = '13800000001';
  SELECT id INTO u2 FROM users WHERE phone = '13800000002';
  SELECT id INTO u3 FROM users WHERE phone = '13800000003';
  SELECT id INTO u4 FROM users WHERE phone = '13800000004';
  SELECT id INTO u5 FROM users WHERE phone = '13800000005';

  -- Get post IDs in creation order
  SELECT array_agg(id ORDER BY created_at) INTO post_ids FROM posts;

  -- Assign to variables (up to 20)
  p1  := post_ids[1];  p2  := post_ids[2];  p3  := post_ids[3];  p4  := post_ids[4];
  p5  := post_ids[5];  p6  := post_ids[6];  p7  := post_ids[7];  p8  := post_ids[8];
  p9  := post_ids[9];  p10 := post_ids[10]; p11 := post_ids[11]; p12 := post_ids[12];
  p13 := post_ids[13]; p14 := post_ids[14]; p15 := post_ids[15]; p16 := post_ids[16];
  p17 := post_ids[17]; p18 := post_ids[18]; p19 := post_ids[19]; p20 := post_ids[20];

  -- === 关注关系（12条） ===
  INSERT INTO follows (follower_id, following_id) VALUES (u1, u3), (u1, u4), (u1, u_admin)
  ON CONFLICT DO NOTHING;
  INSERT INTO follows (follower_id, following_id) VALUES (u2, u4), (u2, u5), (u2, u_admin)
  ON CONFLICT DO NOTHING;
  INSERT INTO follows (follower_id, following_id) VALUES (u3, u1), (u3, u_admin)
  ON CONFLICT DO NOTHING;
  INSERT INTO follows (follower_id, following_id) VALUES (u4, u1), (u4, u2), (u4, u3), (u4, u_admin)
  ON CONFLICT DO NOTHING;
  INSERT INTO follows (follower_id, following_id) VALUES (u5, u2), (u5, u_admin)
  ON CONFLICT DO NOTHING;

  -- === 点赞记录（每篇帖子2-5人点赞） ===
  INSERT INTO likes (user_id, post_id) VALUES
    (u1, p1), (u4, p1), (u5, p1),
    (u2, p2), (u3, p2), (u5, p2),
    (u1, p3), (u4, p3), (u2, p3), (u_admin, p3),
    (u3, p4), (u5, p4),
    (u2, p5), (u4, p5), (u_admin, p5),
    (u1, p6), (u3, p6), (u4, p6),
    (u2, p7), (u5, p7), (u_admin, p7),
    (u3, p8), (u1, p8), (u4, p8), (u5, p8),
    (u4, p9), (u2, p9),
    (u1, p10), (u3, p10), (u5, p10), (u_admin, p10),
    (u2, p11), (u4, p11),
    (u5, p12), (u1, p12), (u_admin, p12),
    (u3, p13), (u4, p13), (u2, p13),
    (u1, p14), (u5, p14),
    (u2, p15), (u3, p15), (u4, p15), (u_admin, p15),
    (u4, p16), (u5, p16),
    (u1, p17), (u2, p17), (u3, p17),
    (u5, p18), (u_admin, p18),
    (u3, p19), (u1, p19), (u4, p19),
    (u2, p20), (u5, p20), (u_admin, p20)
  ON CONFLICT DO NOTHING;

  -- === 收藏记录（15条） ===
  INSERT INTO collects (user_id, post_id) VALUES
    (u1, p3), (u1, p8), (u1, p15),
    (u2, p5), (u2, p11), (u2, p20),
    (u3, p1), (u3, p10), (u3, p13),
    (u4, p6), (u4, p15),
    (u5, p2), (u5, p7), (u5, p12), (u5, p18)
  ON CONFLICT DO NOTHING;

  -- === 评论（25条，含楼中楼） ===

  -- p3 (VibeCoding实战) 热门讨论
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p3, u4, '全程自然语言写代码也太酷了！我上周试了用 Claude 写一个 CLI 工具，体验确实丝滑', NOW() - INTERVAL '2 days') RETURNING id INTO c1;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p3, u1, '同意，关键是 Prompt 要写清楚数据结构，不然 AI 容易自己发挥', c1, NOW() - INTERVAL '2 days' + INTERVAL '3 hours') RETURNING id INTO c2;
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p3, u2, '请问部署那一步也是用对话完成的吗？还是手动部署的', NOW() - INTERVAL '1 day') RETURNING id INTO c3;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p3, u4, '部署部分我是让 Claude 生成 Dockerfile + docker-compose，基本一键搞定', c3, NOW() - INTERVAL '1 day' + INTERVAL '2 hours');

  -- p5 (Prompt反模式) 技术讨论
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p5, u3, '第7条过度指定格式太真实了，我以前每次都写请用JSON返回，结果AI反而被束缚', NOW() - INTERVAL '3 days') RETURNING id INTO c4;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p5, u1, '其实可以用few-shot替代格式约束，让AI看示例比看规则效果好', c4, NOW() - INTERVAL '3 days' + INTERVAL '5 hours');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p5, u_admin, '精华帖置顶！建议配合我们的 Prompt 模板一起使用效果更佳', NOW() - INTERVAL '2 days');

  -- p8 (英语学习套件)
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p8, u5, '已收藏。我加了请纠正我的发音这个指令，效果也很好', NOW() - INTERVAL '4 days') RETURNING id INTO c5;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p8, u3, '可以加一个语法点讲解的环节，让AI不只是纠正还解释原因', c5, NOW() - INTERVAL '4 days' + INTERVAL '1 hour');

  -- p12 (小团队AI替代外包) 爆款讨论
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p12, u1, '月省2万太真实了，我们团队用Claude做Code Review，高级工程师的时间省了一半', NOW() - INTERVAL '1 day') RETURNING id INTO c6;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p12, u4, '客服那块能展开讲讲吗？我们也想用AI做客服，但担心回复太机械', c6, NOW() - INTERVAL '1 day' + INTERVAL '4 hours') RETURNING id INTO c7;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p12, u2, '同问！还有设计那块，Midjourney真的能替代设计师吗？', c6, NOW() - INTERVAL '1 day' + INTERVAL '6 hours');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p12, u5, '省下来的钱建议投到Prompt调优上，ROI比外包高多了', NOW() - INTERVAL '12 hours');

  -- p15 (从零到一VibeCoding) 官方帖子互动
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p15, u4, '官方教程来了！这个系列能不能出个视频版？光看文章不过瘾', NOW() - INTERVAL '5 days') RETURNING id INTO c8;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p15, u_admin, '收到建议！视频版已经在计划中了', c8, NOW() - INTERVAL '5 days' + INTERVAL '6 hours');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p15, u3, '跟着教程走了一遍，确实3天做出来了。不过UI美化还得靠AI多迭代几轮', NOW() - INTERVAL '4 days');

  -- 其他帖子的零散评论
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p20, u5, '刚从ChatGPT切到Claude，这篇文章来得太及时了', NOW() - INTERVAL '6 hours');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p1, u3, '拿去审查了我们项目的代码，发现了3个潜在N+1问题，已经修复', NOW() - INTERVAL '6 days') RETURNING id INTO c10;
  INSERT INTO comments (id, post_id, user_id, content, reply_to, created_at) VALUES
    (uuid_generate_v4(), p1, u5, 'N+1问题经典，我在安全审查prompt里加了SQL注入检测，也很有用', c10, NOW() - INTERVAL '6 days' + INTERVAL '8 hours');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p18, u1, '上下文窗口管理那块写得特别好，我之前就是没意识到需要主动压缩历史', NOW() - INTERVAL '8 hours');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p10, u4, '保存了！下次遇到bug直接复制粘贴，告别 Stack Overflow', NOW() - INTERVAL '4 days');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p6, u2, '已打印贴墙上！每个风格都试了一遍，cyberpunk和watercolor效果最稳定', NOW() - INTERVAL '3 days');
  INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES
    (uuid_generate_v4(), p19, u3, '90%覆盖率有点夸张了吧，我试了大概到75%左右，边缘情况还是得自己补', NOW() - INTERVAL '2 days');

  -- === 私信对话（4个对话线程） ===

  -- 对话1：陈言之 <-> 周默（技术交流）
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u1, u3, '周默你好，看了你关于 Claude Sonnet 的使用心得，想请教一下上下文窗口管理你是怎么做的？', NOW() - INTERVAL '5 days');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u3, u1, '我用了一个简单的策略：每5轮对话让AI做一次摘要，然后把摘要替换掉前5轮，这样永远不爆窗口', NOW() - INTERVAL '5 days' + INTERVAL '10 minutes');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u1, u3, '妙啊！比硬截断智能多了。你是让AI自己摘要还是写了个固定prompt？', NOW() - INTERVAL '5 days' + INTERVAL '15 minutes');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u3, u1, '固定prompt：请用不超过200字总结以上对话的核心信息和关键决策点。我发你模板？', NOW() - INTERVAL '5 days' + INTERVAL '30 minutes');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u1, u3, '求模板！你试过 Claude 的新 thinking 模式没？', NOW() - INTERVAL '4 days');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u3, u1, '试了，复杂推理任务提升明显，但简单问答有点overkill。周末会发一篇 thinking 模式的实战文章', NOW() - INTERVAL '4 days' + INTERVAL '1 hour');

  -- 对话2：林小满 <-> 苏晚晴（创作交流）
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u2, u4, '晚晴姐，你那个 VibeCoding 的帖子太赞了！我虽然是做设计的，但也想试试，零基础能上手吗？', NOW() - INTERVAL '3 days');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u4, u2, '当然能！我建议从做一个个人主页开始，不需要写一行代码，跟AI描述你想要的样子就行', NOW() - INTERVAL '3 days' + INTERVAL '20 minutes');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u2, u4, '好的我试试！有什么常用的prompt模板推荐吗？', NOW() - INTERVAL '2 days');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u4, u2, '我整理了一个VibeCoding入门prompt合集，发你了。对了，你在做的AI绘画项目需要程序员配合的话可以找我', NOW() - INTERVAL '2 days' + INTERVAL '40 minutes');

  -- 对话3：老K --> 林小满（写作指导）
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u5, u2, '小满，看到你收藏了我好几篇文章，谢谢支持！有什么想了解的可以随时问我', NOW() - INTERVAL '2 days');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u2, u5, '老K老师！我最近在用AI写设计说明文档，但总觉得AI写得太官方了，不够亲切，有办法调整吗？', NOW() - INTERVAL '2 days' + INTERVAL '1 hour');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u5, u2, '加一句话就行：请用朋友聊天的方式写，像在咖啡馆跟我说话。试试看效果', NOW() - INTERVAL '2 days' + INTERVAL '2 hours');

  -- 对话4：陈言之 --> 官方（反馈建议）
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u1, u_admin, '建议社区加一个Prompt模板集市，让大家可以一键fork别人的模板来改', NOW() - INTERVAL '1 day');
  INSERT INTO messages (from_user_id, to_user_id, text, created_at) VALUES
    (u_admin, u1, '好建议！我们已经在规划Prompt工坊功能了，到时候会支持模板发布和一键改编，敬请期待', NOW() - INTERVAL '1 day' + INTERVAL '3 hours');

  -- === 通知（20条，混合已读/未读） ===
  INSERT INTO notifications (user_id, from_user_id, type, related_id, content, read, created_at) VALUES
    (u1, u4, 'follow', NULL, '苏晚晴 关注了你', TRUE, NOW() - INTERVAL '7 days'),
    (u3, u1, 'follow', NULL, '陈言之 关注了你', TRUE, NOW() - INTERVAL '6 days'),
    (u1, u3, 'follow', NULL, '周默 关注了你', FALSE, NOW() - INTERVAL '5 days'),
    (u4, u2, 'follow', NULL, '林小满 关注了你', TRUE, NOW() - INTERVAL '4 days'),
    (u2, u4, 'follow', NULL, '苏晚晴 关注了你', FALSE, NOW() - INTERVAL '3 days'),
    (u_admin, u4, 'like', p3, '苏晚晴 赞了你的帖子', TRUE, NOW() - INTERVAL '3 days'),
    (u4, u1, 'like', p8, '陈言之 赞了你的帖子', FALSE, NOW() - INTERVAL '2 days'),
    (u_admin, u2, 'like', p5, '林小满 赞了你的帖子', TRUE, NOW() - INTERVAL '5 days'),
    (u1, u5, 'like', p12, '老K 赞了你的帖子', FALSE, NOW() - INTERVAL '1 day'),
    (u5, u1, 'like', p18, '陈言之 赞了你的帖子', FALSE, NOW() - INTERVAL '8 hours'),
    (u_admin, u3, 'comment', p1, '周默 评论了你的帖子', TRUE, NOW() - INTERVAL '6 days'),
    (u4, u2, 'comment', p3, '林小满 评论了：请问部署也是用对话完成的吗？', TRUE, NOW() - INTERVAL '1 day'),
    (u1, u4, 'comment', p12, '苏晚晴 评论了：月省2万太真实了', FALSE, NOW() - INTERVAL '1 day'),
    (u2, u4, 'comment', p15, '苏晚晴 评论了：官方教程来了！', TRUE, NOW() - INTERVAL '5 days'),
    (u3, u1, 'comment', p18, '陈言之 评论了：上下文窗口管理写得好', FALSE, NOW() - INTERVAL '8 hours'),
    (u1, u3, 'collect', p10, '周默 收藏了你的帖子', TRUE, NOW() - INTERVAL '4 days'),
    (u2, u5, 'collect', p7, '老K 收藏了你的帖子', FALSE, NOW() - INTERVAL '3 days'),
    (u_admin, u4, 'collect', p15, '苏晚晴 收藏了你的帖子', TRUE, NOW() - INTERVAL '2 days'),
    (u3, u1, 'message', NULL, '陈言之 给你发了一条私信', FALSE, NOW() - INTERVAL '1 day'),
    (u1, u3, 'reply', NULL, '周默 回复了你的评论', TRUE, NOW() - INTERVAL '5 days');

END $$;

-- === 最终清理：同步计数器 ===
UPDATE users SET
  following_count = (SELECT COUNT(*) FROM follows WHERE follower_id = users.id),
  follower_count = (SELECT COUNT(*) FROM follows WHERE following_id = users.id),
  post_count = (SELECT COUNT(*) FROM posts WHERE user_id = users.id);

-- 将点赞数最多的 5 篇标记为热门
UPDATE posts SET is_hot = TRUE
WHERE id IN (
  SELECT post_id FROM likes GROUP BY post_id ORDER BY COUNT(*) DESC LIMIT 5
);
