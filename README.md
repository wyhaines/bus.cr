# bus

![CSUUID CI](https://img.shields.io/github/workflow/status/wyhaines/bus.cr/bus.cr%20CI?style=for-the-badge&logo=GitHub)
[![GitHub release](https://img.shields.io/github/release/wyhaines/CSUUID.cr.svg?style=for-the-badge)](https://github.com/wyhaines/bus.cr/releases)
![GitHub commits since latest release (by SemVer)](https://img.shields.io/github/commits-since/wyhaines/bus.cr/latest?style=for-the-badge)


This class implements an in-process pubsub style message bus.

The bus receives messages and routes them to all interested handlers. Additionally, the bus is capable of dispatching the message to only a subset of potential handlers, based on a best-fit, or to all eligible handlers.

## Handler Selection & Winner Selection Protocol

Imagine that there are multiple subscribers for a given type of message (a given tag), but the message being dispatched should only be handled by a single subscriber. This implementation puts the responsibility on each handler to respond to an "evaluate" request on a message on two axex.

The first axis is relevance, which is a measure of how appropriate the subject of the message is to the purpose of the handler. For example, an HTTP request might be highly relevant to both a static asset handler and an API endpoint, and not at all relevant to a handler that proxies database requests.

The second axis is confidence. It reflects how sure the handler is that it can return a valid response to the message. In the aforementioned examples, a static handler that doesn't have any assets that can fullfill the request would have a very low confidence, while one that does have available assets would have a high confidence. Likewise, the API endpoint handler would return a high confidence if it had an endpoint that matched the request.

When a handler receives a message that hasn't been evaluated, the handler should return an evaluation response that indicates it's relevance and confidence.

After the bus has received evaluation responses from all of the handlers which initially received the message, it will select one or more *winners* which will each be passed the message for handling.

Handlers can choose to arbitrarily opt in to receiving a message, or to opt out of consideration.

Everything that opts out has no chance of recieving a message. Everything that opts in will always receive the message (something which may be useful for a logging handler).

All other handlers will be sorted by relevance and confidence, from high to low. The set of potential winners is all of the handlers who have the same highest relevance and confidence.

By default, if there is a tie, the bus picks a handler at random to receive the message. The other options are to just go with whichever handler happens to be first in the list, or to send messages to all handlers.

## Thread Safety

The Bus implementation should be thread safe, as should be the CSUUID and SplayTreMap implementations, but there are parts of Crystal that are not currently thread safe, so your mileage may vary.

For instance, it is possible to eke out a little more performance by replacing all of the SplayTreeMap usage with Hash, but under multithreaded conditions, the Hash can exhibit catastrophic failures, particularly in combination with `--release`. The SplayTreeMap does not exhibit these failures, and future developments with it may make it faster than the Hash for it's intended purpose (as a cache of sorts), so it remains in use.
## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     bus:
       github: your-github-user/bus
   ```

2. Run `shards install`

## Usage

```crystal
require "bus"
```

bus = Bus.new

class TestHandler < Bus::Handler
  def initialize(
    @bus : Bus,
    tags : Array(String) = [] of String,
    @force : Bool? = nil
  )
    super(@bus, tags)
  end

  def evaluate(msg)
    ppl = @pipeline

    msg.send_evaluation(receiver: ppl.origin, force: @force) if ppl
  end

  def handle(msg)
    msg.body << "Handled by #{self}"
    ResultsChannel.send(msg)
  end
end
## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/bus/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/your-github-user) - creator and maintainer

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/wyhaines/bus.cr?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues/wyhaines/bus.cr?style=for-the-badge)