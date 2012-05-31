module("resty.rack.method_override", package.seeall)

_VERSION = '0.01'

function call(options)
    return function(req, res, next)
        local key = options['key'] or '_method'
        req.method = string.upper(req.args[key] or req.method)
        next()
    end
end

