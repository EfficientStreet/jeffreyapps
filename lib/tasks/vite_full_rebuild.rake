# Force a genuinely fresh Vite build on every deploy.
#
# vite_ruby's Builder#build skips rebuilding whenever a digest of the
# watched source files matches the digest recorded in its persisted
# cache (config.build_cache_dir, which lives under tmp/cache/vite).
# On Hatchbox, tmp/ is symlinked to the app's `shared/` directory, so
# that cache digest survives across releases — but the actual build
# *output* (public/vite/ and public/vite-ssr/) lives inside each
# release's own directory, which is NOT shared and starts empty on
# every deploy.
#
# The result: if no watched source file changed since the last deploy,
# vite_ruby logs "Skipping vite build" and never writes ssr.js (or the
# client manifest) into the new release at all, even though it isn't
# there. This showed up in production as a crash-looping SSR process:
# `No ssr entrypoint found... Have you run bin/vite build --ssr?`
#
# Clearing the cache before every precompile makes vite_ruby check for
# real, every time — adding roughly a minute to each deploy in
# exchange for actually correct output. `vite:clobber` is enhanced
# as a genuine prerequisite (not just an enhance block) so it always
# runs before vite_ruby's own build step, regardless of rake file load
# order.
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance([ "vite:clobber" ])
end
