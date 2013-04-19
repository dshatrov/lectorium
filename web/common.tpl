<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html style="height: 100%" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <script type="text/javascript">
    var server_uri = "rtmp://{{ThisRtmpServerAddr}}/lectorium";
    var is_lector = "{{Lectorium_IsLector}}";
  </script>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <title>Moment Video Server - http://momentvideo.org</title>
<!--  <link rel="icon" type="image/vnd.microsoft.icon" href="favicon.ico"/> -->
  <style type="text/css">
    body {
      height: 100%;
      padding: 0;
      margin: 0;
      font-size: 16px;
      font-family: sans-serif;
    }

    tr.welcome_row > td {
      padding-bottom: 1em;
      /**/
      width: 50%;
      white-space: nowrap;
      /**/
    }

    .chat_app {
      display: none;
      position: relative;
      top: 0;
      left: 0;
      width: 100%;
      min-height: 100%;
    }

    .watchers_div {
      display: none;
      width: 200px;
      min-height: 590px;
      /* height: 100%; */
      color: /* #ffffff */ #000000;
      background-color: /* #111111 */ #f7f7f7;
      border-left: 1px solid /* #222222 */ #c0c0c0;
      /* overflow: auto; */
      /**/
      position: absolute;
      top: 10px;
      bottom: 10px;
      right: 0px;
      /**/
    }

    .watchers_div_alt {
      display: none;
      width: 200px;
/*      min-height: 250px; */
      /* height: 100%; */
      color: /* #ffffff */ #000000;
      background-color: /* #111111 */ #f7f7f7 /* #ffbbbb */;
      border-left: 1px solid /* #222222 */ #c0c0c0;
      border-bottom: 1px solid #c0c0c0;
      overflow: auto;
      /**/
      position: absolute;
/*      top: 419px; */
      bottom: 10px;
      right: 0px;
      /**/
    }

    .watchers_div_alt_client {
      top: 430px;
      min-height: 169px;
    }

    .watchers_div_alt_lector {
      top: 489px;
      min-height: 110px;
    }

    .watcher_entry_one {
      background-color: /* #333333 */ #f7f7f7;
    }

    .watcher_entry_two {
      background-color: /* #222222 */ #f7f7f7;
    }

    .header {
      position: absolute;
      top: 0;
      left: 0;
      /* width: 100%; */
      margin-top: 10px;

      /* Flash movie gets reloaded in Firefox when display:none is applied.
       * visibility:hidden and right:-99999px is used as a workaround.
       * There's a minor problem with vertical scrollbar appearing earlier
       * than expected because of this. */
      visibility: hidden;
      left: -99999px;
    }

    .body {
      position: absolute;
      top: 490px;
      bottom: 55px;
      left: 0;
      right: 0;
      width: 100%;
      margin-right: 200px;
    }

    .footer {
      position: absolute;
      bottom: 10px;
      left: 0;
      width: 640px;
/*      margin-left: auto;
      margin-right: auto; */
    }

    .code_input {
      /* Breaks placeholder color in Firefox.
         color: #333333; */
      height: 30px;
      border: 1px solid #cccccc;
      padding-left: 2px;
      padding-right: 2px;
      font-size: 16px;
    }

    .connect_button {
      height: 40px;
      color: white;
      background-color: green;
      border: 0px;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 16px;
      font-weight: bold;
      text-shadow: 1px 1px 0 #004400;
    }

    .connect_button:hover {
      cursor: pointer;
    }

    .word_button_table {
      margin-left: auto;
      margin-right: auto;
    }

    .ask_word_button {
      height: 40px;
      color: white;
      background-color: green;
      border: 0px;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 16px;
      font-weight: bold;
      text-shadow: 1px 1px 0 #004400;
    }

    .ask_word_button:hover {
      cursor: pointer;
    }

    .end_word_button {
      height: 40px;
      color: white;
      background-color: #bb0000;
      border: 0px;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 16px;
      font-weight: bold;
      text-shadow: 1px 1px 0 #004400;
    }

    .end_word_button:hover {
      cursor: pointer;
    }

    .begin_lecture_button {
      height: 40px;
      color: white;
      background-color: green;
      border: 0px;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 16px;
      text-shadow: 1px 1px 0 #004400;
    }

    .begin_lecture_button:hover {
      cursor: pointer;
    }

    .end_lecture_button {
      height: 40px;
      color: white;
      background-color: #bb0000;
      border: 0px;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 16px;
      text-shadow: 1px 1px 0 #004400;
    }

    .end_lecture_button:hover {
      cursor: pointer;
    }

    .give_word_button {
      width: 300px;
      color: white;
      background-color: green;
      padding-left: 10px;
      padding-right: 10px;
    }

    .give_word_button:hover {
      cursor: pointer;
    }

    .drop_participant_button {
      width: 300px;
      color: white;
      background-color: red;
      padding-left: 10px;
      padding-right: 10px;
    }

    .drop_participant_button:hover {
      cursor: pointer;
    }

    .flash_div {
      position: relative;
      width: 640px;
      height: 480px;
      margin-left: auto;
      margin-right: auto;
    }

    .chat_frame {
      width: 634px;
      height: 100%;
      border-left: 1px solid #ccccdd;
      border-right: 1px solid #ccccdd;
      padding-left: 2px;
      padding-right: 2px;
  */     margin-left: auto;
      margin-right: auto;
    }

    .chat_scroll {
      width: 100%;
      height: 100%;
      margin-left: auto;
      margin-right: auto;
      overflow: auto;
    }

    .chat_div {
      padding-bottom: 1.25ex;
      padding-top: 6px;
      font-size: 14px;
      text-align: left;
      word-wrap: break-word;
    }

    .input_div {
      width: 634px;
      background-color: #ffffff;
      border-left: 1px solid #ccccdd;
      border-right: 1px solid #ccccdd;
      border-bottom: 1px solid #ccccdd;
      padding-left: 2px;
      padding-right: 2px;
      padding-bottom: 2px;
      margin-left: auto;
      margin-right: auto;
      text-align: center;
    }

    .chat_input {
      width: 100%;
      height: 30px;
      /* Breaks placeholder color in Firefox.
         color: #333333; */
      outline: 0;
      padding-left: 2px;
      padding-right: 2px;
      padding-top: 1px;
      padding-bottom: 1px;
      margin: 0;
      font-size: 16px;
      font-family: sans-serif;
    }

    .chat_input_blocked {
      border: 0;
      border-right: 0;
    }

    .chat_input_unblocked {
      border: 0;
      border-right: 0;
    }

    .chat_input_wrapper_blocked {
      border: 5px solid #ccccdd;
      border-right: 4px solid #ccccdd;
    }

    .chat_input_wrapper_unblocked {
      border: 5px solid #707088;
      border-right: 4px solid #707088;
    }

    .send_button {
      width: 0px;
      border: 0;
      margin: 0;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 14px;
      font-weight: bold;
      vertical-align: middle;
    }

    .send_button_blocked {
      color: #f8f8ff;
      background-color: #ccccdd;
      text-shadow: 1px 1px 0 #a0a0d0;
    }

    .send_button_unblocked {
      color: white;
      background-color: #707088;
      text-shadow: 1px 1px 0 #000044;
    }

    .send_button_blocked:hover {
      cursor: default;
    }

    .send_button_unblocked:hover {
      cursor: pointer;
    }

    .chat_phrase {
      padding-left: 8px;
      padding-top: 0.5ex;
    }

    .lead_chat_phrase {
      border-top: 1px dotted #a0a0d0;
      padding-left: 8px;
      padding-top: 0.75ex;
      margin-top: 0.75ex;
    }

    .own_chat_phrase {
      color: #707088;
      padding-left: 8px;
      padding-top: 0.5ex;
    }

    .lead_own_chat_phrase {
      color: #707088;
      border-top: 1px dotted #a0a0d0;
      padding-left: 8px;
      padding-top: 0.75ex;
      margin-top: 0.75ex;
    }

    .status_msg {
      color: #a0a0a0;
      padding-left: 8px;
      padding-top: 0.5ex;
      font-style: oblique;
    }

    .lead_status_msg {
      color: #a0a0a0;
      border-top: 1px dotted #a0a0d0;
      padding-left: 8px;
      padding-top: 0.75ex;
      margin-top: 0.75ex;
      font-style: oblique;
    }

    .status_msg_red {
      color: #aa0000;
    }

    .status_msg_green {
      color: #008000;
    }
  </style>
  <script type="text/javascript" src="jquery.js"></script>
  <script type="text/javascript" src="swfobject.js"></script>
  <script type="text/javascript">
    var flashvars = {
      "server_uri" : server_uri,
      "is_lector"  : is_lector
    };

    var params = {
      "movie"   : "Lectorium.swf",
      "bgcolor" : "#000000",
      "scale"   : "noscale",
      "quality" : "high",
      "allowfullscreen"   : "true",
      "allowscriptaccess" : "always"
    };

    var attributes = {
      "id"    : "Lectorium",
      "width" : "100%",
      "height": "100%",
      "align" : "Default"
    };

    swfobject.embedSWF ("Lectorium.swf", "Lectorium_div", "100%", "100%",
			"9.0.0", false, flashvars, params, attributes);
  </script>
  <script type="text/javascript">
    var flash_initialized = false;
    var should_connect = false;

    function codeKeyDown (evt)
    {
	if (evt.keyCode == 13)
	    connect ();
    }

    function my_alert (msg)
    {
	alert (msg);
    }

    function flashInitialized ()
    {
        flash = document.getElementById ("Lectorium");

	flash_initialized = true;
	if (should_connect)
	    doConnect ();
    }

    function connect ()
    {
	document.getElementById ("WelcomeScreen").style.display = "none";

	document.getElementById ("ChatApp").style.display = "block";
	document.getElementById ("watchers_div").style.display = "block";
	document.getElementById ("watchers_div_alt").style.display = "block";
	{
	    header = document.getElementById ("Header");
	    header.style.left = "0";
	    header.style.visibility = "visible";
	}

	doConnect ();

	document.getElementById ("ChatInput").focus();

	{
	    chat_scroll = document.getElementById ("ChatScroll");
	    chat_scroll.scrollTop = chat_scroll.scrollHeight;
	}
    }

    function doConnect ()
    {
	should_connect = true;
	if (!flash_initialized)
	    return;

	document ["Lectorium"].connect (/* document.getElementById ("CodeInput").value */
					"lecture",
					document.getElementById ("NameInput").value);
    }

    function newCall ()
    {
	document.getElementById ("ChatApp").style.display = "none";
	document.getElementById ("watchers_div").style.display = "none";
	document.getElementById ("watchers_div_alt").style.display = "none";
	{
	    header = document.getElementById ("Header");
	    header.style.left = "-99999px";
	    header.style.visibility = "hidden";
	}

	document.getElementById ("WelcomeScreen").style.display = "block";

	document.getElementById ("NameInput").focus();
    }

    function requestParticipation ()
    {
	{
	    ask_button = document.getElementById ("ask_word_button");
	    ask_button.style.display = "none";
	}
	{
	    end_button = document.getElementById ("end_word_button");
	    end_button.style.display = "";
	}

	document ["Lectorium"].requestParticipation ();
    }

    function showAskWordButton ()
    {
	{
	    end_button = document.getElementById ("end_word_button");
	    end_button.style.display = "none";
	}
	{
	    ask_button = document.getElementById ("ask_word_button");
	    ask_button.style.display = "";
	}
    }

    function endParticipation ()
    {
	showAskWordButton ();
	document ["Lectorium"].endParticipation ();
    }

    function giveWord (client_id)
    {
	document ["Lectorium"].giveWord (client_id)
    }

    function dropParticipant (client_id)
    {
	document ["Lectorium"].dropParticipant (client_id);
    }

    function beginLecture ()
    {
	{
	    begin_button = document.getElementById ("begin_lecture_button");
	    begin_button.style.display = "none";
	}
	{
	    end_button = document.getElementById ("end_lecture_button");
	    end_button.style.display = "";
	}

	document ["Lectorium"].beginLecture ();
    }

    function endLecture ()
    {
	{
	    end_button = document.getElementById ("end_lecture_button");
	    end_button.style.display = "none";
	}
	{
	    begin_button = document.getElementById ("begin_lecture_button");
	    begin_button.style.display = "";
	}

	document ["Lectorium"].endLecture ();
    }

    function showDesktop ()
    {
        {
            desktop_button = document.getElementById ("show_desktop_button");
            desktop_button.style.display = "none";
        }
        {
            lecture_button = document.getElementById ("show_lecture_button");
            lecture_button.style.display = "";
        }

        document ["Lectorium"].showDesktop ();
    }

    function showLecture ()
    {
        {
            lecture_button = document.getElementById ("show_lecture_button");
            lecture_button.style.display = "none";
        }
        {
            desktop_button = document.getElementById ("show_desktop_button");
            desktop_button.style.display = "";
        }

        document ["Lectorium"].showLecture ();
    }
  </script>
</head>
<body onload="document.getElementById('NameInput').focus()">

<!-- <div style="position: absolute; width: 100%; height: 100%; top: 0px; left: 0px"> -->
<div style="position: relative; width: 840px; height: 100%; margin-left: auto; margin-right: auto">
<!-- <div style="position: relative; width: 840px; margin-left: auto; margin-right: auto"> -->
  <div id="ChatApp" class="chat_app">
    <div style="height: 490px; padding-bottom: 120px; width: 100%"></div>
    <div class="body">
      <div class="chat_frame">
	<div id="ChatScroll" class="chat_scroll">
	  <div id="ChatDiv" class="chat_div">
	  </div>
	</div>
      </div>
    </div>
    <div class="footer">
      <div class="input_div">
	<table style="width: 100%; height: 100%; border: 0" cellpadding="0" cellspacing="0">
	  <tr>
	    <td style="width: 100%; text-align: left; color: #333333">
	      <div id="ChatInputWrapper" style="chat_input_wrapper_blocked">
	        <input id="ChatInput" class="chat_input chat_input_blocked" type="text" placeholder="Введите сообщение" onkeydown="chatKeyDown(event)"/>
	      </div>
	    </td>
	    <td id="SendButton" tabindex="0" class="send_button send_button_blocked" style="vertical-align: middle" onclick="sendButtonClick()" onkeydown="sendKeyDown(event)">
	      Отправить
	    </td>
	  </tr>
	</table>
      </div>
    </div>
  </div>

  <!-- Header goes after ChatApp for proper Z order in Chrome -->
  <div id="Header" class="header">

    <div class="flash_div">
      <div id="Lectorium_div">
	<a href="http://adobe.com/go/getflashplayer">Get Adobe Flash player</a>
      </div>
    </div>

      <!-- wmode="direct" doesn't work -->
<!-- STATIC EMBEDDING
    <div class="flash_div">
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
	  width="100%"
	  height="100%"
	  id="Lectorium"
	  align="Default">
	<param name="movie" value="Lectorium.swf"/>
	<param name="bgcolor" value="#000000"/>
	<param name="scale" value="noscale"/>
	<param name="quality" value="high"/>
	<param name="allowfullscreen" value="true"/>
	<param name="allowscriptaccess" value="always"/>
	<embed src="Lectorium.swf"
	    name="Lectorium"
	    align="Default"
	    width="100%"
	    height="100%"
	    bgcolor="#000000"
	    scale="noscale"
	    quality="high"
	    allowfullscreen="true"
	    allowscriptaccess="always"
	    type="application/x-shockwave-flash"
	    pluginspage="http://www.adobe.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash"/>
      </object>
    </div>
-->

  </div>

  <div class="watchers_div" id="watchers_div">
{{#BEGIN_LECTURE_BUTTON}}
    <div style="/* border-bottom: 1px solid #c0c0c0; */ padding-top: 10px; padding-bottom: 15px; background-color: #ffffff">
      <table id="begin_lecture_button" class="word_button_table" border="0" cellpadding="0" cellspacing="0">
	<tr>
	  <td class="begin_lecture_button" colspan="2" onclick="beginLecture()">
	    Начать лекцию
	  </td>
	</tr>
      </table>
      <table id="end_lecture_button" class="word_button_table" border="0" cellpadding="0" cellspacing="0" style="display:none">
	<tr>
	  <td class="end_lecture_button" colspan="2" onclick="endLecture()">
	    Завершить лекцию
	  </td>
	</tr>
      </table>
    </div>
    <div style="padding-top: 10px; padding-bottom: 15px; background-color: #ffffff">
      <table id="show_desktop_button" class="word_button_table" border="0" cellpadding="0" cellspacing="0">
        <tr>
          <td class="begin_lecture_button" colspan="2" onclick="showDesktop()">
            Рабочий стол
          </td>
        </tr>
      </table>
      <table id="show_lecture_button" class="word_button_table" border="0" cellpadding="0" cellspacing="0" style="display:none">
        <tr>
          <td class="begin_lecture_button" colspan="2" onclick="showLecture()">
            Видеокамера
          </td>
        </tr>
      </table>
    </div>
{{/BEGIN_LECTURE_BUTTON}}
    <div style="padding: 10px; border-bottom: 1px solid #c0c0c0; border-top: 2px solid #c0c0c0; vertical-align: bottom; text-align: center; background-color: #f0f0f0">
      <span style="font-size: medium; font-weight: bold; color: #333333;">Активный участник</span>
    </div>
    <table style="height: 60px" border="0" cellpadding="0" cellspacing="0">
      <tr><td style="vertical-align: middle"><div id="participant"></div></td></tr>
    </table>
{{#ASK_WORD_BUTTON}}
    <div style="border-top: 1px solid #c0c0c0; padding-top: 15px; padding-bottom: 15px; background-color: #ffffff">
      <table id="ask_word_button" class="word_button_table" border="0" cellpadding="0" cellspacing="0">
	<tr>
	  <td class="ask_word_button" colspan="2" onclick="requestParticipation()">
	    Попросить слово
	  </td>
	</tr>
      </table>
      <table id="end_word_button" class="word_button_table" border="0" cellpadding="0" cellspacing="0" style="display:none">
	<tr>
	  <td class="end_word_button" colspan="2" onclick="endParticipation()">
	    Отменить запрос
	  </td>
	</tr>
      </table>
    </div>
{{/ASK_WORD_BUTTON}}
    <div style="padding: 10px; border-bottom: 1px solid #c0c0c0; border-top: 2px solid #c0c0c0; vertical-align: bottom; text-align: center; background-color: #f0f0f0">
      <span style="font-size: medium; font-weight: bold; color: #333333;">Просят слово</span>
    </div>
    <div id="queue" style="height: 160px; overflow: auto"></div>
    <div style="padding: 10px; border-bottom: 1px solid #c0c0c0; border-top: 2px solid #c0c0c0; vertical-align: bottom; text-align: center; background-color: #f0f0f0">
      <span style="font-size: medium; font-weight: bold; color: #333333;">Зрители</span>
    </div>
  </div>
  <div class="watchers_div_alt watchers_div_alt_{{Lectorium_PageClass}}" id="watchers_div_alt">
    <div id="watchers"></div>
  </div>
</div>

  <div id="WelcomeScreen" style="position: absolute; top: 0px; left: 0px; height: 100%; width: 100%">
    <table style="height: 100%; border: 0; margin-left: auto; margin-right: auto" cellpadding="0" cellspacing="0">
      <tr>
        <td style="vertical-align: middle">
	  <table style="border: 0; width: 800px" cellpadding="0" cellspacing="0">
	    <tr class="welcome_row">
	      <td style="text-align: right; vertical-align: middle; padding-right: 1ex">
		<span style="color: #808080">Введите ваше имя:&nbsp;</span>
	      </td>
	      <td>
		<span style="color: #333333">
		  <input id="NameInput" class="code_input" type="text" placeholder="Ваше имя" onkeydown="codeKeyDown(event)"/>
		</span>
	      </td>
	    </tr>
	    <!-- TODO Выводить список доступных лекций с возможностью выбора -->
	    <!--
	    <tr class="welcome_row">
	      <td style="text-align: right; vertical-align: middle; padding-right: 1ex">
		<span style="color: #808080">Введите название трансляции:&nbsp;</span>
	      </td>
	      <td>
		<span style="color: #333333">
		  <input id="CodeInput" class="code_input" type="text" placeholder="Название трансляции" onkeydown="codeKeyDown(event)"/>
		</span>
	      </td>
	    </tr>
	    -->
	    <tr>
	      <td colspan="2" style="padding-top: 1ex">
		<table border="0" cellpadding="0" cellspacing="0" style="margin-left: auto; margin-right: auto">
		  <tr>
		    <td class="connect_button" colspan="2" onclick="connect()">
		      Подключиться
		    </td>
		  </tr>
		</table>
	      </td>
	    </tr>
	  </table>
	</td>
      </tr>
    </table>
  </div>

  <script type="text/javascript">
/*    flash       = document ["Lectorium"]; */
    chat_input  = document.getElementById ("ChatInput");
    chat_scroll = document.getElementById ("ChatScroll");
    chat_div    = document.getElementById ("ChatDiv");

    got_prv_msg = false;
    prv_phrase_is_own = false;
    prv_msg_is_status = false;

    chat_blocked = true;

    function doAddChatMessage (msg, is_own, is_status, color)
    {
        var scroll_to_bottom = (chat_scroll.scrollTop + chat_scroll.clientHeight >= chat_scroll.scrollHeight);

	var msg_div = document.createElement ('div');

	if (is_status) {
	    if (prv_msg_is_status || !got_prv_msg) {
		msg_div.className = "status_msg";
	    } else {
		msg_div.className = "lead_status_msg";
	    }
	    prv_msg_is_status = true;
	} else {
	    if (is_own) {
		if (got_prv_msg) {
		    if (prv_phrase_is_own && !prv_msg_is_status)
			msg_div.className = "own_chat_phrase";
		    else
			msg_div.className = "lead_own_chat_phrase";
		} else {
		    msg_div.className = "own_chat_phrase";
		}

		prv_phrase_is_own = true;
	    } else {
		if (got_prv_msg) {
		    if (!prv_phrase_is_own && !prv_msg_is_status)
			msg_div.className = "chat_phrase";
		    else
			msg_div.className = "lead_chat_phrase";
		} else {
		    msg_div.className = "chat_phrase";
		}

		prv_phrase_is_own = false;
	    }
	    prv_msg_is_status = false;
	}
	got_prv_msg = true;

	if (color == "red") {
	    msg_div.className += " status_msg_red";
	} else
	if (color == "green") {
	    msg_div.className += " status_msg_green";
	}

	var p_tag = document.createElement ('span');
	var msg_text = document.createTextNode (msg);
	p_tag.appendChild (msg_text);
	msg_div.appendChild (p_tag);
	chat_div.appendChild (msg_div);

	if (scroll_to_bottom)
	    chat_scroll.scrollTop = chat_scroll.scrollHeight;
    }

    function addChatMessage (msg)
    {
	doAddChatMessage (msg, false /* is_own */, false /* is_status */);
    }

    function addStatusMessage (msg)
    {
	doAddChatMessage (msg, false /* is_own */, true /* is_status */, "" /* color */);
    }

    function addRedStatusMessage (msg)
    {
	doAddChatMessage (msg, false /* is_own */, true /* is_status */, "red" /* color */);
    }

    function addGreenStatusMessage (msg)
    {
	doAddChatMessage (msg, false /* is_own */, true /* is_status */, "green" /* color */);
    }

    function sendChatMessage ()
    {
	if (chat_blocked)
	    return;

	msg = chat_input.value;
	chat_input.value = "";

	doAddChatMessage (msg, true /* is_own */, false /* is_status */);
	flash.sendChatMessage (msg);
    }

    function blockChat ()
    {
	chat_blocked = true;
	document.getElementById ("ChatInputWrapper").className = "chat_input_wrapper_blocked";
	document.getElementById ("ChatInput").className = "chat_input chat_input_blocked";
	document.getElementById ("SendButton").className = "send_button send_button_blocked";
    }

    function unblockChat ()
    {
	chat_blocked = false;
	document.getElementById ("ChatInputWrapper").className = "chat_input_wrapper_unblocked";
	document.getElementById ("ChatInput").className = "chat_input chat_input_unblocked";
	document.getElementById ("SendButton").className = "send_button send_button_unblocked";
    }

    function sendButtonClick ()
    {
	sendChatMessage ();
    }

    function chatKeyDown (evt)
    {
	if (evt.keyCode == 13)
	    sendChatMessage ();
    }

    function sendKeyDown (evt)
    {
	if (evt.keyCode == 13 /* Enter */ || evt.keyCode == 32 /* Spacebar */)
	    sendChatMessage ();
    }
  </script>

  <script type="text/javascript">
    function updateWatcherList ()
    {
	var watchers_div = document.getElementById ("watchers");

	$.get ("/lectorium_api/watcher_list?lecture=lecture",
	    {},
	    function (data) {
	        watchers_div.innerHTML = '';

//		addStatusMessage ("--- " + data);
		var watcher_list = eval ('(' + data + ')');
		var class_one = "watcher_entry_one";
		var class_two = "watcher_entry_two";
		var cur_class = class_one;
		for (var i = 0; i < watcher_list.length; ++i) {
		    var item = watcher_list [i];
		    var entry = document.createElement ("div");
		    entry.className = cur_class;
		    entry.style.padding = "10px";
		    entry.style.textAlign = "left";
		    entry.style.verticalAlign = "bottom";
		    /*
		    entry.onclick =
			    (function (uri, stream_name) {
				     return function () {
					     document ["MySubscriber"].setSource (uri, stream_name);
				     };
			     }) (item [1], item [2]);
		    */
		    entry.innerHTML = item [0];
		    watchers_div.appendChild (entry);

		    if (cur_class == class_one)
			cur_class = class_two;
		    else
			cur_class = class_one;
		}
	    }
	);
    }

    function updateQueue ()
    {
	var queue_div = document.getElementById ("queue");

	$.get ("/lectorium_api/queue?lecture=lecture",
	    {},
	    function (data) {
		queue_div.innerHTML = '';

		var queue_list = eval ('(' + data + ')');
		var class_one = "watcher_entry_one";
		var class_two = "watcher_entry_two";
		var cur_class = class_one;
		for (var i = 0; i < queue_list.length; ++i) {
		    var item = queue_list [i];
		    var entry = document.createElement ("div");
		    entry.className = cur_class;
		    entry.style.padding = "10px";
		    entry.style.textAlign = "left";
		    entry.style.verticalAlign = "bottom";
		    entry.innerHTML =
			'<table style="width: 100%" border="0" cellpadding="0" cellspacing="0"><tr><td style="width: 100%">' + item [0] +
			'</td>' +
			(is_lector == "true" ? '<td class="give_word_button" onclick="giveWord(\'' + item [1] + '\')"><b><big>+</big></b></td>' : '');
		    queue_div.appendChild (entry);

		    if (cur_class == class_one)
			cur_class = class_two;
		    else
			cur_class = class_one;
		}
	    }
	);
    }

    function newParticipant (user_name, client_id)
    {
	var participant_div = document.getElementById ("participant");

	participant_div.innerHTML =
		'<div class="watcher_entry_one" style="padding: 10px; text-align: left; vertical-align: bottom">' +
		'<table style="width: 100%" border="0" cellpadding="0" cellspacing="0"><tr><td style="width: 100%">' + user_name +
		'</td>' +
		(is_lector == "true" ? '<td class="drop_participant_button" onclick="dropParticipant(\'' + client_id + '\')"><b><big>-</big></b></td>' : '') +
		'</tr></table></div>';
    }

    function participantGone ()
    {
	var participant_div = document.getElementById ("participant");
	participant_div.innerHTML = '';
    }

    function participationDropped ()
    {
	showAskWordButton ();
    }

    function lectureStart ()
    {
	{
	    begin_button = document.getElementById ("begin_lecture_button");
	    begin_button.style.display = "none";
	}
	{
	    end_button = document.getElementById ("end_lecture_button");
	    end_button.style.display = "";
	}
    }
  </script>
</body>
</html>

