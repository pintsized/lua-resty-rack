use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => 6;

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
};

run_tests();

__DATA__
=== TEST 1: Req headers from HTTP, all cases.
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        local cjson = require "cjson"
        rack.use(function(req, res)
            res.status = 200
            local r = {
                req.header["X-Foo"],
                req.header["x-foo"],
                req.header["x-fOo"],
                req.header["x_fOo"],
                req.header.x_fOo,
                req.header.X_Foo,
            }
            res.body = cjson.encode(r)
        end)
        rack.run()
    ';
}
--- request
GET /t
--- more_headers
X-Foo: bar
--- response_body
["bar","bar","bar","bar","bar","bar"]

=== TEST 2: Res headers, all cases.
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        local cjson = require "cjson"
        rack.use(function(req, res)
            res.status = 200
            res.header["X-Foo"] = "bar"
            local r = {
                res.header["X-Foo"],
                res.header["x-foo"],
                res.header["x-fOo"],
                res.header["x_fOo"],
                res.header.x_fOo,
                res.header.X_Foo,
            }
            res.body = cjson.encode(r)
        end)
        rack.run()
    ';
}
--- request
GET /t
--- response_body
["bar","bar","bar","bar","bar","bar"]

=== TEST 3: Req headers, defined in code.
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        local cjson = require "cjson"
        rack.use(function(req, res)
            res.status = 200
            req.header["X-Foo"] = "bar"
            local r = {
                req.header["X-Foo"],
                req.header["x-foo"],
                req.header["x-fOo"],
                req.header["x_fOo"],
                req.header.x_fOo,
                req.header.X_Foo,
            }
            res.body = cjson.encode(r)
        end)
        rack.run()
    ';
}
--- request
GET /t
--- response_body
["bar","bar","bar","bar","bar","bar"]
