# [GHSA-ID]: [Short, Descriptive Title of Vulnerability]

## Summary
*Provide a high-level overview of the issue (e.g., "SQL Injection in the Authentication module").*

## Impact
* **Vulnerability Type:** (e.g., Remote Code Execution, Cross-Site Scripting)
* **Severity:** [Critical / High / Moderate / Low]
* **Description:** Describe how an attacker could exploit this. Keep it technical but objective.
* **Affected Components:** List the specific files, functions, or API endpoints involved.

## Affected Versions
* **Vulnerable:** `< 1.0.2`, `1.0.1 - 1.0.3`
* **Not Vulnerable:** `1.0.2+`

## Mitigation / Workarounds
*If a patch is not yet available or cannot be applied immediately, provide temporary steps users can take to protect themselves (e.g., "Disable the legacy API endpoint in your configuration").*

## Proof of Concept (PoC)
*Provide a minimal example to reproduce the issue. This section is usually kept private until the fix is published.*

```bash
# Example steps to reproduce (keep this brief)
curl -X POST http://localhost:3000/api/v1/auth -d '{"user": {"$gt": ""}}'
```

## Patch Details
* **Fixed in version:** `v1.0.3`
* **Commit Hash:** `[Insert Hash]`

## Credits
We would like to thank **[Researcher Name/Handle]** for discovering and responsibly reporting this vulnerability.
