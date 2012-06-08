# lua-resty-rack

A simple and extensible HTTP server framework for [OpenResty](http://openresty.org), providing a clean method for loading Lua HTTP applications ("resty" modules) into [Nginx](http://nginx.org).

Drawing inspiration from [Rack](http://rack.github.com/) and also [Connect](https://github.com/senchalabs/connect), **lua-resty-rack** allows you to load your application as a piece of middleware, alongside other middleware. Your application can either; ignore the current request, modify the request or response in some way and pass on to other middleware, or take responsibiliy for the request by generating a response. 

## Status

This library is considered experimental and the API may change without notice. Please free to offer suggestions or raise issues here on Github.

## Installation

Clone the repo and ensure the contents of `lib` are in your `lua_package_path` in `nginx.conf`.

## Using Middleware

To install middleware for a given `location`, you simply call `rack.use(middleware)` in the order you wish the modules to run, and then finally call `rack.run()`.

```nginx
server {
    location / {
        content_by_lua '
            local rack = require "resty.rack"

            rack.use(rack.middleware.method_override)
            rack.use(require "my.module")
            rack.run()
        ';
    }
}
```

### rack.use(...)

**Syntax:** `rack.use(route?, middleware, options?)`

If `route` is supplied, the middleware will only be run for requests where `route` is in the path (`ngx.var.uri`). If the middleware requires any options to be selected they can be provided, usually as a table, as the third parameter.

```lua
rack.use('/some/path', app, { foo = 'bar' })
```

For simple cases, the `middleware` parameter can also be a simple function rather than a Lua module. Your function should accept `req`, `res`, and `next` as parameters. See below for instructions on writing middleware.

```lua
rack.use(function(req, res, next)
    res.header["X-Homer"] = "Doh!"
    next()
end)
```

### rack.run()

**Syntax:** `rack.run()`

Runs each of the middleware in order, until one chooses to handle the response. Thus, the order in which you call `rack.use()` is important.

## Bundled Middleware

Currently there are two simple example pieces of middlware bundled. The plan is to increase that to provide a set of utilities similar to that of [Connect](http://www.senchalabs.org/connect/), where appropriate.

* resty.rack.method_override
* resty.rack.read_body

Currently these are preloaded, which might not be sensible. For now, consider them as examples.

## Creating Middleware

Middleware applications are simply Lua modules which use the HTTP request and response as a minimal interface. They must implement the function `call(options)` which returns a function. The parameters `(req, res, next)` are defined below.

```lua
module("resty.rack.method_override", package.seeall)

_VERSION = '0.01'

function call(options)
    return function(req, res, next)
        local key = options['key'] or '_method'
        req.method = string.upper(req.args[key] or req.method)
        next()
    end
end
```

### req

* req.method (GET|POST...)
* req.scheme (http|https)
* req.uri (/my/uri)
* req.host (example.com),
* req.query (var1=1&var2=2)
* req.args (table)
* req.header (table)
* req.body (an empty string until read)

### res

* req.status (number)
* res.header (table)
* res.body (string)

### next

This parameter is a function provided to the middleware, which may be called to indicate rack should try the next middleware. If your application does not intend to send the response to the browser, it must call this function. If however your application is taking responsibility for the response, simply return without calling next.

*Example purely modifying the request.*
```lua
function call(options)
    return function(req, res, next)
        local key = options['key'] or '_method'
        req.method = string.upper(req.args[key] or req.method)
        next()
    end
end
```

*Example generating a response.*
```lua
function call(options)
    return function(req, res)
        res.status = 200
        res.header['Content-Type'] = "text/plain"
        res.body = "Hello World"
    end
end
```

### Enhancing req / res

Your application can add new fields or even functions to the req / res tables where appropriate, which could be used by other middleware so long as the dependencies are clear (and one calls `use()` in the correct order). 

For exampe, [ledge](https://github.com/pintsized/ledge/blob/master/README.md#ledgebindevent_name-callback) adds some convenience methods to help determine cacheabiliy.

## Author

James Hurst <jhurst@squiz.co.uk>

## Licence

This module is licensed under the 2-clause BSD license.

Copyright (c) 2012, James Hurst <jhurst@squiz.co.uk>

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
