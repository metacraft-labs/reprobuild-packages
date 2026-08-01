import repro_project_dsl

package reprobuildPackages:
  devEnv:
    task "check",
      command = "pwsh -NoProfile -File scripts/check-catalog.ps1",
      description = "Validate package catalog structure"
