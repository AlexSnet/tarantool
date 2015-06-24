from lib.tarantool_server import TarantoolServer
from time import sleep

def check_replication(nodes):
    for node in nodes:
        node.admin('box.info().replication.status')
        node.admin('box.info().replication.message')
        node.admin('box.space.test:select{}')

master = server
master.admin("box.schema.user.grant('guest', 'replication')")

replica = TarantoolServer(server.ini)
replica.script = 'replication/replica.lua'
replica.vardir = server.vardir
replica.rpl_master = master
replica.deploy()

def parallel_run(cmd1, cmd2):
    print 'parallel send: %s' % cmd1
    print 'parallel send: %s' % cmd2
    master.admin.socket.sendall('%s\n' % cmd1),
    replica.admin.socket.sendall('%s\n' % cmd2)

    master.admin.socket.recv(2048)
    replica.admin.socket.recv(2048)

    # wait for status changing in tarantool
    sleep(0.1)

def prepare_cluster():
    print 'reset master-master replication'
    master.stop()
    master.cleanup(True)
    master.start()
    master.admin("box.schema.user.grant('guest', 'replication')")

    replica.stop()
    replica.cleanup(True)
    replica.start()

    master.admin("box.cfg{replication_source='%s'}" % replica.iproto.uri, silent=True)
    r1_id = replica.get_param('server')['id']
    r2_id = master.get_param('server')['id']

    # wait lsn
    replica.wait_lsn(r2_id, master.get_lsn(r2_id))
    master.wait_lsn(r1_id, replica.get_lsn(r1_id))

    master.admin("space = box.schema.space.create('test')")
    master.admin("index = space:create_index('primary', { type = 'tree'})")
    master.admin('for k = 1, 9 do space:insert{k, k*k} end')
    check_replication([master, replica])

# test1: double update in master and replica
prepare_cluster()
parallel_run(
    "box.space.test:update(1, {{'#', 2, 1}})",
    "box.space.test:update(1, {{'#', 2, 1}})"
)
check_replication([master, replica])

# test2: insert different values with single id
prepare_cluster()
parallel_run(
    'box.space.test:insert{20, 1}',
    'box.space.test:insert{20, 2}'
)
check_replication([master, replica])

# test3: auto increment different values
prepare_cluster()
parallel_run(
    'box.space.test:auto_increment{1}',
    'box.space.test:auto_increment{2}'
)
check_replication([master, replica])

# test4: CRDT increment with update
prepare_cluster()
parallel_run(
    "box.space.test:update(1, {{'+', 2, 1}})",
    "box.space.test:update(1, {{'+', 2, 2}})",
)
check_replication([master, replica])

# test5: delte not existing key
prepare_cluster()
parallel_run(
    "box.space.test:delete(999)",
    "box.space.test:delete(999)",
)
check_replication([master, replica])

# cleanup
replica.stop()
replica.cleanup(True)
server.stop()
server.cleanup(True)
server.deploy()
