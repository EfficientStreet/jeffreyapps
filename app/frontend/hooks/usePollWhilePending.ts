import * as React from "react"
import { router } from "@inertiajs/react"

const POLL_INTERVAL_MS = 3000

/**
 * While `pending` is true, quietly reloads the current Inertia page on an
 * interval so background state (e.g. a bookmark's AI summary) can flip from
 * "pending" to its final state without the user refreshing. Stops as soon as
 * `pending` becomes false.
 */
export function usePollWhilePending(pending: boolean, only?: string[]) {
  React.useEffect(() => {
    if (!pending) return

    const interval = setInterval(() => {
      // Inertia's reload() throws if `only` is present but undefined — it
      // must be omitted entirely for a full reload, not set to undefined.
      router.reload(only ? { only, showProgress: false } : { showProgress: false })
    }, POLL_INTERVAL_MS)

    return () => clearInterval(interval)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pending])
}
