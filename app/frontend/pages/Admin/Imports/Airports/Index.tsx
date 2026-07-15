import { router } from "@inertiajs/react"
import { DatabaseBackupIcon, PlayIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import {
  Pagination,
  PaginationContent,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination"
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

import AdminLayout, { type AdminNavigationSection } from "../../AdminLayout"

export interface AdminImportRunRow {
  completedCount: number
  createdAt: string
  failedCount: number
  finishedAt: string | null
  id: number
  issueCount: number
  mode: string
  parameters: Record<string, string>
  sourceKey: string
  startedAt: string | null
  status: string
  totalCount: number
}

export interface AdminAirportImportsIndexPageProps {
  copy: {
    actions: { start: string }
    columns: {
      mode: string
      parameters: string
      progress: string
      source: string
      status: string
      timestamps: string
    }
    description: string
    emptyDescription: string
    emptyTitle: string
    heading: string
    pagination: {
      label: string
      next: string
      previous: string
      summary: string
    }
    progress: { failed: string; issues: string }
    statuses: Record<string, string>
    tableCaption: string
    timestamps: { pending: string }
    title: string
    toolbarLabel: string
  }
  navigation: { sections: AdminNavigationSection[] }
  pagination: {
    currentPage: number
    nextUrl: string | null
    previousUrl: string | null
    totalCount: number
    totalPages: number
  }
  runs: AdminImportRunRow[]
  urls: { create: string; index: string }
}

export default function Index({
  copy,
  navigation,
  pagination,
  runs,
  urls,
}: AdminAirportImportsIndexPageProps) {
  function startImport() {
    router.post(urls.create)
  }

  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      <div className="flex justify-end">
        <Button onClick={startImport} type="button">
          <PlayIcon aria-hidden="true" data-icon="inline-start" />
          {copy.actions.start}
        </Button>
      </div>

      {runs.length > 0 ? (
        <div className="overflow-hidden rounded-lg border bg-background">
          <Table>
            <TableCaption>{copy.tableCaption}</TableCaption>
            <TableHeader>
              <TableRow>
                <TableHead>{copy.columns.source}</TableHead>
                <TableHead>{copy.columns.mode}</TableHead>
                <TableHead>{copy.columns.parameters}</TableHead>
                <TableHead>{copy.columns.status}</TableHead>
                <TableHead>{copy.columns.progress}</TableHead>
                <TableHead>{copy.columns.timestamps}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {runs.map((run) => (
                <TableRow key={run.id}>
                  <TableCell className="font-medium">{run.sourceKey}</TableCell>
                  <TableCell>{run.mode}</TableCell>
                  <TableCell className="max-w-72">
                    <div className="flex flex-col gap-1 text-xs">
                      {Object.entries(run.parameters).map(([key, value]) => (
                        <span className="break-all" key={key}>
                          <span className="text-muted-foreground">{key}:</span>{" "}
                          {value}
                        </span>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant={statusVariant(run.status)}>
                      {copy.statuses[run.status] ?? run.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-col gap-1 text-sm">
                      <span>
                        {run.completedCount}/{run.totalCount}
                      </span>
                      {run.failedCount > 0 ? (
                        <span className="text-xs text-destructive">
                          {run.failedCount} {copy.progress.failed}
                        </span>
                      ) : null}
                      {run.issueCount > 0 ? (
                        <span className="text-xs text-muted-foreground">
                          {run.issueCount} {copy.progress.issues}
                        </span>
                      ) : null}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-col gap-1 text-xs whitespace-nowrap">
                      <span>{formatTimestamp(run.createdAt)}</span>
                      <span className="text-muted-foreground">
                        {run.finishedAt
                          ? formatTimestamp(run.finishedAt)
                          : copy.timestamps.pending}
                      </span>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : (
        <Empty className="min-h-80 bg-background">
          <EmptyHeader>
            <EmptyMedia variant="icon">
              <DatabaseBackupIcon aria-hidden="true" />
            </EmptyMedia>
            <EmptyTitle>{copy.emptyTitle}</EmptyTitle>
            <EmptyDescription>{copy.emptyDescription}</EmptyDescription>
          </EmptyHeader>
        </Empty>
      )}

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-muted-foreground">
          {copy.pagination.summary}
        </p>
        <Pagination aria-label={copy.pagination.label} className="sm:w-auto">
          <PaginationContent>
            {pagination.previousUrl ? (
              <PaginationItem>
                <PaginationPrevious
                  href={pagination.previousUrl}
                  text={copy.pagination.previous}
                />
              </PaginationItem>
            ) : null}
            <PaginationItem>
              <PaginationLink href={urls.index} isActive>
                {pagination.currentPage}
              </PaginationLink>
            </PaginationItem>
            {pagination.nextUrl ? (
              <PaginationItem>
                <PaginationNext
                  href={pagination.nextUrl}
                  text={copy.pagination.next}
                />
              </PaginationItem>
            ) : null}
          </PaginationContent>
        </Pagination>
      </div>
    </AdminLayout>
  )
}

function formatTimestamp(value: string) {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value))
}

function statusVariant(status: string) {
  if (status === "failed" || status === "partially_failed") {
    return "destructive" as const
  }

  if (status === "running") {
    return "default" as const
  }

  return "secondary" as const
}
