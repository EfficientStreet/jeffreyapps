import { Head } from "@inertiajs/react"
import { AppShell } from "@/components/AppShell"

export default function Todos() {
  return (
    <>
      <Head title="To-Dos">
        <meta name="description" content="Your to-do list in JeffreyApps." />
        <meta property="og:title" content="To-Dos" />
        <meta property="og:description" content="Your to-do list in JeffreyApps." />
      </Head>
      <AppShell>
        <h1>To-Dos</h1>
        <p className="mt-2">Your to-dos will live here.</p>
      </AppShell>
    </>
  )
}
