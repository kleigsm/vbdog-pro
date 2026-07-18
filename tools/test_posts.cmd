@echo off
REM Try with the known proxy
curl.exe -s -S -x http://127.0.0.1:7897 "https://bxecdhlbnpwahwswnqzr.supabase.co/rest/v1/posts?select=*&limit=20&offset=0&order=createdAt.desc" -H "apikey: sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU" -H "Authorization: Bearer sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU"
echo EXIT_CODE=%ERRORLEVEL%
