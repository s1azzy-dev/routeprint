---
name: routeprint-yabi-interactor
description: Use this skill when adding or changing Routeprint business use cases, app/interactors code, interactor specs, or deciding whether Rails logic belongs in a yabi interactor. Do not use for pure view, copy, or style-only edits.
---

# Routeprint Yabi Interactor

## When to use

Use for behavior-changing business logic, `app/interactors/**`, `spec/interactors/**`, or controller/model changes whose orchestration should move into a use case.

Do not replace the project harness. First classify the task with `docs/DEVELOPMENT.md`, then use this skill only for the interactor slice.

## Read

- `docs/DEVELOPMENT.md` task router, task packet, execution loop, and verification matrix.
- `docs/CONTEXT_MAP.md` rows for "Interactors/use cases" plus the active domain area.
- `docs/FOUNDATIONS.md` architecture boundary when deciding where logic belongs.
- `app/interactors/application_interactor.rb`.
- The directly relevant interactor and matching spec, then one neighboring interactor/spec in the same namespace.

## Do not read by default

- The whole repository.
- All interactors or all specs.
- ADRs unless the context map names one for the active domain.
- `db/structure.sql` unless the task depends on generated schema output.

## Procedure

1. Fill a compact task packet: task type, behavior change, risk class, docs loaded, context row, red test, approval, verification.
2. If behavior changes, write or update the failing interactor/request spec first.
3. Keep the use case in `app/interactors` using the existing `ApplicationInteractor` helpers.
4. Put persistence invariants in models, HTTP orchestration in controllers, and non-business read composition in queries.
5. Prefer one focused interactor over a new service layer, command object style, or alternate result API.
6. Return `Success(...)` on success and `Failure(code:, errors:)` through `fail_with` on expected failures.
7. Run the narrow spec first, then the verification required by `docs/DEVELOPMENT.md`.
8. Update `CHANGES.md` for behavior, schema, dependency, process, or user-facing changes.

## Default style example

Use this as the shape to preserve; adjust names and fields to the real domain.

```ruby
module Namespace
  class DoThing < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:record_id).filled(:string)
        required(:name).filled(:string)
        optional(:note).maybe(:string)
      end
    end

    def call
      in_transaction do
        record = yield find_record(input[:record_id])
        updated = yield update_record(record)

        Success(record: updated)
      end
    end

    private

    def find_record(record_id)
      record = Record.find_by(id: record_id)

      return Success(record) if record

      fail_with(code: :record_not_found, errors: { record_id: [ "not found" ] })
    end

    def update_record(record)
      return Success(record) if record.update(name: input[:name], note: input[:note])

      fail_with(code: :validation_error, errors: record.errors.to_hash)
    end
  end
end
```

Spec shape:

```ruby
RSpec.describe Namespace::DoThing, type: :interactor do
  subject(:result) { described_class.call(input:) }

  let(:input) { { record_id: record.id, name: "New name" } }
  let(:record) { create(:record) }

  it "returns success" do
    expect(result).to be_success
  end

  it "persists the change" do
    expect { result }.to change { record.reload.name }.to("New name")
  end

  context "when the record does not exist" do
    let(:input) { super().merge(record_id: SecureRandom.uuid) }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.failure[:code]).to eq(:record_not_found)
    end
  end
end
```

## Outputs

When reporting or handing off, include:

```text
Loaded:
Skipped:
Interactor:
Spec:
Failure codes:
Red test:
Verification:
Open question:
```

## Token economy

- Read one base interactor, one target file, one matching spec, and one neighbor.
- Use `rg` for namespace names and failure codes before opening files.
- Summarize large existing specs; keep exact snippets only for style-critical lines.
- Do not paste full validation contracts unless the task changes those fields.
