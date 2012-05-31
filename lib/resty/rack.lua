module("resty.rack", package.seeall)

_VERSION = '0.01'

middleware = {}

-- Preload bundled middleware
middleware.method_override = require "resty.rack.method_override"
middleware.read_body = require "resty.rack.read_body"

function use(mw, options)
    if type(mw.call) == "function" then
        local options = options or {}
        table.insert(middleware, mw.call(options))
    end
end

function run()
    -- The req data available from ngx_lua is read only for the
    -- most part.
    ngx.ctx.req = {
        method = ngx.var.request_method,
        header = ngx.req.get_headers,
        body = nil,
        args = ngx.req.get_uri_args(),
    }

    ngx.ctx.res = {
        status = nil,
        header = {},
        body = nil,
    }
        
    next()
end

function next()
    -- Pick each piece of middleware off in order
    local mw = table.remove(middleware, 1)
    if type(mw) == "function" then
        local status, header, body = mw(ngx.ctx.req, ngx.ctx.res, next)
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

