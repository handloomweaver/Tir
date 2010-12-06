require 'uuid'

local UUID_TYPE = 'random'

function make_session_id()
    return 'APP-' .. uuid.new(UUID_TYPE)
end

function make_expires()
    local temp = os.date("*t", os.time())
    temp.year = temp.year + 20
    return os.date("%a, %d-%b-%Y %X GMT", os.time(temp))
end

function make_session_cookie(ident)
    return 'session="' .. (ident or make_session_id()) ..
            '"; version=1; path=/; expires=' .. make_expires()
end

function parse_session_id(cookie)
    if not cookie then return nil end

    return cookie:match('session="(APP-[a-z0-9\-]+)";?')
end


local function json_ident(req)
    local ident = req.data.session_id

    if not ident then
        ident = make_session_id()
        req.data.session_id = ident
    end

    return ident
end


local function http_cookie_ident(req)
    local ident = parse_session_id(req.headers['cookie'])

    if not ident then
        ident = make_session_id()
        local cookie = make_session_cookie(ident)

        req.headers['set-cookie'] = cookie
        req.headers['cookie'] = cookie
    end

    return ident
end

-- This is the default way an engine identifies a connection, using
-- cookies.  You can change this to use just the connection id too.
-- It will handle either JSON requests or HTTP requests and it will
-- craft cookies for you.
function default_ident(req)
    if req.headers.METHOD == "JSON" then
        return json_ident(req)
    else
        return http_cookie_ident(req)
    end
end