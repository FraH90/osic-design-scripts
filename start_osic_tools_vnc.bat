:: This script automatically download the iic-osic-tools repo if not already available
:: and automatically set it up, download docker images, start the docker container, 
:: and open the browser to the localhost (in vnc mode) in order to already start working with the iic-osic-tools.
:: If file is named start_osic_tools_vnc.bat the vnc mode is used, if is named start_osic_tools_xsrv.bat the x.org server
:: mode is used (a x-server compatible with windows is automatically installed if not available)

@echo off
setlocal enabledelayedexpansion

:: Set the current working directory to the user's home directory
cd /d "%USERPROFILE%"

:: Get the script name
for %%I in (%0) do set SCRIPT_NAME=%%~nI

:: Function to check Docker status
:check_docker
docker info >nul 2>&1
if %errorlevel% equ 0 (
    echo Docker is running.
    goto :docker_running
)

echo Docker is not running. Attempting to start Docker...

:: Try starting Docker Desktop
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo Docker Desktop launch attempted.
    goto :wait_for_docker
)

:: If all attempts fail
echo Failed to start Docker automatically. Please start Docker manually.
echo Once Docker is running, press any key to continue...
pause >nul
goto :check_docker

:wait_for_docker
echo Waiting for Docker to initialize...
timeout /t 20 /nobreak >nul
goto :check_docker

:docker_running
:: Rest of your script starts here

:: Check if the repository exists
if exist "%USERPROFILE%\iic-osic-tools" (
    echo iic-osic-tools repository found. Starting...
) else (
    echo iic-osic-tools repository not found. Cloning...
    git clone --depth=1 https://github.com/iic-jku/iic-osic-tools.git
)

:: Change to the iic-osic-tools directory
cd "%USERPROFILE%\iic-osic-tools"

:: Check if the script name contains "xsrv"
if /i "!SCRIPT_NAME!" == "start_osic_tools_xsrv" (
    :: Install VcXsrv if not already installed
    winget list -e --id marha.VcXsrv >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Installing VcXsrv...
        winget install -e --id marha.VcXsrv
    )
    
    :: Start VcXsrv
    echo Starting VcXsrv...
    start "" "C:\Program Files\VcXsrv\vcxsrv.exe" :0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl
    
    :: Start X server
    echo Starting X server...
    call start_x.bat
) else (
    :: Check if the container exists and its status
    docker inspect -f '{{.State.Status}}' iic-osic-tools_xvnc >nul 2>&1
    if !errorlevel! equ 0 (
        for /f %%i in ('docker inspect -f "{{.State.Status}}" iic-osic-tools_xvnc') do set container_status=%%i
        if "!container_status!"=="exited" (
            echo Container exists but is not running. Starting container...
            docker start iic-osic-tools_xvnc
        ) else (
            echo Container is already running.
        )
    ) else (
        echo Container does not exist. Creating and starting new container...
        :: Start VNC server
        call start_vnc.bat
    )
    echo Remember: The default VNC password is abc123

    :: Open browser (only for VNC mode)
    echo Opening browser...
    start http://localhost
)

:: Close the terminal
echo Closing terminal in 5 seconds...
ping 127.0.0.1 -n 6 > nul
exit