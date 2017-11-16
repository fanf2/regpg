#!/usr/bin/perl
while (<>) {
	print;
	print <<'IFRAME' if m{<body>};
<iframe id="logo" src="https://dotat.at/prog/regpg/logo/re3d.html"
	style="float:right;" width="150" height="125"
	scrolling="no" frameborder="0"></iframe>
IFRAME
}
