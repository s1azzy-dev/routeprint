# frozen_string_literal: true

module Admin
  module Imports
    class CountriesController < BaseController
      include Pagy::Method

      PAGE_SIZE = 25

      def index
        pagy, runs = pagy(:offset, runs_scope, limit: PAGE_SIZE)
        render inertia: "Admin/Imports/Countries/Index", props: index_props(pagy:, runs:)
      end

      def create
        result = ::Imports::Countries::StartRun.call(input: { initiated_by_user_id: current_user.id })
        if result.success?
          redirect_to admin_imports_countries_path, notice: t("admin.imports.countries.flash.started"), status: :see_other
        else
          redirect_to admin_imports_countries_path, alert: start_failure_message(result.failure.fetch(:code))
        end
      end

      private

      def runs_scope
        ::Imports::Run.joins(:source).where(import_sources: { key: source_keys }).includes(:source).order(created_at: :desc, id: :desc)
      end

      def source_keys
        [ ApplicationConfig.config.imports.countries.source_key ]
      end

      def index_props(pagy:, runs:)
        {
          copy: index_copy(pagy:),
          navigation: admin_navigation(current: "imports/countries"),
          pagination: pagination_props(pagy),
          runs: runs.map { |run| run_row_props(run) },
          urls: { index: admin_imports_countries_path, create: admin_imports_countries_path }
        }
      end

      def run_row_props(run)
        {
          id: run.id, sourceKey: run.source.key, mode: run.mode, parameters: safe_parameters(run), status: run.status,
          totalCount: run.total_item_count, completedCount: run.completed_item_count, failedCount: run.failed_item_count,
          issueCount: run.issue_count, createdAt: run.created_at.iso8601, startedAt: run.started_at&.iso8601, finishedAt: run.finished_at&.iso8601
        }
      end

      def safe_parameters(run)
        params = run.params.to_h
        {
          ourairportsSourceUrl: params["ourairports_source_url"],
          cldrRelease: params["cldr_release"],
          parserVersions: params["parser_versions"]
        }.compact
      end

      def index_copy(pagy:)
        prefix = "admin.imports.countries"
        {
          title: t("#{prefix}.index.title"), heading: t("#{prefix}.index.heading"), description: t("#{prefix}.index.description"),
          toolbarLabel: t("admin.shell.toolbar_label"), actions: { start: t("#{prefix}.actions.start") },
          emptyTitle: t("#{prefix}.index.empty_title"), emptyDescription: t("#{prefix}.index.empty_description"),
          tableCaption: t("#{prefix}.index.table_caption"),
          columns: %w[source mode parameters status progress timestamps].to_h { |key| [ key.to_sym, t("#{prefix}.index.columns.#{key}") ] },
          statuses: ::Imports::Run::STATUSES.to_h { |status| [ status, t("#{prefix}.statuses.#{status}") ] },
          pagination: pagination_copy(pagy:, prefix:)
        }
      end

      def pagination_props(pagy)
        urls = pagy.urls_hash
        { currentPage: pagy.page, nextUrl: urls[:next], previousUrl: urls[:prev], totalCount: pagy.count, totalPages: pagy.last }
      end

      def pagination_copy(pagy:, prefix:)
        {
          label: t("#{prefix}.index.pagination.label"), previous: t("#{prefix}.index.pagination.previous"), next: t("#{prefix}.index.pagination.next"),
          summary: t("#{prefix}.index.pagination.summary", from: pagy.from, to: pagy.to, count: pagy.count)
        }
      end

      def start_failure_message(code)
        key = code == :country_source_unavailable ? "start_unavailable" : "start_failed"
        t("admin.imports.countries.flash.#{key}")
      end
    end
  end
end
