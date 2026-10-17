@echo off
rem Launches GameLite. It will ask for administrator rights.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0GameLite.ps1"
