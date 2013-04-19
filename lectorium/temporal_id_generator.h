#ifndef __LECTORIUM__TEMPORAL_ID_GENERATOR__H__
#define __LECTORIUM__TEMPORAL_ID_GENERATOR__H__


#include <libmary/libmary.h>


namespace Lectorium {

using namespace M;

class TemporalIdGenerator : public Object
{
private:
    StateMutex mutex;

    class IdEntry : public Referenced,
		    public IntrusiveListElement<>,
		    public HashEntry<>
    {
    public:
	mt_const Ref<String> id_str;
	mt_const Ref<Referenced> ref_data;

	mt_mutex (TemporalIdGenerator::mutex) bool expired;
	mt_mutex (TemporalIdGenerator::mutex) Time last_used_time;
    };

    typedef Hash< IdEntry,
		  Memory,
		  MemberExtractor< IdEntry,
				   Ref<String>,
				   &IdEntry::id_str,
				   Memory,
				   AccessorExtractor< String,
						      Memory,
						      &String::mem > >,
		  MemoryComparator<> >
	    IdEntryHash;

    typedef IntrusiveList<IdEntry> IdEntryList;

    mt_const ConstMemory id_prefix;

    mt_const Timers * const timers;
    mt_const Timers::TimerKey expiration_timer_key;

    mt_const unsigned long id_timeout_seconds;

    mt_mutex (mutex) IdEntryHash id_hash;
    mt_mutex (mutex) IdEntryList id_list;

    static void expirationTimerTick (void *_self);

public:
    class IdKey
    {
	friend class TemporalIdGenerator;

    private:
	Ref<IdEntry> id_entry;

    public:
	ConstMemory getKey ()
	{
	    return id_entry->id_str->mem();
	}

	Ref<Referenced> getRefData ()
	{
	    return id_entry->ref_data;
	}

	IdKey (IdEntry * const mt_nonnull id_entry)
	    : id_entry (id_entry)
	{
	}

	IdKey ()
	{
	}
    };

    IdKey generateId (Referenced *ref_data);

    void renewId (IdKey id_key);

    void dropId (IdKey id_key);

    TemporalIdGenerator (ConstMemory  id_prefix,
			 Timers      *timers,
			 Time         id_timeout_seconds = 10 * 60 /* 10 minutes */);

    ~TemporalIdGenerator ();
};

}


#endif /* __LECTORIUM__TEMPORAL_ID_GENERATOR__H__ */

