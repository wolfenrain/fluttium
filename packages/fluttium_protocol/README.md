<p align="center">
<img src="https://raw.githubusercontent.com/wolfenrain/fluttium/main/assets/fluttium_full.png" height="125" alt="fluttium logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/fluttium_protocol"><img src="https://img.shields.io/pub/v/fluttium_protocol.svg" alt="Pub"></a>
<a href="https://github.com//wolfenrain/fluttium/actions"><img src="https://github.com/wolfenrain/fluttium/actions/workflows/main.yaml/badge.svg" alt="ci"></a>
<a href="https://github.com//wolfenrain/fluttium/actions"><img src="https://raw.githubusercontent.com/wolfenrain/fluttium/main/coverage_badge.svg" alt="coverage"></a>
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="style: very good analysis"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

The protocol for the communication between the runner and the driver of [Fluttium](https://fluttium.dev).

---

The protocol is used to communicate from the Fluttium runner to the Fluttium driver. It exists out 
of three parts: `Message`, `Emitter` and the `Listener`.

The `Message` describes a single message being send from the runner to the driver. It has a type 
that indicates what type of message it is and depending on that type it's data is different:
- start: `String` the step that is starting
- done: `String` the step that is done
- fail: `List<String>` with the step and the reason
- store: `List<dynamic>` with the file name and then list of bytes.

The `Emitter` then handles emitting a message from the runner to the driver. The message can contain
quite a bit of data, for instance storing a screenshot, and for that reason the `Emitter` emits the
message in chunks. Firstly it emits a `start` object:

```json
{"type": "start"}
```

After that it will emit one or more data chunks that make up the `Message`:

```json
{"type": "data", "data": "... data ..."}
```

Each data chunk's data should be stored until the `done` object has been received:

```json
{"type": "done"}
```

Once the `done` object has been received the data can be parsed as JSON and passed to the 
`Message.fromJson` constructor. 

Listening to the data from an `Emitter` can be done by applying the logic above, or by using the
`Listener` which expects a `Stream` of raw utf8 bytes. It assumes that any prefix to the messages,
like `flutter: ` added by Flutter, are removed by the one using the listener.

Once the listener has successfully constructed an emitted message it will add it to the `messages` 
stream.