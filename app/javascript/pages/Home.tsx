import { Head, Link, usePage } from "@inertiajs/react"
import { ArrowUpRight } from "lucide-react"
import { Button } from "@/components/ui/button"

import type { PageProps } from "@/types/inertia"

type PortfolioItem = {
  name: string
  description: string
  href: string
  created_by: string
}

type HomeProps = {
  // Optional so the SSR entrypoint can render the shell even if invoked
  // without these props (e.g. the SSR smoke test).
  web_apps?: PortfolioItem[]
  skill_repos?: PortfolioItem[]
  websites?: PortfolioItem[]
}

const DESCRIPTION =
  "A portfolio of the web apps, AI skills and agents, and websites I've built through online coursework and/or on my own."

function isExternal(href: string) {
  return /^https?:\/\//.test(href)
}

function PortfolioCard({ item }: { item: PortfolioItem }) {
  const className =
    "group block rounded-lg border border-hairline bg-surface p-5 no-underline transition-colors hover:border-accent"
  const body = (
    <>
      <div className="flex items-start justify-between gap-3">
        <h3 className="text-base font-semibold text-ink-display">{item.name}</h3>
        <ArrowUpRight className="mt-0.5 h-4 w-4 shrink-0 text-ink-muted transition-colors group-hover:text-accent" />
      </div>
      <p className="mt-2 text-sm text-ink-muted">{item.description}</p>
      <p className="mt-2 text-xs text-ink-muted">
        Created by {item.created_by}
      </p>
    </>
  )

  return isExternal(item.href) ? (
    <a
      href={item.href}
      target="_blank"
      rel="noreferrer noopener"
      className={className}
    >
      {body}
    </a>
  ) : (
    <Link href={item.href} className={className}>
      {body}
    </Link>
  )
}

function Section({
  title,
  items,
  twoUp = true,
}: {
  title: string
  items: PortfolioItem[]
  twoUp?: boolean
}) {
  return (
    <section>
      <h2 className="text-xl font-semibold text-ink-display">{title}</h2>
      <div
        className={
          twoUp
            ? "mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2"
            : "mt-5 grid grid-cols-1 gap-4"
        }
      >
        {items.map((item) => (
          <PortfolioCard key={item.name} item={item} />
        ))}
      </div>
    </section>
  )
}

export default function Home() {
  const { props } = usePage<PageProps<HomeProps>>()
  const { web_apps = [], skill_repos = [], websites = [] } = props

  return (
    <>
      <Head title="JeffreyApps">
        <meta name="description" content={DESCRIPTION} />
        <meta property="og:title" content="JeffreyApps" />
        <meta property="og:description" content={DESCRIPTION} />
      </Head>

      <div className="min-h-screen bg-page text-ink-body">
        <header className="border-b border-hairline">
          <div className="mx-auto flex max-w-3xl items-center justify-between px-4 py-4">
            <span className="font-display text-sm font-semibold text-ink-display">
              JeffreyApps
            </span>
            <div className="flex items-center gap-2">
              <Button asChild variant="ghost" size="sm">
                <Link href="/login">Log in</Link>
              </Button>
              <Button asChild size="sm">
                <Link href="/signup">Sign up</Link>
              </Button>
            </div>
          </div>
        </header>

        <main className="mx-auto max-w-3xl px-4 py-12">
          <h1>JeffreyApps</h1>
          <p className="mt-2 max-w-xl text-ink-muted">{DESCRIPTION}</p>

          <div className="mt-10">
            <Section title="Web Applications" items={web_apps} />
            <hr />
            <Section title="Skills / Agents" items={skill_repos} />
            <hr />
            <Section title="Website Development" items={websites} twoUp={false} />
          </div>
        </main>
      </div>
    </>
  )
}
