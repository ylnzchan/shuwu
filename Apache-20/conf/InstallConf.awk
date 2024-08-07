#
# InstallConf.awk Apache HTTP 2.0 script to rewrite the @@ServerRoot@@ 
# tags in httpd-win.conf to httpd.default.conf - then duplicate the
# conf files if they don't already exist.
#
# Note that we -don't- want the ARGV file list, so no additional {} blocks
# are coded.  Use explicit args (more reliable on Win32) and use the fact
# that ARGV[] params are -not- '\' escaped to process the C:\Foo\Bar Win32
# path format.  Note that awk var=path would not succeed, since it -does-
# escape backslashes in the assignment.  Note also, a trailing space is
# required for paths, or the trailing quote following the backslash is 
# escaped, rather than parsed.
#
BEGIN { 
    domainname = ARGV[1];
    servername = ARGV[2];
    serveradmin = ARGV[3];
    serverport = ARGV[4];
    serversslport = ARGV[5];
    serverroot = ARGV[6];

    delete ARGV[6];
    delete ARGV[5];
    delete ARGV[4];
    delete ARGV[3];
    delete ARGV[2];
    delete ARGV[1];

    gsub( /\\/, "/", serverroot );
    gsub( /[ \/]+$/, "", serverroot );
    tstfl = serverroot "/logs/install.log"
    confroot = serverroot "/conf/";

    print "Installing Apache HTTP 2.0 server with" >tstfl;
    print " DomainName =  " domainname >tstfl;
    print " ServerName =  " servername >tstfl;
    print " ServerAdmin = " serveradmin >tstfl;
    print " ServerPort =  " serverport >tstfl;
    print " ServerRoot =  " serverroot >tstfl;

    srcfl = confroot "httpd-win.conf";
    dstfl = confroot "httpd.default.conf";
    while ( ( getline < srcfl ) > 0 ) {
        gsub( /@@ServerRoot@@/, serverroot );
        gsub( /@@DomainName@@/, domainname );
        gsub( /@@ServerName@@/, servername );
        gsub( /@@ServerAdmin@@/, serveradmin );
        gsub( /@@Port@@/, serverport );
        print $0 > dstfl;
    }
    close(dstfl);
    close(srcfl);
    print "Rewrote " srcfl "\n to " dstfl > tstfl;

    gsub(/\//, "\\", srcfl);
    if (system("del \"" srcfl "\"")) {
        print "Failed to remove " srcfl > tstfl;
    } else {
        print "Successfully removed " srcfl > tstfl;
    }

    srcfl = confroot "ssl-std.conf.in";
    dstfl = confroot "ssl.default.conf";
    while ( ( getline < srcfl ) > 0 ) {
	gsub( /@@ServerRoot@@/, serverroot );
	gsub( /SSLMutex  file:@exp_runtimedir@\/ssl_mutex/, "SSLMutex default" );
	gsub( /@exp_runtimedir@/, "logs" );
	gsub( /@exp_htdocsdir@/, serverroot "/htdocs" );
	gsub( /@exp_logfiledir@/, "logs" );
	gsub( /@exp_sysconfdir@/, "conf" );
	gsub( /@exp_cgidir@/, serverroot "/cgi" );
        gsub( /www.example.com/, servername );
        gsub( /you@example.com/, serveradmin );
        gsub( /443/, serversslport );
        print $0 > dstfl;
    }
    if ( close(dstfl) >= 0 ) {
        close(srcfl);
        print "Rewrote " srcfl "\n to " dstfl > tstfl;

        gsub(/\//, "\\", srcfl);
        if (system("del \"" srcfl "\"")) {
            print "Failed to remove " srcfl > tstfl;
        } else {
            print "Successfully removed " srcfl > tstfl;
        }
    }

    srcfl = confroot "httpd.default.conf";
    dstfl = confroot "httpd.conf";
    if ( ( getline < dstfl ) < 0 ) {
	while ( ( getline < srcfl ) > 0 ) {
	    print $0 > dstfl;
    	}
        close(srcfl);
        print "Duplicated " srcfl "\n to " dstfl > tstfl;
    } else {
        print "Existing file " dstfl " preserved" > tstfl;
    }
    close(dstfl);

    srcfl = confroot "ssl.default.conf";
    dstfl = confroot "ssl.conf";
    if ( ( getline < dstfl ) < 0 ) {
	while ( ( getline < srcfl ) > 0 ) {
	    print $0 > dstfl;
    	}
        close(srcfl);
        print "Duplicated " srcfl "\n to " dstfl > tstfl;
    } else {
        print "Existing file " dstfl " preserved" > tstfl;
    }
    close(dstfl);

    srcfl = confroot "magic.default";
    dstfl = confroot "magic";
    if ( ( getline < dstfl ) < 0 ) {
	while ( ( getline < srcfl ) > 0 ) {
	    print $0 > dstfl;
    	}
        close(srcfl);
        print "Duplicated " srcfl "\n to " dstfl > tstfl;
    } else {
        print "Existing file " dstfl " preserved" > tstfl;
    }
    close(dstfl);

    srcfl = confroot "mime.types.default";
    dstfl = confroot "mime.types";
    if ( ( getline < dstfl ) < 0 ) {
	while ( ( getline < srcfl ) > 0 ) {
	    print $0 > dstfl;
    	}
        close(srcfl);
        print "Duplicated " srcfl "\n to " dstfl > tstfl;
    } else {
        print "Existing file " dstfl " preserved" > tstfl;
    }
    close(dstfl);

    srcfl = confroot "InstallConf.awk";
    gsub(/\//, "\\", srcfl);
    if (system("del \"" srcfl "\"")) {
        print "Failed to remove " srcfl > tstfl;
    } else {
        print "Successfully removed " srcfl > tstfl;
    }
    close(tstfl);
}