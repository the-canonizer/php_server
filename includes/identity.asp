

<%

# modes:	selections:
#	0 Browsing as: guest
#		Login
#	1 Browsing as: <cid>
#		Login
#		Clear Browser (logout.asp&clear=1)
#	2 Logged in as: <cid>
#		$Session->{'logged_in'} = 1, can go to personal pages.
#		Logout
#		Clear Browser (logout.asp&clear=1)


my $mode = 0;	# make this global so everyone can see it.


sub guest_cookie_expire_time {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time + (60*60*24));
	my @days = (Sun, Mon, Tue, Wed, Thu, Fri, Sat);
	my @months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);
	$wday = @days[$wday];
	$mon  = $months[$mon];
	$year = $year + 1900;

	return("$wday, $mday $mon $year $hour:$min:$sec GMT\n");
}


sub identity {

	my $script_name = $ENV{'SCRIPT_NAME'};

	if ($ENV{'PATH_INFO'}) {
		$script_name .= $ENV{'PATH_INFO'};
	}

	my $login_url = 'https://' . &func::get_host() . "/secure/login.asp?destination=$script_name";
	my $logout_url = 'http://' . &func::get_host() . "/logout.asp?destination=$script_name";
	my $clear_url = 'http://' . &func::get_host() . "/logout.asp?clear=1&destination=$script_name";

	if ($ENV{'QUERY_STRING'}) {
		$login_url .= ('?' . $ENV{'QUERY_STRING'});
		$logout_url .= ('?' . $ENV{'QUERY_STRING'});
		$clear_url .= ('?' . $ENV{'QUERY_STRING'});
	}


	$Session->{'page_count'}++;

	my $cid = 0; # canon id
	if ($Request->Form('cid')) {
		$cid = int($Request->Form('cid'));
	} elsif ($Request->QueryString('cid')) {
		$cid = int($Request->QueryString('cid'));
	} elsif ($Request->Cookies('canonizer', 'cid')) {
		$cid = int($Request->Cookies('canonizer', 'cid'));
	} elsif ($Session->{'cid'}) {
		$cid = $Session->{'cid'};
	}

	if ($cid != $Session->{'cid'}) { # lookup and reset personal session data.
		$Session->{'cid'} = $cid;
		$Session->{'logged_in'} = 0; # if cid changes - we must move to browsing as mode.
					     # till we login again.
		$Session->{'email'} = '';    # and reload session browsing settings.
	}

	my $logged_in_as;

	if ($cid) {

		if (! length($Session->{'email'})) { # reload browsing values into session and validate cid.
			my $dbh = &func::dbh_connect(1);
			if ($dbh) {
				my $selstmt = "select email from person where cid = $cid";
				my $sth = $dbh->prepare($selstmt) || die $selstmt;
				$sth->execute() || die $selstmt;
				my $rs = $sth->fetch();
				$sth->finish();
				if ($rs) {
					$Session->{'email'} = &func::hex_decode($rs->[0]);
					# must also set canonizer and stuff...
				} else { # invalid cid!
					goto NO_CID;
				}
			} #if no db just leave things as they are.
		}

		# I've got to query the DB here and get the email from the DB
		# especially if we are not logging in - but just returning with cid in cookie.
		# and don't clear the gid if we fail.
		if ($Session->{'gid'}) { # got a cid so free the guest id if not already cleared
			&free_gid($Session->{'gid'});
			$Session->{'gid'} = 0;
		}
		$Session->{'cid'} = $cid;
		$logged_in_as = $Session->{'email'};
		# $logged_in_as = "Canonizer_" . $cid;
		$mode = 1;

		# set cookie cid (and the compact_policy)
		my $compact_policy = 'CP="NON DSP COR LAW CURa CONa HISa TELa OTPa OUR DELa OTRa IND UNI STA"';
	        $Response->AddHeader('P3P', $compact_policy);

		$Response->{Cookies}{canonizer} = {
				Value   => {
					cid => $cid,
				},
				Expires => "Fri, 1 Jan 2010 00:00:00 GMT",
				Domain  => 'canonizer.com',
				Path    => '/'
		};
	} else {
NO_CID:		my $gid = $Session->{'gid'};
		if (! $gid) {  # for some reason, we don't always have a gid here.
			$gid = &get_gid();
			$Session->{'gid'} = $gid;
		}
		$logged_in_as = 'Guest_' . $Session->{'gid'};

		# set cookie gid (and the compact_policy)
		my $compact_policy = 'CP="NON DSP COR LAW CURa CONa HISa TELa OTPa OUR DELa OTRa IND UNI STA"';
	        $Response->AddHeader('P3P', $compact_policy);

		$Response->{Cookies}{canonizer} = {
				Value   => {
					gid => $gid,
				},
				Expires => guest_cookie_expire_time(),
				Domain  => 'canonizer.com',
				Path    => '/'
		};
	}

	my $mode_prompt = 'Browsing as:';
	if ($Session->{'logged_in'}) {
		$mode_prompt = 'Logged in as:';
		$mode = 2;
	}


%>

  	<div class="identity">
  	
	<h1>Identity</h1>

	<p><%=$mode_prompt%> <%=$logged_in_as%></p>
<%
	if ($mode == 2) {
%>
		<p><a href = "<%=$logout_url%>">Logout (to browsing as)</a></p>
		<p><a href = "<%=$clear_url%>">Clear Browser</a></p>
<%
	} elsif ($mode == 1) {
%>
		<p><a href = "<%=$login_url%>">Login</a>
		<p><a href = "<%=$clear_url%>&clear=1">Clear Browser</a></p>
<%
	} else {
%>
		<p><a href = "<%=$login_url%>">Login</a>
		<p><a href = "http://<%=&func::get_host()%>/secure/profile_id.asp">Register</a></p>
<%
	}
%>

  	</div>

<%

}

%>
