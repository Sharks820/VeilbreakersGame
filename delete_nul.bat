@echo off
cd /d "C:\Users\Conner\Downloads\VeilbreakersGame"
del /f /a "\\.\C:\Users\Conner\Downloads\VeilbreakersGame\nul" 2>nul
del /f /a "\\?\C:\Users\Conner\Downloads\VeilbreakersGame\nul" 2>nul
echo Done
del "%~f0"
