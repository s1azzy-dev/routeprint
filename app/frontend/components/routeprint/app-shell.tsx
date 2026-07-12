import type { ReactNode } from "react"

import SiteHeader from "./site-header"

export type ShellProps = {
  authenticated: boolean
  labels: {
    accountMenu: string
    brandName: string
    signIn: string
    signOut: string
  }
  urls: {
    home: string
    signIn: string
    signOut: string
  }
}

type AppShellProps = {
  children: ReactNode
  shell: ShellProps
}

export default function AppShell({ children, shell }: AppShellProps) {
  return (
    <div className="min-h-dvh bg-background text-foreground">
      <SiteHeader {...shell} />
      {children}
    </div>
  )
}
