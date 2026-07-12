export type DashboardShowProps = {
  copy: {
    email: string
    heading: string
  }
}

export default function DashboardShow({ copy }: DashboardShowProps) {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto flex min-h-screen w-full max-w-3xl flex-col justify-center px-6 py-12">
        <div data-dashboard-page>
          <h1 className="text-3xl font-semibold">{copy.heading}</h1>
          <p className="mt-3 text-sm text-muted-foreground">{copy.email}</p>
        </div>
      </section>
    </main>
  )
}
