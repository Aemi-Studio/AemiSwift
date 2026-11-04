# CI

`.github/workflows/ci.yml` calls the family's pinned swift-ci workflow, configured by `action.json`; run the same
checks locally with `.ci/swift-ci local`.

This is a compatibility package: it re-exports aemi's modules under their former names. Each change runs quality
(the analyzers) and the macOS debug tests on Swift 6.4.1 and 6.3.3 (Xcode 26.6), each after
`swift package update`, so the shim is tested against the latest published dependencies, as before. aemi's
modules need Apple frameworks, so there is no Linux leg. Release and sanitizer runs are nightly (when a commit
landed) or manual.
