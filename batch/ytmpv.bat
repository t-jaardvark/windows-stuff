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
    exit /b 1
)

:: Determine where to save the video
if not "%SAVE_PATH%"=="" (
    :: Use the specified save path
    if not exist "%SAVE_PATH%" mkdir "%SAVE_PATH%" 2>nul
    set "download_dir=%SAVE_PATH%"
) else (
    :: Use a temporary directory
    set "download_dir=%TEMP%\yt_download_%RANDOM%"
    if not exist "%download_dir%" mkdir "%download_dir%" 2>nul
)

:: Verify the directory was created successfully
if not exist "%download_dir%" (
    echo Error: Failed to create download directory.
    pause
    exit /b 1
)

:: Change to the download directory
cd /d "%download_dir%" || (
    echo Error: Failed to change to download directory.
    pause
    exit /b 1
)

:: Download the video using yt-dlp
echo Downloading video from: %video_url%
echo Saving to: %download_dir%

:: Set a specific output filename to avoid issues
set "output_filename=downloaded_video.mp4"

:: Download with quality setting if specified, otherwise best quality
if defined quality_param (
    yt-dlp %quality_param% -o "%output_filename%" "%video_url%"
) else (
    echo Downloading best available quality
    yt-dlp -o "%output_filename%" "%video_url%"
)

:: Check if download was successful
if not exist "%output_filename%" (
    echo Download failed! File not found.
    pause
    exit /b 1
)

:: Start mpv in a detached process with full path
echo Starting video playback of: %output_filename%
start "" mpv "%download_dir%\%output_filename%"

:: Exit the batch file
exit
