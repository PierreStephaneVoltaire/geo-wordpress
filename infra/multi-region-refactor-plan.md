# Plan to Generalize Multi-Region Logic in Terraform

## Variables Changes
- Replace the current `regions` and `vpc_cidrs` variables with a single `geo_regions` object variable:
  - `primary`: string (e.g., "singapore")
  - `secondary`: list(string) (e.g., ["ireland"])
  - `all`: map(string) (e.g., { singapore = "ap-southeast-1", ireland = "eu-west-1" })
  - `vpc_cidrs`: map(string) (e.g., { singapore = "10.0.0.0/16", ireland = "10.1.0.0/16" })

## Resource/Module Instantiation Logic
- Use the `primary` region for all primary resources (e.g., main DB, compute, etc.).
- Use `for_each` with the `secondary` list to create replicas and secondary compute modules.
- Use `for_each` with `all` or a combined list for shared resources (e.g., networking, security).
- Pass region-specific values using lookups from the `geo_regions` and `vpc_cidrs` maps.
- Update module blocks to use `for_each` and reference `each.key` for region-specific logic.
- Remove all hardcoded region names from resource/module names and logic.

## Outputs and Data
- Update outputs and data sources to use dynamic keys and maps where needed.

---
This plan will allow you to add or remove regions by editing a single variable, and all region-dependent resources will be created automatically.
