About
=====
`ngx_cache_purge` is `nginx` module which adds ability to purge content from
`FastCGI`, `proxy`, `SCGI` and `uWSGI` caches. A purge operation removes the 
content with the same cache key as the purge request has.


Sponsors
========
Work on the original patch was fully funded by [yo.se](http://yo.se).


Status
======
This module is production-ready.


Configuration directives (same location syntax)
===============================================
fastcgi_cache_purge
-------------------
* **syntax**: `fastcgi_cache_purge on|off|<method> [purge_all] [from all|<ip> [.. <ip>]]`
* **default**: `none`
* **context**: `http`, `server`, `location`

Allow purging of selected pages from `FastCGI`'s cache.


proxy_cache_purge
-----------------
* **syntax**: `proxy_cache_purge on|off|<method> [purge_all] [from all|<ip> [.. <ip>]]`
* **default**: `none`
* **context**: `http`, `server`, `location`

Allow purging of selected pages from `proxy`'s cache.


scgi_cache_purge
----------------
* **syntax**: `scgi_cache_purge on|off|<method> [purge_all] [from all|<ip> [.. <ip>]]`
* **default**: `none`
* **context**: `http`, `server`, `location`

Allow purging of selected pages from `SCGI`'s cache.


uwsgi_cache_purge
-----------------
* **syntax**: `uwsgi_cache_purge on|off|<method> [purge_all] [from all|<ip> [.. <ip>]]`
* **default**: `none`
* **context**: `http`, `server`, `location`

Allow purging of selected pages from `uWSGI`'s cache.


Configuration directives (separate location syntax)
===================================================
fastcgi_cache_purge
-------------------
* **syntax**: `fastcgi_cache_purge zone_name key`
* **default**: `none`
* **context**: `location`

Sets area and key used for purging selected pages from `FastCGI`'s cache.


proxy_cache_purge
-----------------
* **syntax**: `proxy_cache_purge zone_name key`
* **default**: `none`
* **context**: `location`

Sets area and key used for purging selected pages from `proxy`'s cache.


scgi_cache_purge
----------------
* **syntax**: `scgi_cache_purge zone_name key`
* **default**: `none`
* **context**: `location`

Sets area and key used for purging selected pages from `SCGI`'s cache.


uwsgi_cache_purge
-----------------
* **syntax**: `uwsgi_cache_purge zone_name key`
* **default**: `none`
* **context**: `location`

Sets area and key used for purging selected pages from `uWSGI`'s cache.

Configuration directives (Optional)
===================================================

cache_purge_response_type
-----------------
* **syntax**: `cache_purge_response_type html|json|xml|text`
* **default**: `html`
* **context**: `http`, `server`, `location`

Sets a response type of purging result.



Partial Keys
============
Sometimes it's not possible to pass the exact key cache to purge a page. For example; when the content of a cookie or the params are part of the key.
You can specify a partial key adding an asterisk at the end of the URL.

    curl -X PURGE /page*

The asterisk must be the last character of the key, so you **must** put the $uri variable at the end.



Purging multiple cache entries with the same cache key
======================================================
Caching requests that use the "Vary" header may result in multiple cache
entries with the same cache key. For example, when using the request header
"Vary: Accept-Encoding", a separate cache entry (with different file hash)
will be stored for each content encoding (like compressed or uncompressed),
but they will all have the exact same cache key.

Trying to purge such cached content will fail unless both the "Vary" header
is specified in the purge request, plus all headers as listed in the "Vary"
header, with the exact same values as used when the request was cached.

To be able to purge *all* pages with the same cache key, specify the key with
a "$" at the end, like this:

    curl -X PURGE /page$

This will purge all content with the exact key "/page" from the cache.



Sample configuration (same location syntax)
===========================================
    http {
        proxy_cache_path  /tmp/cache  keys_zone=tmpcache:10m;

        server {
            location / {
                proxy_pass         http://127.0.0.1:8000;
                proxy_cache        tmpcache;
                proxy_cache_key    $uri$is_args$args;
                proxy_cache_purge  PURGE from 127.0.0.1;
            }
        }
    }


Sample configuration (same location syntax - purge all cached files)
====================================================================
    http {
        proxy_cache_path  /tmp/cache  keys_zone=tmpcache:10m;

        server {
            location / {
                proxy_pass         http://127.0.0.1:8000;
                proxy_cache        tmpcache;
                proxy_cache_key    $uri$is_args$args;
                proxy_cache_purge  PURGE purge_all from 127.0.0.1;
            }
        }
    }


Sample configuration (separate location syntax)
===============================================
    http {
        proxy_cache_path  /tmp/cache  keys_zone=tmpcache:10m;

        server {
            location / {
                proxy_pass         http://127.0.0.1:8000;
                proxy_cache        tmpcache;
                proxy_cache_key    $uri$is_args$args;
            }

            location ~ /purge(/.*) {
                allow              127.0.0.1;
                deny               all;
                proxy_cache_purge  tmpcache $1$is_args$args;
            }
        }
    }

Sample configuration (Optional)
===============================================
    http {
        proxy_cache_path  /tmp/cache  keys_zone=tmpcache:10m;

        cache_purge_response_type text;

        server {

            cache_purge_response_type json;

            location / { #json
                proxy_pass         http://127.0.0.1:8000;
                proxy_cache        tmpcache;
                proxy_cache_key    $uri$is_args$args;
            }

            location ~ /purge(/.*) { #xml
                allow              127.0.0.1;
                deny               all;
                proxy_cache_purge  tmpcache $1$is_args$args;
                cache_purge_response_type xml;
            }

            location ~ /purge2(/.*) { # json
                allow              127.0.0.1;
                deny               all;
                proxy_cache_purge  tmpcache $1$is_args$args;
            }
        }

        server {

            location / { #text
                proxy_pass         http://127.0.0.1:8000;
                proxy_cache        tmpcache;
                proxy_cache_key    $uri$is_args$args;
            }

            location ~ /purge(/.*) { #text
                allow              127.0.0.1;
                deny               all;
                proxy_cache_purge  tmpcache $1$is_args$args;
            }

            location ~ /purge2(/.*) { #html
                allow              127.0.0.1;
                deny               all;
                proxy_cache_purge  tmpcache $1$is_args$args;
                cache_purge_response_type html;
            }
        }
    }



Testing
=======
`ngx_cache_purge` comes with complete test suite based on [Test::Nginx](http://github.com/agentzh/test-nginx).

You can test it by running:

`$ prove`


License
=======
    Copyright (c) 2009-2014, FRiCKLE <info@frickle.com>
    Copyright (c) 2009-2014, Piotr Sikora <piotr.sikora@frickle.com>
    All rights reserved.

    This project was fully funded by yo.se.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


See also
========
- [ngx_slowfs_cache](http://github.com/FRiCKLE/ngx_slowfs_cache).
