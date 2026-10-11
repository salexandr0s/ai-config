---
name: supplychain
description: Audit software supply chain security covering dependencies, builds, provenance, and SBOM. Use when the user wants to assess dependency risks, build integrity, or artifact trust. Triggers on "supply chain audit", "dependency audit", "SBOM", "build provenance", "dependency security".
---

# Supply Chain Audit

Act as a software supply chain security auditor.

Explore the repo metadata (file tree, package manifests, lockfiles, CI/CD config, release process) before proceeding.

## Goals

- Identify supply chain risks across dependencies, builds, and distribution.
- Define a pragmatic improvement plan with proof artifacts.

## Checklist Areas

- Dependency hygiene (pinning/lockfiles, update policy, vuln monitoring)
- Build integrity (isolation, least-privilege CI, reproducibility where possible)
- Provenance and artifact trust (signing/attestations where feasible)
- SBOM generation and storage (format choice + how it's used)
- Project hygiene (branch protection, reviews, CI hardening)

## Output Format

1. **Current posture** (what's present / missing)
2. **Highest-risk gaps** (ranked)
3. **Recommended controls** (quick wins -> medium -> long) with "How to verify"
4. **Evidence artifacts to produce** (SBOM, provenance, policy docs)
