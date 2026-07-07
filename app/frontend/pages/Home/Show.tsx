type HomeShowProps = {
  appName: string
}

export default function HomeShow({ appName }: HomeShowProps) {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <section className="mx-auto flex min-h-screen w-full max-w-5xl flex-col justify-center px-6 py-12">
        <div className="max-w-2xl">
          <p className="text-sm font-medium uppercase tracking-wide text-muted-foreground">
            Rails / Inertia / React
          </p>
          <h1 className="mt-4 text-4xl font-semibold sm:text-5xl">{appName}</h1>
          <p className="mt-5 text-lg leading-8 text-muted-foreground">
            The Routeprint foundation is ready for the first SDD-controlled
            business slice.
          </p>
        </div>
      </section>
    </main>
  )
}
