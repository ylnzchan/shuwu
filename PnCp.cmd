@echo off

rem -- http://phpnow.org
rem -- YinzCN_at_Gmail.com

setlocal enableextensions
if exist Pn\Config.cmd pushd . && goto cfg
if exist ..\Pn\Config.cmd pushd .. && goto cfg
goto :eof

:cfg
call Pn\Config.cmd
if "%php%"=="" exit /b

if "%1"=="exec" if not "%2"=="" cmd /c "%2 %3 %4 %5 %6" && goto :eof
if not "%1"=="" (
  call :%1 %2
  goto :eof
)

prompt -$g
title PHPnow %pn_ver% ������� (Apache %htd_ver%, %php_dir%, %myd_dir%)
goto menu


:restart_apache
if not exist %htd_dir%\logs\httpd.pid goto :eof
echo.
echo  �������� Apache ...
pushd %htd_dir%
bin\%htd_exe% -k restart -n %htd_svc% || set errno=1
popd
if "%errno%"=="1" %pause%
goto :eof


:execmd
if exist %1 call %1 && goto :eof
if exist %PnCmds%\%1 call %PnCmds%\%1 && goto :eof
echo # δ�ҵ� %1 !
%pause%
goto :eof


:menu
echo   ________________________________________________________________
echo  ^|                                                                ^|
echo  ^|         PHPnow  -  ��ɫ PHP + MySQL �׼�  -  �������          ^|
echo  ^|                                                                ^|
echo  ^|     0 - VHost: ��� ��������       10 - ��� ������������      ^|
echo  ^|     1 - VHost: ɾ�� ��������       11 - ȡ�� ������������      ^|
echo  ^|     2 - VHost: �޸� ��������       12 - ���� MySQL root ����   ^|
echo  ^|     3 - ���� eAccelerator          13 - ���� Apache �˿�       ^|
echo  ^|     4 - �ر� eAccelerator *        14 - --                     ^|
echo  ^|     5 - ���� mod_info ^& status     15 - ���� MySQL ���ݿ�      ^|
echo  ^|     6 - �ر� mod_info ^& status *   16 - �˿�ʹ��״̬���       ^|
echo  ^|     7 - Log: Apache ��־�־�       17 - ���� error_reporting   ^|
echo  ^|     8 - Log: Ĭ�� Apache ��־ *    18 - �����ļ� ���� / ��ԭ   ^|
echo  ^|     9 - Log: �ر� Apache ��־      19 - Pn Ŀ¼ ������ʾ��     ^|
echo  ^|     (�� * �ŵ�ΪĬ��ѡ��)                                      ^|
echo  ^|                                                                ^|
echo  ^|     20 - Start.cmd                 30 - Stop.cmd               ^|
echo  ^|     21 - Apa_Start.cmd             31 - Apa_Stop.cmd           ^|
echo  ^|     22 - My_Start.cmd              32 - My_Stop.cmd            ^|
echo  ^|     23 - Apa_Restart.cmd           33 - ǿ����ֹ���̲�ж��     ^|
echo  ^|________________________________________________________________^|
set /p input=-^> ��ѡ��: 
cls
if "%input%"=="20" call :execmd Start.cmd
if "%input%"=="21" call :execmd Apa_Start.cmd
if "%input%"=="22" call :execmd My_Start.cmd
if "%input%"=="23" call :execmd Apa_Restart.cmd
if "%input%"=="30" call :execmd Stop.cmd
if "%input%"=="31" call :execmd Apa_Stop.cmd
if "%input%"=="32" call :execmd My_Stop.cmd
echo.
if "%input%"== "0" goto vhost_add
if "%input%"== "1" goto vhost_del
if "%input%"== "2" goto vhost_mod
if "%input%"== "3" goto eA_en
if "%input%"== "4" goto eA_dis
if "%input%"== "5" call :httpd_info en
if "%input%"== "6" call :httpd_info dis
if "%input%"== "7" call :apache_log pipe
if "%input%"== "8" call :apache_log default
if "%input%"== "9" call :apache_log dis
if "%input%"=="10" goto vProxy_add
if "%input%"=="11" goto vProxy_dis
if "%input%"=="12" goto reset_mydpwd
if "%input%"=="13" goto chg_port
if "%input%"=="14" goto end
if "%input%"=="15" goto myd_upgrade
if "%input%"=="16" goto chk_port
if "%input%"=="17" call :err_report
if "%input%"=="18" goto cfg_bak
if "%input%"=="19" cmd /k echo  # ��ǰĿ¼ [ %CD% ]
if "%input%"=="33" goto force_stop
goto end


:chg_port
set /p nport=-^> �����µ� http �˿�(1-65535): 
if "%nport%"=="" goto end
%php% "$p = env('nport'); if ($p !== ''.ceil($p) || 1 > $p || $p > 65535) exit(1);" || goto chg_port
%php% "chg_port(env('nport'));" || %pause% && goto end
set htd_port=%nport%
if "%1"=="noRestart" goto end
call :restart_apache
goto end


:vhost_add
echo  # ���е����������б� #
%php% "showvhs();" || %pause% && goto end
echo.
echo  [ �����������������ͱ�ʶ. �� test.com �� blog.test.com ]
set /p hName=-^> ����������: 
if "%hName%"=="" goto end
echo.
echo  [ �������ڰ�����������Ķ������. ֧�� * �ŷ�����.
echo    �� www.test.com �� *.test.com(��������Ĭ��ֵ)
echo    ������ÿո����, �� "s1.test.com s2.test.com *.phpnow.org" ]
set /p hAlias=-^> ��������(��ѡ): 
:vhost_add_htdocs
echo.
echo  [ ָ����վĿ¼. ������Ĭ��Ϊ .\vhosts\%hName%]
set htdocs=
set /p htdocs=-^> ��վĿ¼(��ѡ): 
if "%htdocs%"=="" goto vhost_add_2

%php% "$d = rpl('/', '\\\\', $_ENV['htdocs']); if (is_dir($d)) exit(0); if (file_exists($d)) exit(1); if (!@mkdir($d, 0, 1)) exit(2);" || echo  # ·������ȷ�򴴽�Ŀ¼ʧ��! && %pause% && goto vhost_add_htdocs

:vhost_add_2
echo.
echo  [ �������������������û�, ��������Ȩ��, ������ y,
echo    ����, ������ n. Ĭ�� Y ]
set /p p=-^> ���� php �� open_basedir ? (Y/n): 
%php% "vhost_add(env('hName'), env('htdocs'), env('htd_port'), env('hAlias'), env('p'));" && call :restart_apache && goto end
echo.
%pause%
goto end


:vhost_del
echo  # ���е����������б� #
%php% "showvhs();" || %pause% && goto end
echo.
echo  [ Ҫɾ����������, �����������������. ]
set /p hName=-^> ѡ����������: 
if "%hName%"=="" goto end
%php% "vhost_del(env('hName'));" && call :restart_apache
echo.
%pause%
goto end


:vhost_mod
echo  # ���е����������б� #
%php% "showvhs();" || %pause% && goto end
echo.
echo  [ Ҫ�޸���������, �����������������. ]
set /p hName=-^> ѡ����������: 
if "%hName%"=="" goto end
echo.
echo  [ �������µ���������, ԭ�����ݽ�������! ���ղ��޸�. ]
echo  [ Ҫ��ԭ���������, ������ +phpnow.org �� phpnow.org+ ]
set /p hAlias=-^> ��������: 
echo.
echo  [ ��û�� index.php �� index.html �ļ�ʱ, ��ʾĿ¼�б� ]
set /p hIndex=-^> ���� Ŀ¼����? (y/N): 
:vhost_mod_confirm
echo.
echo  [ ��������������������ȷ���� ]
echo.
set /p sure=-^> ȷ��? (y/n) 
if /i "%sure%"=="n" goto end
if /i not "%sure%"=="y" goto vhost_mod_confirm
%php% "vhost_mod(env('hName'), env('hAlias'), env('hIndex'));" || %pause% && goto end
call :restart_apache
goto end


:vProxy_add
echo  [ ���һ����������, �������� http ��ַ ]
echo.
echo  # ���е����������б� #
%php% "showvhs();" || %pause% && goto end
:vProxy_add_hN
echo.
echo  [ ����µ�������. �� test.com �� jsp.test.com ]
set hName=
set /p hName=-^> ������: 
if "%hName%"=="" goto end
%php% "if (regrpl('[\w\d\.\-]+', '', env('hName'))) exit(1);" && goto vProxy_add_hA
echo  # ������ֻ���� "a-z0-9.-" ���!
%pause% && goto vProxy_add_hN
:vProxy_add_hA
echo.
echo  [ ����������. �� www.abc.com �� *.abc.com(������); ������ÿո���� ]
set hAlias=
set /p hAlias=-^> ��������(��ѡ): 
if "%hAlias%"=="" set hAlias=*.%hName%
%php% "if (regrpl('[\w\d\.\- *]+', '', env('hAlias'))) exit(1);" && goto vProxy_add_hP
echo  # ��������ֻ���� "a-z0-9.-* " ���!
%pause% && goto proxy_add_hA
:vProxy_add_hP
echo.
echo  [ ��: localhost:8080, 192.168.0.100 �� google.com ]
echo  [ ���ʴ���������������, ��������Ŀ��. ]
set hPass=
set /p hPass=-^> ����Ŀ��: 
if "%hPass%"=="" goto vProxy_add_hP
%php% "if (regrpl('[a-z0-9\.\-_:\/]+', '', env('hPass'))) exit(1);" && goto vProxy_add_go
echo  # Ŀ���ַֻ���� "a-z0-9.-_:/" ���!
%pause% && goto vProxy_add_hP
:vProxy_add_go
%php% "vProxy_add(env('hName'), env('hAlias'), env('hPass'));"
call :restart_apache
goto end


:vProxy_dis
echo  [ ������ɾ�����д���������¼! ]
echo.
set /p sure=-^> ȷ��? (y/n)
if /i "%sure%"=="n" goto end
if /i "%sure%"=="y" goto un_proxy_1
goto un_proxy
:un_proxy_1
%php% "vProxy_dis();" || %pause% && goto end
call :restart_apache
goto end


:eA_en
if not exist Pn\eAccelerator*.dll ( echo # eAccelerator dll û���ҵ� && %pause% && goto end )
for /f %%i in ('dir /b /o Pn\eAccelerator*.dll') do set ea_dll=%%i
%php% "frpl($php_ini, '^[;]*(zend_extension_ts=).*eAccelerator.*(\r\n)', '$1`..\..\Pn\%ea_dll%`$2');" || %pause% && goto end
call :restart_apache
goto end


:eA_dis
%php% "frpl($php_ini, '^(zend_extension_ts=.*eAccelerator.*\r\n)', ';;$1');" || %pause% && goto end
call :restart_apache
goto end


:httpd_info
if "%1"=="en" (set a=#+&&set b=) else (set b=##&&set a=)
%php% "$s = rfile($htd_cfg); $s = regrpl('^%a%(Load.*mod_info.*\r\n)', '%b%$1', $s); $s = regrpl('^%a%(Load.*mod_status.*\r\n)', '%b%$1', $s); $s = regrpl('^%a%(Include.*httpd-info.conf\r\n)', '%b%$1', $s); wfile($htd_cfg, $s);" || %pause% && goto end
call :restart_apache
goto end


:apache_log
echo  apache_log_%1();
%php% "apache_log_%1();" || %pause% && goto end
call :restart_apache
goto end


:err_report
echo   ________________________________________________________________
echo  ^|                                                                ^|
echo  ^|        ���� php error_reporting (���󱨸�) �ȼ�                ^|
echo  ^|                                                                ^|
echo  ^|     0 - E_ALL ^& ~E_NOTICE ^& ~E_WARNING                         ^|
echo  ^|                               ��ͨ; ��������, ����һ�㾯��     ^|
echo  ^|                                                                ^|
echo  ^|     1 - E_ALL                                                  ^|
echo  ^|                               �ϸ�; ���Ի���, ��ʾ���д���     ^|
echo  ^|________________________________________________________________^|
set /p input=-^> ��ѡ��: 
if "%input%"=="0" set err_reporting=E_ALL ^& ~E_NOTICE ^& ~E_WARNING
if "%input%"=="1" set err_reporting=E_ALL
if "%err_reporting%"=="" goto end
%php% "frpl($php_ini, '^(error_reporting)\s*=.*(\r\n)', '$1 = %err_reporting%$2');" || %pause% && goto end
call :restart_apache
goto end


:reset_mydpwd
set /p newpwd=-^> ���� root ����: 
if "%newpwd%"=="" goto reset_mydpwd
echo.
set pnTmp=%SystemRoot%\Temp\Pn_%RANDOM%.%RANDOM%
echo SET PASSWORD FOR 'root'@'localhost' = PASSWORD('%newpwd%');>%pnTmp%
if exist %myd_dir%\data\%COMPUTERNAME%.pid %net% stop %myd_svc%
set myini=%CD%\%myd_dir%\my.ini
start /b %myd_dir%\bin\%myd_exe% --defaults-file="%myini%" --init-file=%pnTmp%
%myd_dir%\bin\mysqladmin.exe shutdown -uroot -p"%newpwd%"
echo  �ȴ� MySQL �˳� ...
echo.
%php% "while(@file_exists('%myd_dir%\data\%COMPUTERNAME%.pid')) usleep(50000);"
echo.>%pnTmp%
del %pnTmp% /Q
%net% start %myd_svc% || %pause%
goto end


:myd_upgrade
echo   ______________________________________________________________
echo  ^|                                                              ^|
echo  ^|   �˹������ڸ��� MySQL ���ݿ�Ŀ¼ (data Ŀ¼) �����Ե���ǰ   ^|
echo  ^|   �汾. �� data Ŀ¼Ǩ�Ƶ�һ�����°汾�� MySQL ��ִ�д���.   ^|
echo  ^|                                                              ^|
echo  ^|   ͨ������ mysql_upgrade.exe ʵ��.                           ^|
echo  ^|______________________________________________________________^|
echo.
set /p sure=-^> ȷ�ϼ���? (y/N): 
if /i not "%sure%"=="y" goto end
:myd_upgrade_pwd
set pwd=
set /p pwd=-^> ������ MySQL root ����: 
%php% "chk_mysql('%myd_port%', env('pwd'));" && goto myd_upgrade_exe
if %errorlevel%==1045 (
  echo  # ���벻��ȷ, ����������.
  goto myd_upgrade_pwd
)
if %errorlevel%==2003 (
  echo  # �������� MySQL^(port:%myd_port%^) ʧ��.
  echo  # ��ȷ�� MySQL ��������.
  %pause% & goto end
)
:myd_upgrade_exe
%myd_dir%\bin\mysql_upgrade.exe --user=root --password="%pwd%" --force
echo.
echo  # �븴�������ִ�н��, ȫ�� OK ��Ϊ�����ɹ�.
%pause%
goto end


:chk_port
if not exist %Sys32%\tasklist.exe goto chk_port_1
if not exist %Sys32%\netstat.exe goto chk_port_2
%php% "chk_port('%htd_port%');"
if not errorlevel 1 echo   ָ���� httpd �˿� %htd_port% ��ʱδ��ռ��.
%php% "chk_port('%myd_port%');"
if not errorlevel 1 echo   ָ���� MySQL �˿� %myd_port% ��ʱδ��ռ��.
echo.
%pause% & goto end
:chk_port_1
echo  # ȱ�� %Sys32%\tasklist.exe, �޷�����. & %pause% & goto end
:chk_port_2
echo  # ȱ�� %Sys32%\netstat.exe, �޷�����. & %pause% & goto end


:force_stop
set taskkill=%Sys32%\taskkill.exe
if not exist %taskkill% (
  echo  # ȱ�� %taskkill%, �޷�����. & %pause% & goto end
)
%taskkill% /fi "SERVICES eq %htd_svc%" /f /t
%taskkill% /fi "SERVICES eq %myd_svc%" /f /t
%net% stop %myd_svc%>nul 2>nul
%net% stop %htd_svc%>nul 2>nul
%htd_dir%\bin\%htd_exe% -k uninstall -n %htd_svc%>nul 2>nul
%myd_dir%\bin\%myd_exe% --remove %myd_svc%>nul 2>nul
del %myd_dir%\data\%COMPUTERNAME%.pid %htd_dir%\logs\httpd.pid /q>nul 2>nul
%pause%
goto end


:cfg_bak
echo   ______________________________________________________________
echo  ^|                                                              ^|
echo       ���� / ��ԭ ���������ļ�
echo       Apache ������ :  %htd_dir%\conf\httpd.conf
echo       �������� ���� :  %vhs_cfg%
echo       php.ini       :  %php_dir%\php-apache2handler.ini
echo       MySQL ����    :  %myd_dir%\my.ini
echo  ^|______________________________________________________________^|
echo.
echo  # ���б����б� (������ %cfg_bak_zip%) #
echo.
%php% "cfg_bak('show');" || %pause% && goto end
echo.
echo  # ִ�в��� #
echo.
echo      B - ��������
echo      R - ��ԭ����
echo      D - ɾ������
echo.
set input=
set /p input=-^> ��ѡ��: 
echo.
if /i "%input%"=="B" goto cfg_bak_B
if /i "%input%"=="R" goto cfg_bak_R
if /i "%input%"=="D" goto cfg_bak_D
echo  # δѡ�����, �˳� & %pause% & goto end

:cfg_bak_B
set input=
set /p input= ��������: 
if "%input%"=="" goto cfg_bak_B
%php% "cfg_bak('backup '.env('input'));"
echo.
%pause%
goto end

:cfg_bak_R
echo  # ���б����б� (������ %cfg_bak_zip%) #
echo.
%php% "cfg_bak('show');" || %pause% && goto end
echo.
echo  [ ��ԭ֮ǰ��ȷ���Ƿ���Ҫ���������ý��б���! ]
echo.
set n=
set /p n=-^> ��ԭ���˱������: 
if "%n%"=="" echo  # δִ�в���! && %pause% && goto end
%php% "$p = env('n'); if ($p !== ''.ceil($p) || 0 > $p) exit(1);" || goto cfg_bak_R
%php% "cfg_bak('restore '.env('n'));" || %pause% && goto end
echo.
set input=
set /p input= �����ѻ�ԭ, ������������? (y/N): 
if /i not "%input%"=="y" goto end
call :restart_apache
echo.
%net% stop %myd_svc%
%net% start %myd_svc%
goto end

:cfg_bak_D
echo  # ���б����б� (������ %cfg_bak_zip%) #
echo.
%php% "cfg_bak('show');" || %pause% && goto end
echo.
set n=
set /p n=-^> ɾ������ŵı���: 
if "%n%"=="" echo  # δִ�в���! && %pause% && goto end
%php% "$p = env('n'); if ($p !== ''.ceil($p) || 0 > $p) exit(1);" || goto cfg_bak_D
%php% "cfg_bak('delete '.env('n'));"
echo.
%pause%
goto end


:end
prompt
popd
