# Mozilla Trust Bundle

`cacert-2026-07-16.pem` is the unmodified source-data bundle published at
<https://curl.se/ca/cacert-2026-07-16.pem>.

SHA-256: `3ff344e30b9b1ed2971044eabb438a08f2e2245ddb5f8ab1a3ad8b63ab4eaf91`.
The package retains its existing version and source pin. The upstream PEM is
licensed under MPL 2.0, as documented by the publisher at
<https://curl.se/docs/caextract.html>. Its upstream source location and conversion
details are preserved in the PEM header.

This is certificate data, not a prebuilt executable. Keeping the pinned input
in the source checkout lets the graph install it before any HTTPS downloader
that needs this very bundle. No host trust store is copied and no network or
compiler action is needed to install it. Provider compilation verifies the
SHA-256; the build declares the PEM as an input to both file-copy actions.
The compatibility path is a second copy, so the recipe also works on hosts
without symlink privileges. `.gitattributes` preserves exact bytes on Windows.

When updating the bundle, update the dated source file, version, source pin,
checksum and recipe tests together. Do not edit the upstream PEM contents.
