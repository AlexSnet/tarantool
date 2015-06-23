--# create server no_write with script='box/no_write.lua'
--# start server no_write
net_box = require('net.box')
os = require('os')

--# set connection no_write
space = box.schema.space.create('my_space')
index = space:create_index('primary', { type = 'hash' })
box.schema.user.grant('guest', 'read,write,execute', 'universe')

-- write full wal
for i=1, 10 do space:insert{i,2,3} end

os = require('os')
os.execute('chmod -w ' .. box.cfg.wal_dir)

--# set connection default
--# stop server no_write
--# start server no_write

--# set variable no_write_port to 'no_write.listen'
c = net_box:new(nil, no_write_port)
-- check read operation
c.space.my_space:select{}
-- write in new xlog
c.space.my_space:insert{123,3,4}

--# set connection no_write
os.execute('chmod +w ' .. box.cfg.wal_dir)

-- cleanup
--# set connection default
--# stop server no_write
--# cleanup server no_write
