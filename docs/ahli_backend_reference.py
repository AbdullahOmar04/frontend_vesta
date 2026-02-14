# ===== AHLI BANK BACKEND REFERENCE (DO NOT RUN — for reference only) =====
# This file documents the backend endpoints used by the Ahli Bank integration.
# Backend is deployed on Render at the baseUrl from .env (API_URL).

# ─── Environment Variables ───
# COMPLY_HOST = "https://jo-comply.thefinx.io"
# VESTA_CLIENT_ID, VESTA_CLIENT_SECRET — OAuth client credentials
# FINX_INSTITUTION_APP_CODE — required header for Comply API calls
# AHLI_REDIRECT_URI — e.g. "https://backend-vesta.onrender.com/banks/ahli/callback"
# VESTA_SIGNING_KEY — RSA private key (PEM) for signing JWT request parameter
# FINX_OPENID_CONFIG_URL — OpenID discovery endpoint
# COMPLY_API_BASE — e.g. "https://jo-comply.thefinx.io/api/public/jo/v0.4"

# AHLI_PROVIDER_KEY = "ahli"
# AHLI_PROVIDER_LABEL = "Ahli"
# AHLI_SANDBOX = "finx"

# ─── Endpoints ───

# GET /banks/ahli/start_link/{uid}
# 1. Gets TPP token (client_credentials)
# 2. Creates account-access-consent (readAccounts, readBalances, readTransactions, etc.)
# 3. Generates PKCE pair (code_verifier, code_challenge)
# 4. Stores consent + state + code_verifier in Firestore (linkSessions/{state})
# 5. Builds signed JWT authorize URL with PKCE
# Returns: { "status": "ok", "consentId": "...", "authUrl": "..." }

# GET /banks/ahli/callback?code=...&state=...
# (HTMLResponse — meant to be loaded in WebView/browser)
# 1. Looks up linkSession by state → gets uid, code_verifier
# 2. Exchanges authorization code for PSU tokens (using code_verifier for PKCE)
# 3. Stores tokens in Firestore: users/{uid}.providers.ahli.tokens
# 4. Calls _ahli_sync_accounts_internal(uid) to sync accounts
# 5. Returns HTML: "Ahli linked successfully. You can close this window."
# On error: returns HTMLResponse with status 400
#   - If error param present: "Link failed: {error} {error_desc}"
#   - If missing code/state: "Missing code/state"
#   - If invalid state: "Invalid or expired state"

# GET /banks/ahli/sync_accounts/{uid}
# Re-syncs accounts from Comply API into Firestore
# - Deletes existing Ahli accounts, fetches fresh from /api/public/jo/v0.4/accounts
# - Each account stored at: users/{uid}/accounts/{accountId}
# - Account fields: all raw fields from API + provider="Ahli", sandbox="finx", linked=False
# - Updates users/{uid}.providers.ahli.totals
# Returns: { "status": "success", "accounts_synced": N, "totalBalance": ..., "currency": ... }

# GET /banks/ahli/get_account/{uid}/{account_id}
# Fetches single account from Comply API
# Returns: { "status": "success", "data": {...} }

# GET /banks/ahli/get_balances/{uid}/{account_id}
# Fetches balances for one account
# Returns: { "status": "success", "data": {...} }

# GET /banks/ahli/get_transactions/{uid}/{account_id}
# Fetches transactions for one account, stores new ones in Firestore
# - Stored at: users/{uid}/accounts/{account_id}/transactions/{transactionId}
# - Skips existing transactionIds
# - Transaction fields:
#   accountId, amount (float), currency, type (debit/credit),
#   date (settlementDateTime), merchantName, description,
#   source="openBanking", category=None, provider="Ahli", sandbox="finx", raw={...}
# Returns: { "status": "success", "transactions_synced": N }

# ─── Firestore Schema ───
# users/{uid}:
#   providers:
#     ahli:
#       provider: "Ahli"
#       sandbox: "finx"
#       consentId: "..."
#       state: "..." (cleared after callback)
#       tokens:
#         access_token: "..."
#         refresh_token: "..."
#         expires_at: "ISO8601"
#       linked: true
#       totals:
#         totalBalance: 123.45
#         currency: "JOD"
#
# users/{uid}/accounts/{accountId}:
#   provider: "Ahli"
#   sandbox: "finx"
#   linked: false (set to true by Flutter UI after user selects)
#   ... (all fields from Comply API: accountId, accountCurrency, availableBalance, etc.)
#   bankName, balanceAmount, currency, iban — may need mapping from raw fields
#
# users/{uid}/accounts/{accountId}/transactions/{transactionId}:
#   accountId, amount, currency, type, date, merchantName, description,
#   source, category, provider, sandbox, raw, syncedAt

# ─── Token Refresh ───
# _ensure_psu_access_token(uid) checks expiry, refreshes if <60s remaining
# Uses refresh_token grant with client credentials auth

# ─── Important Notes ───
# - Backend syncs accounts on callback automatically (linked=False initially)
# - Flutter UI sets linked=True for user-selected accounts
# - The callback returns HTML (not JSON) — WebView should intercept BEFORE it navigates
# - PKCE is required (S256) — code_verifier stored in linkSessions/{state}
# - The authorize URL includes a signed JWT "request" parameter (RS256)
