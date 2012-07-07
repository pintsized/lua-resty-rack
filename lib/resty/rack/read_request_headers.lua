module("resty.rack.read_request_headers", package.seeall)

_VERSION = '0.01'

function call(options)
    local max = options.max or 100
    return function(req, res, next)
        for k,v in pairs(ngx.req.get_headers(max)) do
            req.header[k] = v
        end
        next()
    end
end

