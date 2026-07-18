@echo off
curl.exe -s -S "https://bxecdhlbnpwahwswnqzr.supabase.co/rest/v1/posts?select=count" -H "apikey: %SUPABASE_SERVICE_ROLE_KEY%" -H "Authorization: Bearer %SUPABASE_SERVICE_ROLE_KEY%" -H "Accept-Profile: meta"
