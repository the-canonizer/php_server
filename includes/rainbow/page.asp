<%

sub display_page {
	my $title	 = $_[0];    
	my $page_header  = $_[1];
	my $bar_subs	 = $_[2];
	my $content_subs = $_[3];
	my $tab_sub	 = $_[4];

	my $copyright_info = 'Copyright Canonizer LLC 2007';
	my $support_email = 'support@canonizer.com'

%>

<%
print page_header($title);
%>

<div id="header">
     <h1><%=$page_header%></h1>
</div>

<div id="block_tools">     

<%
my $sub;
foreach $sub (@$bar_subs)
{
&$sub();
}
%>
     
</div>

<div id="block_adverts">

<script type="text/javascript"><!--
google_ad_client = "pub-6646446076038181";
//120x600, right bar
google_ad_slot = "5819006657";
google_ad_width = 120;
google_ad_height = 600;
//--></script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>

</div>

<div id="main_content">

<%
foreach $sub (@$content_subs)
{
&$sub();
}
%>

</div>

<div class="clear_floats">&nbsp;</div>

<div id="footer">
     <h3><%=$copyright_info%></h3>
     <h3>Comments: <a href = "mailto:<%=$support_email%>"><%=$support_email%></a></h3>
</div>

<%
print page_footer();
}
%>
