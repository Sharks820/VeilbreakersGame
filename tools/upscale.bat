@echo off
REM Real-ESRGAN Upscale Helper Script
REM Usage: upscale.bat input_image output_image [scale]
REM   scale: 2, 3, or 4 (default: 4)

set ESRGAN_DIR=%~dp0realesrgan
set INPUT=%1
set OUTPUT=%2
set SCALE=%3

if "%SCALE%"=="" set SCALE=4

if "%INPUT%"=="" (
    echo Usage: upscale.bat input_image output_image [scale]
    echo   scale: 2, 3, or 4 ^(default: 4^)
    echo.
    echo Models available:
    echo   realesrgan-x4plus       - General images ^(default^)
    echo   realesrgan-x4plus-anime - Anime/illustration
    echo   realesr-animevideov3    - Anime video frames
    exit /b 1
)

if "%OUTPUT%"=="" (
    echo ERROR: Output file required
    exit /b 1
)

echo Upscaling %INPUT% -^> %OUTPUT% at %SCALE%x...
"%ESRGAN_DIR%\realesrgan-ncnn-vulkan.exe" -i "%INPUT%" -o "%OUTPUT%" -s %SCALE% -n realesrgan-x4plus-anime

if %ERRORLEVEL%==0 (
    echo Done! Output saved to: %OUTPUT%
) else (
    echo ERROR: Upscaling failed
    exit /b 1
)
