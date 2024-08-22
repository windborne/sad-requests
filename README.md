# Sad requests

Basic app for testing request queuing behavior when deployed.
Has two routes, `/sleep` and `/wait`, which accept a query string parameter `delay` to specify how long the request should take to complete, and sleep / busy wait for that amount of time.
They then print stats about how long it took.
They expect a X-Request-Start header.

## Experiments

### Lots of slowish requests

`siege -c 30 -r 1 'https://sad-requests.onrender.com/sleep?delay=10'`

The first 12 requests will be served, the rest will 502. Sometimes it'll be the first 13; either way it's right around 120 seconds.

```text
HTTP/1.1 200    10.38 secs:     250 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    20.48 secs:     251 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    30.71 secs:     250 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    41.72 secs:     256 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    51.14 secs:     255 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    61.38 secs:     256 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    71.51 secs:     257 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    81.76 secs:     255 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    91.91 secs:     257 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    102.17 secs:     255 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    112.32 secs:     255 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    122.61 secs:     253 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.77 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.78 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.78 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.78 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.78 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.78 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.79 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.80 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 502    122.85 secs:   67252 bytes ==> GET  /sleep?delay=10
HTTP/1.1 200    132.74 secs:     253 bytes ==> GET  /sleep?delay=10
```


`siege -c 2 -r 1 'https://sad-requests.onrender.com/sleep?delay=180'`

Render cancels things after ~120 seconds. However

```text
HTTP/1.1 502    126.65 secs:   67252 bytes ==> GET  /sleep?delay=180
HTTP/1.1 502    126.66 secs:   67252 bytes ==> GET  /sleep?delay=180
```

### Small number of very slow requests
This managed to cause a health check failed, but not every time.
`siege -c 2 -r 1 'https://sad-requests.onrender.com/sleep?delay=180'`
Samples:
- 2 502s after 126.65 secs + render health check failed
- 2 502s after 127.33 secs
- 503 after 118.67 secs and 502 after 141.87 secs

Upping the concurrency increased the odds of a health check failure, presumably because that increases the odds of the health check request getting stuck behind other things. The following made the service restart 3/3 times. Interestingly though, render only had a "failed" event for one of those -- perhaps debouncing?

`date -u +"%Y-%m-%d %H:%M:%S";  siege -c 5 -r 1 'https://sad-requests.onrender.com/sleep?delay=180'`

Requests started at 2024-08-21 15:28:19 and services failed at 2024-08-21T15:30:27.574633Z, so about 2 minutes.

To test render's failed events, I went all the way down to 1 worker:
`date -u +"%Y-%m-%d %H:%M:%S";  siege -c 1 -r 1 'https://sad-requests.onrender.com/sleep?delay=180'`

That actually triggers a service restart after ~2 minutes as well. 

Sample #1, render had a failed event. Interestingly, this was "Exited with status 137" rather than health check failed. The server then gave continual 502s to even just the health check path. The render logs just had "Gracefully stopping, waiting for requests to finish", then loads of 502s -- even far past the 3 minute mark. It eventually restarted itself at 8:46:59; requests started at 8:39:47 and graceful shutdown was requested at 8:41:26.

Samples #2-4 it restarted without a failed event.

Sample #5 acted the same as sample number 1. It recovered after 5 minutes.

Sample #6 was the same as 2-4.

Sample #7 was the same as 1.

### Lots of slowish requests pt 2
`siege -c 30 -r 1 'https://sad-requests.onrender.com/sleep?delay=10'`
1. Health check failed
2. Restart without failed health check
3. Restart without failed health check