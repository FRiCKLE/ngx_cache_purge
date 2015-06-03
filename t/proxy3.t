# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => 32;

our $http_config = <<'_EOC_';
    proxy_cache_path  /tmp/ngx_cache_purge_cache keys_zone=test_cache:10m;
    proxy_temp_path   /tmp/ngx_cache_purge_temp 1 2;
_EOC_

our $config = <<'_EOC_';
    location /proxy {
        proxy_pass         $scheme://127.0.0.1:$server_port/etc/passwd;
        proxy_cache        test_cache;
        proxy_cache_key    $uri$is_args$args;
        proxy_cache_valid  3m;
        add_header         X-Cache-Status $upstream_cache_status;

        proxy_cache_purge PURGE purge_all from 1.0.0.0/8 127.0.0.0/8 3.0.0.0/8;
    }


    location = /etc/passwd {
        root               /var/www/html;
    }
_EOC_

worker_connections(128);
no_shuffle();
run_tests();

no_diff();

__DATA__

=== TEST 1: prepare passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 2: prepare shadow
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/shadow
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/



=== TEST 3: get from cache passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: HIT
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 4: get from cache shadow
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/shadow
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: HIT
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 5: purge from cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /proxy/any
--- error_code: 200
--- response_headers
Content-Type: text/html
--- response_body_like: Successful purge
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 6: get from empty cache passwd
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: MISS
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/


=== TEST 7: get from empty cache shadow
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/shadow
--- error_code: 200
--- response_headers
Content-Type: text/plain
X-Cache-Status: MISS
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
