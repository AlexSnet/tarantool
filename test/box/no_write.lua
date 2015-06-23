#!/usr/bin/env tarantool
box.cfg{
    listen              = os.getenv("LISTEN"),
    slab_alloc_arena    = 0.1,
    custom_proc_title   = "no_write",
    rows_per_wal        = 10,
}

require('console').listen(os.getenv('ADMIN'))
