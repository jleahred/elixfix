# ElixFIX


[(doc)](http://jleahred.github.io/elixfix.doc/readme.html)

## Description

Partial FIX protocol implementation on Elixir/Erlang

This is a real-life exercise, it's not a system working on production.

I don't try to support all FIX protocol features, just the basic but common ones  

[FIX protocol](http://www.fixtradingcommunity.org/)



## Source organization

On `f` folder will be modules with pure (or almost pure functions)

This modules will start with FXxxxx


Remember you have links to source from inside this document (when html format).
Thanks great tool **ExDoc**


## Installation

Pending...

## TODOs

* (done) Test on process_message
    * It has to work with parsed message, not with message_map
    * It has to check valid message format
* (done) MsgSeqNum  has to save the value on int (on parse)
* Add specs
* (done) Add credo
* (done) Tags dictionary
* Functions
    * (done) FSessionRec
    * FSessionSender
    * Message Builder
* Services (actors)
    * TCP (acceptor, initiator)
    * MessageParser
    * MessageBuilder
    * SessionDispacher
    * SessionManager
    * ...
