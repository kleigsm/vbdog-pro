-- ============================================
-- 006_get_conversations_rpc.sql
-- 对话列表聚合函数
-- 用法: /rpc/get_conversations body: {"p_user_id": "xxx"}
-- ============================================

CREATE OR REPLACE FUNCTION get_conversations(p_user_id UUID)
RETURNS TABLE(
  user_id UUID,
  nickname TEXT,
  avatar_url TEXT,
  avatar_color TEXT,
  last_message TEXT,
  last_time TIMESTAMPTZ,
  unread_count BIGINT
) AS $$
  WITH pairs AS (
    -- 找到所有与该用户有消息往来的对方
    SELECT DISTINCT
      CASE WHEN from_user_id = p_user_id THEN to_user_id ELSE from_user_id END AS other_id
    FROM messages
    WHERE from_user_id = p_user_id OR to_user_id = p_user_id
  ),
  last_msg AS (
    -- 每个对话的最后一条消息
    SELECT DISTINCT ON (
      CASE WHEN from_user_id = p_user_id THEN to_user_id ELSE from_user_id END
    )
      CASE WHEN from_user_id = p_user_id THEN to_user_id ELSE from_user_id END AS other_id,
      text,
      created_at
    FROM messages
    WHERE from_user_id = p_user_id OR to_user_id = p_user_id
    ORDER BY
      CASE WHEN from_user_id = p_user_id THEN to_user_id ELSE from_user_id END,
      created_at DESC
  ),
  unread AS (
    -- 每个对话的未读数（对方发给我的、当前未计入已读的）
    SELECT
      CASE WHEN from_user_id = p_user_id THEN to_user_id ELSE from_user_id END AS other_id,
      COUNT(*) AS cnt
    FROM messages
    WHERE to_user_id = p_user_id
    GROUP BY CASE WHEN from_user_id = p_user_id THEN to_user_id ELSE from_user_id END
  )
  SELECT
    p.other_id AS user_id,
    u.nickname,
    u.avatar_url,
    u.avatar_color,
    lm.text AS last_message,
    lm.created_at AS last_time,
    COALESCE(ur.cnt, 0) AS unread_count
  FROM pairs p
  JOIN users u ON u.id = p.other_id
  JOIN last_msg lm ON lm.other_id = p.other_id
  LEFT JOIN unread ur ON ur.other_id = p.other_id
  ORDER BY lm.created_at DESC;
$$ LANGUAGE sql STABLE SECURITY DEFINER;
