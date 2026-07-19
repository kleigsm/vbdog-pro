@echo off
REM Test the update_profile RPC directly
REM Usage: test_update_profile.cmd <user_id> <nickname> <bio>

set USER_ID=%1
set NICKNAME=%2
set BIO=%3

set SUPABASE_URL=https://bxecdhlbnpwahwswnqzr.supabase.co
set KEY=sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU

echo ========================================
echo Testing update_profile RPC
echo ========================================
echo.
echo --- Step 1: Call RPC ---
curl.exe -s -w "\n\nHTTP_CODE: %%{http_code}" -X POST "%SUPABASE_URL%/rest/v1/rpc/update_profile" --max-time 15 -H "apikey: %KEY%" -H "Authorization: Bearer %KEY%" -H "Content-Type: application/json" -d "{\"p_user_id\":\"%USER_ID%\",\"p_nickname\":\"%NICKNAME%\",\"p_bio\":\"%BIO%\"}"
echo.
echo.
echo --- Step 2: Verify user record ---
curl.exe -s -w "\n\nHTTP_CODE: %%{http_code}" "%SUPABASE_URL%/rest/v1/users?id=eq.%USER_ID%&select=nickname,bio" --max-time 10 -H "apikey: %KEY%" -H "Authorization: Bearer %KEY%"
echo.
echo ========================================
