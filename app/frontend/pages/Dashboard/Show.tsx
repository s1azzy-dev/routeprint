import { Link } from "@inertiajs/react"

import { Button } from "@/components/ui/button"

export type DashboardShowProps = {
  copy: {
    email: string
    heading: string
    signOut: string
  }
  urls: {
    signOut: string
  }
}

export default function DashboardShow({ copy, urls }: DashboardShowProps) {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto flex min-h-screen w-full max-w-3xl flex-col justify-center px-6 py-12">
        <div data-dashboard-page>
          <h1 className="text-3xl font-semibold">{copy.heading}</h1>
          <p className="mt-3 text-sm text-muted-foreground">{copy.email}</p>
          <Button asChild className="mt-8" variant="outline">
            <Link as="button" href={urls.signOut} method="delete" type="button">
              {copy.signOut}
            </Link>
          </Button>
        </div>
      </section>
    </main>
  )
}
