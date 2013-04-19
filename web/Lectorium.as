/*  Lectorium module for Moment Video Server
    Copyright (C) 2011-2013 Dmitry Shatrov

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


package {

import flash.external.ExternalInterface;
import flash.display.Sprite;
import flash.display.StageScaleMode;
import flash.display.StageAlign;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.media.Camera;
import flash.media.Microphone;
import flash.media.Video;
import flash.media.SoundTransform;
import flash.media.SoundCodec;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.ObjectEncoding;
import flash.net.URLRequest;
import flash.events.Event;
import flash.events.NetStatusEvent;
import flash.events.MouseEvent;
import flash.utils.setInterval;
import flash.utils.clearInterval;

public class Lectorium extends Sprite
{
    private var mode : String;

    private var uri : String;
    private var stream_name : String;

    private var is_lector : Boolean;
    private var user_name : String;

    private var my_client_id : String;
    private var participant_client_id : String;

    private var first_reconnect_interval : Number;
    private var default_buffer_time : Number;

    private var my_video_normal_width  : Number;
    private var my_video_normal_height : Number;
    private var my_video_fullscreen_width  : Number;
    private var my_video_fullscreen_height : Number;

    private var cam : Camera;
    private var mic : Microphone;

    // Lector's video frame
    private var lecture_video : Video;
    // Participant's video frame
    private var participant_video : Video;
    private var participant_video_stub : Sprite;
    // Video grabbed from user's own webcam
    private var my_video : Video;

    private var main_conn : NetConnection;
    // Video from user's webcam goes to 'main_stream'.
    private var main_stream : NetStream;
    private var main_reconnect_timer : uint;
    private var main_reconnect_timer_active : Boolean;
    private var main_reconnect_interval : uint;

    private var lecture_conn : NetConnection;
    private var lecture_stream : NetStream;
    private var lecture_reconnect_timer : uint;
    private var lecture_reconnect_timer_active : Boolean;
    private var lecture_reconnect_interval : uint;

    private var lecture_buffering_complete : Boolean;
    private var lecture_frame_no : uint;

    private var participant_conn : NetConnection;
    private var participant_stream : NetStream;
    private var participant_reconnect_timer : uint;
    private var participant_reconnect_timer_active : Boolean;
    private var participant_reconnect_interval : uint;
    private var participant_closing : Boolean;

    private var buttons_visible : Boolean;

    private var lecture_started : Boolean;
    private var participant_online : Boolean;
    private var participating : Boolean;

    private var mic_on : Boolean;
    private var cam_on : Boolean;
    private var sound_on : Boolean;
    private var participant_sound_on : Boolean;

    // If true, then horizontal mode is enabled.
    private var horizontal_mode : Boolean;

    private var lecture_mic_on : Boolean;
    private var lecture_cam_on : Boolean;

    [Embed (source="img/peer_mic_off.png")]
    private var LectureMicOff : Class;
    private var lecture_mic_off_mark : Bitmap;

    [Embed (source="img/peer_cam_off.png")]
    private var LectureCamOff : Class;
    private var lecture_cam_off_mark : Bitmap;

    [Embed (source="img/my_mic_off.png")]
    private var MyMicOffMark : Class;
    private var my_mic_off_mark : Bitmap;

    [Embed (source="img/my_cam_off.png")]
    private var MyCamOffMark : Class;
    private var my_cam_off_mark : Bitmap;

    [Embed (source="img/roll.png")]
    private var RollButton : Class;
    private var roll_button : Sprite;

    [Embed (source="img/unroll.png")]
    private var UnrollButton : Class;
    private var unroll_button : Sprite;

    [Embed (source="img/mic_on.png")]
    private var MicButtonOn : Class;
    private var mic_button_on : Sprite;

    [Embed (source="img/mic_off.png")]
    private var MicButtonOff : Class;
    private var mic_button_off : Sprite;

    [Embed (source="img/cam_on.png")]
    private var CamButtonOn : Class;
    private var cam_button_on : Sprite;

    [Embed (source="img/cam_off.png")]
    private var CamButtonOff : Class;
    private var cam_button_off : Sprite;

    [Embed (source="img/sound_on.png")]
    private var SoundButtonOn : Class;
    private var sound_button_on : Sprite;

    [Embed (source="img/sound_off.png")]
    private var SoundButtonOff : Class;
    private var sound_button_off : Sprite;

    [Embed (source="img/fullscreen.png")]
    private var FullscreenButton : Class;
    private var fullscreen_button : Sprite;

    [Embed (source="img/horizontal.png")]
    private var HorizontalButton : Class;
    private var horizontal_button : Sprite;

//    [Embed (source="img/splash.png")]
    [Embed (source="img/no_lecture.png")]
    private var SplashImage : Class;
    private var splash : Sprite;

    private var hide_buttons_timer : uint;
    private var hide_buttons_timer_active : Boolean;

    private var stage_width : int;
    private var stage_height : int;

    private function sendChatMessage (msg : String) : void
    {
	if (main_conn)
	    main_conn.call ("lectorium_chat", null, msg);
    }

    public function addChatMessage (msg : String) : void
    {
	ExternalInterface.call ("addChatMessage", msg);
    }

    public function addStatusMessage (msg : String) : void
    {
	ExternalInterface.call ("addStatusMessage", msg);
    }

    public function addRedStatusMessage (msg : String) : void
    {
	ExternalInterface.call ("addRedStatusMessage", msg);
    }

    public function addGreenStatusMessage (msg : String) : void
    {
	ExternalInterface.call ("addGreenStatusMessage", msg);
    }

    public function showSplash () : void
    {
	lecture_video.visible = false;
// Unnecessary
//	participant_video.visible = false;

// Wrong
//	lecture_cam_off_mark.visible = false;
//	lecture_mic_off_mark.visible = false;

	if (mode != "watcher")
	    splash.visible = true;
    }

    public function showLectureVideo () : void
    {
	splash.visible = false;
	if (mode != "watcher")
	    lecture_video.visible = true;

	if (!lecture_cam_on)
	    lecture_cam_off_mark.visible = true;
	if (!lecture_mic_on)
	    lecture_mic_off_mark.visible = true;

// Unnecessary
//	if (participant_online)
//	    participant_video.visible = true;
    }

    public function lectureMicOn () : void
    {
	lecture_mic_on = true;
	repositionButtons ();
	lecture_mic_off_mark.visible = false;
    }

    public function lectureMicOff () : void
    {
	lecture_mic_on = false;
	repositionButtons ();
	lecture_mic_off_mark.visible = true;
    }

    public function lectureCamOn () : void
    {
	lecture_cam_on = true;
	repositionButtons ();
	lecture_cam_off_mark.visible = false;
	showLectureVideo ();
    }

    public function lectureCamOff () : void
    {
	lecture_cam_on = false;
	repositionButtons ();
	lecture_cam_off_mark.visible = true;
	showSplash ();
    }

    public function lectureStart () : void
    {
	lecture_started = true;

	addGreenStatusMessage ("Лекция началась");
	ExternalInterface.call ("lectureStart");
	doLectureStart ();

	if (!is_lector && sound_on)
	    doTurnSoundOn ();
    }

    public function doLectureStart () : void
    {
	splash.visible = false;
	if (mode != "watcher")
	    lecture_video.visible = true;

	if (!lecture_cam_on)
	    lecture_cam_off_mark.visible = true;
	if (!lecture_mic_on)
	    lecture_mic_off_mark.visible = true;

	if (participant_online) {
	    participant_video.visible = true;
	    if (participant_video_stub)
		participant_video_stub.visible = true;
	}
    }

    public function lectureStop () : void
    {
	if (lecture_started) {
	    lecture_started = false;
	    addRedStatusMessage ("Лекция закончилась");
	}

	doLectureStop ();

	if (!is_lector)
	    doTurnSoundOff ();
    }

    public function doLectureStop () : void
    {
	if (is_lector) {
	    doLectureStart ();
	    return;
	}

	lecture_video.visible = false;
	participant_video.visible = false;

	lecture_cam_off_mark.visible = false;
	lecture_mic_off_mark.visible = false;

	if (mode != "watcher")
	    splash.visible = true;
    }

    public function setSessionInfo (client_id : String) : void
    {
//	addStatusMessage ("--- setSessionInfo: client_id: " + client_id);
	my_client_id = client_id;
    }

    private function onLectureEnterFrame (event : Event) : void
    {
	if (lecture_buffering_complete) {
	    repositionVideo ();

	    if (lecture_frame_no == 100)
		lecture_video.removeEventListener (Event.ENTER_FRAME, onLectureEnterFrame);

	    ++lecture_frame_no;
	    return;
	}

	++lecture_frame_no;

	repositionVideo();
	repositionButtons();
    }

    private function onMainStreamNetStatus (event : NetStatusEvent) : void
    {
//	addStatusMessage ("onMainStreamNetStatus: " + event.info.code);
    }

    private function onLectureStreamNetStatus (event : NetStatusEvent) : void
    {
//	addStatusMessage ("onLectureStreamNetStatus: " + event.info.code);

	if (event.info.code == "NetStream.Buffer.Full") {
	    lecture_buffering_complete = true;
	    repositionVideo ();
	}
    }

    private function onParticipantStreamNetStatus (event : NetStatusEvent) : void
    {
//	addStatusMessage ("onParticipantStreamNetStatus: " + event.info.code);
    }

    private function doConnect (lecture_name : String, user_name : String, reconnect : Boolean) : void
    {
//	addStatusMessage ("doConnect: " + uri + '/' + lecture_name);

	stream_name = lecture_name;

	doConnectMain (user_name, reconnect);
	if (mode != "watcher")
	    doConnectLecture (reconnect);

// Unnecessary
//	doConnectParticipant (reconnect);
    }

    private function doConnectMain (user_name : String, reconnect : Boolean) : void
    {
	ExternalInterface.call ("blockChat");

	if (main_conn)
	    main_conn.close ();

	if (!reconnect) {
	    main_reconnect_interval = first_reconnect_interval;
	} else {
	    if (main_reconnect_interval == first_reconnect_interval) {
		main_reconnect_interval = 5000;
		clearInterval (main_reconnect_timer);
		main_reconnect_timer = setInterval (mainReconnectTick, main_reconnect_interval);
	    }
	}

	main_conn = new NetConnection ();
	main_conn.client = new MainConnClient (this);

	main_conn.objectEncoding = ObjectEncoding.AMF0;
	main_conn.addEventListener (NetStatusEvent.NET_STATUS, onMainConnNetStatus);
	main_conn.connect (uri + '/.lectorium.main.' + stream_name);

	var is_hidden : Boolean = (mode == "watcher");
	main_conn.call ("lectorium_intro", null, user_name, is_lector, is_hidden);
    }

    private function doConnectLecture (reconnect : Boolean) : void
    {
	lecture_video.removeEventListener (Event.ENTER_FRAME, onLectureEnterFrame);

	if (lecture_conn)
	    lecture_conn.close ();

	if (!reconnect) {
	    lecture_reconnect_interval = first_reconnect_interval;
	} else {
	    if (lecture_reconnect_interval == first_reconnect_interval) {
		lecture_reconnect_interval = 5000;
		clearInterval (lecture_reconnect_timer);
		lecture_reconnect_timer = setInterval (lectureReconnectTick, lecture_reconnect_interval);
	    }
	}

	lecture_conn = new NetConnection ();
// Not yet implemented
//	lecture_conn.client = new LectureConnClient (this);

	lecture_conn.objectEncoding = ObjectEncoding.AMF0;
	lecture_conn.addEventListener (NetStatusEvent.NET_STATUS, onLectureConnNetStatus);
	lecture_conn.connect (uri + '/.lectorium.lecture.' + stream_name);

// Unnecessary for now
//	lecture_conn.call ("lectorium_intro", null, user_name);
    }

    private function disconnectParticipant () : void
    {
	// TODO Protect from stream status notifications?

	if (participant_conn)
	    participant_conn.close ();

	if (participant_reconnect_timer_active) {
	    clearInterval (participant_reconnect_timer);
	    participant_reconnect_timer_active = false;
	}
    }

    private function doConnectParticipant (reconnect : Boolean) : void
    {
	if (participant_conn)
	    participant_conn.close ();

	if (!reconnect) {
	    participant_reconnect_interval = first_reconnect_interval;
	} else {
	    if (participant_reconnect_interval == first_reconnect_interval) {
		participant_reconnect_interval = 5000;

		// TODO FIXME Do the same for all other conns.
		if (participant_reconnect_timer_active)
		    clearInterval (participant_reconnect_timer);

		participant_reconnect_timer = setInterval (participantReconnectTick, participant_reconnect_interval);
		participant_reconnect_timer_active = true;
	    }
	}

	participant_conn = new NetConnection ();
// Not yet implemented
//	participant_conn.client = new ParticipantConnClient (this);

	participant_conn.objectEncoding = ObjectEncoding.AMF0;
	participant_conn.addEventListener (NetStatusEvent.NET_STATUS, onParticipantConnNetStatus);
	participant_conn.connect (uri + '/.lectorium.participant.' + stream_name);

// Unnecessary for now
//	participant_conn.call ("lectorium_intro", null, user_name);
    }

    private function connect (lecture_name : String, new_user_name : String) : void
    {
	user_name = new_user_name;

//	showSplash ();
	doLectureStop ();

	addStatusMessage ("Ваше имя: " + user_name);
	addStatusMessage ("Соединение с сервером " + uri + " ...");

	doConnect (lecture_name, user_name, false /* reconnect */);
    }

    private function requestParticipation () : void
    {
	if (!main_conn || !main_stream) {
	    addRedStatusMessage ("Нет соединения. Попробуйте попросить слово чуть позже.");
	    return;
	}

	main_conn.call ("lectorium_request_participation", null);

	if (!cam) {
	    /* Not in Flex 4.1 SDK
             * if (Camera.isSupported) */ {
		cam = Camera.getCamera();
		if (cam) {
		    my_video.attachCamera (cam);
		    cam.setMode (640, 480, 15);
		    cam.setQuality (100000, 0);
		}
	    }
	}

	if (!mic) {
	    /* Not in Flex 4.1 SDK
	     * if (Microphone.isSupported) */ {
/* OLD
		mic = Microphone.getMicrophone();
		if (mic) {
		    mic.setLoopBack (false);
		    mic.setUseEchoSuppression (true);
		}
*/
                mic = Microphone.getEnhancedMicrophone();
                if (mic) {
                    mic.setSilenceLevel (0, 2000);
                } else {
                    mic = Microphone.getMicrophone();
                }

                if (mic) {
                    mic.codec = SoundCodec.SPEEX;
                    mic.setUseEchoSuppression (true);
                    mic.setLoopBack (false);
                    mic.gain = 50;
                }
	    }
	}

	// TODO Attach after participation is granted
	if (cam && cam_on)
	    main_stream.attachCamera (cam);

	// TODO Attach after participation is granted
	if (mic && mic_on)
	    main_stream.attachAudio (mic);

	participating = true;
	doUnrollMyVideo ();

	addStatusMessage ("Вы попросили слово");
    }

    private function endParticipation () : void
    {
	if (!main_conn || !main_stream)
	    return;

	participating = false;
	doRollMyVideo ();

	main_conn.call ("lectorium_end_participation", null);
    }

    private function giveWord (client_id : String) : void
    {
	if (main_conn) {
//	    addStatusMessage ("Слово предоставляется зрителю " + client_id);
	    main_conn.call ("lectorium_give_word", null, client_id);
	}
    }

    private function dropParticipant (client_id : String) : void
    {
	if (main_conn) {
//	    addStatusMessage ("Выступление зрителя " + client_id + " завершено");
	    main_conn.call ("lectorium_drop_participant", null, client_id);
	}
    }

    private function beginLecture () : void
    {
	if (main_conn)
	    main_conn.call ("lectorium_begin_lecture", null);
    }

    private function endLecture () : void
    {
	if (main_conn)
	    main_conn.call ("lectorium_end_lecture", null);
    }

    private function showDesktop () : void
    {
        if (main_conn)
            main_conn.call ("lectorium_show_desktop", null);
    }

    private function showLecture () : void
    {
        if (main_conn)
            main_conn.call ("lectorium_show_lecture", null);
    }

    private function mainReconnectTick () : void
    {
	doConnectMain (user_name, true /* reconnect */);
// Unnecessary
//	doConnectParticipant (true /* reconnect */);
    }

    private function lectureReconnectTick () : void
    {
	doConnectLecture (true /* reconnect */);
    }

    private function participantReconnectTick () : void
    {
//	addStatusMessage ("participantReconnectTimerTick");
	doConnectParticipant (true /* reconnect */);
    }

    private function onMainConnNetStatus (event : NetStatusEvent) : void
    {
//	addStatusMessage ("onMainConnNetStatus: " + event.info.code);

	if (event.info.code == "NetConnection.Connect.Success") {
	    if (main_reconnect_timer_active) {
		clearInterval (main_reconnect_timer);
		main_reconnect_timer_active = false;
	    }
	    main_reconnect_interval = first_reconnect_interval;

	    addStatusMessage ("Соединение установлено");

	    ExternalInterface.call ("unblockChat");

	    if (!mic_on)
		main_conn.call ("lectorium_mic_off", null);

	    if (!cam_on)
		main_conn.call ("lectorium_cam_off", null);

	    main_stream = new NetStream (main_conn);

	    main_stream.bufferTime = default_buffer_time;
	    // This does not work with older versions of Flash player
	    // main_stream.bufferTimeMax = 0.1;

	    main_stream.addEventListener (NetStatusEvent.NET_STATUS, onMainStreamNetStatus);

	    main_stream.publish (stream_name);

	    if (cam && cam_on)
		main_stream.attachCamera (cam);

	    if (mic && mic_on)
		main_stream.attachAudio (mic);

	    ExternalInterface.call ("flashConnected", mode);
	} else
	// TODO Rejected, AppShutDown error codes.
	if (event.info.code == "NetConnection.Connect.Closed" ||
	    event.info.code == "NetConnection.Connect.Failed")
	{
	    if (!main_reconnect_timer_active &&
		event.info.code == "NetConnection.Connect.Failed")
	    {
		addRedStatusMessage ("Ошибка соединения с сервером");
	    }

	    if (event.info.code == "NetConnection.Connect.Closed")
		addRedStatusMessage ("Соединение с сервером разорвано");

	    ExternalInterface.call ("blockChat");

	    if (!main_reconnect_timer_active) {
		addStatusMessage ("Повторное соединение...");

		if (main_reconnect_interval == 0) {
		    doConnectMain (user_name, true /* reconnect */);
// Unnecessary
//		    doConnectParticipant (true /* reconnect */);
		    return;
		}

		main_reconnect_timer = setInterval (mainReconnectTick, main_reconnect_interval);
		main_reconnect_timer_active = true;
	    }
	}
    }

    private function onLectureConnNetStatus (event : NetStatusEvent) : void
    {
//	addStatusMessage ("onLectureConnNetStatus: " + event.info.code);

	if (event.info.code == "NetConnection.Connect.Success") {
	    if (lecture_reconnect_timer_active) {
		clearInterval (lecture_reconnect_timer);
		lecture_reconnect_timer_active = false;
	    }
	    lecture_reconnect_interval = first_reconnect_interval;

//	    addStatusMessage ("Соединение установлено (lecture)");

	    lecture_stream = new NetStream (lecture_conn);

	    lecture_stream.bufferTime = default_buffer_time;
	    // This does not work with older versions of Flash player
	    // lecture_stream.bufferTimeMax = 0.1;

	    lecture_stream.addEventListener (NetStatusEvent.NET_STATUS, onLectureStreamNetStatus);

	    lecture_buffering_complete = false;
	    lecture_frame_no = 0;

// This has no effect
//            lecture_video.clear ();
//            lecture_video.attachNetStream (null);

	    lecture_video.addEventListener (Event.ENTER_FRAME, onLectureEnterFrame);

	    if (!sound_on || (!is_lector && !lecture_started))
		doTurnSoundOff ();

	    lecture_video.attachNetStream (lecture_stream);
	    lecture_stream.play (stream_name);

//	    showLectureVideo ();
	} else
	// TODO Rejected, AppShutDown error codes.
	if (event.info.code == "NetConnection.Connect.Closed" ||
	    event.info.code == "NetConnection.Connect.Failed")
	{
	    lecture_video.removeEventListener (Event.ENTER_FRAME, onLectureEnterFrame);

	    if (!lecture_reconnect_timer_active &&
		event.info.code == "NetConnection.Connect.Failed")
	    {
//		addRedStatusMessage ("Ошибка соединения с сервером (lecture)");
	    }

//	    if (event.info.code == "NetConnection.Connect.Closed")
//		addRedStatusMessage ("Соединение с сервером разорвано (lecture)");

	    if (!lecture_reconnect_timer_active) {
//		addStatusMessage ("Повторное соединение (lecture)...");

		if (lecture_reconnect_interval == 0) {
		    doConnectLecture (true /* reconnect */);
		    return;
		}

		lecture_reconnect_timer = setInterval (lectureReconnectTick, lecture_reconnect_interval);
		lecture_reconnect_timer_active = true;
	    }
	}
    }

    private function onParticipantConnNetStatus (event : NetStatusEvent) : void
    {
//	addStatusMessage ("onParticipantConnNetStatus: " + event.info.code);

	if (event.info.code == "NetConnection.Connect.Success") {
	    if (participant_reconnect_timer_active) {
		clearInterval (participant_reconnect_timer);
		participant_reconnect_timer_active = false;
	    }
	    participant_reconnect_interval = first_reconnect_interval;

//	    addStatusMessage ("Соединение установлено (participant)");

	    participant_stream = new NetStream (participant_conn);

	    participant_stream.bufferTime = default_buffer_time;
	    // This does not work with older versions of Flash player
	    // participant_stream.bufferTimeMax = 0.1;

	    participant_stream.addEventListener (NetStatusEvent.NET_STATUS, onParticipantStreamNetStatus);

	    if (!participant_sound_on || my_client_id == participant_client_id)
		doTurnParticipantSoundOff ();
// Unnecessary
//	    else
//		doTurnParticipantSoundOn ();

	    participant_video.attachNetStream (participant_stream);

	    participant_stream.play (stream_name);
	} else
	// TODO Rejected, AppShutDown error codes.
	if (event.info.code == "NetConnection.Connect.Closed" ||
	    event.info.code == "NetConnection.Connect.Failed")
	{
	    if (participant_closing) {
//		addStatusMessage ("participant_closing");
		return;
	    }

	    if (!participant_reconnect_timer_active &&
		event.info.code == "NetConnection.Connect.Failed")
	    {
//		addRedStatusMessage ("Ошибка соединения с сервером (participant)");
	    }

//	    if (event.info.code == "NetConnection.Connect.Closed")
//		addRedStatusMessage ("Соединение с сервером разорвано (participant)");

	    if (!participant_reconnect_timer_active) {
//		addStatusMessage ("Повторное соединение (participant)...");

		if (participant_reconnect_interval == 0) {
		    doConnectParticipant (true /* reconnect */);
		    return;
		}

		participant_reconnect_timer = setInterval (participantReconnectTick, participant_reconnect_interval);
		participant_reconnect_timer_active = true;
	    }
	}
    }

    public function updateWatcherList () : void
    {
	ExternalInterface.call ("updateWatcherList");
    }

    public function updateQueue () : void
    {
	ExternalInterface.call ("updateQueue");
    }

    public function newParticipant (user_name : String, client_id : String) : void
    {
	if (mode == "lector")
	    return;

        addStatusMessage ("Слово предоставляется зрителю " + user_name);

	participant_online = true;
	participant_client_id = client_id;

//	addStatusMessage ("newParticipant()");
	doConnectParticipant (false /* reconnect */);

	participant_video.clear ();
	participant_video.visible = true;
	if (participant_video_stub)
	    participant_video_stub.visible = true;

	ExternalInterface.call ("newParticipant", user_name, client_id);
    }

    public function participantGone (user_name : String) : void
    {
	addStatusMessage ("Выступление зрителя " + user_name + " завершено");

//	addStatusMessage ("participantGone");

	participant_online = false;

	participant_video.visible = false;
	participant_video.clear ();
	if (participant_video_stub)
	    participant_video_stub.visible = false;

	participant_closing = true;
	disconnectParticipant ();
	participant_closing = false;

	ExternalInterface.call ("participantGone");
    }

    public function participationDropped () : void
    {
	participating = false;
	doRollMyVideo ();
	addRedStatusMessage ("Ваше выступление завершено");

	ExternalInterface.call  ("participationDropped");
    }

    private function rollMyVideo (event : MouseEvent) : void
    {
	doRollMyVideo ();
    }

    private function doRollMyVideo () : void
    {
	my_video.visible = false;
	my_mic_off_mark.visible = false;
	my_cam_off_mark.visible = false;
	showButtons ();
    }

    private function unrollMyVideo (event : MouseEvent) : void
    {
	doUnrollMyVideo ();
    }

    private function doUnrollMyVideo () : void
    {
	my_video.visible = true;

	if (!mic_on)
	    my_mic_off_mark.visible = true;

	if (!cam_on)
	    my_cam_off_mark.visible = true;

	showButtons ();
    }

    private function turnMicOn (event : MouseEvent) : void
    {
	if (main_stream)
	    main_stream.attachAudio (mic);

	mic_on = true;
	repositionButtons ();
	my_mic_off_mark.visible = false;
	showButtons ();

	if (main_conn)
	    main_conn.call ("lectorium_mic_on", null);
    }

    private function turnMicOff (event : MouseEvent) : void
    {
	if (main_stream)
	    main_stream.attachAudio (null);

	mic_on = false;
	repositionButtons ();

	if (cam && my_video.visible)
	    my_mic_off_mark.visible = true;

	showButtons ();

	if (main_conn)
	    main_conn.call ("lectorium_mic_off", null);
    }

    private function turnCamOn (event : MouseEvent) : void
    {
	if (main_stream)
	    main_stream.attachCamera (cam);

	cam_on = true;
	repositionButtons ();
	my_cam_off_mark.visible = false;
	showButtons ();

	if (main_conn)
	    main_conn.call ("lectorium_cam_on", null);
    }

    private function turnCamOff (event : MouseEvent) : void
    {
	if (main_stream)
	    main_stream.attachCamera (null);

	cam_on = false;
	repositionButtons ();

	if (cam && my_video.visible)
	    my_cam_off_mark.visible = true;

	showButtons ();

	if (main_conn)
	    main_conn.call ("lectorium_cam_off", null);
    }

    private function turnSoundOn (event : MouseEvent) : void
    {
	sound_on = true;
	showButtons ();

	doTurnSoundOn ();
    }

    private function doTurnSoundOn () : void
    {
	if (!is_lector && !lecture_started) {
	    doTurnSoundOff ();
	    return;
	}

	/* SoundTransform works with a noticable delay */
	if (lecture_stream) {
//	    if (!lecture_stream.soundTransform)
		lecture_stream.soundTransform = new SoundTransform ();
//	    else
//		lecture_stream.soundTransform.volume = 1;
	}
    }

    private function turnSoundOff (event : MouseEvent) : void
    {
	sound_on = false;
	showButtons ();

	doTurnSoundOff ();
    }

    private function doTurnSoundOff () : void
    {
	if (lecture_stream) {
//	    if (!lecture_stream.soundTransform)
		lecture_stream.soundTransform = new SoundTransform (0);
//	    else
//		lecture_stream.soundTransform.volume = 0;
	}
    }

    private function doTurnParticipantSoundOn () : void
    {
	if (participant_stream)
	    participant_stream.soundTransform = new SoundTransform ();
    }

    private function doTurnParticipantSoundOff () : void
    {
	if (participant_stream)
	    participant_stream.soundTransform = new SoundTransform (0);
    }

    private function toggleFullscreen (event : MouseEvent) : void
    {
	if (stage.displayState == "fullScreen")
	    stage.displayState = "normal";
	else
	    stage.displayState = "fullScreen";
    }

    private function toggleHorizontal (event : MouseEvent) : void
    {
	horizontal_mode = !horizontal_mode;
	repositionVideo ();
    }

    private function doResize () : void
    {
	stage_width  = stage.stageWidth;
	stage_height = stage.stageHeight;

	repositionVideo ();
	repositionButtons ();
	repositionSplash ();

	showButtons ();
    }

    private function repositionButtons () : void
    {
	lecture_mic_off_mark.x = 25;
	lecture_mic_off_mark.y = 25;

	lecture_cam_off_mark.x = lecture_mic_on ? 25 : 90;
	lecture_cam_off_mark.y = 25;

	my_mic_off_mark.x = 20;
	my_mic_off_mark.y = (stage_height - my_video.height - 10) + 10;

	my_cam_off_mark.x = 20 + (!mic_on ? my_mic_off_mark.width + 10 : 0);
	my_cam_off_mark.y = (stage_height - my_video.height - 10) + 10;

	roll_button.x = my_video.x;
	roll_button.y = my_video.y + my_video.height - roll_button.height;

	unroll_button.x = my_video.x;
	unroll_button.y = my_video.y + my_video.height - unroll_button.height;

	horizontal_button.x = stage_width - horizontal_button.width - 20;
//	horizontal_button.y = stage_height - horizontal_button.height - 90;
	horizontal_button.y = 90;

	fullscreen_button.x = stage_width  - fullscreen_button.width  - 20;
//	fullscreen_button.y = stage_height - fullscreen_button.height - 20;
	fullscreen_button.y = 20;

	sound_button_on.x  = stage_width  - sound_button_on.width   - 90;
//	sound_button_on.y  = stage_height - sound_button_on.height  - 20;
	sound_button_on.y  = 20;
	sound_button_off.x = stage_width  - sound_button_off.width  - 90;
//	sound_button_off.y = stage_height - sound_button_off.height - 20;
	sound_button_off.y = 20;

	cam_button_on.x  = stage_width  - cam_button_on.width   - 160;
//	cam_button_on.y  = stage_height - cam_button_on.height  -  20;
	cam_button_on.y  = 20;
	cam_button_off.x = stage_width  - cam_button_off.width  - 160;
//	cam_button_off.y = stage_height - cam_button_off.height -  20;
	cam_button_off.y = 20;

	mic_button_on.x  = stage_width  - mic_button_on.width   - 230;
//	mic_button_on.y  = stage_height - mic_button_on.height  -  20;
	mic_button_on.y  = 20;
	mic_button_off.x = stage_width  - mic_button_off.width  - 230;
//	mic_button_off.y = stage_height - mic_button_off.height -  20;
	mic_button_off.y = 20;
    }

    private function repositionSplash () : void
    {
        splash.x = (stage_width - splash.width) / 2;
        splash.y = (stage_height - splash.height) / 2;
    }

    private function videoShouldBeHorizontal () : Boolean
    {
	if (stage_width == 0 || stage_height == 0)
	    return true;

	var x_aspect : Number = (0.0 + Number (lecture_video.videoWidth))  / Number (stage_width);
	var y_aspect : Number = (0.0 + Number (lecture_video.videoHeight)) / Number (stage_height);

	return x_aspect >= y_aspect;
    }

    private function repositionVideo () : void
    {
	if (horizontal_mode || videoShouldBeHorizontal()) {
	    lecture_video.width = stage_width;
	    lecture_video.height = stage_width * (lecture_video.videoHeight / lecture_video.videoWidth);
	    lecture_video.x = 0;
	    lecture_video.y = (stage_height - lecture_video.height) / 2;
	} else {
	    lecture_video.width = stage_height * (lecture_video.videoWidth / lecture_video.videoHeight);
	    lecture_video.height = stage_height;
	    lecture_video.x = (stage_width - lecture_video.width) / 2;
	    lecture_video.y = 0;
	}

	if (mode == "watcher") {
	    my_video.width = stage_width;
	    my_video.height = stage_height;
	    my_video.x = 0;
	    my_video.y = 0;
	} else {
	    if (stage.displayState == "fullScreen") {
		my_video.width  = my_video_fullscreen_width;
		my_video.height = my_video_fullscreen_height;
	    } else {
		my_video.width  = my_video_normal_width;
		my_video.height = my_video_normal_height;
	    }

	    my_video.x = 10;
	    my_video.y = (stage_height - my_video.height - 10);
	}

	if (mode == "watcher") {
	    participant_video.width = stage_width;
	    participant_video.height = stage_height;
	    participant_video.x = 0;
	    participant_video.y = 0;
	} else {
	    if (stage.displayState == "fullScreen") {
		participant_video.width  = my_video_fullscreen_width;
		participant_video.height = my_video_fullscreen_height;
	    } else {
		participant_video.width  = my_video_normal_width;
		participant_video.height = my_video_normal_height;
	    }

	    participant_video.x = (stage_width  - participant_video.width  - 10);
	    participant_video.y = (stage_height - participant_video.height - 10);
	}
    }

    private function hideButtonsTick () : void
    {
	if (hide_buttons_timer_active) {
	    clearInterval (hide_buttons_timer);
	    hide_buttons_timer_active = false;
	}

	buttons_visible = false;
	roll_button.visible = false;
	unroll_button.visible = false;
	mic_button_on.visible = false;
	mic_button_off.visible = false;
	cam_button_on.visible = false;
	cam_button_off.visible = false;
	sound_button_on.visible = false;
	sound_button_off.visible = false;
	fullscreen_button.visible = false;
	horizontal_button.visible = false;
    }

    private function showButtons () : void
    {
	buttons_visible = true;

	if (mode != "watcher" && cam && participating) {
	    if (my_video.visible) {
		roll_button.visible = true;
		unroll_button.visible = false;
	    } else {
		roll_button.visible = false;
		unroll_button.visible = true;
	    }
	} else {
	    roll_button.visible = false;
	    unroll_button.visible = false;
	}

	if (mic_on) {
//	    mic_button_on.visible = true;
	    mic_button_on.visible = false;
	    mic_button_off.visible = false;
	} else {
	    mic_button_on.visible = false;
//	    mic_button_off.visible = true;
	    mic_button_off.visible = false;
	}

	if (cam_on) {
//	    cam_button_on.visible = true;
	    cam_button_on.visible = false;
	    cam_button_off.visible = false;
	} else {
	    cam_button_on.visible = false;
//	    cam_button_off.visible = true;
	    cam_button_off.visible = false;
	}

	if (sound_on) {
	    sound_button_on.visible = true;
	    sound_button_off.visible = false;
	} else {
	    sound_button_on.visible = false;
	    sound_button_off.visible = true;
	}

	fullscreen_button.visible = true;

	if (lecture_video.visible &&
	    !videoShouldBeHorizontal ())
	{
	    horizontal_button.visible = true;
	} else {
	    horizontal_button.visible = false;
	}
    }

    private function onMouseMove (event : MouseEvent) : void
    {
	if (hide_buttons_timer_active) {
	    clearInterval (hide_buttons_timer);
	    hide_buttons_timer_active = false;
	}

	if (!hide_buttons_timer_active) {
	    hide_buttons_timer = setInterval (hideButtonsTick, 5000);
	    hide_buttons_timer_active = true;
	}

	showButtons ();
    }

    private function loaderComplete (loader : Loader) : Boolean
    {
        if (loader.contentLoaderInfo
            && loader.contentLoaderInfo.bytesTotal > 0
            && loader.contentLoaderInfo.bytesTotal == loader.contentLoaderInfo.bytesLoaded)
        {
            return true;
        }

        return false;
    }

/* Unused
    private function doLoaderLoadComplete (loaded_element : LoadedElement) : void
    {
        repositionSplash ();
	repositionButtons ();
	loaded_element.allowVisible ();
    }

    private function loaderLoadCompleteHandler (loaded_element : LoadedElement) : Function
    {
	return function (event : Event) : void {
	    doLoaderLoadComplete (loaded_element);
	};
    }

    private function createLoadedElement (img_url  : String,
					  visible_ : Boolean) : LoadedElement
    {
	var loaded_element : LoadedElement;
	var loader : Loader;

	loader = new Loader ();

        loaded_element = new LoadedElement (visible_);
	loaded_element.obj = loader;

        loader.load (new URLRequest (img_url));
        loader.visible = false;

        addChild (loaded_element.obj);

        if (loader.contentLoaderInfo)
	    loader.contentLoaderInfo.addEventListener (Event.COMPLETE, loaderLoadCompleteHandler (loaded_element));
        if (loaderComplete (loader))
            doLoaderLoadComplete (loaded_element);

	return loaded_element;
    }
*/

    public function Lectorium ()
    {
	my_client_id = "";

	mode = loaderInfo.parameters ["mode"];

	uri = loaderInfo.parameters ["server_uri"];
	stream_name = "lecture";

	is_lector = (loaderInfo.parameters ["is_lector"] == "true");
	if (is_lector)
	    addStatusMessage ("Вы \u2014 лектор");
	else
	    addStatusMessage ("Вы \u2014 зритель");

	stage.scaleMode = StageScaleMode.NO_SCALE;
	stage.align = StageAlign.TOP_LEFT;

        stage_width = stage.stageWidth;
        stage_height = stage.stageHeight;

//	addStatusMessage ("--- A");

	first_reconnect_interval = 1000;
	default_buffer_time = 0.0; // Live stream
//	default_buffer_time = 0.1;

	main_reconnect_timer_active = false;
	lecture_reconnect_timer_active = false;
	participant_reconnect_timer_active = false;

//	addStatusMessage ("--- B");

	/*
	my_video_normal_width  = 160;
	my_video_normal_height = 120;
	my_video_fullscreen_width  = 240;
	my_video_fullscreen_height = 180;
	*/
	my_video_normal_width  = 240;
	my_video_normal_height = 180;
	my_video_fullscreen_width  = 320;
	my_video_fullscreen_height = 240;

	buttons_visible = true;
	hide_buttons_timer = setInterval (hideButtonsTick, 5000);
	hide_buttons_timer_active = true;

	lecture_started = false;
	participant_online = false;
	participating = false;

//	addStatusMessage ("--- C");

	mic_on = true;
	cam_on = true;
	if (is_lector)
	    sound_on = false;
	else
	    sound_on = true;

	participant_sound_on = true;

	horizontal_mode = false;

	var splash_bitmap : Bitmap = new SplashImage ();
	splash = new Sprite ();
	splash.addChild (splash_bitmap);
	splash.graphics.beginFill (0x100060);
	splash.graphics.drawRect (0, 0, 640, 480);
	splash.graphics.endFill ();
	splash.width = 640;
	splash.height = 480;
	splash.x = 0;
	splash.y = 0;
	splash_bitmap.x = (splash.width  - splash_bitmap.width ) / 2;
	splash_bitmap.y = (splash.height - splash_bitmap.height) / 2 - 30;
	if (mode == "watcher") {
	    splash.visible = false;
	}
	addChild (splash);

//	addStatusMessage ("--- D");

	lecture_video = new Video ();
	lecture_video.width  = 640;
	lecture_video.height = 480;
	lecture_video.smoothing = true;
	lecture_video.visible = false;
	addChild (lecture_video);

	my_video = new Video ();
	my_video.width  = my_video_normal_width;
	my_video.height = my_video_normal_height;
	my_video.y = stage_height - my_video.height - 10;
	my_video.x = 10;
	my_video.smoothing = true;
	addChild (my_video);

	participant_video = new Video ();
	participant_video.width  = my_video_normal_width;
	participant_video.height = my_video_normal_height;
	participant_video.x = stage_width  - participant_video.width  - 10;
	participant_video.y = stage_height - participant_video.height - 10;
	participant_video.smoothing = true;
	participant_video.visible = false;
	addChild (participant_video);

	/*
	participant_video_stub = new Sprite ();
	participant_video_stub.graphics.beginFill (0xaa00ff, 0.5);
        participant_video_stub.graphics.drawRect (0, 0, 200, 200);
	participant_video_stub.graphics.endFill ();
	participant_video_stub.width = 160;
	participant_video_stub.height = 120;
	participant_video_stub.x = 10;
	participant_video_stub.y = 10;
	participant_video_stub.visible = false;
	addChild (participant_video_stub);
	*/

	main_reconnect_interval = first_reconnect_interval;
	lecture_reconnect_interval = first_reconnect_interval;
	participant_reconnect_interval = first_reconnect_interval;

	lecture_buffering_complete = false;
	lecture_frame_no = 0;

	participant_closing = false;

	lecture_mic_on = true;
	lecture_cam_on = true;

	lecture_mic_off_mark = new LectureMicOff;
	lecture_mic_off_mark.visible = false;

	lecture_cam_off_mark = new LectureCamOff;
	lecture_cam_off_mark.visible = false;

	my_mic_off_mark = new MyMicOffMark;
	my_cam_off_mark = new MyCamOffMark;

	var roll_button_bitmap : Bitmap = new RollButton;
	roll_button = new Sprite();
	roll_button.addChild (roll_button_bitmap);
	addChild (roll_button);
	roll_button.addEventListener (MouseEvent.CLICK, rollMyVideo);

	var unroll_button_bitmap : Bitmap = new UnrollButton;
	unroll_button = new Sprite();
	unroll_button.addChild (unroll_button_bitmap);
	addChild (unroll_button);
	unroll_button.addEventListener (MouseEvent.CLICK, unrollMyVideo);

	var mic_button_on_bitmap : Bitmap = new MicButtonOn;
	mic_button_on = new Sprite();
	mic_button_on.addChild (mic_button_on_bitmap);
	addChild (mic_button_on);
	mic_button_on.addEventListener (MouseEvent.CLICK, turnMicOff);

	var mic_button_off_bitmap : Bitmap = new MicButtonOff;
	mic_button_off = new Sprite();
	mic_button_off.addChild (mic_button_off_bitmap);
	addChild (mic_button_off);
	mic_button_off.addEventListener (MouseEvent.CLICK, turnMicOn);

	var cam_button_on_bitmap : Bitmap = new CamButtonOn;
	cam_button_on = new Sprite();
	cam_button_on.addChild (cam_button_on_bitmap);
	addChild (cam_button_on);
	cam_button_on.addEventListener (MouseEvent.CLICK, turnCamOff);

	var cam_button_off_bitmap : Bitmap = new CamButtonOff;
	cam_button_off = new Sprite();
	cam_button_off.addChild (cam_button_off_bitmap);
	addChild (cam_button_off);
	cam_button_off.addEventListener (MouseEvent.CLICK, turnCamOn);

	var sound_button_on_bitmap : Bitmap = new SoundButtonOn;
	sound_button_on = new Sprite();
	sound_button_on.addChild (sound_button_on_bitmap);
	addChild (sound_button_on);
	sound_button_on.addEventListener (MouseEvent.CLICK, turnSoundOff);

	var sound_button_off_bitmap : Bitmap = new SoundButtonOff;
	sound_button_off = new Sprite();
	sound_button_off.addChild (sound_button_off_bitmap);
	addChild (sound_button_off);
	sound_button_off.addEventListener (MouseEvent.CLICK, turnSoundOn);

	var fullscreen_button_bitmap : Bitmap = new FullscreenButton;
	fullscreen_button = new Sprite();
	fullscreen_button.addChild (fullscreen_button_bitmap);
	addChild (fullscreen_button);
	fullscreen_button.addEventListener (MouseEvent.CLICK, toggleFullscreen);

	var horizontal_button_bitmap : Bitmap = new HorizontalButton;
	horizontal_button = new Sprite();
	horizontal_button.addChild (horizontal_button_bitmap);
	addChild (horizontal_button);
	horizontal_button.addEventListener (MouseEvent.CLICK, toggleHorizontal);

	ExternalInterface.addCallback ("sendChatMessage", sendChatMessage);
	ExternalInterface.addCallback ("connect", connect);
	ExternalInterface.addCallback ("requestParticipation", requestParticipation);
	ExternalInterface.addCallback ("endParticipation", endParticipation);
	ExternalInterface.addCallback ("giveWord", giveWord);
	ExternalInterface.addCallback ("dropParticipant", dropParticipant);
	ExternalInterface.addCallback ("beginLecture", beginLecture);
	ExternalInterface.addCallback ("endLecture", endLecture);
        ExternalInterface.addCallback ("showDesktop", showDesktop);
        ExternalInterface.addCallback ("showLecture", showLecture);

//	addStatusMessage ("--- E");

	// Local camera and mike are disabled temporarily
	if (0 /* && Camera.isSupported */) {
	    cam = Camera.getCamera();
	    if (cam) {
		my_video.attachCamera (cam);

//		cam.setMode (320, 240, 15);
		cam.setMode (640, 480, 15);
//		cam.setMode (800, 600, 15);

//		cam.setQuality (65536, 0);
		cam.setQuality (100000, 0);
//		cam.setQuality (10000000, 100);
	    }
	}

	// Local camera and mike are disabled temporarily
	if (0 /* && Microphone.isSupported */) {
	    mic = Microphone.getMicrophone();
	    if (mic)
		mic.setLoopBack (false);
	}

//	showSplash ();
	doLectureStop ();
	showButtons ();

//	addStatusMessage ("--- F");

	doResize ();
	stage.addEventListener ("resize",
	    function (event : Event) : void {
		doResize ();
	    }
	);

	stage.addEventListener ("mouseMove", onMouseMove);

	ExternalInterface.call ("flashInitialized");
	try {
	    ExternalInterface.call ("flashInitializedWithMode", mode);
	} catch (error : Error) {
	}
    }
}

}

/* Unused
internal class LoadedElement
{
    private var visible_allowed : Boolean;
    private var visible : Boolean;

    public var obj : flash.display.Loader;

    public function applyVisible () : void
    {
	obj.visible = visible;
    }

    public function allowVisible () : void
    {
	visible_allowed = true;
	applyVisible ();
    }

    public function setVisible (visible_ : Boolean) : void
    {
	visible = visible_;
	if (visible_allowed)
	    applyVisible ();
    }

    public function LoadedElement (visible_ : Boolean)
    {
	visible = visible_;
	visible_allowed = false;
    }
}
*/

internal class MainConnClient
{
    private var lectorium : Lectorium;

    public function lectorium_lecture_start () : void
    {
	lectorium.lectureStart ();
    }

    public function lectorium_lecture_stop () : void
    {
	lectorium.lectureStop ();
    }

    public function lectorium_session_info (client_id : String) : void
    {
	lectorium.setSessionInfo (client_id);
    }

    public function lectorium_chat (user_name : String, msg : String) : void
    {
	lectorium.addChatMessage (user_name + ': ' + msg);
    }

    public function lectorium_mic_on () : void
    {
	lectorium.lectureMicOn ();
    }

    public function lectorium_mic_off () : void
    {
	lectorium.lectureMicOff ();
    }

    public function lectorium_cam_on () : void
    {
	lectorium.lectureCamOn ();
    }

    public function lectorium_cam_off () : void
    {
	lectorium.lectureCamOff ();
    }

    public function lectorium_peer_connected () : void
    {
      // TODO
    }

    public function lectorium_peer_disconnected () : void
    {
      // TODO
    }

    public function lectorium_end_call () : void
    {
      // TODO
    }

    public function lectorium_wl_upd () : void
    {
	lectorium.updateWatcherList ();
    }

    public function lectorium_queue_upd () : void
    {
	lectorium.updateQueue ();
    }

    public function lectorium_new_participant (user_name : String, client_id : String) : void
    {
	lectorium.newParticipant (user_name, client_id);
    }

    public function lectorium_participant_gone (user_name : String) : void
    {
	lectorium.participantGone (user_name);
    }

    public function lectorium_participation_dropped () : void
    {
	lectorium.participationDropped ();
    }

    public function MainConnClient (lectorium : Lectorium)
    {
	this.lectorium = lectorium;
    }
}

/* Unused
internal class ParticipantConnClient
{
    private var lectorium : Lectorium;

    // TODO

    public function ParticipantConnClient (lectorium : Lectorium)
    {
	this.lectorium = lectorium;
    }
}
*/

