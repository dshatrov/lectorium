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


#include <libmary/libmary.h>

#include <moment/module_init.h>
#include <moment/api.h>

#include <moment/libmoment.h>


#define LECTORIUM__MAX_REPORTED_WATCHERS 1000


// TODO These header macros are the same as in rtmpt_server.cpp
#define LECTORIUM__HEADERS_DATE \
	Byte date_buf [unixtimeToString_BufSize]; \
	Size const date_len = unixtimeToString (Memory::forObject (date_buf), getUnixtime());

#define LECTORIUM__COMMON_HEADERS \
	"Server: Moment/1.0\r\n" \
	"Date: ", ConstMemory (date_buf, date_len), "\r\n" \
	"Connection: Keep-Alive\r\n" \
	"Cache-Control: no-cache\r\n"

#define LECTORIUM__OK_HEADERS(mime_type, content_length) \
	"HTTP/1.1 200 OK\r\n" \
	LECTORIUM__COMMON_HEADERS \
	"Content-Type: ", (mime_type), "\r\n" \
	"Content-Length: ", (content_length), "\r\n"

#define LECTORIUM__404_HEADERS(content_length) \
	"HTTP/1.1 404 Not found\r\n" \
	LECTORIUM__COMMON_HEADERS \
	"Content-Type: text/plain\r\n" \
	"Content-Length: ", (content_length), "\r\n"

#define LECTORIUM__400_HEADERS(content_length) \
	"HTTP/1.1 400 Bad Request\r\n" \
	LECTORIUM__COMMON_HEADERS \
	"Content-Type: text/plain\r\n" \
	"Content-Length: ", (content_length), "\r\n"

#define LECTORIUM__500_HEADERS(content_length) \
	"HTTP/1.1 500 Internal Server Error\r\n" \
	LECTORIUM__COMMON_HEADERS \
	"Content-Type: text/plain\r\n" \
	"Content-Length: ", (content_length), "\r\n"


using namespace M;


namespace Lectorium {

class Lectorium
{
private:
    StateMutex mutex;

    class ClientSession;

    class ParticipantQueue_name;
    typedef IntrusiveList<ClientSession, ParticipantQueue_name> ParticipantQueue;

    class Lecture : public Object
    {
    public:
      mt_const Lectorium *lectorium_unsafe;

      mt_const Ref<Moment::VideoStream> mix_video_stream;

      mt_const MomentStream *virt_stream;

      mt_mutex (Lectorium::mutex)
      mt_begin
	bool valid;

        bool started;

        bool desktop_on;

        Ref<String> lecture_name;
	Ref<String> stream_name;

	// List of "Main" sessions.
	IntrusiveList<ClientSession> watcher_list;
	// List of "Lecture" sessions.
	IntrusiveList<ClientSession> participant_session_list;
	// List of "Participant" sessions.
	IntrusiveList<ClientSession> lecture_session_list;

	ParticipantQueue participant_queue;

	ClientSession *participant_watcher;

	typedef StringHash< Ref<Lecture> > LectureHash_;

	LectureHash_::EntryKey hash_key;

	// TODO Make use of this
	Timers::TimerKey wl_upd_timer;
	// TODO Make use of this
	Timers::TimerKey queue_upd_timer;

	Timers::TimerKey retry_get_stream_timer;

      mt_end // Lectorium::mutex
    };

    typedef Lecture::LectureHash_ LectureHash;

    class ClientSession : public IntrusiveListElement<>,
			  public IntrusiveListElement<ParticipantQueue_name>,
			  public Referenced
    {
    public:
	enum SessionType
	{
	    Type_Main,
	    Type_Lecture,
	    Type_Participant
	};

      mt_const Lectorium *lectorium_unsafe;
      mt_const SessionType session_type;

      mt_mutex (Lectorium::mutex)
      mt_begin

	bool valid;

	Lectorium *lectorium;

	MomentClientSession *srv_session;
	MomentStream *srv_in_stream;
	MomentStream *srv_out_stream;

	WeakRef<Lecture> weak_lecture;

	Ref<String> user_name;
	Ref<String> client_id;
	bool is_lector;
	bool is_hidden;

	bool mic_on;
	bool cam_on;

	bool in_participant_queue;

      mt_end // Lectorium::mutex
    };

    mt_const Moment::MomentServer *moment;
    mt_const PagePool *page_pool;
    mt_const Timers *timers;

    mt_mutex (mutex) LectureHash lecture_hash;

    mt_mutex (mutex) Uint64 anonymous_id_counter;

    mt_mutex (mutex) void sendSessionInfo_single (ClientSession * mt_nonnull session);

    mt_mutex (mutex) void sendWatcherListUpdated (Lecture * mt_nonnull lecture);

    mt_mutex (mutex) void sendQueueUpdated_single (Lecture       * mt_nonnull lecture,
						   ClientSession * mt_nonnull session);

    mt_mutex (mutex) void sendQueueUpdated (Lecture * mt_nonnull lecture);

    mt_mutex (mutex) void sendNewParticipant_single (Lecture       * mt_nonnull lecture,
						     ClientSession * mt_nonnull participant_session,
						     ClientSession * mt_nonnull session);

    mt_mutex (mutex) void sendNewParticipant (Lecture       * mt_nonnull lecture,
					      ClientSession * mt_nonnull session);

    mt_mutex (mutex) void sendParticipantGone (Lecture     * mt_nonnull lecture,
					       ConstMemory  user_name);

    mt_mutex (mutex) void sendParticipationDropped_single (ClientSession * mt_nonnull session);

    mt_mutex (mutex) void sendLectureStart_single (ClientSession * mt_nonnull session);

    mt_mutex (mutex) void sendLectureStart (Lecture * mt_nonnull lecture);

    mt_mutex (mutex) void sendLectureStop (Lecture * mt_nonnull lecture);

    mt_mutex (mutex) void sendChat (Lecture       * mt_nonnull lecture,
				    ClientSession * mt_nonnull sender_session,
				    ConstMemory    user_name,
				    ConstMemory    chat_msg);

    mt_mutex (mutex) void dropCurrentParticipant (Lecture *lecture);

    mt_mutex (mutex) void destroyClientSession (ClientSession *session);

    static void clientConnected (MomentClientSession  *srv_session,
				 char const           *app_name_buf,
				 size_t                app_name_len,
				 char const           *full_app_name_buf,
				 size_t                full_app_name_len,
				 void                **ret_client_data,
				 void                 *_self);

    static void clientDisconnected (void *_session,
				    void *_self);

    static int startWatching (char const    *stream_name_buf,
                              size_t         stream_name_len,
                              void          *_session,
                              void          *_self,
                              MomentStartWatchingResultCallback cb,
                              void          *cb_data,
                              MomentStream **ret_stream);

    static int startStreaming (char const          *stream_name_buf,
                               size_t               stream_name_len,
                               MomentStream        *stream,
                               MomentRecordingMode  rec_mode,
                               void                *_session,
                               void                *_self,
                               MomentStartStreamingResultCallback cb,
                               void                *cb_data,
                               MomentResult        *ret_res);

    static void rtmpCommandMessage (MomentMessage *msg,
				    void          *_session,
				    void          *_self);

    static void watcherAudioMessage (void *_audio_msg,
				     void *_session);

    static void watcherVideoMessage (void *_video_msg,
				     void *_session);

    mt_iface (HttpService::HttpHandler)
      static HttpService::HttpHandler http_handler;

      static Result httpRequest (HttpRequest   * mt_nonnull req,
				 Sender        * mt_nonnull conn_sender,
				 Memory const  & /* msg_body */,
				 void         ** mt_nonnull /* ret_msg_data */,
				 void          *_self);
    mt_iface_end

    static void lectureStreamClosed (void *_lecture);

    mt_mutex (mutex) void retryGetStream (Lecture *lecture);

    static void retryGetStreamTimerTick (void *_lecture);

    void doGetStream (Lecture *lecture);

    mt_mutex (mutex) Result switchStream (Lecture *lecture,
                                          bool     to_desktop,
                                          bool     force_switch);

    mt_mutex (mutex) void createLecture (ConstMemory lecture_name,
					 ConstMemory stream_name);

public:
    void init (char const *prefix_buf,
	       size_t      prefix_len);

    Lectorium ()
	: page_pool (NULL),
	  timers (NULL),
	  anonymous_id_counter (0)
    {
    }

  // TODO ~Lectorium() destructor
};

static Lectorium glob_lectorium;

static unsigned char glob_mic_off_buf [512];
static size_t glob_mic_off_len;

static unsigned char glob_cam_off_buf [512];
static size_t glob_cam_off_len;

static unsigned char glob_wl_upd_buf [512];
static size_t glob_wl_upd_len;

static unsigned char glob_queue_upd_buf [512];
static size_t glob_queue_upd_len;

static unsigned char glob_participation_dropped_buf [512];
static size_t glob_participation_dropped_len;

//static unsigned char glob_new_participant_buf [512];
//static size_t glob_new_participant_len;

static unsigned char glob_participant_gone_buf [512];
static size_t glob_participant_gone_len;

static unsigned char glob_lecture_start_buf [512];
static size_t glob_lecture_start_len;

static unsigned char glob_lecture_stop_buf [512];
static size_t glob_lecture_stop_len;

static char const intro_str [] = "lectorium_intro";

static char const chat_str             [] = "lectorium_chat";
static char const request_participation_str [] = "lectorium_request_participation";
static char const end_participation_str     [] = "lectorium_end_participation";
static char const give_word_str        [] = "lectorium_give_word";
static char const drop_participant_str [] = "lectorium_drop_participant";
static char const begin_lecture_str    [] = "lectorium_begin_lecture";
static char const end_lecture_str      [] = "lectorium_end_lecture";
static char const show_desktop_str     [] = "lectorium_show_desktop";
static char const show_lecture_str     [] = "lectorium_show_lecture";

static char const mic_on_str    [] = "lectorium_mic_on";
static char const mic_off_str   [] = "lectorium_mic_off";
static char const cam_on_str    [] = "lectorium_cam_on";
static char const cam_off_str   [] = "lectorium_cam_off";
static char const wl_upd_str    [] = "lectorium_wl_upd"; // Watcher list update
static char const queue_upd_str [] = "lectorium_queue_upd";
static char const session_info_str     [] = "lectorium_session_info";
static char const new_participant_str  [] = "lectorium_new_participant";
static char const participant_gone_str [] = "lectorium_participant_gone";
static char const participation_dropped_str [] = "lectorium_participation_dropped";
static char const lecture_start_str [] = "lectorium_lecture_start";
static char const lecture_stop_str  [] = "lectorium_lecture_stop";

mt_mutex (mutex) void
Lectorium::sendSessionInfo_single (ClientSession * const mt_nonnull session)
{
    unsigned char msg_buf [1024];
    size_t msg_len;

    MomentAmfEncoder * const encoder = moment_amf_encoder_new_AMF0 ();

    moment_amf_encoder_reset (encoder);
    moment_amf_encoder_add_string (encoder, session_info_str, sizeof (session_info_str) - 1);
    moment_amf_encoder_add_number (encoder, 0.0);
    moment_amf_encoder_add_null_object (encoder);

    if (session->client_id) {
	moment_amf_encoder_add_string (encoder,
				       (char const*) session->client_id->mem().mem(),
				       session->client_id->mem().len());
    } else {
	moment_amf_encoder_add_string (encoder, "", 0);
    }

    if (moment_amf_encoder_encode (encoder, msg_buf, sizeof (msg_buf), &msg_len)) {
	logE_ (_func, "moment_amf_encoder_encode() failed");
	moment_amf_encoder_delete (encoder);
	return;
    }

    moment_amf_encoder_delete (encoder);

    if (session->srv_session)
	moment_client_send_rtmp_command_message (session->srv_session, msg_buf, msg_len);
}

mt_mutex (mutex) void
Lectorium::sendWatcherListUpdated (Lecture * const mt_nonnull lecture)
{
    logD_ (_func_);

    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
	if (session->srv_session) {
	    moment_client_send_rtmp_command_message (session->srv_session,
						     glob_wl_upd_buf,
						     glob_wl_upd_len);
	}
    }
}

mt_mutex (mutex) void
Lectorium::sendQueueUpdated_single (Lecture       * mt_nonnull const /* lecture */,
				    ClientSession * mt_nonnull const session)
{
    if (session->srv_session) {
	moment_client_send_rtmp_command_message (session->srv_session,
						 glob_queue_upd_buf,
						 glob_queue_upd_len);
    }
}

mt_mutex (mutex) void
Lectorium::sendQueueUpdated (Lecture * const mt_nonnull lecture)
{
    logD_ (_func_);

    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
	sendQueueUpdated_single (lecture, session);
    }
}

mt_mutex (mutex) void
Lectorium::sendNewParticipant_single (Lecture       * const mt_nonnull /* lecture */,
				      ClientSession * const mt_nonnull participant_session,
				      ClientSession * const mt_nonnull session)
{
    unsigned char msg_buf [1024];
    size_t msg_len;

    MomentAmfEncoder * const encoder = moment_amf_encoder_new_AMF0 ();

    moment_amf_encoder_reset (encoder);
    moment_amf_encoder_add_string (encoder, new_participant_str, sizeof (new_participant_str) - 1);
    moment_amf_encoder_add_number (encoder, 0.0);
    moment_amf_encoder_add_null_object (encoder);

    if (participant_session->user_name) {
	moment_amf_encoder_add_string (encoder,
				       (char const*) participant_session->user_name->mem().mem(),
				       participant_session->user_name->mem().len());
    } else {
	moment_amf_encoder_add_string (encoder, "", 0);
    }

    if (participant_session->client_id) {
	moment_amf_encoder_add_string (encoder,
				       (char const*) participant_session->client_id->mem().mem(),
				       participant_session->client_id->mem().len());
    } else {
	moment_amf_encoder_add_string (encoder, "", 0);
    }

    if (moment_amf_encoder_encode (encoder, msg_buf, sizeof (msg_buf), &msg_len)) {
	logE_ (_func, "moment_amf_encoder_encode() failed");
	moment_amf_encoder_delete (encoder);
	return;
    }

    moment_amf_encoder_delete (encoder);

    if (session->srv_session)
	moment_client_send_rtmp_command_message (session->srv_session, msg_buf, msg_len);
}

mt_mutex (mutex) void
Lectorium::sendNewParticipant (Lecture       * const mt_nonnull lecture,
			       ClientSession * const mt_nonnull participant_session)
{
    logD_ (_func_);

    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
	sendNewParticipant_single (lecture, participant_session, session);
    }
}

mt_mutex (mutex) void
Lectorium::sendParticipantGone (Lecture     * const mt_nonnull lecture,
				ConstMemory   const user_name)
{
    logD_ (_func_);

    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
#if 0
	if (session->srv_session) {
	    moment_client_send_rtmp_command_message (session->srv_session,
		    				     glob_participant_gone_buf,
						     glob_participant_gone_len);
	}
#endif

	unsigned char msg_buf [1024];
	size_t msg_len;

	MomentAmfEncoder * const encoder = moment_amf_encoder_new_AMF0 ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, participant_gone_str, sizeof (participant_gone_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);

	moment_amf_encoder_add_string (encoder, (char const *) user_name.mem(), user_name.len());

	if (moment_amf_encoder_encode (encoder, msg_buf, sizeof (msg_buf), &msg_len)) {
	    logE_ (_func, "moment_amf_encoder_encode() failed");
	    moment_amf_encoder_delete (encoder);
	    continue;
	}

	moment_amf_encoder_delete (encoder);

	if (session->srv_session)
	    moment_client_send_rtmp_command_message (session->srv_session, msg_buf, msg_len);
    }
}

mt_mutex (mutex) void
Lectorium::sendParticipationDropped_single (ClientSession * mt_nonnull const session)
{
    if (session->srv_session) {
	moment_client_send_rtmp_command_message (session->srv_session,
						 glob_participation_dropped_buf,
						 glob_participation_dropped_len);
    }
}

mt_mutex (mutex) void
Lectorium::sendLectureStart_single (ClientSession * const mt_nonnull session)
{
    if (session->srv_session) {
	moment_client_send_rtmp_command_message (session->srv_session,
						 glob_lecture_start_buf,
						 glob_lecture_start_len);
    }
}

mt_mutex (mutex) void
Lectorium::sendLectureStart (Lecture * const mt_nonnull lecture)
{
    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
	sendLectureStart_single (session);
    }
}

mt_mutex (mutex) void
Lectorium::sendLectureStop (Lecture * const mt_nonnull lecture)
{
    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
	if (session->srv_session) {
	    moment_client_send_rtmp_command_message (session->srv_session,
						     glob_lecture_stop_buf,
						     glob_lecture_stop_len);
	}
    }
}

mt_mutex (mutex) void
Lectorium::sendChat (Lecture       * const mt_nonnull lecture,
		     ClientSession * const mt_nonnull sender_session,
		     ConstMemory     const user_name,
		     ConstMemory     const chat_msg)
{
    logD_ (_func_);

    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
    while (!lecture->watcher_list.iter_done (iter)) {
	ClientSession * const session = lecture->watcher_list.iter_next (iter);
	if (session == sender_session)
	    continue;

	unsigned char msg_buf [65526 * 2];
	size_t msg_len;

	MomentAmfEncoder * const encoder = moment_amf_encoder_new_AMF0 ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, chat_str, sizeof (chat_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);

	moment_amf_encoder_add_string (encoder, (char const *) user_name.mem(), user_name.len());
	moment_amf_encoder_add_string (encoder, (char const *) chat_msg.mem(), chat_msg.len());

	if (moment_amf_encoder_encode (encoder, msg_buf, sizeof (msg_buf), &msg_len)) {
	    logE_ (_func, "moment_amf_encoder_encode() failed");
	    moment_amf_encoder_delete (encoder);
	    continue;
	}

	moment_amf_encoder_delete (encoder);

	if (session->srv_session)
	    moment_client_send_rtmp_command_message (session->srv_session, msg_buf, msg_len);
    }
}

mt_mutex (mutex) void
Lectorium::dropCurrentParticipant (Lecture * const lecture)
{
    Ref<String> const user_name = lecture->participant_watcher->user_name;
    lecture->participant_watcher = NULL;
    sendParticipantGone (lecture, user_name ? user_name->mem() : ConstMemory());
}

mt_mutex (mutex) void
Lectorium::destroyClientSession (ClientSession * const session)
{
    logD_ (_func, "session 0x", fmt_hex, (UintPtr) session);

    if (!session->valid) {
	return;
    }
    session->valid = false;

//    Lectorium * const self = session->lectorium_unsafe;

    Ref<Lecture> const lecture = session->weak_lecture.getRef();
    if (lecture) {
	switch (session->session_type) {
	    case ClientSession::Type_Main: {
		lecture->watcher_list.remove (session);
		if (lecture->participant_watcher == session) {
		    Ref<String> const user_name = lecture->participant_watcher->user_name;
		    lecture->participant_watcher = NULL;
		    sendParticipantGone (lecture, user_name ? user_name->mem() : ConstMemory());
		}
	    } break;
	    case ClientSession::Type_Lecture: {
		lecture->lecture_session_list.remove (session);
	    } break;
	    case ClientSession::Type_Participant: {
		lecture->participant_session_list.remove (session);
	    } break;
	}

	if (session->in_participant_queue) {
	    lecture->participant_queue.remove (session);
	    session->in_participant_queue = false;
	    sendQueueUpdated (lecture);
	}
    }

    moment_client_session_unref (session->srv_session);

    if (session->srv_in_stream) {
	moment_stream_unref (session->srv_in_stream);
	session->srv_in_stream = NULL;
    }

    if (session->srv_out_stream) {
	moment_stream_unref (session->srv_out_stream);
	session->srv_out_stream = NULL;
    }

    if (lecture && session->user_name)
	sendWatcherListUpdated (lecture);
}

void
Lectorium::clientConnected (MomentClientSession  * const srv_session,
			    char const           * const app_name_buf,
			    size_t                 const app_name_len,
			    char const           * const full_app_name_buf,
			    size_t                 const full_app_name_len,
			    void                ** const ret_client_data,
			    void                 * const _self)
{
    logD_ (_func, "app ", ConstMemory (app_name_buf, app_name_len), ", "
	   "full_app ", ConstMemory (full_app_name_buf, full_app_name_len));

    Lectorium * const self = static_cast <Lectorium*> (_self);

    Ref<ClientSession> session = grab (new ClientSession);
    session->lectorium_unsafe = self;
    session->valid = true;

    session->is_lector = false;
    session->is_hidden = false;

    session->mic_on = true;
    session->cam_on = true;

    session->in_participant_queue = false;

    session->srv_session = srv_session;
    moment_client_session_ref (srv_session);

    session->srv_in_stream = moment_create_stream ();
    {
	MomentStreamHandler * const stream_handler = moment_stream_handler_new ();
	// TODO 'session' refcounting - ?
// This is for live mixing.
//	moment_stream_handler_set_audio_message (stream_handler, watcherAudioMessage, session);
//	moment_stream_handler_set_video_message (stream_handler, watcherVideoMessage, session);

	moment_stream_add_handler (session->srv_in_stream, stream_handler);

	moment_stream_handler_delete (stream_handler);
    }

    session->srv_out_stream = NULL;

    ConstMemory const main_prefix        = ".lectorium.main.";
    ConstMemory const lecture_prefix     = ".lectorium.lecture.";
    ConstMemory const participant_prefix = ".lectorium.participant.";

    ConstMemory app_name_mem (app_name_buf, app_name_len);
    if (app_name_len > 0 && app_name_buf [0] == '/')
	app_name_mem = app_name_mem.region (1);

    ConstMemory real_app_name (app_name_mem);

    if (app_name_mem.len() >= main_prefix.len() &&
	equal (app_name_mem.region (0, main_prefix.len()), main_prefix))
    {
	session->session_type = ClientSession::Type_Main;
	real_app_name = app_name_mem.region (main_prefix.len());
    } else
    if (app_name_mem.len() >= lecture_prefix.len() &&
	equal (app_name_mem.region (0, lecture_prefix.len()), lecture_prefix))
    {
	session->session_type = ClientSession::Type_Lecture;
	real_app_name = app_name_mem.region (lecture_prefix.len());
    } else
    if (app_name_mem.len() >= participant_prefix.len() &&
	equal (app_name_mem.region (0, participant_prefix.len()), participant_prefix))
    {
	session->session_type = ClientSession::Type_Participant;
	real_app_name = app_name_mem.region (participant_prefix.len());
    }

    self->mutex.lock ();

    LectureHash::EntryKey const lecture_key = self->lecture_hash.lookup (real_app_name);
    if (lecture_key) {
	logD_ (_func, "Connecting to lecture \"", app_name_mem, "\"");

	Ref<Lecture> const lecture = lecture_key.getData();
	session->weak_lecture = lecture;

	switch (session->session_type) {
	    case ClientSession::Type_Main: {
		lecture->watcher_list.append (session);
	    } break;
	    case ClientSession::Type_Lecture: {
		lecture->lecture_session_list.append (session);
	    } break;
	    case ClientSession::Type_Participant: {
		lecture->participant_session_list.append (session);
	    } break;
	}

#if 0
	session->srv_in_stream = peer_session->srv_out_stream;
	moment_stream_ref (session->srv_in_stream);
	session->srv_out_stream = peer_session->srv_in_stream;
	moment_stream_ref (session->srv_out_stream);
	logD_ (_func, "REFCOUNT: ", ((Moment::VideoStream*) session->srv_in_stream)->getRefCount());
#endif
    } else {
	logD_ (_func, "Lecture not found: \"", app_name_mem, "\"");
    }

    self->mutex.unlock ();

    *ret_client_data = static_cast <void*> (session);
    session->ref();
}

void
Lectorium::clientDisconnected (void * const _session,
			       void * const _self)
{
    logD_ (_func_);

    Lectorium * const self = static_cast <Lectorium*> (_self);
    ClientSession * const session = static_cast <ClientSession*> (_session);

    self->mutex.lock ();
    if (!session->valid) {
	self->mutex.unlock ();
	return;
    }

    self->destroyClientSession (session);
    self->mutex.unlock ();

    session->unref();
}

int
Lectorium::startWatching (char const    * const stream_name_buf,
                          size_t          const stream_name_len,
                          void          * const _session,
                          void          * const /* _self */,
                          MomentStartWatchingResultCallback const /* cb */,
                          void          * const /* cb_data */,
                          MomentStream ** const ret_stream)
{
    *ret_stream = NULL;

    logD_ (_func, ConstMemory (stream_name_buf, stream_name_len));

//    Lectorium * const self = static_cast <Lectorium*> (_self);
    ClientSession * const session = static_cast <ClientSession*> (_session);

    Ref<Lecture> const lecture = session->weak_lecture.getRef();

    if (!lecture) {
	logW_ (_func, "Not connected to any lecture");
        *ret_stream = NULL;
        return 1;
    }

    switch (session->session_type) {
	case ClientSession::Type_Main: {
	    logE_ (_func, "Attempted to watch a stream from \"Main\" session\n");
            *ret_stream = NULL;
            return 1;
	} break;
	case ClientSession::Type_Lecture: {
	  // Fallthrough
	} break;
	case ClientSession::Type_Participant: {
	    if (lecture->participant_watcher) {
		*ret_stream = lecture->participant_watcher->srv_in_stream;
                return 1;
            }

            *ret_stream = NULL;
            return 1;
	} break;
    }

    if (lecture->virt_stream) {
	*ret_stream = lecture->virt_stream;
        return 1;
    }

#if 0
// This is a possible path for serving video grabbed from a flash client
// (lector using webcam + flash encoder).

    return moment_get_stream (stream_name_buf,
			      stream_name_len,
			      NULL  /* ret_stream_key */,
			      false /* create */);
#endif

    *ret_stream = NULL;
    return 1;
}

int
Lectorium::startStreaming (char const          * const stream_name_buf,
                           size_t                const stream_name_len,
                           MomentStream        * const stream,
                           MomentRecordingMode   const /* rec_mode */,
                           void                * const _session,
                           void                * const /* _self */,
                           MomentStartStreamingResultCallback const /* cb */,
                           void                * const /* cb_data */,
                           MomentResult        * const ret_res)
{
    *ret_res = MomentResult_Failure;

    logD_ (_func, ConstMemory (stream_name_buf, stream_name_len));
    ClientSession * const session = static_cast <ClientSession*> (_session);

    moment_stream_bind_to_stream (session->srv_in_stream,
                                  stream /* bind_audio_stream */,
                                  stream /* bind_video_stream */,
                                  1      /* bind_audio */,
                                  1      /* bind_video */);

    *ret_res = MomentResult_Success;
    return 1;
}

void
Lectorium::rtmpCommandMessage (MomentMessage * const msg,
			       void          * const _session,
			       void          * const _self)
{
    MomentAmfDecoder * const decoder = moment_amf_decoder_new_AMF0 (msg);

  {
    Lectorium * const self = static_cast <Lectorium*> (_self);
    ClientSession * const session = static_cast <ClientSession*> (_session);

    logD_ (_func_);

    self->mutex.lock ();

    char method_name [512];
    size_t method_name_len;
    if (!moment_amf_decode_string (decoder,
				   method_name,
				   sizeof (method_name),
				   &method_name_len,
				   NULL /* ret_full_len */))
    {
	if (method_name_len == sizeof (mic_on_str) - 1
	    && !memcmp (method_name, mic_on_str, sizeof (mic_on_str) - 1))
	{
	    logD_ (_func, "mic on");
	    session->mic_on = true;
	    // TODO Don't broadcast this
	} else
	if (method_name_len == sizeof (mic_off_str) - 1
	    && !memcmp (method_name, mic_off_str, sizeof (mic_off_str) - 1))
	{
	    logD_ (_func, "mic off");
	    session->mic_on = false;
	    // TODO Don't broadcast this
	} else
	if (method_name_len == sizeof (cam_on_str) - 1
	    && !memcmp (method_name, cam_on_str, sizeof (cam_on_str) - 1))
	{
	    logD_ (_func, "cam on");
	    session->cam_on = true;
	    // TODO Don't broadcast this
	} else
	if (method_name_len == sizeof (cam_off_str) - 1
	    && !memcmp (method_name, cam_off_str, sizeof (cam_off_str) - 1))
	{
	    logD_ (_func, "cam off");
	    session->cam_on = false;
	    // TODO Don't broadcast this
	} else
	if (method_name_len == sizeof (chat_str) - 1
	    && !memcmp (method_name, chat_str, sizeof (chat_str) - 1))
	{
	    logD_ (_func, "chat");

	    if (moment_amf_decode_number (decoder, NULL))
		logW_ (_func, "Could not skip transaction id");

	    if (moment_amf_decoder_skip_object (decoder))
		logW_ (_func, "Could not skip command object");

	    char chat_msg_buf [65536];
	    size_t chat_msg_len;
	    if (moment_amf_decode_string (decoder,
					  chat_msg_buf,
					  sizeof (chat_msg_buf),
					  &chat_msg_len,
					  NULL /* ret_full_len */))
	    {
		logW_ (_func, "Could not decode chat msg");
		chat_msg_len = 0;
	    }

	    ConstMemory const chat_msg_mem ((Byte const *) chat_msg_buf, chat_msg_len);

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		self->sendChat (lecture,
				session,
				session->user_name ? session->user_name->mem() : ConstMemory(),
				chat_msg_mem);
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
	if (method_name_len == sizeof (request_participation_str) - 1
	    && !memcmp (method_name, request_participation_str, sizeof (request_participation_str) - 1))
	{
	    logD_ (_func, "request_participation");

	    if (session->in_participant_queue) {
		logD_ (_func, "already in the participant queue");
		self->mutex.unlock ();
		goto _return;
	    }

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		lecture->participant_queue.append (session);
		session->in_participant_queue = true;

		self->sendQueueUpdated (lecture);

		// TEST: Switching to the new participant immediately.
//		lecture->participant_watcher = session;
//		self->sendNewParticipant (lecture, session);
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
	if (method_name_len == sizeof (end_participation_str) - 1
	    && !memcmp (method_name, end_participation_str, sizeof (end_participation_str) - 1))
	{
	    logD_ (_func, "end_participation");

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		if (session->in_participant_queue) {
		    lecture->participant_queue.remove (session);
		    session->in_participant_queue = false;
		    self->sendQueueUpdated (lecture);
		}

		if (lecture->participant_watcher == session)
		    self->dropCurrentParticipant (lecture);
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
	if (method_name_len == sizeof (give_word_str) - 1
	    && !memcmp (method_name, give_word_str, sizeof (give_word_str) - 1))
	{
	    logD_ (_func, "give_word");

	    if (moment_amf_decode_number (decoder, NULL))
		logW_ (_func, "Could not skip transaction id");

	    if (moment_amf_decoder_skip_object (decoder))
		logW_ (_func, "Could not skip command object");

	    char client_id_buf [512];
	    size_t client_id_len;
	    if (moment_amf_decode_string (decoder,
					  client_id_buf,
					  sizeof (client_id_buf),
					  &client_id_len,
					  NULL /* ret_full_len */))
	    {
		logW_ (_func, "Could not decode client id");
		client_id_len = 0;
	    }

	    ConstMemory const client_id_mem ((Byte const *) client_id_buf, client_id_len);
	    logD_ (_func, "client id: ", client_id_mem);

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		ParticipantQueue::iter iter (lecture->participant_queue);
		while (!lecture->participant_queue.iter_done (iter)) {
		    ClientSession * const session = lecture->participant_queue.iter_next (iter);
		    if (session->client_id
			&& equal (session->client_id->mem(), client_id_mem))
		    {
			lecture->participant_watcher = session;

			lecture->participant_queue.remove (session);
			session->in_participant_queue = false;

			self->sendNewParticipant (lecture, session);
			self->sendQueueUpdated (lecture);
			break;
		    }
		}
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
	if (method_name_len == sizeof (drop_participant_str) - 1
	    && !memcmp (method_name, drop_participant_str, sizeof (drop_participant_str) - 1))
	{
	    logD_ (_func, "drop_participant");

	    if (!session->is_lector) {
		logW_ (_func, "drop_participant: not a lector\n");
		self->mutex.unlock ();
		goto _return;
	    }

	    if (moment_amf_decode_number (decoder, NULL))
		logW_ (_func, "Could not skip transaction id");

	    if (moment_amf_decoder_skip_object (decoder))
		logW_ (_func, "Could not skip command object");

	    char client_id_buf [512];
	    size_t client_id_len;
	    if (moment_amf_decode_string (decoder,
					  client_id_buf,
					  sizeof (client_id_buf),
					  &client_id_len,
					  NULL /* ret_full_len */))
	    {
		logW_ (_func, "Could not decode client id");
		client_id_len = 0;
	    }

	    ConstMemory const client_id_mem ((Byte const *) client_id_buf, client_id_len);
	    logD_ (_func, "client id: ", client_id_mem);

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		if (!lecture->participant_watcher) {
		    logD_ (_func, "no participant watcher");
		} else {
		    if (!lecture->participant_watcher->client_id) {
			logD_ (_func, "no participant client id");
		    } else {
			if (!equal (lecture->participant_watcher->client_id->mem(), client_id_mem))
			    logD_ (_func, "not current participant");
		    }
		}

		if (lecture->participant_watcher
		    && lecture->participant_watcher->client_id
		    && equal (lecture->participant_watcher->client_id->mem(), client_id_mem))
		{
		    self->sendParticipationDropped_single (lecture->participant_watcher);
		    self->dropCurrentParticipant (lecture);
		}
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
	if (method_name_len == sizeof (begin_lecture_str) - 1
	    && !memcmp (method_name, begin_lecture_str, sizeof (begin_lecture_str) - 1))
	{
	    logD_ (_func, begin_lecture_str);

	    if (!session->is_lector) {
		logW_ (_func, "begin_lecture: not a lector\n");
		self->mutex.unlock ();
		goto _return;
	    }

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		if (!lecture->started) {
		    lecture->started = true;
		    self->sendLectureStart (lecture);
		}
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
	if (method_name_len == sizeof (end_lecture_str) - 1
	    && !memcmp (method_name, end_lecture_str, sizeof (end_lecture_str) - 1))
	{
	    logD_ (_func, end_lecture_str);

	    if (!session->is_lector) {
		logW_ (_func, "end_lecture: not a lector\n");
		self->mutex.unlock ();
		goto _return;
	    }

	    Ref<Lecture> const lecture = session->weak_lecture.getRef();
	    if (lecture) {
		lecture->started = false;
		self->sendLectureStop (lecture);
	    }

	    self->mutex.unlock ();
	    goto _return;
	} else
        if (method_name_len == sizeof (show_desktop_str) - 1
            && !memcmp (method_name, show_desktop_str, sizeof (show_desktop_str) - 1))
        {
            logD_ (_func, show_desktop_str);

            if (!session->is_lector) {
                logW_ (_func, show_desktop_str, ": not a lector\n");
                self->mutex.unlock ();
                goto _return;
            }

            Ref<Lecture> const lecture = session->weak_lecture.getRef();
            if (lecture)
                self->switchStream (lecture, true /* to_desktop */, true /* force_switch */);

            self->mutex.unlock ();
            goto _return;
        } else
        if (method_name_len == sizeof (show_lecture_str) - 1
            && !memcmp (method_name, show_lecture_str, sizeof (show_lecture_str) - 1))
        {
            logD_ (_func, show_lecture_str);

            if (!session->is_lector) {
                logW_ (_func, show_lecture_str, ": not a lector\n");
                self->mutex.unlock ();
                goto _return;
            }

            Ref<Lecture> const lecture = session->weak_lecture.getRef();
            if (lecture)
                self->switchStream (lecture, false /* to_desktop */, true /* force_switch */);

            self->mutex.unlock ();
            goto _return;
        } else
	if (method_name_len == sizeof (intro_str) - 1
	    && !memcmp (method_name, intro_str, sizeof (intro_str) - 1))
	{
	    logD_ (_func, "intro");

	    if (session->user_name)
		logW_ (_func, "Duplicate ", intro_str, " call");

	    if (moment_amf_decode_number (decoder, NULL))
		logW_ (_func, "Could not skip transaction id");

	    if (moment_amf_decoder_skip_object (decoder))
		logW_ (_func, "Could not skip command object");

	    char user_name [512];
	    size_t user_name_len;
	    if (moment_amf_decode_string (decoder,
					  user_name,
					  sizeof (user_name),
					  &user_name_len,
					  NULL /* ret_full_len */))
	    {
		logW_ (_func, "Could not decode user name");
		user_name_len = 0;
	    }

	    ConstMemory const user_name_mem ((Byte const *) user_name, user_name_len);
	    logD_ (_func, "User name: ", user_name_mem);

	    int is_lector;
	    if (moment_amf_decode_boolean (decoder, &is_lector)) {
		logW_ (_func, "Could not decode is_lector\n");
		is_lector = false;
	    }
	    logD_ (_func, "is_lector: ", is_lector);

	    int is_hidden;
	    if (moment_amf_decode_boolean (decoder, &is_hidden)) {
		logW_ (_func, "Could not decode is_hidden\n");
		is_hidden = false;
	    }
	    logD_ (_func, "is_hidden: ", is_hidden);

	    session->user_name = grab (new String (ConstMemory (user_name, user_name_len)));
	    ++self->anonymous_id_counter;
	    session->client_id = makeString (session->user_name->mem(), "_", self->anonymous_id_counter);
	    session->is_lector = is_lector;
	    session->is_hidden = is_hidden;

	    self->sendSessionInfo_single (session);
	    {
		Ref<Lecture> const lecture = session->weak_lecture.getRef();
		if (lecture) {
		    self->sendWatcherListUpdated (lecture);
		    self->sendQueueUpdated_single (lecture, session);
		    if (lecture->started)
			self->sendLectureStart_single (session);
		    if (lecture->participant_watcher)
			self->sendNewParticipant_single (lecture, lecture->participant_watcher, session);
		}
	    }

	    self->mutex.unlock ();
	    goto _return;
	}
    }

    if (!session->valid) {
	self->mutex.unlock ();
	goto _return;
    }

    {
	Ref<Lecture> const lecture = session->weak_lecture.getRef();
	if (lecture) {
	    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
	    while (!lecture->watcher_list.iter_done (iter)) {
		ClientSession * const watcher_session = lecture->watcher_list.iter_next (iter);
		if (watcher_session == session)
		    continue;

		moment_client_send_rtmp_command_message_passthrough (watcher_session->srv_session, msg);
	    }
	}
    }

    self->mutex.unlock ();
  }

_return:
    moment_amf_decoder_delete (decoder);
}

void
Lectorium::watcherAudioMessage (void * const _audio_msg,
				void * const _session)
{
    Moment::VideoStream::AudioMessage * const audio_msg =
	    static_cast <Moment::VideoStream::AudioMessage*> (_audio_msg);
    ClientSession * const session = static_cast <ClientSession*> (_session);
    Lectorium * const self = session->lectorium_unsafe;

    logD_ (_func_);

    Ref<Lecture> const lecture = session->weak_lecture.getRef();
    if (!lecture)
	return;

    self->mutex.lock ();
    if (lecture->participant_watcher != session) {
	self->mutex.unlock ();
	return;
    }

    self->mutex.unlock ();

    lecture->mix_video_stream->fireAudioMessage (audio_msg);
}

void
Lectorium::watcherVideoMessage (void * const _video_msg,
				void * const _session)
{
    Moment::VideoStream::VideoMessage * const video_msg =
	    static_cast <Moment::VideoStream::VideoMessage*> (_video_msg);
    ClientSession * const session = static_cast <ClientSession*> (_session);
    Lectorium * const self = session->lectorium_unsafe;

    logD_ (_func_);

    Ref<Lecture> const lecture = session->weak_lecture.getRef();
    if (!lecture)
	return;

    self->mutex.lock ();
    if (lecture->participant_watcher != session) {
	self->mutex.unlock ();
	return;
    }

    self->mutex.unlock ();

    lecture->mix_video_stream->fireVideoMessage (video_msg);
}

HttpService::HttpHandler Lectorium::http_handler = {
    httpRequest,
    NULL /* httpMessageBody */
};

Result
Lectorium::httpRequest (HttpRequest   * const mt_nonnull req,
			Sender        * const mt_nonnull conn_sender,
			Memory const  & /* msg_body */,
			void         ** const mt_nonnull /* ret_msg_data */,
			void          * const _self)
{
    Lectorium * const self = static_cast <Lectorium*> (_self);

    logD_ (_func, req->getFullPath());

    LECTORIUM__HEADERS_DATE

    if (req->getNumPathElems() >= 2
	&& equal (req->getPath (1), "watcher_list"))
    {
	logD_ (_func, "watcher_list");

	PagePool::PageListHead page_list;
	PagePool::PageListOutputStream pl_out (self->page_pool, &page_list);

	ConstMemory const lecture_name = req->getParameter ("lecture");
	if (!lecture_name.mem()) {
	    logE_ (_func, "No \"lecture\" request parameter");
	    goto _bad_request;
	}
	logD_ (_func, "lecture name: ", lecture_name);

	LectureHash::EntryKey const lecture_key = self->lecture_hash.lookup (lecture_name);
	if (lecture_key) {
	    Ref<Lecture> const lecture = lecture_key.getData();

	    pl_out.print ("[\n");

	    IntrusiveList<ClientSession>::iter iter (lecture->watcher_list);
	    Count watchers_reported = 0;
	    while (!lecture->watcher_list.iter_done (iter)) {
		ClientSession * const session = lecture->watcher_list.iter_next (iter);
		if (session->is_lector || session->is_hidden)
		    continue;

		ConstMemory user_name;
		if (session->user_name)
		    user_name = session->user_name->mem();
		else
		    user_name = "(Anonymous)";

		pl_out.print ("[\"", user_name, "\"],\n");
		++watchers_reported;
		if (watchers_reported >= LECTORIUM__MAX_REPORTED_WATCHERS) {
		    logD_ (_func, "max reported watchers limit hit");
		    break;
		}
	    }

	    pl_out.print ("]\n");
	} else {
	    logD_ (_func, "Lecture not found: \"", lecture_name, "\"");
	}

        // Counting content length.
	Size content_length = 0;
	{
	    PagePool::Page *cur_page = page_list.first;
	    while (cur_page) {
		content_length += cur_page->data_len;
		cur_page = cur_page->getNextMsgPage();
	    }
	}

	conn_sender->send (self->page_pool,
			   false /* do_flush */,
			   LECTORIUM__OK_HEADERS ("text/plain; charset=UTF-8", content_length),
			   "\r\n");
	conn_sender->sendPages (self->page_pool, page_list.first, true /* do_flush */);
	if (!req->getKeepalive())
	    conn_sender->closeAfterFlush();

	logA_ ("lectorium 200 ", req->getClientAddress(), " ", req->getRequestLine());
    } else
    if (req->getNumPathElems() >= 2
	&& equal (req->getPath (1), "queue"))
    {
	logD_ (_func, "queue");

	PagePool::PageListHead page_list;
	PagePool::PageListOutputStream pl_out (self->page_pool, &page_list);

	ConstMemory const lecture_name = req->getParameter ("lecture");
	if (!lecture_name.mem()) {
	    logE_ (_func, "No \"lecture\" request parameter");
	    goto _bad_request;
	}
	logD_ (_func, "lecture name: ", lecture_name);

	LectureHash::EntryKey const lecture_key = self->lecture_hash.lookup (lecture_name);
	if (lecture_key) {
	    Ref<Lecture> const lecture = lecture_key.getData();

	    pl_out.print ("[\n");

	    ParticipantQueue::iter iter (lecture->participant_queue);
	    Count participants_reported = 0;
	    while (!lecture->participant_queue.iter_done (iter)) {
		ClientSession * const session = lecture->participant_queue.iter_next (iter);
		ConstMemory user_name;
		if (session->user_name)
		    user_name = session->user_name->mem();
		else
		    user_name = "(Anonymous)";

		pl_out.print ("[\"", user_name, "\", \"", session->client_id, "\"],\n");
		++participants_reported;
		if (participants_reported >= LECTORIUM__MAX_REPORTED_WATCHERS) {
		    logD_ (_func, "max reported participants limit hit");
		    break;
		}
	    }

	    pl_out.print ("]\n");
	} else {
	    logD_ (_func, "Lecture not found: \"", lecture_name, "\"");
	}

        // Counting content length.
	Size content_length = 0;
	{
	    PagePool::Page *cur_page = page_list.first;
	    while (cur_page) {
		content_length += cur_page->data_len;
		cur_page = cur_page->getNextMsgPage();
	    }
	}

	conn_sender->send (self->page_pool,
			   false /* do_flush */,
			   LECTORIUM__OK_HEADERS ("text/plain; charset=UTF-8", content_length),
			   "\r\n");
	conn_sender->sendPages (self->page_pool, page_list.first, true /* do_flush */);
	if (!req->getKeepalive())
	    conn_sender->closeAfterFlush();

	logA_ ("lectorium 200 ", req->getClientAddress(), " ", req->getRequestLine());
    } else {
	logE_ (_func, "Unknown HTTP request: ", req->getFullPath());

	ConstMemory const reply_body = "Unknown command";
	conn_sender->send (self->page_pool,
			   true /* do_flush */,
			   LECTORIUM__404_HEADERS (reply_body.len()),
			   "\r\n",
			   reply_body);
	if (!req->getKeepalive())
	    conn_sender->closeAfterFlush();

	logA_ ("lectorium 404 ", req->getClientAddress(), " ", req->getRequestLine());
    }

    return Result::Success;

_bad_request:
    {
	LECTORIUM__HEADERS_DATE
	ConstMemory const reply_body = "400 Bad Request";
	conn_sender->send (
		self->page_pool,
		true /* do_flush */,
		LECTORIUM__400_HEADERS (reply_body.len()),
		"\r\n",
		reply_body);
	if (!req->getKeepalive())
	    conn_sender->closeAfterFlush();

	logA_ ("lectorium 400 ", req->getClientAddress(), " ", req->getRequestLine());
    }

    return Result::Success;
}

void
Lectorium::lectureStreamClosed (void * const _lecture)
{
    logD_ (_func_);

//#error Act only when the currently active stream has been closed.

    Lecture * const lecture = static_cast <Lecture*> (_lecture);
    Lectorium * const self = lecture->lectorium_unsafe;

    self->mutex.lock ();
    self->retryGetStream (lecture);
    self->mutex.unlock ();
}

mt_mutex (mutex) void
Lectorium::retryGetStream (Lecture * const lecture)
{
    logD_ (_func_);

    if (lecture->retry_get_stream_timer)
	return;

    lecture->retry_get_stream_timer = timers->addTimer (
	    CbDesc<Timers::TimerCallback> (retryGetStreamTimerTick,
					   lecture,
					   lecture),
	    1 /* TODO Config parameter for the timeout */,
	    false /* periodical */);
}

void
Lectorium::retryGetStreamTimerTick (void * const _lecture)
{
    logD_ (_func, "lecture 0x", fmt_hex, (UintPtr) _lecture);

    Lecture * const lecture = static_cast <Lecture*> (_lecture);
    Lectorium * const self = lecture->lectorium_unsafe;

    self->mutex.lock ();
    assert (lecture->retry_get_stream_timer);
    self->timers->deleteTimer (lecture->retry_get_stream_timer);
    lecture->retry_get_stream_timer = NULL;

    self->doGetStream (lecture);

    self->mutex.unlock ();
}

mt_mutex (mutex) void
Lectorium::doGetStream (Lecture * const lecture)
{
    logD_ (_func, "lecture 0x", fmt_hex, (UintPtr) lecture, ", desktop_on: ", lecture->desktop_on);
//    moment_log_dump_stream_list ();

    switchStream (lecture, lecture->desktop_on, true /* force_switch */);

//    if (!switchStream (lecture, lecture->desktop_on, true /* force_switch */))
//	retryGetStream (lecture);
}

mt_mutex (mutex) Result
Lectorium::switchStream (Lecture * const lecture,
                         bool      const to_desktop,
                         bool      const force_switch)
{
    logD_ (_func, "lecture 0x", fmt_hex, (UintPtr) lecture, ", "
           "prv desktop_on: ", lecture->desktop_on, ", force_switch: ", force_switch);
//    moment_log_dump_stream_list ();

    if (lecture->desktop_on == to_desktop
        && !force_switch)
    {
      // No switching required.
        logD_ (_func, "No switching required");
        return Result::Success;
    }
    lecture->desktop_on = to_desktop;
    logD_ (_func, "New desktop_on: ", lecture->desktop_on);

    Ref<String> stream_name;
    if (to_desktop)
        stream_name = makeString (lecture->stream_name->mem(), ".desktop");
    else
        stream_name = makeString (lecture->stream_name->mem(), ".camera");

    MomentStream * const stream = moment_get_stream ((const char *) stream_name->mem().mem(),
                                                     stream_name->mem().len(),
                                                     NULL  /* ret_stream_key */,
                                                     false /* create */);
    if (stream) {
        {
            MomentStreamHandler * const stream_handler = moment_stream_handler_new ();
            moment_stream_handler_set_closed (stream_handler, lectureStreamClosed, lecture);
            // TODO isClosed_subscribe() is needed - race condition.

            moment_stream_add_handler (stream, stream_handler);

            moment_stream_handler_delete (stream_handler);
        }

        // TODO Switch audio only when connecting/reconnecting to lector's stream.
        moment_stream_bind_to_stream (lecture->virt_stream,
                                      !to_desktop ? stream : NULL /* bind_audio_stream */,
                                      stream                      /* bind_video_stream */,
                                      !to_desktop ? 1 : 0         /* bind_audio */,
                                      1                           /* bind_video */);
        moment_stream_unref (stream);
    } else {
        logE_ (_func, "Stream \"", stream_name, "\" not found");
        // TODO Return error to js.
	retryGetStream (lecture);
        return Result::Failure;
    }

    return Result::Success;
}

mt_mutex (mutex) void
Lectorium::createLecture (ConstMemory const lecture_name,
			  ConstMemory const stream_name)
{
    logD_ (_func, "lecture_name: \"", lecture_name, "\", stream_name: \"", stream_name, "\"");

    Ref<Lecture> const lecture = grab (new Lecture);
    lecture->lectorium_unsafe = this;
    lecture->valid = true;
    lecture->started = false;
    lecture->desktop_on = false;
    lecture->lecture_name = grab (new String (lecture_name));
    lecture->stream_name = grab (new String (stream_name));
    lecture->participant_watcher = NULL;
    lecture->wl_upd_timer = NULL;
    lecture->queue_upd_timer = NULL;
    lecture->retry_get_stream_timer = NULL;

    lecture->mix_video_stream = moment->getMixVideoStream ();

    {
        // TODO 'lecture->virt_stream' is never deleted.
        Ref<String> const virt_name = makeString (".virt.", lecture->stream_name->mem());
        lecture->virt_stream = moment_get_stream ((const char *) virt_name->mem().mem(),
                                                  virt_name->mem().len(),
                                                  NULL /* ret_stream_key */,
                                                  true /* create */);
        assert (lecture->virt_stream);
    }

    doGetStream (lecture);

    lecture->hash_key = lecture_hash.add (lecture->lecture_name->mem(), lecture);
}

static Moment::MomentServer::PageRequestResult
watcherPageRequest (Moment::MomentServer::PageRequest * const req,
		    ConstMemory   const /* path */,
		    ConstMemory   const /* full_path */,
		    void        * const /* cb_data */)
{
    logD_ (_func_);
    req->addHashVar ("Lectorium_IsLector", "false");
    req->addHashVar ("Lectorium_PageClass", "client");
    req->showSection ("ASK_WORD_BUTTON");
    return Moment::MomentServer::PageRequestResult::Success;
}

static Moment::MomentServer::PageRequestHandler watcher_page_request_handler = {
    watcherPageRequest
};

static Moment::MomentServer::PageRequestResult
lectorPageRequest (Moment::MomentServer::PageRequest * const req,
		   ConstMemory   const /* path */,
		   ConstMemory   const /* full_path */,
		   void        * const /* cb_data */)
{
    logD_ (_func_);
    req->addHashVar ("Lectorium_IsLector", "true");
    req->addHashVar ("Lectorium_PageClass", "lector");
    req->showSection ("BEGIN_LECTURE_BUTTON");
    return Moment::MomentServer::PageRequestResult::Success;
}

static Moment::MomentServer::PageRequestHandler lector_page_request_handler = {
    lectorPageRequest
};

void
Lectorium::init (char const * const prefix_buf,
		 size_t       const prefix_len)
{
    logD_ (_func_);

    moment = Moment::MomentServer::getInstance();
    MConfig::Config * const config = moment->getConfig();
    HttpService * const http_service = moment->getHttpService();
    page_pool = moment->getPagePool();
    timers = moment->getServerApp()->getServerContext()->getMainThreadContext()->getTimers();

    {
	ConstMemory const opt_name = "lectorium/enable";
	MConfig::BooleanValue const enable = config->getBoolean (opt_name);
	if (enable == MConfig::Boolean_Invalid) {
	    logE_ (_func, "Invalid value for ", opt_name, ": ", config->getString (opt_name));
	    return;
	}

	if (enable != MConfig::Boolean_True) {
	    logI_ (_func, "Lectorium module is not enabled. "
		   "Set \"", opt_name, "\" option to \"y\" to enable.");
	    return;
	}
    }

    moment->addPageRequestHandler (
	    CbDesc<Moment::MomentServer::PageRequestHandler> (
		    &watcher_page_request_handler, NULL, NULL),
	    "lectorium/client.html");
    moment->addPageRequestHandler (
	    CbDesc<Moment::MomentServer::PageRequestHandler> (
		    &lector_page_request_handler, NULL, NULL),
	    "lectorium/lector.html");

    mutex.lock ();
//    createLecture ("", "lecture");
    createLecture ("lecture", "lecture");
    mutex.unlock ();

    {
	MomentAmfEncoder * const encoder = moment_amf_encoder_new_AMF0 ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, mic_off_str, sizeof (mic_off_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_mic_off_buf, sizeof (glob_mic_off_buf), &glob_mic_off_len))
	    abort ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, cam_off_str, sizeof (cam_off_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_cam_off_buf, sizeof (glob_cam_off_buf), &glob_cam_off_len))
	    abort ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, wl_upd_str, sizeof (wl_upd_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_wl_upd_buf, sizeof (glob_wl_upd_buf), &glob_wl_upd_len))
	    abort ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, queue_upd_str, sizeof (queue_upd_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_queue_upd_buf, sizeof (glob_queue_upd_buf), &glob_queue_upd_len))
	    abort ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, participation_dropped_str, sizeof (participation_dropped_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_participation_dropped_buf, sizeof (glob_participation_dropped_buf), &glob_participation_dropped_len))
	    abort ();

#if 0
	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, new_participant_str, sizeof (new_participant_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_new_participant_buf, sizeof (glob_new_participant_buf), &glob_new_participant_len))
	    abort ();
#endif

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, participant_gone_str, sizeof (participant_gone_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_participant_gone_buf, sizeof (glob_participant_gone_buf), &glob_participant_gone_len))
	    abort ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, lecture_start_str, sizeof (lecture_start_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_lecture_start_buf, sizeof (glob_lecture_start_buf), &glob_lecture_start_len))
	    abort ();

	moment_amf_encoder_reset (encoder);
	moment_amf_encoder_add_string (encoder, lecture_stop_str, sizeof (lecture_stop_str) - 1);
	moment_amf_encoder_add_number (encoder, 0.0);
	moment_amf_encoder_add_null_object (encoder);
	if (moment_amf_encoder_encode (encoder, glob_lecture_stop_buf, sizeof (glob_lecture_stop_buf), &glob_lecture_stop_len))
	    abort ();

	moment_amf_encoder_delete (encoder);
    }

    MomentClientHandler *ch = moment_client_handler_new ();
    moment_client_handler_set_connected (ch, clientConnected, this);
    moment_client_handler_set_disconnected (ch, clientDisconnected, this);
    moment_client_handler_set_start_watching (ch, startWatching, this);
    moment_client_handler_set_start_streaming (ch, startStreaming, this);
    moment_client_handler_set_rtmp_command_message (ch, rtmpCommandMessage, this);

    moment_add_client_handler (ch, prefix_buf, prefix_len);

    moment_client_handler_delete (ch);

    http_service->addHttpHandler (
	    CbDesc<HttpService::HttpHandler> (
		    &http_handler, this, NULL /* coderef_container */),
	    "lectorium_api");
}

} // namespace Lectorium

extern "C" {

void moment_module_init ()
{
    logI_ (_func, "Initializing mod_lectorium");
    char const prefix [] = "lectorium";
    Lectorium::glob_lectorium.init (prefix, sizeof (prefix) - 1);
}

void moment_module_unload ()
{
    logI_ (_func, "Unloading mod_lectorium");
}

}

