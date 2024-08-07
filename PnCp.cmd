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
title PHPnow %pn_ver% 控制面板 (Apache %htd_ver%, %php_dir%, %myd_dir%)
goto menu


:restart_apache
if not exist %htd_dir%\logs\httpd.pid goto :eof
echo.
echo  正在重启 Apache ...
pushd %htd_dir%
bin\%htd_exe% -k restart -n %htd_svc% || set errno=1
popd
if "%errno%"=="1" %pause%
goto :eof


:execmd
if exist %1 call %1 && goto :eof
if exist %PnCmds%\%1 call %PnCmds%\%1 && goto :eof
echo # 未找到 %1 !
%pause%
goto :eof


:menu
echo   ________________________________________________________________
echo  ^|                                                                ^|
echo  ^|         PHPnow  -  绿色 PHP + MySQL 套件  -  控制面板          ^|
echo  ^|                                                                ^|
echo  ^|     0 - VHost: 添加 虚拟主机       10 - 添加 代理虚拟主机      ^|
echo  ^|     1 - VHost: 删除 虚拟主机       11 - 取消 代理虚拟主机      ^|
echo  ^|     2 - VHost: 修改 虚拟主机       12 - 重设 MySQL root 密码   ^|
echo  ^|     3 - 开启 eAccelerator          13 - 更改 Apache 端口       ^|
echo  ^|     4 - 关闭 eAccelerator *        14 - --                     ^|
echo  ^|     5 - 开启 mod_info ^& status     15 - 升级 MySQL 数据库      ^|
echo  ^|     6 - 关闭 mod_info ^& status *   16 - 端口使用状态检测       ^|
echo  ^|     7 - Log: Apache 日志分卷       17 - 设置 error_reporting   ^|
echo  ^|     8 - Log: 默认 Apache 日志 *    18 - 配置文件 备份 / 还原   ^|
echo  ^|     9 - Log: 关闭 Apache 日志      19 - Pn 目录 命令提示符     ^|
echo  ^|     (带 * 号的为默认选项)                                      ^|
echo  ^|                                                                ^|
echo  ^|     20 - Start.cmd                 30 - Stop.cmd               ^|
echo  ^|     21 - Apa_Start.cmd             31 - Apa_Stop.cmd           ^|
echo  ^|     22 - My_Start.cmd              32 - My_Stop.cmd            ^|
echo  ^|     23 - Apa_Restart.cmd           33 - 强行终止进程并卸载     ^|
echo  ^|________________________________________________________________^|
set /p input=-^> 请选择: 
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
if "%input%"=="19" cmd /k echo  # 当前目录 [ %CD% ]
if "%input%"=="33" goto force_stop
goto end


:chg_port
set /p nport=-^> 输入新的 http 端口(1-65535): 
if "%nport%"=="" goto end
%php% "$p = env('nport'); if ($p !== ''.ceil($p) || 1 > $p || $p > 65535) exit(1);" || goto chg_port
%php% "chg_port(env('nport'));" || %pause% && goto end
set htd_port=%nport%
if "%1"=="noRestart" goto end
call :restart_apache
goto end


:vhost_add
echo  # 现有的虚拟主机列表 #
%php% "showvhs();" || %pause% && goto end
echo.
echo  [ 虚拟主机的主机名和标识. 例 test.com 或 blog.test.com ]
set /p hName=-^> 新增主机名: 
if "%hName%"=="" goto end
echo.
echo  [ 别名用于绑定主机名以外的多个域名. 支持 * 号泛解析.
echo    如 www.test.com 或 *.test.com(泛解析，默认值)
echo    多个请用空格隔开, 如 "s1.test.com s2.test.com *.phpnow.org" ]
set /p hAlias=-^> 主机别名(可选): 
:vhost_add_htdocs
echo.
echo  [ 指定网站目录. 留空则默认为 .\vhosts\%hName%]
set htdocs=
set /p htdocs=-^> 网站目录(可选): 
if "%htdocs%"=="" goto vhost_add_2

%php% "$d = rpl('/', '\\\\', $_ENV['htdocs']); if (is_dir($d)) exit(0); if (file_exists($d)) exit(1); if (!@mkdir($d, 0, 1)) exit(2);" || echo  # 路径不正确或创建目录失败! && %pause% && goto vhost_add_htdocs

:vhost_add_2
echo.
echo  [ 如果分配此主机给其他用户, 并限制其权限, 请输入 y,
echo    否则, 请输入 n. 默认 Y ]
set /p p=-^> 限制 php 的 open_basedir ? (Y/n): 
%php% "vhost_add(env('hName'), env('htdocs'), env('htd_port'), env('hAlias'), env('p'));" && call :restart_apache && goto end
echo.
%pause%
goto end


:vhost_del
echo  # 现有的虚拟主机列表 #
%php% "showvhs();" || %pause% && goto end
echo.
echo  [ 要删除虚拟主机, 请输入主机名或序号. ]
set /p hName=-^> 选择虚拟主机: 
if "%hName%"=="" goto end
%php% "vhost_del(env('hName'));" && call :restart_apache
echo.
%pause%
goto end


:vhost_mod
echo  # 现有的虚拟主机列表 #
%php% "showvhs();" || %pause% && goto end
echo.
echo  [ 要修改虚拟主机, 请输入主机名或序号. ]
set /p hName=-^> 选择虚拟主机: 
if "%hName%"=="" goto end
echo.
echo  [ 请输入新的主机别名, 原有数据将被覆盖! 留空不修改. ]
echo  [ 要在原基础上添加, 请输入 +phpnow.org 或 phpnow.org+ ]
set /p hAlias=-^> 主机别名: 
echo.
echo  [ 在没有 index.php 或 index.html 文件时, 显示目录列表 ]
set /p hIndex=-^> 启用 目录索引? (y/N): 
:vhost_mod_confirm
echo.
echo  [ 请检查上面的输入的内容正确无误 ]
echo.
set /p sure=-^> 确认? (y/n) 
if /i "%sure%"=="n" goto end
if /i not "%sure%"=="y" goto vhost_mod_confirm
%php% "vhost_mod(env('hName'), env('hAlias'), env('hIndex'));" || %pause% && goto end
call :restart_apache
goto end


:vProxy_add
echo  [ 添加一个虚拟主机, 代理到其他 http 地址 ]
echo.
echo  # 现有的虚拟主机列表 #
%php% "showvhs();" || %pause% && goto end
:vProxy_add_hN
echo.
echo  [ 添加新的主机名. 如 test.com 或 jsp.test.com ]
set hName=
set /p hName=-^> 主机名: 
if "%hName%"=="" goto end
%php% "if (regrpl('[\w\d\.\-]+', '', env('hName'))) exit(1);" && goto vProxy_add_hA
echo  # 主机名只能由 "a-z0-9.-" 组成!
%pause% && goto vProxy_add_hN
:vProxy_add_hA
echo.
echo  [ 绑定其他域名. 如 www.abc.com 或 *.abc.com(泛解析); 多个请用空格隔开 ]
set hAlias=
set /p hAlias=-^> 主机别名(可选): 
if "%hAlias%"=="" set hAlias=*.%hName%
%php% "if (regrpl('[\w\d\.\- *]+', '', env('hAlias'))) exit(1);" && goto vProxy_add_hP
echo  # 主机别名只能由 "a-z0-9.-* " 组成!
%pause% && goto proxy_add_hA
:vProxy_add_hP
echo.
echo  [ 例: localhost:8080, 192.168.0.100 或 google.com ]
echo  [ 访问此虚拟主机的域名, 将代理到此目标. ]
set hPass=
set /p hPass=-^> 代理目标: 
if "%hPass%"=="" goto vProxy_add_hP
%php% "if (regrpl('[a-z0-9\.\-_:\/]+', '', env('hPass'))) exit(1);" && goto vProxy_add_go
echo  # 目标地址只能由 "a-z0-9.-_:/" 组成!
%pause% && goto vProxy_add_hP
:vProxy_add_go
%php% "vProxy_add(env('hName'), env('hAlias'), env('hPass'));"
call :restart_apache
goto end


:vProxy_dis
echo  [ 继续将删除所有代理主机记录! ]
echo.
set /p sure=-^> 确认? (y/n)
if /i "%sure%"=="n" goto end
if /i "%sure%"=="y" goto un_proxy_1
goto un_proxy
:un_proxy_1
%php% "vProxy_dis();" || %pause% && goto end
call :restart_apache
goto end


:eA_en
if not exist Pn\eAccelerator*.dll ( echo # eAccelerator dll 没有找到 && %pause% && goto end )
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
echo  ^|        设置 php error_reporting (错误报告) 等级                ^|
echo  ^|                                                                ^|
echo  ^|     0 - E_ALL ^& ~E_NOTICE ^& ~E_WARNING                         ^|
echo  ^|                               普通; 运作环境, 忽略一般警告     ^|
echo  ^|                                                                ^|
echo  ^|     1 - E_ALL                                                  ^|
echo  ^|                               严格; 调试环境, 显示所有错误     ^|
echo  ^|________________________________________________________________^|
set /p input=-^> 请选择: 
if "%input%"=="0" set err_reporting=E_ALL ^& ~E_NOTICE ^& ~E_WARNING
if "%input%"=="1" set err_reporting=E_ALL
if "%err_reporting%"=="" goto end
%php% "frpl($php_ini, '^(error_reporting)\s*=.*(\r\n)', '$1 = %err_reporting%$2');" || %pause% && goto end
call :restart_apache
goto end


:reset_mydpwd
set /p newpwd=-^> 重设 root 密码: 
if "%newpwd%"=="" goto reset_mydpwd
echo.
set pnTmp=%SystemRoot%\Temp\Pn_%RANDOM%.%RANDOM%
echo SET PASSWORD FOR 'root'@'localhost' = PASSWORD('%newpwd%');>%pnTmp%
if exist %myd_dir%\data\%COMPUTERNAME%.pid %net% stop %myd_svc%
set myini=%CD%\%myd_dir%\my.ini
start /b %myd_dir%\bin\%myd_exe% --defaults-file="%myini%" --init-file=%pnTmp%
%myd_dir%\bin\mysqladmin.exe shutdown -uroot -p"%newpwd%"
echo  等待 MySQL 退出 ...
echo.
%php% "while(@file_exists('%myd_dir%\data\%COMPUTERNAME%.pid')) usleep(50000);"
echo.>%pnTmp%
del %pnTmp% /Q
%net% start %myd_svc% || %pause%
goto end


:myd_upgrade
echo   ______________________________________________________________
echo  ^|                                                              ^|
echo  ^|   此功能用于更新 MySQL 数据库目录 (data 目录) 的特性到当前   ^|
echo  ^|   版本. 当 data 目录迁移到一个更新版本的 MySQL 请执行此项.   ^|
echo  ^|                                                              ^|
echo  ^|   通过调用 mysql_upgrade.exe 实现.                           ^|
echo  ^|______________________________________________________________^|
echo.
set /p sure=-^> 确认继续? (y/N): 
if /i not "%sure%"=="y" goto end
:myd_upgrade_pwd
set pwd=
set /p pwd=-^> 请输入 MySQL root 密码: 
%php% "chk_mysql('%myd_port%', env('pwd'));" && goto myd_upgrade_exe
if %errorlevel%==1045 (
  echo  # 密码不正确, 请重新输入.
  goto myd_upgrade_pwd
)
if %errorlevel%==2003 (
  echo  # 尝试连接 MySQL^(port:%myd_port%^) 失败.
  echo  # 请确认 MySQL 运行正常.
  %pause% & goto end
)
:myd_upgrade_exe
%myd_dir%\bin\mysql_upgrade.exe --user=root --password="%pwd%" --force
echo.
echo  # 请复查上面的执行结果, 全部 OK 即为升级成功.
%pause%
goto end


:chk_port
if not exist %Sys32%\tasklist.exe goto chk_port_1
if not exist %Sys32%\netstat.exe goto chk_port_2
%php% "chk_port('%htd_port%');"
if not errorlevel 1 echo   指定的 httpd 端口 %htd_port% 暂时未被占用.
%php% "chk_port('%myd_port%');"
if not errorlevel 1 echo   指定的 MySQL 端口 %myd_port% 暂时未被占用.
echo.
%pause% & goto end
:chk_port_1
echo  # 缺少 %Sys32%\tasklist.exe, 无法进行. & %pause% & goto end
:chk_port_2
echo  # 缺少 %Sys32%\netstat.exe, 无法进行. & %pause% & goto end


:force_stop
set taskkill=%Sys32%\taskkill.exe
if not exist %taskkill% (
  echo  # 缺少 %taskkill%, 无法进行. & %pause% & goto end
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
echo       备份 / 还原 下列配置文件
echo       Apache 主配置 :  %htd_dir%\conf\httpd.conf
echo       虚拟主机 配置 :  %vhs_cfg%
echo       php.ini       :  %php_dir%\php-apache2handler.ini
echo       MySQL 配置    :  %myd_dir%\my.ini
echo  ^|______________________________________________________________^|
echo.
echo  # 现有备份列表 (保存在 %cfg_bak_zip%) #
echo.
%php% "cfg_bak('show');" || %pause% && goto end
echo.
echo  # 执行操作 #
echo.
echo      B - 备份配置
echo      R - 还原配置
echo      D - 删除备份
echo.
set input=
set /p input=-^> 请选择: 
echo.
if /i "%input%"=="B" goto cfg_bak_B
if /i "%input%"=="R" goto cfg_bak_R
if /i "%input%"=="D" goto cfg_bak_D
echo  # 未选择操作, 退出 & %pause% & goto end

:cfg_bak_B
set input=
set /p input= 备份名称: 
if "%input%"=="" goto cfg_bak_B
%php% "cfg_bak('backup '.env('input'));"
echo.
%pause%
goto end

:cfg_bak_R
echo  # 现有备份列表 (保存在 %cfg_bak_zip%) #
echo.
%php% "cfg_bak('show');" || %pause% && goto end
echo.
echo  [ 还原之前请确认是否需要对现有配置进行备份! ]
echo.
set n=
set /p n=-^> 还原到此备份序号: 
if "%n%"=="" echo  # 未执行操作! && %pause% && goto end
%php% "$p = env('n'); if ($p !== ''.ceil($p) || 0 > $p) exit(1);" || goto cfg_bak_R
%php% "cfg_bak('restore '.env('n'));" || %pause% && goto end
echo.
set input=
set /p input= 配置已还原, 立即重启服务? (y/N): 
if /i not "%input%"=="y" goto end
call :restart_apache
echo.
%net% stop %myd_svc%
%net% start %myd_svc%
goto end

:cfg_bak_D
echo  # 现有备份列表 (保存在 %cfg_bak_zip%) #
echo.
%php% "cfg_bak('show');" || %pause% && goto end
echo.
set n=
set /p n=-^> 删除此序号的备份: 
if "%n%"=="" echo  # 未执行操作! && %pause% && goto end
%php% "$p = env('n'); if ($p !== ''.ceil($p) || 0 > $p) exit(1);" || goto cfg_bak_D
%php% "cfg_bak('delete '.env('n'));"
echo.
%pause%
goto end


:end
prompt
popd
