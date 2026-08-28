import * as React from "react"
import { AppFooter } from "@/components/AppFooter"
import { MainNav } from "@/components/MainNav"

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-page text-ink-body">
      <MainNav />
      <main className="flex min-w-0 flex-1 flex-col px-6 py-8 sm:px-10">
        <div className="mx-auto w-full max-w-4xl flex-1">{children}</div>
        <AppFooter />
      </main>
    </div>
  )
}
