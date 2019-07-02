local logger = require('log')

-- инициализирует спейс хранилища
local function bootstrap()
    local kv = box.space.kv;
    if kv then
        return
    end

    kv = box.schema.space.create('kv');

    kv:format({
            {name = 'key', type = 'string'},
            {name = 'value', type = 'string'},
    });

    box.space.kv:create_index('pk', {type = 'hash', parts = {'key'}});
    box.schema.user.grant('guest', 'read,write,execute', 'universe');
end

-- запускает инициализацию
box.once('kv-store-1.0', bootstrap);

-- логирует действия с хранилищем
local function log_action(action, key)
    logger.info('kvstore: Action: ' .. action .. '; key: ' .. key)
end

-- проверяет наличие кортежа по ключу
local function key_free(key)
    local records = box.space.kv:select{key}
    local is_free = #records == 0
    return is_free, record
end

-- находит кортеж по первичному ключу
-- возвращает кортеж, вторым параметром явный признак был ли кортеж найден
local function select_data(key)
    local records = box.space.kv:select{key}
    local is_found = #records ~= 0
    if is_found then
        log_action('select', key)
    end
    return records, is_found
end

-- добавляет кортеж по ключу
-- возвращает true - если запись была добавлена, false - если ключ уже занят.
local function insert(key, value)
    local can_insert = key_free(key)
    if can_insert then
        box.space.kv:insert{key, value}
        log_action('insert', key)
    end
    return can_insert
end

-- обновляет кортеж по ключу
-- возвращает true - если запись была обновлена, false - если ключ не был найден.
local function update(key, value)
    local key_exists = (key_free(key) == false)
    if key_exists then
        box.space.kv:update({key}, {{'=', 2, value}})
        log_action('update', key)
    end
    return key_exists
end

-- удаляет кортеж по ключу
-- возвращает true - если запись была удалена, false - если ключ не был найден.
local function delete(key)
    local key_exists = (key_free(key) == false)
    if key_exists then
        box.space.kv:delete{key}
        log_action('delete', key)
    end
    return key_exists
end

local kvstore = {
    select = select_data,
    insert = insert,
    update = update,
    delete = delete
}

return kvstore
