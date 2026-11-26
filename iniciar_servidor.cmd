@echo off
setlocal
cd /d "%~dp0"
set "PHP_EXE=C:\xampp\php\php.exe"
if not exist "%PHP_EXE%" set "PHP_EXE=php"
echo Servidor de atividades na porta 8080.
"%PHP_EXE%" -S 127.0.0.1:8080 -t server/public server/router.php
if errorlevel 1 pause
