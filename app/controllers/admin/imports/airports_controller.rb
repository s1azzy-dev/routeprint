module Admin
  module Imports
    class AirportsController < BaseController
      include Pagy::Method

      PAGE_SIZE = 25

      def index
        pagy, runs = pagy(:offset, runs_scope, limit: PAGE_SIZE)

        render inertia: "Admin/Imports/Airports/Index", props: index_props(pagy:, runs:)
      end

      def create
        result = ::Imports::OurAirports::StartRun.call(input: { initiated_by_user_id: current_user.id })

        if result.success?
          redirect_to admin_imports_airports_path, notice: t("admin.imports.airports.flash.started"), status: :see_other
        else
          redirect_to admin_imports_airports_path, alert: start_failure_message(result.failure.fetch(:code))
        end
      end

      private

      def runs_scope
        ::Imports::Run
          .joins(:source)
          .where(import_sources: { key: ApplicationConfig.config.imports.ourairports.source_key })
          .includes(:source)
          .order(created_at: :desc, id: :desc)
      end

      def index_props(pagy:, runs:)
        {
          copy: index_copy(pagy:),
          navigation: admin_navigation(current: "imports/airports"),
          pagination: pagination_props(pagy),
          runs: runs.map { |run| run_row_props(run) },
          urls: { index: admin_imports_airports_path, create: admin_imports_airports_path }
        }
      end

      def run_row_props(run)
        {
          id: run.id,
          sourceKey: run.source.key,
          mode: run.mode,
          parameters: safe_parameters(run),
          status: run.status,
          totalCount: run.total_item_count,
          completedCount: run.completed_item_count,
          failedCount: run.failed_item_count,
          issueCount: run.issue_count,
          createdAt: run.created_at.iso8601,
          startedAt: run.started_at&.iso8601,
          finishedAt: run.finished_at&.iso8601
        }
      end

      def safe_parameters(run)
        {
          sourceUrl: run.params.to_h["source_url"],
          parserVersion: run.params.to_h["parser_version"]
        }.compact
      end

      def index_copy(pagy:)
        {
          title: t("admin.imports.airports.index.title"),
          heading: t("admin.imports.airports.index.heading"),
          description: t("admin.imports.airports.index.description"),
          toolbarLabel: t("admin.shell.toolbar_label"),
          actions: {
            start: t("admin.imports.airports.actions.start")
          },
          emptyTitle: t("admin.imports.airports.index.empty_title"),
          emptyDescription: t("admin.imports.airports.index.empty_description"),
          tableCaption: t("admin.imports.airports.index.table_caption"),
          columns: {
            source: t("admin.imports.airports.index.columns.source"),
            mode: t("admin.imports.airports.index.columns.mode"),
            parameters: t("admin.imports.airports.index.columns.parameters"),
            status: t("admin.imports.airports.index.columns.status"),
            progress: t("admin.imports.airports.index.columns.progress"),
            timestamps: t("admin.imports.airports.index.columns.timestamps")
          },
          statuses: ::Imports::Run::STATUSES.to_h do |status|
            [ status, t("admin.imports.airports.statuses.#{status}") ]
          end,
          pagination: pagination_copy(pagy:)
        }
      end

      def pagination_props(pagy)
        urls = pagy.urls_hash

        {
          currentPage: pagy.page,
          nextUrl: urls[:next],
          previousUrl: urls[:prev],
          totalCount: pagy.count,
          totalPages: pagy.last
        }
      end

      def pagination_copy(pagy:)
        {
          label: t("admin.imports.airports.index.pagination.label"),
          previous: t("admin.imports.airports.index.pagination.previous"),
          next: t("admin.imports.airports.index.pagination.next"),
          summary: t(
            "admin.imports.airports.index.pagination.summary",
            from: pagy.from,
            to: pagy.to,
            count: pagy.count
          )
        }
      end

      def start_failure_message(code)
        key = case code
        when :run_already_active
          "start_already_active"
        when :source_not_found, :source_disabled
          "start_unavailable"
        else
          "start_failed"
        end

        t("admin.imports.airports.flash.#{key}")
      end
    end
  end
end
