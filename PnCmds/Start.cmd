@echo off

rem -- http://PHPnow.org
rem -- By Yinz ( MSN / QQ / Email : Cwood@qq.com )

setlocal enableextensions
if exist Pn\Config.cmd pushd . & goto cfg
if exist ..\Pn\Config.cmd pushd .. & goto cfg
goto :eof


:execmd
echo %1
if exist %1 call %1 && goto :eof
if exist %PnCmds%\%1 call %PnCmds%\%1 && goto :eof
echo # �Ҳ��� %1, ���� %PnCmds% �� %CD% Ŀ¼.
%pause%
goto :eof


:cfg
call Pn\Config.cmd
if "%php%"=="" exit /b
title �������� Apache �� MySQL ����
echo.
call :execmd Apa_Start.cmd
echo.
call :execmd My_Start.cmd

popd
