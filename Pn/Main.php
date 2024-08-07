<?php
/*
  http://phpnow.org
  YinzCN_at_Gmail.com
*/

error_reporting(E_ALL);
ini_set('date.timezone', 'UTC');
date_default_timezone_set('UTC');

// variables
$PnDir = getcwd();
$sysroot = env('SystemRoot');

$htd_dir = env('htd_dir');
$php_dir = env('php_dir');
$htd_cfg = $htd_dir.'\conf\httpd.conf';
$vhs_cfg = env('vhs_cfg');
$php_ini = $php_dir.'\php-apache2handler.ini';


// Load
if (count($argv) > 1) {
  $a = implode(' ', $argv);
  $a = substr($a, strlen($argv[0]) + 1);
  $a = str_replace('`', '"', $a);
  eval($a);
}
exit;
// end of Load


// �˳�(��Ϣ $m, ������� $n);
function quit($m, $n) {
  echo "\r\n ".$m."\r\n";
  exit($n);
}


function env($n) { return getenv($n); }


function rpl($a, $b, $c) { return str_replace($a, $b, $c);}


// ���¶��� preg_replace()
function regrpl($p, $r, $s) {
  $p = '/'.$p.'/im';
  $s = preg_replace($p, $r, $s);
  if ($s === NULL) quit('regrpl(): ����! Ϊ�������ݶ���ֹ.', 1);
  return $s;
}


// ��ȡ�������ļ� $fn ������
function rfile($fn) {
  if (file_exists($fn)) {
    $handle = fopen($fn, 'r');
    $c = fread($handle, filesize($fn));
    fclose($handle);
    return $c;
  } else {
    quit('�ļ� '.$fn.' ������', 1);
  }
}


// д������ $c ���ļ� $fn
function wfile($fn, $c) {
  if (!is_writable($fn) && file_exists($fn))
    quit('�ļ� '.$fn.' ����д', 1);
  else {
    $handle = fopen($fn, 'w');
    if (fwrite($handle, $c) === FALSE)
      quit('д���ļ� '.$fn.' ʧ��', 1);
    fclose($handle);
  }
}


// �����ļ� $a �� $b
function cp($a, $b) {
  $c = rfile($a);
  wfile($b, $c);
}


// ���ļ� $fn ʹ��������ʽ $p �滻Ϊ $r
function frpl($fn, $p, $r) {
  global $htd_dir, $php_dir, $htd_cfg, $vhs_cfg, $php_ini;

  $s = rfile($fn);
  $p = '/'.$p.'/im';
  $s = preg_replace($p, $r, $s);
  wfile($fn, $s);
}


function chk_path($path) {
  $str = regrpl('[^\x80-\xff]+', '', $path);
  if (!$str) exit(0);
  echo "\r\n # ·�����ɺ���˫�ֽ��ַ�: ".$str."\r\n";
  echo "\r\n # ���� Apache + PHP ��������������.";
  echo "\r\n # �뻻һ������Ӣ���ַ���·������.\r\n\r\n";
  exit(1);
}


// check port
// ���˿��Ƿ�ռ��. netstat + tasklist
function chk_port($port) {
  $s = shell_exec('netstat.exe -ano');
  $tok = strtok($s, ' ');
  $pid = NULL;
  while ($tok) {
    if ($tok == '0.0.0.0:'.$port) {
      for ($i=3; $i; $i--)
        $pid = rtrim(strtok(' '));
      if (is_numeric($pid))
        break;
    }
    $tok = strtok(' ');
  }

  $task = NULL;
  if (is_numeric($pid)) {
    $lst = array(
      'WebThunder.exe'  => 'Web Ѹ��',
      'inetinfo.exe'    => 'IIS',
      'Thunder5.exe'    => 'Ѹ��5',
      'httpd.exe'       => 'Apache 2.2',
      'mysqld-nt.exe'   => 'MySQL',
      'mysqld.exe'   => 'MySQL');
    $s = shell_exec('tasklist.exe /fi "pid eq '.$pid.'" /nh');
    $task = trim(strtok($s, ' '));
    $d = ' ';
    if (isset($lst[$task]))
      $d = ' "'.$lst[$task].'" ';
    quit(' �˿� '.$port.' �ѱ�'.$d.'('.$task.' PID '.$pid.') ʹ��!', 1);
  }
}


// change httpd port
function chg_port($newport) {
  global $htd_cfg, $vhs_cfg;
  if (file_exists($htd_cfg)) {
    $c = rfile($htd_cfg);
    $c = regrpl('^([ \t]*Listen[ \t]+[^:]+):\d+(\r\n)', '$1:'.$newport.'$2', $c);
    $c = regrpl('^([ \t]*Listen)[ \t]+\d+(\r\n)', '$1 '.$newport.'$2', $c);
    $c = regrpl('^([ \t]*ServerName[ \t]+[^:]+):\d+(\r\n)', '$1:'.$newport.'$2', $c);
    wfile($htd_cfg, $c);
  }

  if (file_exists($vhs_cfg)) frpl($vhs_cfg, '(ServerName[ \t]+[^:]+):\d+', '$1:'.$newport);
  frpl('Pn/Config.cmd', '^(set htd_port)=\d+(\r\n)', '$1='.$newport.'$2');
}


// update config
function upcfg() {
  global $htd_dir, $php_dir, $htd_cfg, $vhs_cfg, $php_ini, $PnDir, $sysroot;

  // php.ini
  $str = rfile($php_ini);
  $str = regrpl('[A-Z]:\\\\[^\\\\\r\n]+(\\\\Temp)', $sysroot.'$1', $str);
  $str = regrpl('(\.\.\\\\\.\.\\\\)[^\\\\]+(\\\\ext\\\\)', '$1'.$php_dir.'$2', $str);
  $str = regrpl('^(extension_dir)[ \t]+=[ \t]+"[^"]+"', '$1 = "..\\..\\'.$php_dir.'\\ext"', $str);
  wfile($php_ini, $str);

  // httpd.conf
  $str = rfile($htd_cfg);
  $str = regrpl('(php5_module "\.\.\/)[^\/]+(\/[^\/]+\.dll")', '$1'.$php_dir.'$2', $str);
  $str = regrpl('(PHPIniDir "\.\.\/)[^\/]+(\/")', '$1'.$php_dir.'$2', $str);
  wfile($htd_cfg, $str);

  // httpd-vhosts.conf
  $str = rfile($vhs_cfg);
  $str = regrpl('(open_basedir ")[^;]+(\\\\vhosts\\\\[^;]+;)', '$1'.$PnDir.'$2', $str);
  $str = regrpl('[A-Z]:\\\\[^\\\\]+\\\\Temp;', $sysroot.'\Temp;', $str);
  wfile($vhs_cfg, $str);
}


function apache_log_default() {
  global $htd_cfg;
  $str = rfile($htd_cfg);
  $str = regrpl('\r\nLogFormat.*comonvhost\r\nCustomLog.*comonvhost\r\n', '', $str);
  $str = regrpl('##(CustomLog.*common\r\n)', '$1', $str);
  wfile($htd_cfg, $str);
}


function apache_log_pipe() {
  global $htd_cfg;
  $str = rfile($htd_cfg);
  $str = regrpl('^([ ]*)(CustomLog.*common\r\n)', '$1##$2', $str);
  $str = regrpl('\r\nLogFormat.*comonvhost\r\nCustomLog.*comonvhost\r\n', '', $str);
  $str .= '
LogFormat "%v %h %l %u %t \"%r\" %>s %b" comonvhost
CustomLog "|bin/rotatelogs.exe logs/%Y-%m-%d_access_log 16M" comonvhost
';
  wfile($htd_cfg, $str);
}


function apache_log_dis() {
  global $htd_cfg;
  $str = rfile($htd_cfg);
  $str = regrpl('\r\nLogFormat.*comonvhost\r\nCustomLog.*comonvhost\r\n', '', $str);
  $str = regrpl('^[ ]*(CustomLog.*common\r\n)', '##$1', $str);
  wfile($htd_cfg, $str);
}


function vProxy_add($hName, $hAlias, $hPass)
{
  global $htd_cfg, $vhs_cfg;
  frpl($htd_cfg, '^#(Load.*proxy_mod.*\r\n)', '$1');
  frpl($htd_cfg, '^#(Load.*proxy_http.*\r\n)', '$1');

  if (!$hAlias) $hAlias = '*.'.$hName;
  $str = rfile($vhs_cfg);
  $str.= '
<VirtualHost *>
    ServerName '.$hName.':'.env('htd_port').'
    ServerAlias '.$hAlias.'
    ProxyPass / http://'.$hPass.'/
    ProxyPassReverse / http://'.$hPass.'/
</VirtualHost>
';
  wfile($vhs_cfg, $str);
}


function vProxy_dis()
{
  global $htd_cfg, $vhs_cfg;
  frpl($htd_cfg, '^(Load.*proxy_mod.*\r\n)', '#$1');
  frpl($htd_cfg, '^(Load.*proxy_http.*\r\n)', '#$1');

  $str = rfile($vhs_cfg);
  $str = rpl("\r\n", "\n", $str);
  $str = regrpl('\n?<VirtualHost \*>[^<]*ProxyPass [^<]*<\/VirtualHost>\n?', '', $str);
  $str = rpl("\n", "\r\n", $str);
  wfile($vhs_cfg, $str);
}


// �����������: $hn ������, $htdocs ����Ŀ¼, $port �˿�, $hAlias ����, $lt �Ƿ����� open_basedir
function vhost_add($hn, $htdocs, $port, $hAlias, $lt) {
  global $vhs_cfg, $PnDir, $sysroot;

  $htdocs = trim($htdocs);

  $hn = trim($hn);
  if (regrpl('[\d]+', '', $hn) === '') quit(' # ����������Ϊ������!', 1);
  if ($tmp = regrpl('[a-z0-9\.-]+', '', $hn)) quit(' # ���������зǷ��ַ� "'.$tmp.'"', 1);

  if ($port < 1 || $port > 65535) exit;

  $str = rfile($vhs_cfg);

  if (strpos($str, 'ServerName '.$hn.':')) quit(' # �������Ѵ���!', 1);
  if (!$hAlias) $hAlias = '*.'.$hn;

  if (!$htdocs) {
    if (!file_exists('vhosts')) mkdir('vhosts');
    $tmp = 'vhosts/'.$hn;
    @mkdir($tmp);
    $htdocs = '../'.$tmp;
    $vhDir = $PnDir.'\\vhosts\\'.$hn;
    copy($PnDir.'/Pn/index.ph_', $PnDir.'/'.$tmp.'/index.php');
    $vhDir_Cfg = '
    <Directory "'.$htdocs.'">
        Options -Indexes FollowSymLinks
    </Directory>';
  } else {
    $tmp = getcwd();
    chdir($htdocs);
    $vhDir = getcwd();
    chdir($tmp);

    $htdocs = rpl("\\", '/', $vhDir);
    if (!file_exists($htdocs.'/index.php'))
      copy($PnDir.'/Pn/index.ph_', $htdocs.'/index.php');

    $vhDir_Cfg = '
    <Directory "'.$htdocs.'">
        Options -Indexes FollowSymLinks
        Allow from all
        AllowOverride All
    </Directory>';
  }

  $o_bdir = '';
  if (!($lt=='n' || $lt=='N'))
    $o_bdir = "\r\n".'    php_admin_value open_basedir "'.$vhDir.';'.$sysroot.'\Temp;"';

  $str .= '
<VirtualHost *>'.$vhDir_Cfg.'
    ServerAdmin admin@'.$hn.'
    DocumentRoot "'.$htdocs.'"
    ServerName '.$hn.':'.$port.'
    ServerAlias '.$hAlias.'
    ErrorLog logs/'.$hn.'-error_log'.$o_bdir.'
</VirtualHost>
';

  wfile($vhs_cfg, $str);
}


// �޸���������
function vhost_mod($vh, $n_hA, $hIndex) {
  global $htd_cfg, $vhs_cfg;

  $str = rfile($vhs_cfg);
  $Vhs = rvhs($str);

  // ȷ����� $n �������� $vh
  if (regrpl('[0-9]+', '', $vh) === '') {
    $n = $vh;
    if (!isset($Vhs[$n])) quit(' # �Ҳ������Ϊ '.$n.' ����������!', 1);
    $vh = cuts($Vhs[$n], 'ServerName ', ':');
  } else {
    foreach ($Vhs as $i => $tmp)
      if (strpos($tmp, 'ServerName '.$vh.':'))
        $n = $i;
    if (!isset($n)) quit(' # �Ҳ�����Ϊ "'.$vh.'" ����������!', 1);
  }

  // �޸��������� (ServerAlias)
  $n_hA = trim($n_hA);
  if ($n_hA) {
    $hA = cuts($Vhs[$n], 'ServerAlias ', "\n");  // ȡ��ԭ���� ServerAlias
    if (substr_count($n_hA, '+'))
      $n_hA = rpl('+', ' '.$hA.' ', $n_hA);
    $n_hA = trim(regrpl('[ \t]+', ' ', $n_hA));
    $str = regrpl('(ServerAlias)[ \t]+'.quotemeta($hA)."(\r\n)", '$1 '.$n_hA.'$2', $str);
  }

  // �޸�Ŀ¼��������
  $hIndex = strtolower($hIndex);
  $A = ($hIndex === 'y') ? '-' : '';
  $B = ($hIndex === 'n') ? '-' : '';

  if ($n == 0) {
    frpl($htd_cfg, '(Options) '.$A.'(Indexes) (FollowSymLinks)', '$1 '.$B.'$2 $3');
  } else {
    $d_str = rpl("\r\n", '!', $str);
    $d_str = regrpl('.*(<VirtualHost [^<]+ServerName '.$vh.':[^<]+<\/VirtualHost>).*', '$1', $d_str);
    $vhDir = regrpl('.*DocumentRoot "([^!]+)"!.*', '$1', $d_str);
    $vhDir = rpl('/', '\/', $vhDir);
    if ($hIndex === 'y') {
      $htd_cfg_str = rfile($htd_cfg);
      $htd_cfg_str = regrpl('^##(LoadModule.*autoindex.*\.so)', '$1', $htd_cfg_str);
      $htd_cfg_str = regrpl('^##?(Include.*autoindex.*)', '$1', $htd_cfg_str);
      wfile($htd_cfg, $htd_cfg_str);
    }
    $str = regrpl('(<Directory "'.$vhDir.'">[^<]+Options )'.$A.'(Indexes[^<]+<\/Directory>)', '$1'.$B.'$2', $str);
  }
  wfile($vhs_cfg, $str);
}


// ɾ����������
function vhost_del($vh) {
  global $vhs_cfg;

  $str = rfile($vhs_cfg);
  $Vhs = rvhs($str);

  // ȷ����� $n �������� $vh
  if (regrpl('[0-9]+', '', $vh) === '') {
    $n = $vh;
    if (!isset($Vhs[$n])) quit(' # �Ҳ������Ϊ '.$n.' ����������!', 1);
    $vh = cuts($Vhs[$n], 'ServerName ', ':');
  } else {
    foreach ($Vhs as $i => $tmp)
      if (strpos($tmp, 'ServerName '.$vh.':'))
        $n = $i;
    if (!isset($n)) quit(' # �Ҳ�����Ϊ "'.$vh.'" ����������!', 1);
  }

  if ($vh == 'default')
    quit(' # Ĭ����������ɾ��!', 1);

  $vhDir = cuts($Vhs[$n], 'DocumentRoot "', '"');
  $vhDir = rpl('/', '\/', $vhDir);

  $str = rpl("\r\n", "\n", $str);
  $str = regrpl('<(\/?Directory[^>]*)>', '[$1]', $str);
  $str = regrpl('\n?<VirtualHost[^<]+ServerName[ \t]+'.$vh.':[^<]+<\/VirtualHost>\n?', '', $str);
  $str = regrpl('\[(\/?Directory[^\]]*)\]', '<$1>', $str);
  $str = rpl("\n", "\r\n", $str);

  wfile($vhs_cfg, $str);
  quit(' # �������� "'.$vh.'" ��ɾ��!', 0);
}


function showvhs() {
  global $vhs_cfg;

  $Vhs = rvhs(rfile($vhs_cfg));
  $str = '';
  for ($i=0; $i<count($Vhs); $i++) {
    $vh = str_pad(cuts($Vhs[$i], 'ServerName ', ':'), 18).'| ';
    $vh .= cuts($Vhs[$i], 'ServerAlias ', "\n");
    $P = cuts($Vhs[$i], 'DocumentRoot "', "\"\n");
    if (!$P) {
      $P = cuts($Vhs[$i], 'ProxyPass / http://', "/\n");
      if ($P) $P = '~'.$P;
    }
    else {
      $P = rpl('../vhosts/', 'vhosts/', $P);
    }
    if ($P) $vh = str_pad($vh, 42).' | '.str_pad($P, ' ', 20);
    $vh = str_pad($vh, (strlen($vh) < 71) ? 70 : 150).'|';
    $str .= ' |'.str_pad($i, 3, ' ', STR_PAD_LEFT).' | '.$vh."\r\n";
  }
  echo ' '.str_repeat('-', 78)."\r\n";
  echo ' | No.| ServerName ������ | ServerAlias ��������   | ����Ŀ¼ / ~����Ŀ��     |'."\r\n";
  echo ' '.str_repeat('-', 78)."\r\n";
  echo $str;
  echo ' '.str_repeat('-', 78);
  echo "\r\n";
}


// ��ȡ $str �а�������������, ��������
function rvhs($str) {
  $Vhs = array();
  $str = regrpl('\s*\n\s*', "\n", $str);
  $str = regrpl('[ \t]+', ' ', $str);
  for ($i=0; $str=strstr($str, "\n<Vir"); $i++) {
    $p = strpos($str, "\n</Vir") + 14;
    $Vhs[$i] = substr($str, 1, $p);
    $str = substr($str, $p);
  }
  return $Vhs;
}


// ��ȡ $str ���� $a ֮��, $z ֮ǰ���ַ���
function cuts($str, $a, $z) {
  $p0 = strpos($str, $a);
  if ($p0 === FALSE) return $p0;
  $p1 = strlen($a) + $p0;
  $p2 = strpos($str, $z, $p1);
  return substr($str, $p1, $p2 - $p1);
}


// check mysql connection
function chk_mysql($port, $pwd) {
  dl('php_mysql.dll');
  for($n=0; $n<3; $n++) {
    $link = @mysql_connect('localhost:'.$port, 'root', $pwd);
    if ($link) {
      mysql_close($link);
      exit();
    }
    $errno = mysql_errno();
    if ($errno === 1045) exit($errno);
    echo ' # �������� MySQL, ���Ե�...'."\r\n";
    sleep(2);
  }
  exit($errno);
}


// �����ļ����� / ��ԭ
function cfg_bak($Arg) {
  global $htd_cfg, $vhs_cfg, $php_ini;

  $Arg = explode(' ', $Arg);
  if(PHP_VERSION_ID < 50300) dl('php_zip.dll');

  $Files = array(
    $htd_cfg,
    $vhs_cfg,
    $php_ini,
    env('myd_dir').'/my.ini',
    'Pn/config.cmd');

  $zipfile = env('cfg_bak_zip');
  $zip = new ZipArchive;
  $zip->open($zipfile, ZIPARCHIVE::CREATE);
  if (!$zip->locateName($tmp = 'PHPnow_config_backup'))
    $zip->addFromString($tmp, '');

  // get Entries
  $Entries = array();
  for ($i=0; $i<$zip->numFiles; $i++)
    $Entries[$i] = $zip->getNameIndex($i);

  // get BakDirs
  $BakDirs = array();
  foreach ($Entries As $e) {
    if ($p = strpos($e, '/')) {
      $bakDir = substr($e, 0, $p);
      if (!in_array($bakDir, $BakDirs))
        array_push($BakDirs, $bakDir);
    }
  }

  // ִ�б���
  if ($Arg[0] === 'backup') {
    $bakDir = $Arg[1].'_'.gmdate('YmdHi', strtotime('+8 hour'));
    $tmp = $bakDir;

    for ($i=1; in_array($tmp.'/', $BakDirs); $i++)
      $tmp = $bakDir.'_'.$i;

    $bakDir = $tmp;

    foreach ($Files as $fn) {
      if (file_exists($fn))
        $zip->addFile($fn, $bakDir.'/'.basename($fn));
    }
    echo "\r\n �����ѱ��ݵ� ".$zipfile." -> ".$bakDir."\r\n";
  }

  // ��ԭ�����ļ�
  if ($Arg[0] === 'restore') {
    $n = $Arg[1];
    if (isset($BakDirs[$n])) {
      $bakDir = $BakDirs[$n];
      foreach ($Files as $fn) {
        $c = $zip->getFromName($bakDir.'/'.basename($fn));
        if ($c) wfile($fn, $c);
      }
    } else {
      quit(" δ�ҵ����Ϊ ".$n." ����\r\n", 1);
    }
  }

  // ��ʾ����
  if ($Arg[0] === 'show') {
    if (count($BakDirs)) {
      foreach ($BakDirs as $n => $bakDir) {
        echo '  '.$n.' - '.$bakDir."\r\n";
      }
    } else {
      echo "\r\n  **�����ļ���Ϊ��**\r\n";
    }
  }

  // ɾ������
  if ($Arg[0] === 'delete') {
    $n = $Arg[1];
    if (isset($BakDirs[$n])) {
      $bakDir = $BakDirs[$n];
      foreach ($Entries As $e) {
        if (substr($e, 0, strlen($bakDir)) === $bakDir)
        $zip->deleteName($e);
      }
      quit(' ���� '.substr($bakDir, 0, -1).' ��ɾ��', 0);
    } else {
      quit(' ɾ��ʧ��! δ�ҵ����Ϊ '.$n.' ����', 1);
    }
  }

  $zip->close();
}
?>