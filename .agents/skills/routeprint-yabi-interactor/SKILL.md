---
name: routeprint-yabi-interactor
description: Use when adding, changing, reviewing, or refactoring Routeprint business use cases, app/interactors code, interactor specs, or controller/model logic that may belong in a yabi interactor. Enforces real input contracts, orchestration-first call methods, explicit fail-fast pipelines, injected interactor collaborators, narrow exception handling, concise YARD, simple state machines, and proportionate tests. Do not use for pure view, copy, or style-only edits.
---

# Routeprint Yabi Interactor

## Load

- Read the "Interactors/use cases" row plus the active domain row in
  `docs/CONTEXT_MAP.md`.
- Read `docs/FOUNDATIONS.md` architecture boundary.
- Read `app/interactors/application_interactor.rb`, the target interactor/spec,
  and one good neighboring interactor/spec.

Do not scan every interactor or load unrelated ADRs by default.

## Core rules

1. One interactor represents one meaningful use case, not one private method.
   Prefer focused private methods before creating another interactor. Extract a
   collaborator only for an independent contract, reuse, authorization,
   transaction, domain boundary, or separately meaningful action.
2. Validate only real input. Define an explicit `ValidationContract` listing
   every accepted `input` field. Do not add dummy `input` or an empty contract
   when the use case has no input.
3. `call` is normally an orchestrator. Read `input` once there, bind values to
   locals, and pass them explicitly to private methods. Avoid hidden mutable
   instance state and private methods that reach back into `input`.
4. Express multi-stage work as an ordered, one-directional pipeline. Use
   `yield` with `Success`/`Failure` results so the first failure stops later
   stages. Keep a genuinely small one-step `call` direct.
5. Declare interactor collaborators with injected `option` dependencies. Never
   call another interactor by constant from inside an interactor.
6. Return expected failures as `Failure(code:, errors:)` through `fail_with`.
   Rescue only where the exception can be handled meaningfully. Broad rescue
   belongs only at an outer job/orchestration boundary and must preserve the
   exception class, message, and backtrace in logs or structured failure
   evidence.
7. Start with the simplest correct state machine. Do not add leases,
   cancellation, checkpoints, recovery loops, custom locking, or generic
   pipeline frameworks without a current requirement and matching tests.
   For queued work, tolerate duplicate delivery through durable state and
   existing queue/database guarantees; keep rare stale-work cleanup outside the
   happy-path interactor.
8. Document every interactor class with concise YARD: purpose, example call,
   and arguments. Document other public methods, but do not repeat the class
   documentation above the interactor's single `call` method.

## Procedure

1. Identify the use case boundary and write the public input/output/failure
   contract before decomposing implementation steps.
2. Sketch the happy path as a short sequence of named stages. Make `call` show
   that sequence in execution order.
3. Pass stage values explicitly. Use private methods for local steps; introduce
   another interactor only when the extraction rule above is satisfied.
4. Keep transactions around the atomic business boundary. Fail fast and do not
   continue later records or stages after a failure unless the specification
   explicitly defines partial success.
5. Inject interactor collaborators through `option`; keep external I/O at a
   narrow boundary.
6. Keep the public use case covered by its focused interactor/request spec and
   run `spec/tooling/interactor_conventions_spec.rb` when these conventions change.

## Canonical shape

```ruby
module Namespace
  # Updates a record and records the completed business action.
  #
  # @example
  #   Namespace::DoThing.call(input: { record_id:, name: "New name" })
  # @param input [Hash] record identifier and editable attributes
  class DoThing < ApplicationInteractor
    option :input
    option :audit_interactor, default: -> { Namespace::AuditThing }

    class ValidationContract < ApplicationContract
      params do
        required(:record_id).filled(:string)
        required(:name).filled(:string)
        optional(:note).maybe(:string)
      end
    end

    def call
      record_id = input.fetch(:record_id)
      name = input.fetch(:name)
      note = input[:note]

      in_transaction do
        record = yield find_record(record_id)
        updated = yield update_record(record, name:, note:)
        yield audit_interactor.call(input: { record: updated })

        Success(record: updated)
      end
    end

    private

    def find_record(record_id)
      record = Record.find_by(id: record_id)
      return Success(record) if record

      fail_with(code: :record_not_found, errors: { record_id: [ "not found" ] })
    end

    def update_record(record, name:, note:)
      return Success(record) if record.update(name:, note:)

      fail_with(code: :validation_error, errors: record.errors.to_hash)
    end
  end
end
```

## Testing

- Prove success, expected failure codes, and state changes at the public use-case
  boundary.
- Prove fail-fast behavior when later work must not run after a failed stage.
- Prove rollback when the use case promises atomicity.
- Use doubles for external I/O or injected collaborators when testing
  orchestration order/error propagation.
- Keep at least one real fixture/integration path for critical import pipelines;
  do not replace parser, database, matching, and domain apply all at once.
- Run `spec/tooling/interactor_conventions_spec.rb` when changing these
  conventions.

## Review checklist

- Is this one meaningful use case with one `call`?
- Does the contract list only real input fields?
- Is the happy-path pipeline obvious from `call`?
- Does the first failure stop later stages?
- Are values passed explicitly instead of read from hidden state?
- Are nested interactors injected through `option`?
- Are rescues narrow and failures observable?
- Was complexity added only for a demonstrated requirement?
- Do YARD and tests describe the public boundary without duplicating internals?

## Handoff

Report the interactor, public input/output, failure codes, transaction boundary,
specs run, and any deliberately deferred complexity.
