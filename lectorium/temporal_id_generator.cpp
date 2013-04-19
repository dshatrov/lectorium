#include <lectorium/temporal_id_generator.h>


using namespace M;


namespace Lectorium {

void
TemporalIdGenerator::expirationTimerTick (void * const _self)
{
    TemporalIdGenerator * const self = static_cast <TemporalIdGenerator*> (_self);
    Time const cur_time = getTime();
    self->mutex.lock ();

    IdEntryList::rev_iter iter (self->id_list);
    while (!self->id_list.rev_iter_done (iter)) {
	IdEntry * const id_entry = self->id_list.rev_iter_next (iter);
	if (id_entry->last_used_time < cur_time
	    && cur_time - id_entry->last_used_time >= self->id_timeout_seconds)
	{
	    id_entry->expired = true;
	    self->id_list.remove (id_entry);
	    self->id_hash.remove (id_entry);
	} else {
	    break;
	}
    }

    self->mutex.unlock ();
}

TemporalIdGenerator::IdKey
TemporalIdGenerator::generateId (Referenced* const ref_data)
{
    Time const cur_time = getTime();

    // TODO Handle overflows and overlapping ids.
    static uint64_t id_counter = 0;

    Ref<IdEntry> const id_entry = new IdEntry;
    id_entry->ref_data = ref_data;
    id_entry->expired = false;
    id_entry->last_used_time = cur_time;

    ++id_counter;
    id_entry->id_str = makeString (id_prefix, "_", id_counter);

    mutex.lock ();
    id_list.append (id_entry);
    id_hash.add (id_entry);
    mutex.unlock ();

    return IdKey (id_entry);
}

void
TemporalIdGenerator::renewId (IdKey id_key)
{
    Time const cur_time = getTime();

    mutex.lock ();
    if (id_key.id_entry->expired) {
	mutex.unlock ();
	return;
    }

    id_key.id_entry->last_used_time = cur_time;
    id_list.remove (id_key.id_entry);
    id_list.append (id_key.id_entry);

    mutex.unlock ();
}

void
TemporalIdGenerator::dropId (IdKey id_key)
{
    mutex.lock ();
    id_list.remove (id_key.id_entry);
    id_hash.remove (id_key.id_entry);
    mutex.unlock ();
}

TemporalIdGenerator::TemporalIdGenerator (ConstMemory   const id_prefix,
					  Timers      * const timers,
					  Time          const id_timeout_seconds)
    : id_prefix (id_prefix),
      timers (timers),
      id_timeout_seconds (id_timeout_seconds)
{
    expiration_timer_key = timers->addTimer (CbDesc<Timers::TimerCallback> (expirationTimerTick,
									    this,
									    this),
					     id_timeout_seconds,
					     true /* periodical */);
}

TemporalIdGenerator::~TemporalIdGenerator ()
{
}

}

