module("resty.rack", package.seeall)

_VERSION = '0.01'

middleware = {}

-- Preload bundled middleware
-- This is at least means the modules only load once, but perhaps some kind
-- of lazy loading method would be better.
middleware.method_override = require "resty.rack.method_override"
middleware.read_body = require "resty.rack.read_body"


-- Register some middleware to be used.
--
-- @param   string  route       Optional, dfaults to '/'.
-- @param   table   middleware  The middleware module
-- @param   table   options     Table of options for the middleware. 
-- @return  void
function use(...)
    -- Process the args
    local args = {...}
    local route, mw, options = nil, nil, nil
    route = table.remove(args, 1)
    if type(route) == "table" or type(route) == "function" then
        mw = route
        route = nil
    else
        mw = table.remove(args, 1)
    end
    options = table.remove(args, 1) or {}

    if route then
        -- Only carry on if we have a route match
        if string.sub(ngx.var.uri, 1, route:len()) ~= route then return false end
    end
    
    -- If we have a 'call' function, then we insert the result into our rack
    if type(mw) == "table" and type(mw.call) == "function" then
        table.insert(middleware, mw.call(options))
        return true
    -- Or if we simply have a function, we can add that instead
    elseif (type(mw) == "function") then
        table.insert(middleware, mw)
        return true
    else
        return nil, "Invalid middleware"
    end
end


-- Start the rack.
function run()
    -- We need a decent req / res environment to pass around middleware.
    if not ngx.ctx.rack then
        ngx.ctx.rack = {
            req = {
                method = ngx.var.request_method,
                scheme = ngx.var.scheme,
                uri = ngx.var.uri,
                host = ngx.var.host,
                query = ngx.var.query_string or "",
                args = ngx.req.get_uri_args(),
                header = ngx.req.get_headers(),
                body = "",
            },
            res = {
                status = nil,
                header = {},
                body = nil,
            }
        }

        -- uri_relative = /test?arg=true 
        ngx.ctx.rack.req.uri_relative = ngx.var.uri .. ngx.var.is_args .. ngx.ctx.rack.req.query
        -- uri_full = http://example.com/test?arg=true
        ngx.ctx.rack.req.uri_full = ngx.var.scheme .. '://' .. ngx.var.host .. ngx.ctx.rack.req.uri_relative
    end 
    next()
end


-- Runs the next middleware in the rack.
function next()
    -- Pick each piece of middleware off in order
    local mw = table.remove(middleware, 1)


    if type(mw) == "function" then
        -- Call the middleware, which may itself call next(). 
        -- The first to return is handling the reponse.
        local post_function = mw(ngx.ctx.rack.req, ngx.ctx.rack.res, next)
        
        if not ngx.ctx.rack.headers_sent then
            assert(ngx.ctx.rack.res.status, 
            "Middleware returned with no status. Perhaps you need to call next().")

            ngx.status = ngx.ctx.rack.res.status
            for k,v in pairs(ngx.ctx.rack.res.header) do
                ngx.header[k] = v
            end
            ngx.ctx.rack.headers_sent = true
            ngx.print(ngx.ctx.rack.res.body)
            ngx.eof()
        end

        -- Middleware may return a function to call post-EOF.
        -- This code will only run for persistent connections, and is not really guaranteed
        -- to run, since browser behaviours differ. Also be aware that long running tasks
        -- may affect performance by hogging the connection.
        if post_function and type(post_function == "function") then
            post_function(ngx.ctx.rack.req, ngx.ctx.rack.res)
        end
    end
end


-- to prevent use of casual module global variables
getmetatable(resty.rack).__newindex = function (table, key, val)
    error('attempt to write to undeclared variable "' .. key .. '": '
            .. debug.traceback())
end

