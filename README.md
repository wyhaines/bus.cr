# bus.cr
It is sometimes useful to have a pubsub type message bus inside your software. This library implements a bus to send messages to interested subscribers. Those subscribers can reply to those messages, and are guaranteed that the reply will be routed back to the sender.
