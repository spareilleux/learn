---
title: 3 — When a boundary crosses a process
description: Work through lost replies, concurrent retries, module extraction and recovery without assuming a port provides distributed guarantees.
sidebar:
  order: 3
---

## The lost reply

The teacher clicks Save. The server commits the plan; the connection closes before the receipt arrives. A retry can create a duplicate even though every dependency points inward. [Amazon's idempotent API guidance](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/) explains why caller intent needs a stable identity across retries. Our specific contract below is a proposed design, **to verify** in an implementation.

Use an idempotency key scoped to the authenticated teacher, plus a canonical payload digest. Store the key, digest, plan and receipt in the same transaction. A concurrent retry must encounter a uniqueness rule or equivalent atomic reservation, not a separate “does this key exist?” check followed by an insert.

| Event | Required result | Test observation |
|---|---|---|
| Reply lost after commit | Retry returns the persisted receipt | One plan; same ID and revision |
| Two identical requests arrive together | One commit; both obtain the same result | One key and one plan after both finish |
| Same key, different payload | Conflict, no second plan | Original digest and receipt unchanged |
| Storage fails before commit | No success receipt | Retry can still complete |
| Catalog revision rejected during commit | Typed stale rejection | Neither plan nor success receipt exists |

Set a retention policy for keys. Once the record expires, the same key might create a new plan; “idempotent forever” is not implied. Decide whether rejected attempts are remembered. Our candidate records successful commits only, so a stale rejection may be retried after refreshing the catalog.

## A port does not make remote calls local

Suppose Catalog moves to another process. A local call becomes subject to latency, timeout, unavailable peers, authentication and schema versions. A timeout says the caller lacks a result; it does not prove the remote action failed. Borrowed memory or an in-process object reference cannot be the wire contract.

The strongest argument against extraction is that our one team still releases both modules together. The simpler alternative is a public module API in the existing process. Reject extraction unless independent deployment, scaling or isolation produces a measured benefit large enough to pay for operating a second service.

If Practice must validate the latest remote catalog atomically with its local commit, an ordinary request followed by a local transaction cannot guarantee that. Choose deliberately: accept an immutable pinned snapshot, introduce a coordinated protocol, or weaken the freshness requirement visibly. This course chooses pinned snapshots for its first slice; changing that rule requires a product decision.

## Notifications expose another transaction

Saving a plan and notifying the student are two effects. Calling a remote notification service inside a local transaction cannot make both commits atomic. A possible design stores a pending notification record with the plan, then a worker delivers it. Delivery retries require a stable message ID and recipient-side deduplication. This is a proposed outbox exercise, not a claim of exactly-once delivery.

Hidden costs include retry queues, poison messages, reconciliation, retention and support tools. If notifications are optional, showing the saved plan in the existing UI is the simpler initial behavior.

## Exercise — Trace the crash

A worker sends a notification successfully, then crashes before marking the pending record delivered. On restart it sends again. What belongs in the contract? Name a useful metric and a rejection criterion for this feature.

<details>
<summary>Worked solution</summary>

The recipient must recognize the same message ID, or duplicate delivery remains possible and must be acceptable to the product. Marking the record first merely changes the failure to a lost notification. Measure the age of the oldest pending notification and count duplicate effects separately from delivery attempts. Reject automatic notifications if the receiver cannot deduplicate and duplicate user-visible messages are unacceptable. Keep the durable plan receipt independent of notification success. Test both crash windows before claiming reliable delivery; this lesson has not executed them.

</details>
