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


#ifndef LECTORIUM__TEMPORAL_ID_GENERATOR__H__
#define LECTORIUM__TEMPORAL_ID_GENERATOR__H__


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


#endif /* LECTORIUM__TEMPORAL_ID_GENERATOR__H__ */

