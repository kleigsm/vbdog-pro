-- ============================================
-- VBDog Pro 数据库迁移 v1
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== 用户表 ====================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone TEXT UNIQUE NOT NULL,
  nickname TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url TEXT DEFAULT '',
  avatar_color TEXT DEFAULT '#FF6B35',
  bio TEXT DEFAULT '',
  level INTEGER DEFAULT 1,
  exp INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  follower_count INTEGER DEFAULT 0,
  post_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== 帖子表 ====================
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  prompt TEXT DEFAULT '',
  category TEXT DEFAULT 'Prompt',
  model TEXT DEFAULT 'Claude',
  tags TEXT[] DEFAULT '{}',
  like_count INTEGER DEFAULT 0,
  collect_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  is_hot BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== 点赞表 ====================
CREATE TABLE IF NOT EXISTS likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- ==================== 收藏表 ====================
CREATE TABLE IF NOT EXISTS collects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

-- ==================== 评论表 ====================
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  reply_to UUID REFERENCES comments(id) ON DELETE SET NULL,
  like_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== 评论点赞表 ====================
CREATE TABLE IF NOT EXISTS comment_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, comment_id)
);

-- ==================== 关注表 ====================
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- ==================== 私信表 ====================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== 通知表 ====================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  from_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  related_id UUID,
  content TEXT DEFAULT '',
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 索引
-- ============================================
CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_category ON posts(category);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_likes ON posts(like_count DESC);
CREATE INDEX IF NOT EXISTS idx_likes_post ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_collects_post ON collects(post_id);
CREATE INDEX IF NOT EXISTS idx_collects_user ON collects(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_messages_users ON messages(from_user_id, to_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- ============================================
-- 触发器：自动更新评论计数
-- ============================================
CREATE OR REPLACE FUNCTION update_comment_count() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_comment_count ON comments;
CREATE TRIGGER trigger_comment_count
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_count();

-- ============================================
-- 触发器：自动更新点赞计数
-- ============================================
CREATE OR REPLACE FUNCTION update_like_count() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET like_count = like_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_like_count ON likes;
CREATE TRIGGER trigger_like_count
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION update_like_count();

-- ============================================
-- 触发器：自动更新收藏计数
-- ============================================
CREATE OR REPLACE FUNCTION update_collect_count() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET collect_count = collect_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET collect_count = collect_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_collect_count ON collects;
CREATE TRIGGER trigger_collect_count
  AFTER INSERT OR DELETE ON collects
  FOR EACH ROW EXECUTE FUNCTION update_collect_count();

-- ============================================
-- RLS 策略（允许匿名读、需认证写）
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE collects ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 公开可读
CREATE POLICY "public_read_users" ON users FOR SELECT USING (true);
CREATE POLICY "public_read_posts" ON posts FOR SELECT USING (true);
CREATE POLICY "public_read_comments" ON comments FOR SELECT USING (true);

-- 仅认证用户可写
CREATE POLICY "auth_insert_posts" ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "auth_delete_posts" ON posts FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "auth_insert_likes" ON likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "auth_delete_likes" ON likes FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "auth_insert_collects" ON collects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "auth_delete_collects" ON collects FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "auth_insert_comments" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "auth_delete_comments" ON comments FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "auth_insert_follows" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "auth_delete_follows" ON follows FOR DELETE USING (auth.uid() = follower_id);
CREATE POLICY "auth_insert_messages" ON messages FOR INSERT WITH CHECK (auth.uid() = from_user_id);
CREATE POLICY "auth_select_messages" ON messages FOR SELECT USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);
CREATE POLICY "auth_select_notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "auth_update_notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 登录/注册存储过程
-- ============================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION register(p_phone TEXT, p_nickname TEXT, p_password TEXT)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_user users;
BEGIN
  INSERT INTO users (phone, nickname, password_hash, avatar_color)
  VALUES (p_phone, p_nickname, crypt(p_password, gen_salt('bf')),
          (ARRAY['#FF6B35','#FF3B30','#FF9500','#FFCC00','#34C759','#007AFF','#5856D6','#AF52DE','#FF2D55','#00C7BE'])[floor(random()*10+1)])
  RETURNING id INTO v_user_id;

  SELECT * INTO v_user FROM users WHERE id = v_user_id;
  RETURN row_to_json(v_user);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION login(p_phone TEXT, p_password TEXT)
RETURNS JSON AS $$
DECLARE
  v_user users;
BEGIN
  SELECT * INTO v_user FROM users
  WHERE phone = p_phone AND password_hash = crypt(p_password, password_hash);

  IF v_user.id IS NULL THEN
    RAISE EXCEPTION 'Invalid phone or password';
  END IF;

  RETURN row_to_json(v_user);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 种子数据
-- ============================================
INSERT INTO users (phone, nickname, bio, level, exp, password_hash) VALUES
  ('00000000000', 'VBDog 官方', '管理员账号', 9, 99999, crypt('admin123', gen_salt('bf'))),
  ('13800000001', 'Prompt 大师', '热爱分享 AI Prompt 的创作者', 5, 1500, crypt('123456', gen_salt('bf'))),
  ('13800000002', 'AI 探险家', '在 AI 世界里探索无限可能', 3, 450, crypt('123456', gen_salt('bf')))
ON CONFLICT (phone) DO NOTHING;

-- 测试帖子（VBDog 官方发布）
DO $$
DECLARE
  v_admin_id UUID;
  v_user1_id UUID;
  v_user2_id UUID;
  v_post1 UUID;
  v_post2 UUID;
  v_post3 UUID;
  v_post4 UUID;
BEGIN
  SELECT id INTO v_admin_id FROM users WHERE phone = '00000000000';
  SELECT id INTO v_user1_id FROM users WHERE phone = '13800000001';
  SELECT id INTO v_user2_id FROM users WHERE phone = '13800000002';

  -- 只在没有帖子时插入种子数据
  IF (SELECT COUNT(*) FROM posts) = 0 THEN
    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_admin_id, '高效的代码审查 Prompt 模板',
       '分享一个我常用的代码审查 Prompt，帮助 AI 更好地理解代码上下文，给出有深度的审查意见。',
       '你是一位资深代码审查专家。请审查以下代码，重点关注：\n1. 安全隐患\n2. 性能瓶颈\n3. 代码可维护性\n对于每个问题，请给出具体的改进建议和代码示例。',
       'Prompt', 'Claude', ARRAY['代码审查', '模板']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_admin_id, '用 Claude 生成精美的数据可视化图表',
       '无需写一行前端代码，直接用 Prompt 让 Claude 生成交互式图表',
       '请根据以下数据集生成一个交互式的柱状图，使用 Chart.js 库，配色方案使用暖色调，支持鼠标悬停显示详细数据。\n\n数据：[...]',
       'Skill', 'Claude', ARRAY['可视化', '数据', 'Chart.js']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_user1_id, 'Vibe Coding 实战：3 小时做出一个 Todo App',
       '全程用自然语言和 Claude 对话，从零到一做出了一个完整的 Todo 应用，分享一下过程和心得。',
       '我想创建一个 Todo 应用，需要以下功能：添加任务、标记完成、删除任务、按优先级排序、数据持久化。请一步一步引导我完成。',
       'VibeCoding', 'Claude', ARRAY['VibeCoding', '实战', 'Todo']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_user1_id, 'GPT-4o vs Claude Sonnet 4 写诗对比评测',
       '用同样的 Prompt 让两个模型写诗，结果太有意思了',
       '请用李白的风格写一首七言绝句，主题是「人工智能时代的孤独」',
       '教程', 'ChatGPT', ARRAY['对比评测', 'GPT-4o', 'Claude']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_user2_id, 'AI 辅助写 API 文档的神仙 Prompt',
       '告别枯燥的文档编写，一个 Prompt 让 AI 帮你生成规范的 API 文档',
       '请根据以下 Express.js 路由代码，生成 OpenAPI 3.0 规范的 API 文档，包括请求参数、响应格式、错误码和示例。',
       'Prompt', 'Claude', ARRAY['API', '文档', '技巧']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_user2_id, '开发工具懒人包：我的 AI 编程工作流',
       '分享经过 100+ 小时打磨后的个人 AI 编程工作流配置',
       '请帮我设计一套完整的 AI 辅助编程工作流，包括代码生成、审查、测试、部署环节，每个环节推荐对应的工具和 Prompt 模板。',
       '工具', 'Claude', ARRAY['工作流', '效率', '工具推荐']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_admin_id, '用 AI Diff Debug 比 console.log 快 10 倍',
       '快速精准定位 bug 的终极技巧',
       '我有一段代码出现了预期之外的输出。请分析以下代码，找出潜在的 bug 并解释原因，然后给出修复后的代码。\n\n代码：[buggy code here]',
       '教程', 'Claude', ARRAY['Debug', '技巧', '效率']);

    INSERT INTO posts (user_id, title, content, prompt, category, model, tags) VALUES
      (v_user1_id, 'Prompt Engineering 入门指南（2026 版）',
       '面向新手的 Prompt 工程完整教程，从基础到进阶，附实战案例',
       '请用通俗易懂的语言解释什么是 Prompt Engineering，并给出 5 个不同难度级别的 Prompt 示例，涵盖零样本、少样本、思维链等技巧。',
       '教程', 'ChatGPT', ARRAY['入门', 'Prompt Engineering', '教程']);

  END IF;
END $$;
