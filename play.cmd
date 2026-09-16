@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ============================================================================
rem  play.cmd - launch A Guild Story on Windows. Double-click it.
rem
rem  Needs nothing but Windows: no bash, no PowerShell, no Python. It looks for
rem  Godot 4 in this order and uses the first it finds:
rem    1. godot\Godot*.exe          - a copy dropped in the "godot" folder beside
rem                                   this file (zip the folder with it and the
rem                                   game runs on any Windows machine)
rem    2. the GODOT environment variable, if it names an .exe
rem    3. %LOCALAPPDATA%\Programs\Godot\...\Godot*.exe  (the installer's home)
rem    4. godot.exe / godot4.exe on PATH
rem
rem  Verbs:   play.cmd          start the game (window; this console closes)
rem           play.cmd debug    start it in the foreground so errors stay visible
rem           play.cmd where    print which Godot would be used and stop
rem           play.cmd check    boot headless for a moment to prove it runs
rem
rem  The project is Godot 4.7 (4.3 or newer works). Any flavour is fine - the
rem  game is GDScript only, so the standard build is the lighter download:
rem  https://godotengine.org/download/windows/
rem ============================================================================
cd /d "%~dp0"

set "GODOT_EXE="
set "GODOT_CONSOLE="

rem ---- 1. a copy beside the project ------------------------------------------
if exist "godot\" (
  for %%F in ("godot\Godot*.exe") do call :consider "%%~fF"
)

rem A vendored copy wins even when it is only the console build.
if not defined GODOT_EXE if defined GODOT_CONSOLE set "GODOT_EXE=%GODOT_CONSOLE%"

rem ---- 2. the GODOT variable --------------------------------------------------
if not defined GODOT_EXE if defined GODOT if exist "%GODOT%" call :consider "%GODOT%"

rem ---- 3. the installer's home ------------------------------------------------
if not defined GODOT_EXE if exist "%LOCALAPPDATA%\Programs\Godot\" (
  for /d %%D in ("%LOCALAPPDATA%\Programs\Godot\*") do (
    for %%F in ("%%~fD\Godot*.exe") do call :consider "%%~fF"
  )
  for %%F in ("%LOCALAPPDATA%\Programs\Godot\Godot*.exe") do call :consider "%%~fF"
)

rem ---- 4. PATH ----------------------------------------------------------------
if not defined GODOT_EXE for %%N in (godot.exe godot4.exe) do (
  if not defined GODOT_EXE for %%P in ("%%~$PATH:N") do if not "%%~P"=="" call :consider "%%~fP"
)

rem A console build is fine when it is all there is.
if not defined GODOT_EXE if defined GODOT_CONSOLE set "GODOT_EXE=%GODOT_CONSOLE%"

if not defined GODOT_EXE (
  echo.
  echo   A Guild Story needs Godot 4 to run, and none was found.
  echo.
  echo   Download Godot 4.7 for Windows ^(the standard build, not .NET^):
  echo     https://godotengine.org/download/windows/
  echo   Unzip it, then EITHER drop the .exe into the "godot" folder next to
  echo   this file, OR install it under %%LOCALAPPDATA%%\Programs\Godot.
  echo   Then run play.cmd again.
  echo.
  pause
  exit /b 1
)

if /i "%~1"=="where" (
  echo %GODOT_EXE%
  exit /b 0
)

if /i "%~1"=="check" (
  echo Booting headless with: %GODOT_EXE%
  "%GODOT_EXE%" --headless --path . --quit-after 120
  echo exit code %ERRORLEVEL%
  exit /b %ERRORLEVEL%
)

if /i "%~1"=="debug" (
  echo Running: %GODOT_EXE% --path .
  if defined GODOT_CONSOLE set "GODOT_EXE=%GODOT_CONSOLE%"
  "%GODOT_EXE%" --path . --verbose
  echo.
  echo Godot exited with code %ERRORLEVEL%
  pause
  exit /b %ERRORLEVEL%
)

start "A Guild Story" "%GODOT_EXE%" --path .
exit /b 0

rem ---- helper: remember the first windowed exe and the first console exe ------
:consider
set "CAND=%~1"
set "STRIPPED=!CAND:_console=!"
if /i not "!STRIPPED!"=="!CAND!" (
  if not defined GODOT_CONSOLE set "GODOT_CONSOLE=%CAND%"
) else (
  if not defined GODOT_EXE set "GODOT_EXE=%CAND%"
)
exit /b 0
