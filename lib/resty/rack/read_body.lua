module("resty.rack.read_body", package.seeall)

_VERSION = '0.01'

function call(options)
    return function(req, res, next)
        ngx.req.read_body()
        req.body = ngx.req.get_body_data()
        next()
    end
end

