-- 004_get_posts_rpc.sql
-- 创建 get_posts RPC 函数，替代 GET /posts

CREATE OR REPLACE FUNCTION get_posts(p_category TEXT DEFAULT NULL, p_sort TEXT DEFAULT 'latest', p_page INTEGER DEFAULT 0)
RETURNS SETOF posts AS $$
BEGIN
  IF p_category IS NOT NULL AND p_category <> '' THEN
    IF p_sort = 'hot' THEN
      RETURN QUERY SELECT * FROM posts WHERE category = p_category ORDER BY like_count DESC LIMIT 20 OFFSET p_page * 20;
    ELSE
      RETURN QUERY SELECT * FROM posts WHERE category = p_category ORDER BY created_at DESC LIMIT 20 OFFSET p_page * 20;
    END IF;
  ELSE
    IF p_sort = 'hot' THEN
      RETURN QUERY SELECT * FROM posts ORDER BY like_count DESC LIMIT 20 OFFSET p_page * 20;
    ELSE
      RETURN QUERY SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET p_page * 20;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
