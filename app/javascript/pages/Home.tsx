import { Link, Head } from "@inertiajs/react"
import { Button } from "@/components/ui/button"

export default function Home() {
  return (
    <>
      <Head title="JeffreyApps">
        <meta
          name="description"
          content="JeffreyApps keeps your to-dos and your bookmarks together in one place, behind a single login."
        />
        <meta property="og:title" content="JeffreyApps" />
        <meta
          property="og:description"
          content="JeffreyApps keeps your to-dos and your bookmarks together in one place, behind a single login."
        />
      </Head>
      <main className="mx-auto flex min-h-screen max-w-2xl flex-col items-center justify-center px-4 py-16 text-center">
        <h1>JeffreyApps</h1>
        <p className="mt-2 max-w-md text-ink-muted">
          Your to-dos and bookmarks in one place.
        </p>
        <div className="mt-6 flex items-center gap-3">
          <Button asChild>
            <Link href="/signup">Sign up</Link>
          </Button>
          <Button asChild variant="secondary">
            <Link href="/login">Log in</Link>
          </Button>
        </div>
      </main>
    </>
  )
}
