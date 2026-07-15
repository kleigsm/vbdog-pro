-- ============================================
-- 003_more_seed.sql
-- 补充种子数据：更多帖子 + 评论 + 点赞
-- ============================================

-- 添加更多测试用户
INSERT INTO users (phone, nickname, bio, level, exp, password_hash, avatar_color)
SELECT '13800000003', 'Claude 玩家', '专注 Claude Prompt 调优', 4, 800, crypt('123456', gen_salt('bf')), '#5856D6'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE phone = '13800000003');

INSERT INTO users (phone, nickname, bio, level, exp, password_hash, avatar_color)
SELECT '13800000004', 'AI 画家', '用 AI 创作视觉艺术作品', 3, 500, crypt('123456', gen_salt('bf')), '#34C759'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE phone = '13800000004');

INSERT INTO users (phone, nickname, bio, level, exp, password_hash, avatar_color)
SELECT '13800000005', '全栈 Prompt 工程师', 'Prompt is all you need', 6, 3000, crypt('123456', gen_salt('bf')), '#AF52DE'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE phone = '13800000005');

-- 补充更多帖子
DO $$
DECLARE
  v_u1 UUID; v_u2 UUID; v_u3 UUID; v_u4 UUID; v_u5 UUID; v_ad UUID;
BEGIN
  SELECT id INTO v_ad FROM users WHERE phone = '00000000000';
  SELECT id INTO v_u1 FROM users WHERE phone = '13800000001';
  SELECT id INTO v_u2 FROM users WHERE phone = '13800000002';
  SELECT id INTO v_u3 FROM users WHERE phone = '13800000003';
  SELECT id INTO v_u4 FROM users WHERE phone = '13800000004';
  SELECT id INTO v_u5 FROM users WHERE phone = '13800000005';

  -- 只在帖子少于 12 篇时补充
  IF (SELECT COUNT(*) FROM posts) < 12 THEN

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u3, '如何让 AI 写出更有人味的中文',
     '经过上百次实验总结的中文 Prompt 优化技巧',
     '请用口语化、自然的中文回答以下问题，避免翻译腔和官方口吻，适当加入幽默和个人观点。',
     'Tutorial', 'Claude', ARRAY['中文优化','技巧','实验'], 36);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u4, '用 Midjourney + ChatGPT 双 AI 创作插画',
     'AI 绘画工作流分享：从创意构思到成稿全过程',
     '我有一篇小说片段：[文本]，请根据情节生成 Midjourney 提示词，风格要求：宫崎骏风格，柔和水彩，温暖色调。',
     'Tool', 'ChatGPT', ARRAY['Midjourney','工作流','插画'], 52);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u5, 'Prompt 反模式：那些让你白费 token 的常见错误',
     '总结 10 个最常见的 Prompt 编写误区，帮你省钱省时间',
     '请列举 Prompt 设计中常见的 10 个错误或反模式，每个给出错误示例和正确示例，并解释原因。',
     'Tutorial', 'Claude', ARRAY['反模式','优化','效率'], 89);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u3, '程序员必备的 5 个 Debug Prompt',
     '保存这 5 个模板，遇到 bug 不慌',
     '以下代码出现了 [错误描述]，请逐行分析可能的原因，并给出至少 3 种不同的解决方案，按推荐度排序。',
     'Prompt', 'Claude', ARRAY['Debug','模板','程序员'], 67);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_ad, '从零到一：用 Vibe Coding 开发了一个完整 App',
     '全程用自然语言对话，没写一行代码，3 天做出社区应用',
     '请引导我逐步开发一个 [应用类型]，从数据模型开始，逐层构建功能，每步给出完整可运行代码。',
     'VibeCoding', 'Claude', ARRAY['VibeCoding','从零到一','实战'], 120);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u4, 'AI 绘画 Prompt 词典：100 个风格关键词',
     '整理了控制画面风格的 100+ 个关键词，按类别分类',
     '请按以下类别整理 AI 绘画的风格关键词：\n- 艺术流派（10个）\n- 光照效果（10个）\n- 构图方式（10个）\n每个关键词附带英文原文和简短说明。',
     'Skill', 'ChatGPT', ARRAY['绘画','词典','关键词'], 78);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u2, '分享我的 AI 辅助学英语 Prompt 套件',
     '听说读写全覆盖，英语学习效率提升了 3 倍',
     '你现在是一位精通中英双语的语言教练。请用英文和我对话，纠正我的语法错误，给出自然的表达建议。难度：中级。',
     'Skill', 'Claude', ARRAY['英语学习','套件','效率'], 45);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u5, '多轮对话 Prompt 设计指南',
     '如何让 AI 在长对话中保持上下文一致性',
     '请分析以下长对话片段中的信息丢失问题，并给出改进后的多轮对话系统提示词设计策略。要求覆盖：记忆机制、上下文窗口管理、话题切换检测。',
     'Tutorial', 'Claude', ARRAY['多轮对话','设计','进阶'], 33);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u1, '用 Prompt 自动生成单元测试，代码覆盖率提升到 90%',
     '一个 Prompt 让 AI 给整个项目写测试，还能自动 Mock 依赖',
     '请为以下 TypeScript 函数生成完整的 Jest 单元测试，包括：正常用例、边界情况、异常处理、Mock 外部依赖。覆盖率目标 > 90%。',
     'Prompt', 'Copilot', ARRAY['单元测试','自动化','Jest'], 41);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u3, '从 ChatGPT 到 Claude 迁移指南',
     '两个平台的 Prompt 写法差异全总结',
     '请对比 ChatGPT 和 Claude 在处理以下场景时的差异：代码生成、数据分析、创意写作。给出每类场景在两个平台上的最佳 Prompt 写法。',
     'Tutorial', 'ChatGPT', ARRAY['迁移','对比','指南'], 56);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u4, 'AI 生成视频脚本的完整工作流',
     '从大纲到分镜，AI 全程参与的视频创作实践',
     '请根据以下主题生成一个 3 分钟短视频的完整脚本：包含开场 hook、主体内容（3 个要点）、结尾 CTA。风格要求：快节奏、信息密度高、适合抖音/TikTok。',
     'Skill', 'Claude', ARRAY['视频','工作流','脚本'], 63);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags, like_count) VALUES
    (v_u2, '小团队用 AI 替代 3 个外包岗位的实操经验',
     '我们公司用 AI 做设计、写文档、回复客服，省了每月 2 万',
     '请为一家 10 人创业公司设计一套 AI 工具集成方案，覆盖：UI 设计、技术文档、客户支持。列出每个环节的工具选择和 Prompt 模板。',
     'Tool', 'Claude', ARRAY['创业','成本','实践'], 151);

  END IF;
END $$;
