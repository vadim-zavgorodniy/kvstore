box.cfg{
    --   listen = 'localhost:3301';
    -- background = true,
    -- log = '1.log',
    -- pid_file = '1.pid'
}

--==========================================================

local json = require('json')
local kvstore = require('kv-store')
-- local kvstore = dofile('kv-store.lua')

local function make_json_response(code, response)
    response.status = code
    response.headers = { ['content-type'] = 'application/json; charset=utf-8' }
    return response
end

local function read_body_as_json(req)
    local body = req:read();
    local is_valid_json, lua_table = pcall(json.decode, body)
    return is_valid_json, lua_table
end

local function read(req)
    local key = req:stash('key')
    local records, found = kvstore.select(key)
    local response = {}

    if not found then
        return make_json_response(404, response)
    end

    response.body = records[1][2]
    return make_json_response(200, response)
end

local function create(req)
    local response = {}
    local valid_json, body = read_body_as_json(req)
    if not valid_json or type(body) ~= 'table' then
        return make_json_response(400, response)
    end

    if body.key == nill or body.value == nill then
        return make_json_response(400, response)
    end
    if type(body.key) ~= 'string' then
        return make_json_response(400, response)
    end

    local value = json.encode(body.value)
    local created = kvstore.insert(body.key, value)
    if not created then
        return make_json_response(409, response)
    end

    return make_json_response(200, response)
end

local function update(req)
    local response = {}
    local valid_json, body = read_body_as_json(req)
    if not valid_json or type(body) ~= 'table' then
        return make_json_response(400, response)
    end
    if body.value == nill then
        return make_json_response(400, response)
    end

    local key = req:stash('key')
    local value = json.encode(body.value)
    local found = kvstore.update(key, value)
    if not found then
        return make_json_response(404, response)
    end

    return make_json_response(200, response)
end

local function delete(req)
    local key = req:stash('key')
    local found = kvstore.delete(key)
    local response = {}
    if not found then
        return make_json_response(404, response)
    end
    return make_json_response(200, response)
end


local kv_host = 'localhost';
local kv_port = '8080';

httpd = require('http.server').new(kv_host, kv_port)
httpd:route({path = '/kv', method = 'POST'}, create)
httpd:route({path = '/kv/:key', method = 'GET'}, read)
httpd:route({path = '/kv/:key', method = 'PUT'}, update)
httpd:route({path = '/kv/:key', method = 'DELETE'}, delete)

httpd:start()

--==========================================================
