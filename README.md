# TokenBucket

A simple Token Bucket implementation in Swift. A token bucket is simple algorithm useful for rate-limiting events.

This implementation simply uses an NSCondition to manage concurrency. There are no timers or any dependency on the run loop to refill the bucket.

## Usage

To use it, create a bucket with the desired parameter for capacity, the number of tokens per interval and the replishing time interval.
Then you just have to consume tokens from the bucket before starting your rate-limited work/event.

```swift
// create a bucket
let bucket = TokenBucket(capacity: 10, tokensPerInterval: 1, interval: 0.5)

// consume token(s)
if bucket.tryConsume(1, until: Date().addingTimeInterval(0.1))) {
    // perform some work
} else {
    // failed to retrieve token, handle accordingly
}

```

There's also a handy utility method simply called ```consume()``` that will wait indefinitely for the desired tokens to become available.

```swift
bucket.consume(1)
```

## Installation

It's just a single file, copy it to your project and you're done.

