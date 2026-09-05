# SimplestAntispam

Retail chat filtering, updated for Midnight 12.1.0 (build 69587).
After updating the files, run `/reload`, then `/sa` to open Settings.
Settings are saved immediately and separately for each character.

- Repeated public channel and yell messages are hidden for the configured
  interval (2 minutes by default). As in the original addon, matching text from
  different senders also counts as a repeat. Each chat window filters independently.
- Raid target icons are removed from these messages. Your own messages are exempt.
- Setting **Hide levels below** to 0 disables level checks (the default).
  Otherwise, the addon can temporarily add a same-realm character to the legacy
  friend list to learn their level, then remove its own temporary entry.
  Existing friends are exempt from the level check. Requests are serialized and
  throttled; failed lookups time out. Unknown levels and other-realm players pass
  the level check, and level checks pause in instances.
- Midnight restricts access to some chat messages. Filtering passes those
  messages through and pauses during chat messaging lockdown. It does not read
  restricted values or replace chat frames' `AddMessage` methods.

LibStub, CallbackHandler, and LibDataBroker are bundled. AutoTurnIn is not required.
The optional launcher appears in compatible data broker displays; `/sa` always
opens settings. Unsupported locales use English labels.
