Features that sooner or later will be added to `ngx_cache_purge`:

* Add support for alternative in-location cache purges using specified
  request method, with following configuration syntax:

      location / {
          proxy_pass         http://127.0.0.1:8000;
          proxy_cache        tmpcache;
          proxy_cache_key    $uri$is_args$args;
          proxy_cache_purge  DELETE from 127.0.0.1;
      }

  This will allow for purges using:

      curl -X DELETE http://example.com/logo.jpg

  instead of:

      curl http://example.com/purge/logo.jpg


Features that __will not__ be added to `ngx_cache_purge`:

* Support for prefixed purges (`/purge/images/*`).  
  Reason: Impossible with current cache implementation.

* Support for wildcard/regex purges (`/purge/*.jpg`).  
  Reason: Impossible with current cache implementation.
