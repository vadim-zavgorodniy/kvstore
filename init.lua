box.cfg{
    listen = 'localhost:3301';
    log = 'kvstore.log',
    too_long_threshold = 0.5;
}

local kvstore = require('kv.kv-http')
kvstore.start('0.0.0.0', '8080')
