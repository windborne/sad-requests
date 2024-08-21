# Sad requests

Basic app for testing request queuing behavior when deployed.
Has two routes, `/sleep` and `/wait`, which accept a query string parameter `delay` to specify how long the request should take to complete, and sleep / busy wait for that amount of time.
They then print stats about how long it took.
They expect a X-Request-Start header.