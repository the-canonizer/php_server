<%

########
# main #
########

use topic;


my $nick_name_id = 0;
my $list_cid = 0;
my $anonymous_nick = 1;
if ($Request->Form('nick_name_id')) {
	$nick_name_id = int($Request->Form('nick_name_id'));
} elsif ($Request->QueryString('nick_name_id')) {
	$nick_name_id = int($Request->QueryString('nick_name_id'));
} elsif ($Request->Form('list_cid')) {
	$list_cid = int($Request->Form('list_cid'));
	$anonymous_nick = 0;
} elsif ($Request->QueryString('list_cid')) {
	$list_cid = int($Request->QueryString('list_cid'));
	$anonymous_nick = 0;
}

my $namespace = '';
if ($Request->Form('namespace')) {
	$namespace = $Request->Form('namespace');
} elsif ($Request->QueryString('namespace')) {
	$namespace = $Request->QueryString('namespace');
}

my $dbh = &func::dbh_connect(1) || die "unable to connect to database";

my $title = '';
my $header = '';
my $error_message = '';
my $selstmt;
my $sth;
my $rs;
my $nick_name;

my $name_space_displayed = 0;
my $namespace_select_str = func::make_namespace_select_str($dbh, $namespace);

$namespace_select_str .= qq{

<script>
function change_namespace(namespace) {
	if (namespace == 'general') {
		namespace = '';
	}
	window.document.name_space_form.submit();
}
</script>

};



if ($nick_name_id) {

	$selstmt = 'select nick_name, owner_code, private from nick_name where nick_name_id = ' . $nick_name_id;

	$sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";

	if ($rs = $sth->fetchrow_hashref()) {
		$sth->finish();
		$nick_name = $rs->{'nick_name'};
		if ($rs->{'private'}) {
			my $title = "Supported camps by nick name: $nick_name";
			my $header = '<table><tr><td class="label">Supported camps by nick name: </td>' .
					'<td class="topic">' . $nick_name. '</td></tr>' .
					"</table>\n";
			display_page($title, $header, [\&identity, \&search, \&as_of, \&main_ctl], [\&list_nick_support]);
			$Response->End();
		} else { # not private
			$anonymous_nick = 0;
			$list_cid = func::canon_decode($rs->{'owner_code'});
		}
	} else {
		$sth->finish();
		$error_message = 'Unkown nick_name_id: ' . $Request->QueryString('nick_name_id');
		display_page("Unknown nick_name_id", 'Unknown nick_name_id', [\&identity, \&search, \&as_of, \&main_ctl], [\&error_page]);
		$Response->End();
	}
}

if ($list_cid) {
	display_page('User Information', 'User Information', [\&identity, \&search, \&as_of, \&main_ctl], [\&list_cid_support]);
}


$Response->End();


########
# subs #
########


sub list_cid_support {

	my $rs;
	my $selstmt = "select * from person where cid = $list_cid";
	my $sth = $dbh->prepare($selstmt) or die "Failed to prepair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";

	if ($rs = $sth->fetchrow_hashref()) {

		my $name_line = '';
		my $private_flags = $rs->{'private_flags'};
		my $have_name = 0;

		if ((length($rs->{'first_name'}) > 0) and ($private_flags !~ m|first_name|)) {
			$name_line = $rs->{'first_name'};
			$have_name = 1;
		}

		if ((length($rs->{'middle_name'}) > 0) and ($private_flags !~ m|middle_name|)) {
			if ($have_name) {
				$name_line .= '&nbsp;';
			}
			$name_line .= $rs->{'second_name'};
			$have_name = 1;
		}

		if ((length($rs->{'last_name'}) > 0) and ($private_flags !~ m|last_name|)) {
			if ($have_name) {
				$name_line .= '&nbsp;';
			}
			$name_line .= $rs->{'last_name'};
			$have_name = 1;
		}
		if (! $have_name) {
			$name_line = 'Name is private';
		}

		%>
		<table>
		<tr><td>Canonizer User: </td><td class="simple_bold"><%=$name_line%></td></tr>
		<%

		display_line($rs, $private_flags, 'email');
		display_line($rs, $private_flags, 'birthday');
		display_line($rs, $private_flags, 'address_1');
		display_line($rs, $private_flags, 'address_2');
		display_line($rs, $private_flags, 'city');
		display_line($rs, $private_flags, 'state');
		display_line($rs, $private_flags, 'postal_code');
		display_line($rs, $private_flags, 'country');

		%>
		</table>

		<br>

		<form name="name_space_form" id="name_space_form">
		Namespace: <%= $namespace_select_str %>
		<input type=hidden name=nick_name_id value="<%= $nick_name_id %>">
		<input type=hidden name=list_cid value="<%= $list_cid %>">
		<input type=hidden name=anonymous_nick value="<%= $anonymous_nick %>">
		</form>

		<br>
		<br>
		<%

		$name_space_displayed = 1;

		my %nick_name_hash = func::get_nick_name_hash($list_cid, $dbh);
		my $tmp_nick_name_id; # stupid perl!
		foreach $tmp_nick_name_id (keys %nick_name_hash) {
			$nick_name_id = $tmp_nick_name_id;
			if (! $nick_name_hash{$nick_name_id}->{'private'}) {
				$nick_name = $nick_name_hash{$nick_name_id}->{'nick_name'};
				list_nick_support();
			}
		}

		if ($Session->{'cid'} == $list_cid) {
			if ($Session->{'logged_in'}) {
				%>
				<p>Anonymous Nick Names:</p>
				<%
				foreach $tmp_nick_name_id (keys %nick_name_hash) {
					$nick_name_id = $tmp_nick_name_id;
					if ($nick_name_hash{$nick_name_id}->{'private'}) {
						$nick_name = $nick_name_hash{$nick_name_id}->{'nick_name'};
						list_nick_support();
					}
				}
			} else {
				%>
				<p>Your anonymous nick names will list here when you are fully logged in.</p>
				<%
			}
		}

	} else {
		%>
		<h1>Unknown cid: $list_cid</h1>
		<%
	}
}


sub display_line {
	my $rs            = $_[0];
	my $private_flags = $_[1];
	my $line_value    = $_[2];

	my $print_value = $rs->{$line_value};
	if ($line_value eq 'email') {
		$print_value =~ s|\@| at |g;
	}

	if ((length($rs->{$line_value}) > 0) and ($private_flags !~ m|$line_value|)) {
		%>
		<tr><td><%= $line_value %>: </td><td class="simple_bold"><%= $print_value %></td></tr>
		<%
	}
}


sub display_mind_expert {
	my $as_of_clause = $_[0];

	my $topic_num = 81; # mind experts topic number;

	my $selstmt = qq{
select c.camp_num from camp c,
       (select zc.camp_num, max(zc.go_live_time) as camp_max_glt from camp zc
       	       where zc.topic_num=$topic_num and zc.nick_name_id=$nick_name_id and zc.objector is null $as_of_clause group by camp_num) z
where c.topic_num=$topic_num and c.nick_name_id=$nick_name_id and c.go_live_time=z.camp_max_glt;
};

	my $sth = $dbh->prepare($selstmt) or die "Failed to prepair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";

	if ($rs = $sth->fetchrow_hashref()) {
		my $camp_num = $rs->{'camp_num'};
		%>
		<li>This nick name is being ranked as a
		<a href="http://<%=func::get_host()%>/topic.asp/<%= $topic_num %>/<%= $camp_num %>">
		Mind Expert
		</a> which is used to measure <a href="http://canonizer.com/topic.asp/53/11">
		scientific consensus</a>.</li><br>
		<%
	}
}


sub list_nick_support {

	my $as_of_mode = $Session->{'as_of_mode'};
	my $as_of_date = $Session->{'as_of_date'};

	my $sel_namespace = $namespace;
	if ($sel_namespace eq 'general') {
	   $sel_namespace = '';
	}

	my $as_of_time = time;
	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_time = &func::parse_as_of_date($as_of_date);
		$as_of_clause = "and go_live_time < $as_of_time";
	} else {
		$as_of_clause = 'and go_live_time < ' . time;
	}

	if (! $name_space_displayed) {
		%>	   
		Namespace: <%= $namespace_select_str %>
		<%
		$name_space_displayed = 1;
	}

	if ($anonymous_nick) {
		%>
		<p><%=$nick_name%> is an anonymous nick name.</p>
		<%
	}
	%>
	<li>Nick name <b class="simple_bold"><%=$nick_name%></b>:</li>

	<ul>
		<%
		display_mind_expert($as_of_clause);
		%>

		<li class="simple_bold">List of supported camps:</li>
	</ul>

	<%

###################################################################
# test version:
#
# select u.topic_num, u.camp_num, u.title, p.support_order, p.delegate_nick_name_id from support p, 
# 
# (select s.title, s.topic_num, s.camp_num from camp s,
# 	(select topic_num, camp_num, max(go_live_time) as camp_max_glt from camp
# 		where objector is null and go_live_time < 1222045100 group by topic_num, camp_num) cz,
# 
# 		(select t.topic_num, t.topic_name, t.namespace, t.go_live_time from topic t,
# 			(select ts.topic_num, max(ts.go_live_time) as topic_max_glt from topic ts
# 				where ts.namespace='/personal_attributes/' and ts.objector is null and ts.go_live_time < 1222045100 group by ts.topic_num) tz
# 					where t.namespace='/personal_attributes/' and t.topic_num = tz.topic_num and t.go_live_time = tz.topic_max_glt) uz
# 
# 		where s.topic_num = cz.topic_num and s.camp_num=cz.camp_num and s.go_live_time = cz.camp_max_glt and s.topic_num=uz.topic_num) u
# 
# where u.topic_num = p.topic_num and ((u.camp_num = p.camp_num) or (u.camp_num = 1)) and p.nick_name_id = 1 and
# (p.start < 1222045100) and ((p.end = 0) or (p.end > 1222045100))
# 
# Thu Nov 1 16:20:40 2007:   1193934040
# Mon Sep 22 00:58:20 2008:  1222045100	right before mind experts created
# Sun Jul 19 19:06:33 2009:  1248030393
#
###################################################################


	my $selstmt = qq{
select u.topic_num, u.camp_num, u.title, p.support_order, p.delegate_nick_name_id from support p, 

(select s.title, s.topic_num, s.camp_num from camp s,
	(select topic_num, camp_num, max(go_live_time) as camp_max_glt from camp
		where objector is null $as_of_clause group by topic_num, camp_num) cz,

		(select t.topic_num, t.topic_name, t.namespace, t.go_live_time from topic t,
			(select ts.topic_num, max(ts.go_live_time) as topic_max_glt from topic ts
				where ts.namespace=? and ts.objector is null $as_of_clause group by ts.topic_num) tz
					where t.namespace=? and t.topic_num = tz.topic_num and t.go_live_time = tz.topic_max_glt) uz

		where s.topic_num = cz.topic_num and s.camp_num=cz.camp_num and s.go_live_time = cz.camp_max_glt and s.topic_num=uz.topic_num) u

where u.topic_num = p.topic_num and ((u.camp_num = p.camp_num) or (u.camp_num = 1)) and p.nick_name_id = $nick_name_id and
(p.start < $as_of_time) and ((p.end = 0) or (p.end > $as_of_time))
};

	$sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute($sel_namespace, $sel_namespace) or die "Failed to execute $selstmt.\n";
	my %support_struct = ();
	my $delegate_hash  = 0;
	my $rs;
	my $topic_num;
	while ($rs = $sth->fetchrow_hashref()) {
		$topic_num     = $rs->{'topic_num'};
		my $camp_num = $rs->{'camp_num'};
		if ($rs->{'delegate_nick_name_id'}) {
			$delegate_hash->{$topic_num} = $rs->{'support_order'};
		} elsif ($camp_num == 1) {
			$support_struct{$topic_num}->{'topic_title'} = $rs->{'title'};
		} else {
			$support_struct{$topic_num}->{'array'}->[$rs->{'support_order'}]->{'title'} = $rs->{'title'};
			$support_struct{$topic_num}->{'array'}->[$rs->{'support_order'}]->{'camp_num'} = $camp_num;
		}
	}

	my $supported_topic = 0;
	foreach $topic_num (sort {$a <=> $b} (keys %support_struct)) {
		if (! $supported_topic) {
			$supported_topic = 1;
			%>
			<ul>
			<%
		}
		%>
		<li><a href="http://<%=func::get_host()%>/topic.asp/<%=$topic_num%>"><%=$support_struct{$topic_num}->{'topic_title'}%></a></li>
		<%

		if ($support_struct{$topic_num}->{'array'}) {
			%>
			<ul>
			<%
			my $hash_ref;
			foreach $hash_ref (@{$support_struct{$topic_num}->{'array'}}) {
				%>
				<li><a href="http://<%=func::get_host()%>/topic.asp/<%=$topic_num%>/<%=$hash_ref->{'camp_num'}%>"><%=$hash_ref->{'title'}%></a></li>
				<%
			}
			%>
			</ul>
			<%
		}
		%>
		<br>
		<%
	}

	if ($supported_topic) {
		%>
		</ul>
		<%
	} else {
		%>
		<h1>No directly supported camps</h1>
		<%
	}

	if ($delegate_hash) {

		$selstmt = "select support_id, nick_name, s.nick_name_id, camp_num, delegate_nick_name_id, support_order from support s, nick_name n where s.nick_name_id = n.nick_name_id and topic_num = $topic_num and ((start < $as_of_time) and (end = 0 or end > $as_of_time))";


	}

}



# ???? need to convert this to use the support.pm version.
sub list_support {

	if ($Session->{'cid'} != 1) {
		%>
		<h1> Only 1 can do this.
		<%
		$Response->End();
	}

	my $as_of_time = time;
	my $as_of_clause = '';
	if ($as_of_mode eq 'review') {
		# no as_of_clause;
	} elsif ($as_of_mode eq 'as_of') {
		$as_of_time = &func::parse_as_of_date($as_of_date);
		$as_of_clause = "and go_live_time < $as_of_time";
	} else {
		$as_of_clause = 'and go_live_time < ' . $as_of_time;
	}


#	my $selstmt = 'select nick_name, nick_name_id from nick_name';
	my $selstmt = 'select cid, first_name, middle_name, last_name, email, address_1, address_2, city, state, postal_code, country, birthday, gender from person';

	if ($nick_name_id) {
		# $selstmt .= " where nick_name_id = $nick_name_id";
	}

	my $sth = $dbh->prepare($selstmt) or die "Failed to preparair $selstmt.\n";
	$sth->execute() or die "Failed to execute $selstmt.\n";
	my $rs;
	%>
	<ol>
	<%
	while ($rs = $sth->fetchrow_hashref()) {
		my $not_supporting = 1;
		# $selstmt = "select topic.name, support.name camp.delegate_id from suppo
		%>
		<li><%=$rs->{'first_name'} . ' ' . $rs->{'middle_name'} . ' ' . $rs->{'last_name'}%> [<%=$rs->{'cid'}%>] (<%=$rs->{'email'}%>)<br>
		<%=$rs->{'address_1'} . ' ' . $rs->{'address_2'} . ' ' . $rs->{'city'} . ' ' . $rs->{'state'} . ' ' . $rs->{'postal_code'} . ' ' . $rs->{'contry'}%></li>
		<ol>
		<%
		my %nick_name_hash = func::get_nick_name_hash($rs->{'cid'}, $dbh);
		my $nick_name_id;
		foreach $nick_name_id (keys %nick_name_hash) {
			%>
			<li><%=$nick_name_hash{$nick_name_id}->{'nick_name'}%> [<%=$nick_name_id%>]</li>
			<%
		}
		%>
		</ol>
		<br>
		<%
	}
	%>
	</ol>
	<%
}

%>


<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/page_sections.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/as_of.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/error_page.asp"-->
