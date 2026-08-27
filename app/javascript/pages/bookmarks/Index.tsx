import { Head } from "@inertiajs/react"
import { AppShell } from "@/components/AppShell"

export default function BookmarksIndex() {
  return (
    <>
      <Head title="Bookmarks">
        <meta name="description" content="Your saved bookmarks in JeffreyApps." />
        <meta property="og:title" content="Bookmarks" />
        <meta property="og:description" content="Your saved bookmarks in JeffreyApps." />
      </Head>
      <AppShell>
        <h1>Bookmarks</h1>
        <p className="mt-2">Your bookmarks will live here.</p>
      </AppShell>
    </>
  )
}
