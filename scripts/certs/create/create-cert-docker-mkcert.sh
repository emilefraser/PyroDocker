@echo off
setlocal

set SERVICENAME=media
set PORT=fwfiles
set EXITCODE=0

rem
rem Input validation
rem
if /i "%1"=="/?" goto usage
if /i "%1"=="" goto usage



mkcert -cert-file "localhost.pem" -key-file "localhost-key.pem" localhost "*.docker.localhost" localhost 127.0.0.1 0.0.0.0 ::1
mkcert -pkcs12 -p12-file "localhost.p12" localhost "*.docker.localhost" localhost 127.0.0.1 0.0.0.0 ::1

:usage
set EXITCODE=1
echo Creates working directories for WinPE image customization and media creation.
echo.
echo copype { amd64 ^| x86 ^| arm ^| arm64 } ^<workingDirectory^>
echo.
echo  amd64             Copies amd64 boot files and WIM to ^<workingDirectory^>\media.
echo  x86               Copies x86 boot files and WIM to ^<workingDirectory^>\media.
echo  arm               Copies arm boot files and WIM to ^<workingDirectory^>\media.
echo  arm64             Copies arm64 boot files and WIM to ^<workingDirectory^>\media.
echo                    Note: ARM/ARM64 content may not be present in this ADK.
echo  workingDirectory  Creates the working directory at the specified location.
echo.
echo Example: copype amd64 C:\WinPE_amd64
goto cleanup

:success
set EXITCODE=0
echo.
echo Success
echo.
cd /d "%~2"
goto cleanup

:fail
set EXITCODE=1
echo Failed!
goto cleanup

:cleanup
endlocal & exit /b %EXITCODE%
