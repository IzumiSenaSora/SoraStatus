#!/bin/bash

MESSAGE=$(
	cat <<EOM
From: SoraStatus System <$SMTP_FROM>
To: Izumi Sena Sora <$SMTP_TO>
Subject: $([[ -s maintenance ]] && echo -n "Scheduled Maintenance" || echo -n "Status") Notification From SoraStatus System
Date: $(date --utc '+%a, %d %b %Y %X')
Mime-Version: 1.0
Content-Type: text/html; charset=utf-8
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>SoraStatus System</title>
<style type="text/css">
body{width:100% !important;} .ReadMsgBody{width:100%;} .ExternalClass{width:100%;}
body{-webkit-text-size-adjust:none;}
body{margin:0; padding:0;}
img{border:0; height:auto; line-height:100%; outline:none; text-decoration:none;}
table td{border-collapse:collapse;}
#backgroundTable{height:100% !important; margin:0; padding:0; width:100% !important;}

body, #backgroundTable{
background-color:#FAFAFA;
}

#templateContainer{
border: 1px solid #DDDDDD;
}

h1, .h1{
color:#202020;
display:block;
font-family:Arial;
font-size:34px;
font-weight:bold;
line-height:100%;
margin-top:0;
margin-right:0;
margin-bottom:10px;
margin-left:0;
text-align:center;
}

h2, .h2{
color:#202020;
display:block;
font-family:Arial;
font-size:30px;
font-weight:bold;
line-height:100%;
margin-top:0;
margin-right:0;
margin-bottom:10px;
margin-left:0;
text-align:center;
opacity:0.7;
}

h3, .h3{
color:#202020;
display:block;
font-family:Arial;
font-size:26px;
font-weight:bold;
line-height:100%;
margin-top:0;
margin-right:0;
margin-bottom:10px;
margin-left:0;
text-align:center;
opacity:0.7;
}

h4, .h4{
color:#202020;
display:block;
font-family:Arial;
font-size:22px;
font-weight:bold;
line-height:100%;
margin-top:0;
margin-right:0;
margin-bottom:10px;
margin-left:0;
text-align:center;
opacity:0.7;
}

#templateContainer, .bodyContent{
background-color:#FFFFFF;
}

.bodyContent div{
color:#505050;
font-family:Arial;
font-size:14px;
line-height:150%;
text-align:left;
}

.bodyContent div a:link, .bodyContent div a:visited, .bodyContent div a .yshortcuts {
color:#336699;
font-weight:normal;
text-decoration:underline;
}

.bodyContent img{
display:inline;
height:auto;
}

#templateFooter{
background-color:#FFFFFF;
border-top:0;
}

.footerContent div{
color:#707070;
font-family:Arial;
font-size:12px;
line-height:125%;
text-align:left;
}

.footerContent div a:link, .footerContent div a:visited, .footerContent div a .yshortcuts {
color:#336699;
font-weight:normal;
text-decoration:underline;
}

.footerContent img{
display:inline;
}

#utility div{
text-align:center;
}

}

</style>
</head>
<body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0">
<center>
<table border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="backgroundTable">
<tr>
<td align="center" valign="top">
<table border="0" cellpadding="10" cellspacing="0" width="600" id="templatePreheader">
<tr>
<td valign="top" class="preheaderContent"></td>
</tr>
</table>
<table border="0" cellpadding="0" cellspacing="0" width="600" id="templateContainer">
<tr>
<td align="center" valign="top">
<table border="0" cellpadding="0" cellspacing="0" width="600" id="templateBody">
<tr>
<td valign="top" class="bodyContent">
<table border="0" cellpadding="20" cellspacing="0" width="100%">
<tr>
<td valign="top">
<div>
<h1 class="h1">$([[ -s maintenance ]] && echo -n "Scheduled Maintenance Reminder" || echo -n "Incident Update")</h1>
<h4 class="h4">SoraStatus System</h4>
<br />
<strong>State:</strong> Service Disruption
<br />
<strong>$([[ -s maintenance ]] && echo -n "Planned Start" || echo -n "Started"):</strong> $DATETIME
<br />
<strong>$([[ -s maintenance ]] && echo -n "Expected End" || echo -n "Resolved"):</strong> Not Yet
<br />
<br />
<strong>Affected Infrastructure</strong>
<br />
<strong>Name:</strong> $NAME
<br />
<strong>Url:</strong> $URL
<br />
<strong>Up:</strong> $UP
<br />
<br />
<strong>$([[ -s maintenance ]] && echo -n "Details" || echo -n "Update"):</strong> Investigating
<br />
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td align="center" valign="top">
<table border="0" cellpadding="10" cellspacing="0" width="600" id="templateFooter">
<tr>
<td valign="top" class="footerContent">
<table border="0" cellpadding="10" cellspacing="0" width="100%">
<tr>
<td colspan="2" valign="middle" id="utility">
<div>
<a href="https://sorastatus.eu.org">Visit Status Page</a> | <a href="https://lotns.eu.org">Learn More</a>
<p>Copyright &copy; $(TZ='UTC' date +'%Y') SoraStatus</p>
</div>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</center>
</body>
</html>
EOM
)

echo "    Status $STATUS So Sending Alert Via SMTPS"
curl \
	--ssl-reqd \
	--silent \
	--show-error \
	smtps://"$SMTP_HOST":"$SMTP_PORT" \
	--user "$SMTP_USERNAME:$SMTP_PASSWORD" \
	--mail-from "$SMTP_FROM" \
	--mail-rcpt "$SMTP_TO" \
	--connect-timeout 10 \
	--upload-file - <<EOF
$MESSAGE
EOF

echo "    Status $STATUS So Sending Alert Via WebHook"
curl \
	--silent \
	--show-error \
	--output /dev/null \
	--header "Title: $([[ -s maintenance ]] && echo -n "Scheduled Maintenance" || echo -n "Status") Notification From SoraStatus System" \
	--header "Priority: urgent" \
	--header "Tags: warning" \
	--header "Click: https://sorastatus.eu.org" \
	--header "Icon: https://sorastatus.eu.org/opengraph.png" \
	--header "Markdown: yes" \
	--data "# $([[ -s maintenance ]] && echo -n "Scheduled Maintenance Reminder" || echo -n "Incident Update")

**State:** Service Disruption
**$([[ -s maintenance ]] && echo -n "Planned Start" || echo -n "Started"):** $DATETIME
**$([[ -s maintenance ]] && echo -n "Expected End" || echo -n "Resolved"):** Not Yet

##### Affected Infrastructure
**Name:** $NAME
**Url:** $URL
**Up:** $UP

**$([[ -s maintenance ]] && echo -n "Details" || echo -n "Update"):** Investigating" \
	"$WEBHOOK"
