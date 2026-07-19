-- ============================================
-- 010_update_profile_rpc.sql
-- RPC for editing user profile (nickname/bio)
-- Usage: /rpc/update_profile body: {"p_user_id":"uuid", "p_nickname":"name", "p_bio":"bio"}
-- SECURITY DEFINER bypasses RLS on users table
-- ============================================

CREATE OR REPLACE FUNCTION update_profile(p_user_id text, p_nickname text, p_bio text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users
  SET nickname = p_nickname,
      bio = p_bio
  WHERE id = p_user_id::uuid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found: %', p_user_id;
  END IF;
END;
$$;
