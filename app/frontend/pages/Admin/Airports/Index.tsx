import { router } from "@inertiajs/react"
import { PencilIcon, PlaneIcon, Trash2Icon } from "lucide-react"

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
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

import AdminLayout, { type AdminNavigationSection } from "../AdminLayout"

export interface AdminAirportRow {
  countryCode: string
  destroyUrl: string
  editUrl: string
  iataCode: string | null
  icaoCode: string | null
  municipalityName: string | null
  name: string
  operationalStatus: string
  placeId: string
  timeZone: string | null
}

export interface AdminAirportsIndexPageProps {
  airports: AdminAirportRow[]
  copy: {
    actions: { cancel: string; delete: string; edit: string }
    columns: {
      actions: string
      airport: string
      codes: string
      country: string
      status: string
      timeZone: string
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
    tableCaption: string
    title: string
    toolbarLabel: string
    statuses: Record<string, string>
  }
  navigation: { sections: AdminNavigationSection[] }
  pagination: {
    currentPage: number
    nextUrl: string | null
    previousUrl: string | null
    totalCount: number
    totalPages: number
  }
  urls: { index: string }
}

export default function Index({
  airports,
  copy,
  navigation,
  pagination,
  urls,
}: AdminAirportsIndexPageProps) {
  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      {airports.length > 0 ? (
        <div className="overflow-hidden rounded-lg border bg-background">
          <Table>
            <TableCaption>{copy.tableCaption}</TableCaption>
            <TableHeader>
              <TableRow>
                <TableHead>{copy.columns.airport}</TableHead>
                <TableHead>{copy.columns.codes}</TableHead>
                <TableHead>{copy.columns.country}</TableHead>
                <TableHead>{copy.columns.status}</TableHead>
                <TableHead>{copy.columns.timeZone}</TableHead>
                <TableHead className="text-right">
                  {copy.columns.actions}
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {airports.map((airport) => (
                <TableRow key={airport.placeId}>
                  <TableCell className="min-w-64">
                    <div className="flex min-w-0 flex-col gap-1">
                      <span className="font-medium">{airport.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {airport.municipalityName ?? "—"}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-col gap-1 text-sm">
                      <span>{airport.iataCode ?? "—"}</span>
                      <span className="text-xs text-muted-foreground">
                        {airport.icaoCode ?? "—"}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>{airport.countryCode}</TableCell>
                  <TableCell>
                    <Badge
                      variant={
                        airport.operationalStatus === "closed"
                          ? "destructive"
                          : "secondary"
                      }
                    >
                      {copy.statuses[airport.operationalStatus] ??
                        airport.operationalStatus}
                    </Badge>
                  </TableCell>
                  <TableCell>{airport.timeZone ?? "—"}</TableCell>
                  <TableCell>
                    <div className="flex justify-end gap-1">
                      <Button
                        asChild
                        aria-label={`${copy.actions.edit}: ${airport.name}`}
                        size="icon-sm"
                        variant="ghost"
                      >
                        <a href={airport.editUrl}>
                          <PencilIcon aria-hidden="true" />
                        </a>
                      </Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild>
                          <Button
                            aria-label={`${copy.actions.delete}: ${airport.name}`}
                            size="icon-sm"
                            variant="ghost"
                          >
                            <Trash2Icon aria-hidden="true" />
                          </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader>
                            <AlertDialogTitle>
                              {copy.actions.delete}
                            </AlertDialogTitle>
                            <AlertDialogDescription>
                              {airport.name}
                            </AlertDialogDescription>
                          </AlertDialogHeader>
                          <AlertDialogFooter>
                            <AlertDialogCancel>
                              {copy.actions.cancel}
                            </AlertDialogCancel>
                            <AlertDialogAction
                              onClick={() => router.delete(airport.destroyUrl)}
                              variant="destructive"
                            >
                              {copy.actions.delete}
                            </AlertDialogAction>
                          </AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
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
              <PlaneIcon aria-hidden="true" />
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
