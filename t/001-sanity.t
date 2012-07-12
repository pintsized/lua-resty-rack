use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => 6;

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
};

run_tests();

__DATA__
=== TEST 1: No middleware.
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        rack.run()
    ';
}
--- request
GET /t
--- error_code: 200

=== TEST 2: Simple response as a function
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        rack.use(function(req, res)
            res.status = 200
            res.body = "Hello"
        end)
        rack.run()
    ';
}
--- request
GET /t
--- error_code: 200
--- response_body: Hello

=== TEST 3: Status code
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        rack.use(function(req, res)
            res.status = 304
        end)
        rack.run()
    ';
}
--- request
GET /t
--- error_code: 304

=== TEST 4: Module
--- http_config eval: $::HttpConfig
--- config
location /t {
    content_by_lua '
        local rack = require "resty.rack"
        local m = {
            call = function(o)
                return function(req, res, next)
                    res.status = 200
                    res.body = "Module"
                end
            end
        }
        rack.use(m)
        rack.run()
    ';
}
--- request
GET /t
--- error_code: 200
--- response_body: Module
