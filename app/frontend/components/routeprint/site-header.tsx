import { Link } from "@inertiajs/react"
import {
  ChevronDownIcon,
  CircleUserRoundIcon,
  LogOutIcon,
  PlaneTakeoffIcon,
} from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

import type { ShellProps } from "./app-shell"

export default function SiteHeader({
  authenticated,
  labels,
  urls,
}: ShellProps) {
  return (
    <header
      className="sticky top-0 z-50 border-b border-border/70 bg-background/95 shadow-md backdrop-blur"
      data-ui="site-header"
    >
      <div className="mx-auto flex h-16 w-full max-w-[120rem] items-center gap-4 px-4 sm:px-6 lg:px-8">
        <Link
          aria-label={labels.brandName}
          className="group flex items-center gap-2.5 rounded-md outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          href={urls.home}
        >
          <span className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm transition-transform group-hover:-rotate-6">
            <PlaneTakeoffIcon aria-hidden="true" className="size-4" />
          </span>
          <span className="text-lg font-semibold tracking-tight">
            {labels.brandName}
          </span>
        </Link>

        <div className="ml-auto">
          {authenticated ? (
            <AccountMenu labels={labels} urls={urls} />
          ) : (
            <Button asChild className="rounded-full px-4" size="lg">
              <Link href={urls.signIn}>{labels.signIn}</Link>
            </Button>
          )}
        </div>
      </div>
    </header>
  )
}

function AccountMenu({ labels, urls }: Pick<ShellProps, "labels" | "urls">) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          aria-label={labels.accountMenu}
          className="rounded-full px-4"
          size="lg"
          variant="outline"
        >
          <CircleUserRoundIcon aria-hidden="true" data-icon="inline-start" />
          <span className="hidden sm:inline">{labels.accountMenu}</span>
          <ChevronDownIcon aria-hidden="true" data-icon="inline-end" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem asChild>
          <Link as="button" href={urls.signOut} method="delete" type="button">
            <LogOutIcon aria-hidden="true" data-icon="inline-start" />
            {labels.signOut}
          </Link>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
