# Security Guide

## How your data is stored

| Data | Where | Visibility |
|------|-------|------------|
| Task titles & descriptions | GitHub Issues | Public |
| Task status | GitHub Labels | Public |
| Discussion / comments | Issue Comments | Public |
| Worker profiles | `workers/*.yml` files | Public |
| Payment / contact details | **Not stored publicly** | Private (exchanged via DM) |
| Your GitHub token | Your device only | Local |

## Key security measures

### 1. Payment info is never public

When a worker is accepted, the Gofer Bot prompts both parties to exchange payment details **privately** via GitHub DM or email. No payment info, phone numbers, or personal contact details are ever stored in issue comments.

### 2. Minimal token permissions

If using a Personal Access Token, create a **fine-grained token** with the minimum permissions:

1. Go to https://github.com/settings/tokens?type=beta
2. Click "Generate new token"
3. Set **Repository access** to "Only select repositories" → choose `LiuGus404/gofer-marketplace`
4. Set **Permissions**:
   - Issues: **Read and write** (to post/accept tasks)
   - Contents: **Read and write** (to register as worker)
   - All other permissions: **No access**
5. Set an **expiration date** (e.g., 90 days)

This ensures that even if your token is compromised, it can only affect the marketplace repo — not your other repos or account settings.

### 3. Local-only credential storage

Your GitHub token is stored using `flutter_secure_storage`:
- **iOS**: Keychain
- **Android**: EncryptedSharedPreferences (AES-256)
- **Web**: Encrypted localStorage

The token is never sent to any server other than `api.github.com`.

### 4. OAuth Device Flow (recommended)

If the marketplace has a registered GitHub OAuth App, the login uses the [Device Flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow):

1. You click "Connect with GitHub"
2. A one-time code appears (e.g., `ABCD-1234`)
3. You enter it on github.com in your browser
4. The app receives an OAuth token automatically

This is more secure than manual tokens because:
- You never copy/paste a token
- The token scope is controlled by the OAuth App
- You can revoke access at any time from GitHub Settings → Applications

## What to avoid

- **Never post payment details** (PayPal email, Venmo handle, crypto address) in public issue comments
- **Never share your GitHub token** with anyone
- **Don't use tokens with broad permissions** — always use fine-grained tokens scoped to this repo only
- **Set token expiration** — avoid "No expiration" tokens

## For sensitive tasks

If your task involves confidential information:

1. Keep the public issue **brief** — describe the task type and scope without revealing specifics
2. After a worker is accepted, share the detailed brief via **private channel** (GitHub DM, email, encrypted document)
3. Consider requiring the worker to sign an NDA before sharing sensitive details

## Revoking access

To revoke your token:
- **Personal Access Token**: Go to https://github.com/settings/tokens → delete the token
- **OAuth App**: Go to https://github.com/settings/applications → revoke access for "Gofer.ai"

## Reporting security issues

If you find a security vulnerability, please report it privately via GitHub Security Advisories or contact the maintainer directly. Do not post security issues publicly.
