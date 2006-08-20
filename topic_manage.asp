
<!--#include file = "includes/default/page.asp"-->

<!--#include file = "includes/identity.asp"-->
<!--#include file = "includes/search.asp"-->
<!--#include file = "includes/main_ctl.asp"-->
<!--#include file = "includes/topic_tabs.asp"-->

<%

use history_class;


sub error_page {
	%>
	<h1>Error: Unkown topic_id: <%=$topic_id%>.</h1>
	<%
}

sub unknown_num_page {

	if ($num) {
		%>
		<br>
		<h1>Unknown Topic Number:&nbsp;<%=$num%>.</h1>
		<%
	} else {
		%>
		<br>
		<h1>No topic number specified.</h1>
		<%
	}
}


sub manage_topic {

	$history->print_history($dbh);

}



########
# main #
########

local $num = '';
if ($Request->Form('number')) {
	$num = int($Request->Form('number'));
} elsif ($Request->QueryString('number')) {
	$num = int($Request->QueryString('number'));
}


if (!$num) {
	&display_page('CANONIZER', 'Manage Topic: '. $num, [\&identity, \&search, \&main_ctl], [\&unknown_num_page]);
	$Response->End();
}

local $dbh = &func::dbh_connect(1) || die "unable to connect to database";

local $history = history_class->new($dbh, 'topic_class', $num);

if ($history->{active} == 0) {
	&display_page('CANONIZER', 'Manage Topic: ' . $history->{active}, [\&identity, \&search, \&main_ctl], [\&unknown_num_page]);
	$Response->End();
}


&display_page('CANONIZER', 'Topic: ' . $history->{active}->{name}, [\&identity, \&search, \&main_ctl], [\&manage_topic], \&topic_tabs);



%>