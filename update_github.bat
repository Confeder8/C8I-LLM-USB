@echo off
:: Change directory to the location of this script (USB Root)
cd /d "%~dp0"

:: Check if the .git folder does not exist
if not exist ".git" (
    echo Git repository not detected. Initializing now...
    git init
    
    echo Creating an initial commit...
    git add -v .
    git commit -m "Initial commit"
    
    echo.
    echo -------------------------------------------------------------
    echo  IMPORTANT: You must link your online GitHub URL now!
    echo  Please run this command manually in your command prompt:
    echo  git remote add origin YOUR_GITHUB_REPOSITORY_URL
    echo -------------------------------------------------------------
    echo.
    pause
    exit /b
)

echo Adding changes...
git add -v .

:: Asks you to type a commit message
REM set /p msg="Type the Commit Message.. "

echo Committing changes...
REMM git commit -m "%msg%"
git commit -m "C8I-LLM-USB"

echo Pushing to GitHub...
git push

echo Done!
pause
