
  PHPnow 1.5.6-1

  更多信息请访问 http://PHPnow.org



  安装使用

    解压后执行 Setup.cmd，根据提示进行，程序将会调用 Init.cmd 初始化。
    成功初始化后 Init.cmd 自动改名为 Init.cm_。
    如有必要，可将其改名为 Init.cmd 重新初始化。重新初始化不会丢失网站数据，仅仅是配置复位。

    PnCp.cmd 是 PHPnow 控制面板(Control Panel)。大部分功能都在上面实现。

    PnCmds 目录下有一些常用的 cmd 脚本，控制程序的运行。你可以建立快捷方式到桌面或其他位置。



  包含组件

    Apache-2.0.63
    Apache-2.2.16
    MySQL-5.0.90
    MySQL-5.1.50

    PHP-5.2.14
    Zend Optimizer-3.3.3
    phpMyAdmin-3.3.7
    * eAccelerator 0.9.6-1
    * 默认没有启用。执行 PnCp.cmd 选 3 启用。



  默认参数：

    Apache 默认已支持 rewrite, 请使用 .htaccess 文件配置
      ( 更多信息请看 http://phpnow.org/go.php?id=1008 )
    php.ini 位置 = php-5.2.x-Win32/php-apache2handler.ini



  默认 php 扩展

    php_curl.dll
    php_gd2.dll
    php_mbstring.dll
    php_mcrypt.dll
    php_mhash.dll
    php_mysql.dll
    php_pdo.dll
    php_pdo_mysql.dll
    php_sockets.dll
    php_xmlrpc.dll
    php_zip.dll
    ...
