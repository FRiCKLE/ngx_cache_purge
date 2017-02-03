# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => repeat_each() * (blocks() * 4 + 3 * 1);

our $http_config = <<'_EOC_';
    proxy_cache_path  /tmp/ngx_cache_purge_cache keys_zone=test_cache:10m;
    proxy_temp_path   /tmp/ngx_cache_purge_temp 1 2;
_EOC_

our $config = <<'_EOC_';

    cache_purge_response_type json;

    location /proxy {
        proxy_pass         $scheme://127.0.0.1:$server_port/etc/passwd;
        proxy_cache        test_cache;
        proxy_cache_key    $uri$is_args$args;
        proxy_cache_valid  3m;
        add_header         X-Cache-Status $upstream_cache_status;
    }

    location ~ /purge(/.*) {
        proxy_cache_purge           test_cache $1$is_args$args;
        cache_purge_response_type   html;
    }

    location ~ /purge_json(/.*) {
        proxy_cache_purge           test_cache $1$is_args$args;
    }

    location ~ /purge_xml(/.*) {
        proxy_cache_purge           test_cache $1$is_args$args;
        cache_purge_response_type   xml;
    }

    location ~ /purge_text(/.*) {
        proxy_cache_purge           test_cache $1$is_args$args;
        cache_purge_response_type   text;
    }



    location = /etc/passwd {
        root               /;
    }
_EOC_

worker_connections(128);
no_shuffle();
run_tests();

no_diff();

__DATA__

=== TEST 1: prepare
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
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62



=== TEST 2: get from cache
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
--- skip_nginx2: 5: < 0.8.3 or < 0.7.62



=== TEST 3: purge from cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /purge/proxy/passwd
--- error_code: 200
--- response_headers
Content-Type: text/html
--- response_body_like: Successful purge
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62



=== TEST 4: purge from empty cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /purge/proxy/passwd
--- error_code: 404
--- response_headers
Content-Type: text/html
--- response_body_like: 404 Not Found
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62



=== TEST 5: get from source
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
--- skip_nginx2: 5: < 0.8.3 or < 0.7.62



=== TEST 6: get from cache
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
--- skip_nginx2: 5: < 0.8.3 or < 0.7.62

=== TEST 7-prepare: prepare purge
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd?t=7
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62


=== TEST 7: get a JSON response after purge from cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /purge_json/proxy/passwd?t=7
--- error_code: 200
--- response_headers
Content-Type: application/json
--- response_body_like: {\"Key\": \"\/proxy\/passwd\?t=7\",\"Path\": \"\/tmp\/ngx_cache_purge_cache\/
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62

=== TEST 8-prepare: prepare purge
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd?t=8
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62


=== TEST 8: get a XML response after purge from cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /purge_xml/proxy/passwd?t=8
--- error_code: 200
--- response_headers
Content-Type: text/xml
--- response_body_like: \<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><status><Key><\!\[CDATA\[\/proxy\/passwd\?t=8\]\]><\/Key><Path><\!\[CDATA\[\/tmp\/ngx_cache_purge_cache\/
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62

=== TEST 9-prepare: prepare purge
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /proxy/passwd?t=9
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: root
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62


=== TEST 9: get a TEXT response after purge from cache
--- http_config eval: $::http_config
--- config eval: $::config
--- request
PURGE /purge_text/proxy/passwd?t=9
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body_like: Key
--- timeout: 10
--- no_error_log eval
qr/\[(warn|error|crit|alert|emerg)\]/
--- skip_nginx2: 4: < 0.8.3 or < 0.7.62


