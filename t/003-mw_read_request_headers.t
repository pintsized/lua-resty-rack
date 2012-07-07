use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => 4;

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
};

run_tests();

__DATA__
=== TEST 1: Lazy loading (real) request headers.
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        local cjson = require "cjson"
        rack.use(function(req, res)
            res.status = 200
            r = {
                req.header,
                req.header.x_foo
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
[{},"bar"]


=== TEST 2: Pre loading (real) request headers.
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        local cjson = require "cjson"
        rack.use(rack.middleware.read_request_headers)
        rack.use(function(req, res)
            res.status = 200
            res.body = cjson.encode(req.header)
        end)
        rack.run()
    ';
}
--- request
GET /t
--- more_headers
X-Foo: bar
--- response_body_like
^(.*)("X-Foo":"bar"{1})(.*)$
