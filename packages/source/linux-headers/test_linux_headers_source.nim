import std/unittest
import repro_project_dsl
import ./repro

suite "Linux UAPI headers source recipe":
  test "pins the official kernel release archive":
    let spec = registeredFetchSpec("linuxHeadersSource")
    check spec.kind == dfkTarball
    check spec.url == "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.142.tar.xz"
    check spec.hashAlg == dshaSha256
    check spec.hashHex == "b2f6607a75cd27b2e368cf2d25e1637e1e0da9dfed4cda536658879eee6f2b70"
    check spec.extractStrip == 1

  test "declares the compiler and tools used by headers_install":
    let dependencies = registeredAuthoredNativeBuildDeps("linuxHeadersSource")
    for tool in ["gcc >=11", "make >=4.3", "rsync"]:
      check tool in dependencies

  test "exports the header-prefix discovery tool":
    let artifacts = registeredArtifacts("linuxHeadersSource")
    require artifacts.len == 1
    check artifacts[0].packageName == "linuxHeadersSource"
    check artifacts[0].artifactName == "linux-headers"
    check artifacts[0].kind == dakExecutable
