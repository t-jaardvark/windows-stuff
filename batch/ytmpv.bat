@echo off
setlocal enabledelayedexpansion

:: Configuration - Set these variables as needed
:: ----------------------------------------------

:: Set this to a path to save videos permanently
:: Example: set "SAVE_PATH=C:\Videos"
:: Leave empty to use temporary directory
set "SAVE_PATH="

:: Set maximum video quality/resolution
:: Valid values: 144, 240, 360, 480, 720, 1080, 1440, 2160
:: Also accepts: 144p, 240p, 360p, 480p, 720p, 1080p, 1440p, 2160p, 4k
:: Aliases: sd (480p), hd (720p), fhd (1080p), 4k (2160p)
:: Leave empty for best quality
set "MAX_QUALITY="

:: ----------------------------------------------

:: Process the quality setting
set "quality_param="
if not "%MAX_QUALITY%"=="" (
    :: Remove trailing 'p' if present
    set "MAX_QUALITY=%MAX_QUALITY:p=%"

    :: Handle aliases
    if /i "%MAX_QUALITY%"=="sd" set "MAX_QUALITY=480"
    if /i "%MAX_QUALITY%"=="hd" set "MAX_QUALITY=720"
    if /i "%MAX_QUALITY%"=="fhd" set "MAX_QUALITY=1080"
    if /i "%MAX_QUALITY%"=="4k" set "MAX_QUALITY=2160"

    :: Set the quality parameter for yt-dlp
    set "quality_param=-f best[height<=%MAX_QUALITY%]"
    echo Maximum quality set to %MAX_QUALITY%p
)

:: Check if URL was provided as parameter 1
if "%~1"=="" (
    :: No URL provided, prompt the user
    echo Please enter the video URL:
    set /p "video_url="
) else (
    :: Use the provided URL
    set "video_url=%~1"
)

:: Validate that we have a URL
if "%video_url%"=="" (
    echo No URL provided. Exiting.
    pause
    exit /b 1
)

:: Create a download directory
if not "%SAVE_PATH%"=="" (
    :: Use the specified save path
    set "download_dir=%SAVE_PATH%"
) else (
    :: Use the current directory as fallback
    set "download_dir=%CD%\yt_download_%RANDOM%"
)

:: Try to create the directory if it doesn't exist
if not exist "%download_dir%" (
    echo Creating directory: %download_dir%
    mkdir "%download_dir%" 2>nul
    if errorlevel 1 (
        echo Error: Failed to create download directory.
        echo Using current directory instead.
        set "download_dir=%CD%"
    )
)

:: Change to the download directory
cd /d "%download_dir%" 2>nul
if errorlevel 1 (
    echo Error: Cannot access download directory.
    echo Using current directory instead.
    set "download_dir=%CD%"
    cd /d "%download_dir%"
)

:: Download the video using yt-dlp
echo Downloading video from: %video_url%
echo Saving to: %download_dir%

:: Download with quality setting if specified, otherwise best quality
if defined quality_param (
    yt-dlp %quality_param% -o "video.%%(ext)s" "%video_url%"
) else (
    echo Downloading best available quality
    yt-dlp -o "video.%%(ext)s" "%video_url%"
)

if errorlevel 1 (
    echo Error: Download failed.
    pause
    exit /b 1
)

:: Find the downloaded file
set "video_file="
for /f "delims=" %%i in ('dir /b /a-d /o-d') do (
    set "video_file=%%i"
    goto :found_file
)

:found_file
:: Check if download was successful
if not defined video_file (
    echo Error: No video file found after download.
    pause
    exit /b 1
)

:: Start mpv in a detached process
echo Starting video playback of: %video_file%
start "" mpv "%download_dir%\%video_file%"

:: Exit the batch file
exit /b 0
