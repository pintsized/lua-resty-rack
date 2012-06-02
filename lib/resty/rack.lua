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
    if type(route) == "table" then
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
    else
        return nil, "Middleware provided did not contain the function 'call(options)'"
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
                body = nil,
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
        local status, header, body = mw(ngx.ctx.rack.req, ngx.ctx.rack.res, next)
        -- If we get non-nil values back, this middleware is handling the response.
        if status and header and body then
            ngx.status = status
            for k,v in pairs(header) do
                ngx.header[k] = v
            end
            ngx.print(body)
            return -- all done
        end
    end
end


-- to prevent use of casual module global variables
getmetatable(resty.rack).__newindex = function (table, key, val)
    error('attempt to write to undeclared variable "' .. key .. '": '
            .. debug.traceback())
end

