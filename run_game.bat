@echo off
setlocal EnableExtensions
rem ============================================================================
rem  run_game.bat - double-click to play A Guild Story.
rem
rem  Runs tools/run_game.sh through Git Bash (the same script the build tooling
rem  uses). If Git Bash is not installed it falls back to launching Godot
rem  directly, so the game still starts.
rem
rem    run_game.bat                     main scene
rem    run_game.bat res://path/x.tscn   a specific scene
rem ============================================================================
cd /d "%~dp0"

set "BASH_EXE="
rem Git for Windows, in the usual places. WindowsApps\bash.exe is WSL - skip it.
for %%P in (
  "%ProgramFiles%\Git\bin\bash.exe"
  "%ProgramFiles(x86)%\Git\bin\bash.exe"
  "%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
  "%ProgramFiles%\Git\usr\bin\bash.exe"
) do if not defined BASH_EXE if exist "%%~P" set "BASH_EXE=%%~P"

if defined BASH_EXE (
  if not exist "tools\run_game.sh" (
    echo tools\run_game.sh is missing next to this file.
    pause
    exit /b 1
  )
  "%BASH_EXE%" -lc "./tools/run_game.sh \"$@\"" run_game %*
  set "RC=%ERRORLEVEL%"
  if not "%RC%"=="0" (
    echo.
    echo Godot exited with code %RC%
    pause
  )
  exit /b %RC%
)

rem ---- no Git Bash: launch Godot ourselves -----------------------------------
echo Git Bash not found - launching Godot directly.
set "GODOT_EXE="
if defined GODOT if exist "%GODOT%" set "GODOT_EXE=%GODOT%"
if not defined GODOT_EXE for /d %%D in ("%LOCALAPPDATA%\Programs\Godot\*") do (
  for %%F in ("%%~fD\Godot*_console.exe") do if not defined GODOT_EXE set "GODOT_EXE=%%~fF"
)
if not defined GODOT_EXE for /d %%D in ("%LOCALAPPDATA%\Programs\Godot\*") do (
  for %%F in ("%%~fD\Godot*.exe") do if not defined GODOT_EXE set "GODOT_EXE=%%~fF"
)
if not defined GODOT_EXE for %%N in (godot.exe godot4.exe) do (
  if not defined GODOT_EXE for %%P in ("%%~$PATH:N") do if not "%%~P"=="" set "GODOT_EXE=%%~fP"
)

if not defined GODOT_EXE (
  echo.
  echo   Godot 4 was not found. Install it from
  echo     https://godotengine.org/download/windows/
  echo   or set the GODOT environment variable to the .exe, then try again.
  echo.
  pause
  exit /b 1
)

"%GODOT_EXE%" --path . %*
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo Godot exited with code %RC%
  pause
)
exit /b %RC%
