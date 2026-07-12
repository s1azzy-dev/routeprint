SHELL := /bin/bash

# Host-side commands orchestrate Docker, git hooks, and project-local OpenSpec
# wrappers. Rails, Ruby, frontend runtime, test, lint, audit, and dependency
# freshness commands run inside the web container through APP.
COMPOSE := docker compose
APP := $(COMPOSE) run --rm web
RTK_FRONTEND_FORMAT_ARGS := --check --log-level warn 'app/frontend/**/*.{ts,tsx,css}' vite.config.ts eslint.config.mjs package.json tsconfig.json components.json
AGENT_LOG_LIMIT ?= 20
AGENT_DOCKER_LOG_LINES ?= 200
AGENT_DOCKER_SERVICE ?= web

.PHONY: setup openspec-install openspec-update openspec-validate harness-check frontend-install frontend-format frontend-lint frontend-typecheck frontend-test frontend-build frontend-audit frontend-check frontend-verify frontend-outdated agent-state agent-search agent-diff-stat agent-diff-names agent-log agent-docker-logs agent-rtk agent-rtk-gain agent-rtk-gain-daily agent-rtk-gain-history agent-rtk-session agent-rtk-discover agent-host-state agent-host-search agent-host-diff-stat agent-host-diff-names agent-host-log agent-host-docker-logs agent-host-rtk-gain agent-host-rtk-session agent-host-rtk-discover agent-container-rtk agent-container-rtk-gain agent-container-rtk-gain-daily agent-container-rtk-gain-history agent-frontend-format agent-frontend-lint agent-frontend-typecheck agent-frontend-test agent-rubocop agent-rubocop-fix agent-ruby-test agent-rspec agent-test agent-verify-fast install-hooks up down logs shell bash bundle lint rubocop rubocop-check rubocop-fix rubocop-autocorrect ruby-test test security verify verify-fast ci migration doctor bundle-outdated maplibre-outdated outdated

setup: openspec-install
	$(COMPOSE) up --build -d

# Host OpenSpec wrapper targets.
openspec-install:
	bin/npm ci

openspec-update:
	bin/openspec update --force

openspec-validate:
	bin/openspec validate --all --strict

harness-check:
	bin/check-agent-harness

# Containerized frontend targets.
frontend-install:
	$(APP) bin/npm ci

frontend-format:
	$(APP) bin/npm run frontend:format

frontend-lint:
	$(APP) bin/npm run frontend:lint

frontend-typecheck:
	$(APP) bin/npm run frontend:typecheck

frontend-test:
	$(APP) bin/npm run frontend:test

frontend-build:
	$(APP) bin/npm run frontend:build

frontend-audit:
	$(APP) bin/npm run frontend:audit

frontend-check: frontend-format frontend-lint frontend-typecheck frontend-test frontend-build

frontend-verify:
	$(MAKE) frontend-check
	$(MAKE) frontend-audit

# Agent commands keep app/runtime work inside the web container where needed and
# keep routine workspace/tool feedback compact before it reaches the context.
agent-state: agent-host-state

agent-host-state:
	@printf 'Branch: '
	@git branch --show-current
	@printf 'Last commit: '
	@git log -1 --oneline
	@printf 'Working tree:\n'
	@git status -sb --untracked-files=all
	@printf 'Unstaged changes:\n'
	@git diff --name-status
	@printf 'Staged changes:\n'
	@git diff --cached --name-status

agent-search: agent-host-search

agent-host-search:
ifndef Q
	$(error Q is required, for example: make agent-host-search Q='render inertia' SCOPE='app spec')
endif
	rtk rg -n "$(Q)" $(SCOPE)

agent-diff-stat: agent-host-diff-stat

agent-host-diff-stat:
	rtk git diff --stat $(BASE)

agent-diff-names: agent-host-diff-names

agent-host-diff-names:
	rtk git diff --name-status $(BASE)

agent-log: agent-host-log

agent-host-log:
	rtk git log --oneline -$(AGENT_LOG_LIMIT)

agent-docker-logs: agent-host-docker-logs

agent-host-docker-logs:
	rtk docker compose logs --tail=$(AGENT_DOCKER_LOG_LINES) $(AGENT_DOCKER_SERVICE)

agent-rtk: agent-container-rtk

agent-container-rtk:
	$(APP) rtk --version

agent-rtk-gain: agent-container-rtk-gain

agent-container-rtk-gain:
	$(APP) rtk gain

agent-rtk-gain-daily: agent-container-rtk-gain-daily

agent-container-rtk-gain-daily:
	$(APP) rtk gain --daily

agent-rtk-gain-history: agent-container-rtk-gain-history

agent-container-rtk-gain-history:
	$(APP) rtk gain --history

agent-rtk-session: agent-host-rtk-session

agent-host-rtk-gain:
	rtk gain

agent-host-rtk-session:
	rtk session

agent-rtk-discover: agent-host-rtk-discover

agent-host-rtk-discover:
	rtk discover

agent-frontend-format:
	$(APP) bash -lc "PATH=/app/node_modules/.bin:$$PATH rtk prettier $(RTK_FRONTEND_FORMAT_ARGS)"

agent-frontend-lint:
	$(APP) bash -lc "PATH=/app/node_modules/.bin:$$PATH rtk eslint . --quiet"

agent-frontend-typecheck:
	$(APP) bash -lc "PATH=/app/node_modules/.bin:$$PATH rtk tsc --noEmit --pretty false"

agent-frontend-test:
	$(APP) bash -lc "PATH=/app/node_modules/.bin:$$PATH rtk vitest run --coverage --reporter=minimal --passWithNoTests"

agent-rubocop:
	$(APP) env RUBOCOP_CACHE_ROOT=/app/tmp/rubocop rtk rubocop --format simple --config /app/.rubocop.yml

agent-rubocop-fix:
	$(APP) env RUBOCOP_CACHE_ROOT=/app/tmp/rubocop rtk rubocop -A --format simple --config /app/.rubocop.yml

agent-ruby-test:
	$(APP) bash -lc "RAILS_ENV=test bin/rails db:prepare && ROUTEPRINT_SKIP_SIMPLECOV=1 RAILS_ENV=test rtk rspec"

agent-rspec:
	$(APP) bash -lc "RAILS_ENV=test bin/rails db:prepare && ROUTEPRINT_SKIP_SIMPLECOV=1 RAILS_ENV=test rtk rspec $(SPEC)"

agent-test: frontend-install
	$(APP) bash -lc "bin/npm run frontend:build:test && RAILS_ENV=test bin/rails db:prepare && ROUTEPRINT_SKIP_SIMPLECOV=1 RAILS_ENV=test rtk rspec"

agent-verify-fast: frontend-install
	$(MAKE) agent-frontend-format
	$(MAKE) agent-frontend-lint
	$(MAKE) agent-frontend-typecheck
	$(MAKE) agent-frontend-test
	$(MAKE) frontend-build
	$(MAKE) agent-rubocop
	$(MAKE) agent-ruby-test

# Host Git and Docker orchestration targets.
install-hooks:
	git config core.hooksPath .githooks

up:
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f web

# Containerized app/runtime targets.
shell:
	$(APP) bin/rails console

bash:
	$(APP) bash

bundle:
	$(APP) bundle install

lint: rubocop-check

rubocop: rubocop-check

rubocop-autocorrect:
	$(MAKE) rubocop-fix

rubocop-check:
	$(APP) env RUBOCOP_CACHE_ROOT=/app/tmp/rubocop bin/rubocop --format simple --config /app/.rubocop.yml

rubocop-fix:
	$(APP) env RUBOCOP_CACHE_ROOT=/app/tmp/rubocop bin/rubocop -A --format simple --config /app/.rubocop.yml

ruby-test:
	$(APP) bash -lc "RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bundle exec rspec"

test: frontend-install
	$(APP) bash -lc "bin/npm run frontend:build:test && RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bundle exec rspec"

security:
	$(APP) bash -lc "bin/bundler-audit && bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

verify: openspec-validate verify-fast frontend-audit security

verify-fast: frontend-install frontend-check rubocop-check ruby-test

ci:
	$(APP) bin/ci

migration:
ifndef NAME
	$(error NAME is required, for example: make migration NAME=CreateUsers)
endif
	$(APP) bin/rails generate migration $(NAME)

doctor:
	@bin/node --version
	@bin/npm --version
	@bin/openspec --version
	@rtk --version
	@docker compose version
	@docker info --format '{{.ServerVersion}}'
	$(APP) bash -lc "ruby -v && bundle -v && rtk --version && bin/rails about"

bundle-outdated:
	$(APP) bundle outdated

frontend-outdated:
	$(APP) bin/npm outdated

maplibre-outdated:
	$(APP) bin/check-maplibre-gl

outdated:
	$(APP) bin/check-outdated
