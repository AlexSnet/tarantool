--
-- gh-853 - memory leak on start if replace in xlog
--
--# create server tiny with script='box/tiny.lua'
--# start server tiny
--# set connection tiny
_ = box.schema.space.create('test')
_ = box.space.test:create_index('pk')
--# setopt delimiter ';'
for i=1, 500 do
    box.space.test:replace{1, string.rep('a', 10000)}
-- or we run out of memory too soon
    collectgarbage('collect')
end;
--# setopt delimiter ''
--# stop server tiny
--# start server tiny
box.space.test:len()
box.space.test:drop()
--# cleanup server tiny
--# set connection default

