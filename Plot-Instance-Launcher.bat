echo off
title Plot Instance Launcher
CLS
setlocal
rem ###   Settings   ####
rem
rem ### K32 is the minimmum plot size for mainnet
rem
set plotsize=32
rem
rem ### Amount of RAM per plot instance
rem
set ram=3990
rem
rem ### Amount of threads per plot instance (phase 1)
rem
set threads=2
rem
rem ### Temp directory 1 (no spaces and make sure to include \ at the end EX T:\)
rem
set temp1=
rem
rem ### Final directory for plot output (no spaces and make sure to include \ at the end EX T:\Chia_Plots\)
rem
set destination=
rem
rem
rem
rem
rem ### Optional advanced Settings ###
rem
rem ### Use plotcopy (must save and configure plotcopy in the output directory to copy plots to the final drive)
rem
set plotcopy=
rem
rem ### If you are launching multiple copies of this for multiple directories, provide a name EX: NVME1
rem
set duplicate=
rem
rem ### Delay start of first plot
rem
set delay=
rem
rem ### Log to file (will no longer log to screen) stored in your user directory %userprofile%\.chia\mainnet\plotter\ (log=yes to enable)
rem 
set log=
rem
rem ### Temp directory 2 (make sure to include \ at the end)
rem
set temp2=
rem
rem ### Farmer Public Key (Utilise this when you want to create plots on other machines for which you do not want to give full chia account access. 
rem ### To find your Chia Farmer Public Key use the following command *on your main wallet/farmer*: chia keys show)
rem
set farmkey=
rem
rem ### Pool Public Key (Utilise this when you want to create plots on other machines for which you do not want to give full chia account access. 
rem ### To find your Chia Pool Public Key use the following command *on your main wallet/farmer*: chia keys show)
rem
set poolkey=
rem
rem ###   Begin program   ###
rem ###   no need to edit past here   ###  
echo %date% %time:~0,-3% Started Plot Generator
echo.
if not defined farmkey if defined poolkey echo Both pool and farm keys are required.  Please check Optional Settings. & goto END
if not defined poolkey if defined farmkey echo Both pool and farm keys are required.  Please check Optional Settings. & goto END
if not defined plotsize echo Missing settings.  Please ensure all settings are configured. & goto END
if not defined ram echo Missing settings.  Please ensure all settings are configured. & goto END
if not defined threads echo Missing settings.  Please ensure all settings are configured. & goto END
if not defined temp1 echo Missing settings.  Please ensure all settings are configured. & goto END
if not defined destination echo Missing settings.  Please ensure all settings are configured. & goto END
rem Request information
set /p loopcount="Generate how many parallel plotting instances: "
set /p startdelay="Delay in seconds between plot instance spawning: "
set /p perinstance="How many plots to queue per parallel plotting instance: "
set /a var=1
if %plotcopy% equ yes echo %date% %time:~0,-3% Started Plot Copy & echo. & start %destination%plotcopy.bat
if defined delay for /f "delims=" %%G IN ('powershell "(get-date %time%).AddSeconds(%delay%).ToString('HH:mm:ss')"') do set offsettime=%%G
if defined delay echo Delayed start for %delay% seconds.  Starting at %offsettime%. & timeout /t %delay% /nobreak > nul
rem Start launch loop
:loop
rem Assemble create string
set assembled=-k %plotsize% -b %ram% -r %threads% -t %temp1%%var% -d %destination% -n %perinstance%
if defined temp2 set assembled=%assembled% -2 %temp2%
if defined farmkey if defined poolkey set assembled=%assembled% -f %farmkey% -p %poolkey%
rem Check for and skip running instances
FOR /F %%t IN ('tasklist /NH /FI "WINDOWTITLE eq Plot%var%_%duplicate%*"') DO IF %%t == cmd.exe echo Plot%var%_%duplicate% already running. Checking next plot. & goto SKIP
for /f "delims=" %%G IN ('powershell "(get-date %time%).AddSeconds(%startdelay%).ToString('HH:mm:ss')"') do set endtime=%%G
rem Plot not running: initiate delay if looped then start plot otherwise start first plot
if %var% equ 1 echo Started Plot%var%_%duplicate% & goto PLOT
echo Starting Plot%var%_%duplicate% at %endtime%.
timeout /t %startdelay% /nobreak > nul
:PLOT
if not exist %temp1%\%var% mkdir %temp1%\%var%
if %log% equ yes set hh=%time:~0,2%
if %log% equ yes set logfile=%userprofile%\.chia\mainnet\plotter\plotter_log_%date:~4,2%_%date:~7,2%_%date:~10,4%-%hh: =0%-%time:~3,2%-%time:~6,2%_Plot%var%_%duplicate%.log
if %log% equ yes start "Plot%var%_%duplicate%" cmd /k "chia plots create %assembled% >> %logfile% & find "Time for" %logfile% & find "Total time" %logfile%"
if %log% neq yes start "Plot%var%_%duplicate%" cmd /k chia plots create %assembled%
rem Plot running: increment variable, decrease loop variable, check if requested instances have launched and loop or finish
if %var% gtr 1 echo Started Plot%var%_%duplicate%
:SKIP
set /a var=%var%+1
set /a loopcount=%loopcount%-1
if %loopcount% lss 1 echo All plots running at %endtime%. 
if %loopcount% geq 1 goto loop
endlocal
:END
pause
