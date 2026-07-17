-- 008_post_images.sql
-- 帖子图片支持
ALTER TABLE posts ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}';
