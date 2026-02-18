#
######################################################CAPITAL BANK (CBOJ) ##########################################################
## Capital Bank has its own sandbox (not FINX Comply)
#CBOJ_CLIENT_ID = os.getenv("CBOJ_CLIENT_ID", "")
#CBOJ_CLIENT_SECRET = os.getenv("CBOJ_CLIENT_SECRET", "")
#CBOJ_REDIRECT_URI = os.getenv("CBOJ_REDIRECT_URI", "")
#CBOJ_SANDBOX_HOST = os.getenv("CBOJ_SANDBOX_HOST", "https://sandbox.api.capitalbank.jo:8448").rstrip("/")
#CBOJ_API_BASE = os.getenv("CBOJ_API_BASE", f"{CBOJ_SANDBOX_HOST}/ob/api/ais").rstrip("/")
#CBOJ_TOKEN_URL = os.getenv("CBOJ_TOKEN_URL", f"{CBOJ_SANDBOX_HOST}/ob/oauth2/token")
#CBOJ_AUTHORIZE_URL = os.getenv("CBOJ_AUTHORIZE_URL", f"{CBOJ_SANDBOX_HOST}/ob/web/login")
#
#CBOJ_PROVIDER_KEY = "capital"
#CBOJ_PROVIDER_LABEL = "Capital"
#CBOJ_SANDBOX = "capitalbank"
#
#
## ----------------------------
## CBOJ Helpers (Capital Bank direct sandbox — NOT FINX Comply)
## ----------------------------
#def _cboj_require_env() -> None:
#    missing = []
#    if not CBOJ_CLIENT_ID: missing.append("CBOJ_CLIENT_ID")
#    if not CBOJ_CLIENT_SECRET: missing.append("CBOJ_CLIENT_SECRET")
#    if not CBOJ_REDIRECT_URI: missing.append("CBOJ_REDIRECT_URI")
#    if missing:
#        raise HTTPException(status_code=500, detail=f"Missing env vars: {', '.join(missing)}")
#
#
#def _cboj_tpp_token() -> dict:
#    """Client credentials token from Capital Bank's own OAuth server."""
#    _cboj_require_env()
#    data = {
#        "grant_type": "client_credentials",
#        "client_id": CBOJ_CLIENT_ID,
#        "client_secret": CBOJ_CLIENT_SECRET,
#        "scope": "accounts",
#    }
#    r = requests.post(CBOJ_TOKEN_URL, data=data, timeout=20)
#    r.raise_for_status()
#    return r.json()
#
#
#def _cboj_create_consent(tpp_access_token: str, permissions: list[str],
#                         tx_from: datetime, tx_to: datetime) -> dict:
#    """
#    POST /account-access-consents
#    CBOJ spec requires transactionFromDateTime + transactionToDateTime.
#    Response returns consentRef (not consentId).
#    """
#    url = f"{CBOJ_API_BASE}/account-access-consents"
#    headers = {
#        "Authorization": f"Bearer {tpp_access_token}",
#        "x-interactions-id": str(uuid.uuid4()),
#        "Content-Type": "application/json",
#        "Accept": "application/json",
#    }
#    payload = {
#        "transactionFromDateTime": _iso(tx_from),
#        "transactionToDateTime": _iso(tx_to),
#        "permissions": permissions,
#    }
#    r = requests.post(url, headers=headers, json=payload, timeout=25)
#    r.raise_for_status()
#    return r.json()
#
#
#def _cboj_build_auth_url(*, consent_ref: str, state: str, code_challenge: str) -> str:
#    """
#    Build authorize URL for Capital Bank's direct sandbox.
#    Uses standard OAuth2 authorize — no JWT request param needed.
#    """
#    _cboj_require_env()
#
#    params = {
#        "client_id": CBOJ_CLIENT_ID,
#        "response_type": "code",
#        "redirect_uri": CBOJ_REDIRECT_URI,
#        "scope": "openid accounts",
#        "state": state,
#        "nonce": uuid.uuid4().hex,
#        "consentRef": consent_ref,
#        "code_challenge": code_challenge,
#        "code_challenge_method": "S256",
#    }
#    return f"{CBOJ_AUTHORIZE_URL}?{urlencode(params)}"
#
#
#def _cboj_exchange_code(*, code: str, code_verifier: str) -> dict:
#    """Exchange authorization code for PSU tokens."""
#    data = {
#        "grant_type": "authorization_code",
#        "client_id": CBOJ_CLIENT_ID,
#        "client_secret": CBOJ_CLIENT_SECRET,
#        "code": code,
#        "redirect_uri": CBOJ_REDIRECT_URI,
#        "code_verifier": code_verifier,
#    }
#    r = requests.post(CBOJ_TOKEN_URL, data=data, timeout=25)
#    r.raise_for_status()
#    return r.json()
#
#
#def _cboj_refresh_token(*, refresh_token: str) -> dict:
#    """Refresh an expired PSU access token."""
#    data = {
#        "grant_type": "refresh_token",
#        "client_id": CBOJ_CLIENT_ID,
#        "client_secret": CBOJ_CLIENT_SECRET,
#        "refresh_token": refresh_token,
#    }
#    r = requests.post(CBOJ_TOKEN_URL, data=data, timeout=25)
#    r.raise_for_status()
#    return r.json()
#
#
#def _cboj_headers_psu(psu_access_token: str) -> dict:
#    """Headers for CBOJ data APIs. Per YAML spec, x-interactions-id and
#    x-idempotency-key are both required."""
#    return {
#        "Authorization": f"Bearer {psu_access_token}",
#        "Accept": "application/json",
#        "x-interactions-id": str(uuid.uuid4()),
#        "x-idempotency-key": str(uuid.uuid4()),
#    }
#
#
#def _cboj_providers_ref(uid: str):
#    return db.collection("users").document(uid)
#
#
#def _cboj_write_provider_state(uid: str, data: dict):
#    user_ref = _cboj_providers_ref(uid)
#    user_ref.set(
#        {"providers": {CBOJ_PROVIDER_KEY: data}},
#        merge=True,
#    )
#
#
#def _cboj_read_provider_state(uid: str) -> dict:
#    snap = _cboj_providers_ref(uid).get()
#    d = snap.to_dict() or {}
#    return ((d.get("providers") or {}).get(CBOJ_PROVIDER_KEY) or {})
#
#
#def _cboj_ensure_psu_token(uid: str) -> str:
#    """Load stored PSU token for CBOJ; refresh if expired."""
#    st = _cboj_read_provider_state(uid)
#    tokens = st.get("tokens") or {}
#    access_token = tokens.get("access_token")
#    refresh_token = tokens.get("refresh_token")
#    expires_at = tokens.get("expires_at")
#
#    if not access_token:
#        raise HTTPException(status_code=400, detail="Capital Bank not linked yet. Start link first.")
#
#    if not expires_at:
#        return access_token
#
#    try:
#        exp = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
#    except Exception:
#        return access_token
#
#    if exp <= (_utc_now() + timedelta(seconds=60)) and refresh_token:
#        newt = _cboj_refresh_token(refresh_token=refresh_token)
#
#        new_access = newt.get("access_token", access_token)
#        new_refresh = newt.get("refresh_token", refresh_token)
#        ttl = int(newt.get("expires_in") or 0)
#        new_exp = _utc_now() + timedelta(seconds=max(ttl, 0))
#
#        _cboj_write_provider_state(uid, {
#            "sandbox": CBOJ_SANDBOX,
#            "tokens": {
#                "access_token": new_access,
#                "refresh_token": new_refresh,
#                "expires_at": _iso(new_exp),
#                "updatedAt": firestore.SERVER_TIMESTAMP,
#            }
#        })
#        return new_access
#
#    return access_token
#
#
## ----------------------------
## CBOJ ENDPOINTS
## ----------------------------
#
#@app.get("/banks/capital/start_link/{uid}")
#def capital_start_link(uid: str):
#    
#    #1) Get TPP token (client_credentials)
#    #2) Create consent with CBOJ-spec permissions
#    #3) Build auth URL for user to open in WebView/browser
#    
#    _cboj_require_env()
#
#    # PascalCase permissions per CBOJ YAML spec
#    permissions = [
#        "ReadAccounts",
#        "ReadBalances",
#        "ReadTransactions",
#        "ReadBeneficiaries",
#        "ReadStandingOrders&ScheduledPayments",
#    ]
#    tx_from = datetime(2000, 1, 1, tzinfo=timezone.utc)
#    tx_to = datetime(2052, 12, 2, tzinfo=timezone.utc)
#
#    tpp = _cboj_tpp_token()
#    tpp_access = tpp.get("access_token", "")
#    if not tpp_access:
#        raise HTTPException(status_code=500, detail="Failed to get CBOJ TPP access_token")
#
#    consent = _cboj_create_consent(tpp_access, permissions=permissions,
#                                   tx_from=tx_from, tx_to=tx_to)
#    # CBOJ uses consentRef (not consentId)
#    consent_ref = consent.get("consentRef") or consent.get("consentId")
#    if not consent_ref:
#        raise HTTPException(status_code=500, detail=f"Consent response missing consentRef: {consent}")
#
#    state = uuid.uuid4().hex
#    code_verifier, code_challenge = _pkce_pair()
#
#    _cboj_write_provider_state(uid, {
#        "provider": CBOJ_PROVIDER_LABEL,
#        "sandbox": CBOJ_SANDBOX,
#        "consentRef": consent_ref,
#        "state": state,
#        "status": consent.get("status"),
#        "permissions": permissions,
#        "createdAt": firestore.SERVER_TIMESTAMP,
#        "updatedAt": firestore.SERVER_TIMESTAMP,
#    })
#
#    db.collection("linkSessions").document(state).set({
#        "uid": uid,
#        "bank": CBOJ_PROVIDER_KEY,
#        "consentRef": consent_ref,
#        "code_verifier": code_verifier,
#        "createdAt": firestore.SERVER_TIMESTAMP,
#    })
#
#    auth_url = _cboj_build_auth_url(
#        consent_ref=consent_ref,
#        state=state,
#        code_challenge=code_challenge,
#    )
#
#    return {"status": "ok", "consentRef": consent_ref, "authUrl": auth_url}
#
#
#@app.get("/banks/capital/callback", response_class=HTMLResponse)
#def capital_callback(request: Request):
#    _cboj_require_env()
#
#    qp = dict(request.query_params)
#    code = (qp.get("code") or "").strip()
#    state = (qp.get("state") or "").strip()
#    error = (qp.get("error") or "").strip()
#    error_desc = (qp.get("error_description") or "").strip()
#
#    if error:
#        return HTMLResponse(f"Link failed: {error} {error_desc}", status_code=400)
#    if not code or not state:
#        return HTMLResponse("Missing code/state", status_code=400)
#
#    session_ref = db.collection("linkSessions").document(state)
#    session_snap = session_ref.get()
#    if not session_snap.exists:
#        return HTMLResponse("Invalid or expired state", status_code=400)
#
#    session = session_snap.to_dict() or {}
#    uid = (session.get("uid") or "").strip()
#    if not uid:
#        return HTMLResponse("Invalid session: missing uid", status_code=400)
#
#    code_verifier = (session.get("code_verifier") or "").strip()
#    if not code_verifier:
#        return HTMLResponse("Invalid session: missing code_verifier", status_code=400)
#
#    st = _cboj_read_provider_state(uid)
#    expected_state = (st.get("state") or "").strip()
#    if not expected_state or expected_state != state:
#        return HTMLResponse("Invalid state", status_code=400)
#
#    tokens = _cboj_exchange_code(code=code, code_verifier=code_verifier)
#
#    access_token = tokens.get("access_token")
#    refresh_token = tokens.get("refresh_token")
#    ttl = int(tokens.get("expires_in") or 0)
#    exp = _utc_now() + timedelta(seconds=max(ttl, 0))
#
#    if not access_token:
#        return HTMLResponse(f"Token exchange failed: {tokens}", status_code=400)
#
#    _cboj_write_provider_state(uid, {
#        "provider": CBOJ_PROVIDER_LABEL,
#        "sandbox": CBOJ_SANDBOX,
#        "consentRef": st.get("consentRef"),
#        "state": None,
#        "tokens": {
#            "access_token": access_token,
#            "refresh_token": refresh_token,
#            "expires_at": _iso(exp),
#            "updatedAt": firestore.SERVER_TIMESTAMP,
#        },
#        "linked": True,
#        "linkedAt": firestore.SERVER_TIMESTAMP,
#        "updatedAt": firestore.SERVER_TIMESTAMP,
#    })
#
#    session_ref.delete()
#
#    try:
#        _cboj_sync_accounts_internal(uid)
#    except Exception:
#        pass
#
#    return HTMLResponse(
#        "<h3>Capital Bank linked successfully.</h3><p>You can close this window and return to Vesta.</p>",
#        status_code=200,
#    )
#
#
#def _cboj_sync_accounts_internal(uid: str) -> dict:
#    #Fetch accounts from CBOJ and store in Firestore.
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#
#    body = r.json()
#    accounts = body.get("data") if isinstance(body, dict) else None
#    if accounts is None and isinstance(body, list):
#        accounts = body
#    if accounts is None:
#        accounts = []
#
#    user_ref = db.collection("users").document(uid)
#    accounts_ref = user_ref.collection("accounts")
#
#    # Delete only Capital Bank accounts
#    for doc in accounts_ref.stream():
#        d = doc.to_dict() or {}
#        if d.get("provider") == CBOJ_PROVIDER_LABEL and d.get("sandbox") == CBOJ_SANDBOX:
#            doc.reference.delete()
#
#    batch = db.batch()
#    total_balance = 0.0
#    currency = "JOD"
#
#    for acc in accounts:
#        account_id = str(acc.get("accountId") or "").strip()
#        if not account_id:
#            continue
#
#        # CBOJ schema: availableBalance is {amount, currency}
#        bal_obj = acc.get("availableBalance") or {}
#        raw_bal = bal_obj.get("amount")
#        try:
#            bal = float(raw_bal) if raw_bal is not None else 0.0
#        except Exception:
#            bal = 0.0
#
#        total_balance += bal
#        currency = (bal_obj.get("currency") or acc.get("currencies") or currency)
#
#        # IBAN from mainRoute.address
#        main_route = acc.get("mainRoute") or {}
#        iban = main_route.get("address") or ""
#
#        # Bank/institution name
#        inst = acc.get("institutionBasicInfo") or {}
#        bank_name = ((inst.get("name") or {}).get("enName") or "Capital Bank")
#
#        acc_type = acc.get("accountType") or {}
#
#        acc_doc = {
#            "accountId": account_id,
#            "provider": CBOJ_PROVIDER_LABEL,
#            "sandbox": CBOJ_SANDBOX,
#            "linked": False,
#            "bankName": bank_name,
#            "accountTypeCode": acc_type.get("code", ""),
#            "accountTypeName": acc_type.get("name", ""),
#            "balanceAmount": bal,
#            "currency": currency,
#            "iban": iban,
#            "accountStatus": acc.get("status", ""),
#            "lockedForDebit": bool(acc.get("lockedForDebit", False)),
#            "isSharedAccount": bool(acc.get("isSharedAccount", False)),
#            "syncedAt": firestore.SERVER_TIMESTAMP,
#        }
#
#        batch.set(accounts_ref.document(account_id), acc_doc, merge=True)
#
#    batch.set(
#        user_ref,
#        {
#            "providers": {
#                CBOJ_PROVIDER_KEY: {
#                    "totals": {
#                        "totalBalance": total_balance,
#                        "currency": currency,
#                        "updatedAt": firestore.SERVER_TIMESTAMP,
#                    }
#                }
#            }
#        },
#        merge=True,
#    )
#    batch.commit()
#
#    return {"accounts_synced": len(accounts), "totalBalance": total_balance, "currency": currency}
#
#
#@app.get("/banks/capital/sync_accounts/{uid}")
#def capital_sync_accounts(uid: str):
#    # Refresh accounts from Capital Bank
#    out = _cboj_sync_accounts_internal(uid)
#    return {"status": "success", **out}
#
#
#@app.get("/banks/capital/get_account/{uid}/{account_id}")
#def capital_get_account(uid: str, account_id: str):
#    # GET /accounts/{accountId}
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/{account_id}"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_account_by_iban/{uid}/{iban}")
#def capital_get_account_by_iban(uid: str, iban: str):
#    # GET /accounts/address/{accountAddress}?accountSchema=IBAN
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/address/{iban}"
#    r = requests.get(url, headers=headers, params={"accountSchema": "IBAN"}, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_balances/{uid}/{account_id}")
#def capital_get_balances(uid: str, account_id: str):
#    # GET /accounts/{accountId}/balances
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/{account_id}/balances"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_transactions/{uid}/{account_id}")
#def capital_get_transactions(uid: str, account_id: str):
#    
#    #Fetch transactions from CBOJ and store in Firestore.
#    #CBOJ schema: amount={amount,currency}, transactionDirection=credit/debit.
#    
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/{account_id}/transactions"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#
#    body = r.json()
#    txs = body.get("data") if isinstance(body, dict) else None
#    if txs is None and isinstance(body, list):
#        txs = body
#    if txs is None:
#        txs = []
#
#    account_ref = (
#        db.collection("users")
#          .document(uid)
#          .collection("accounts")
#          .document(account_id)
#    )
#    tx_ref = account_ref.collection("transactions")
#    existing_ids = {doc.id for doc in tx_ref.stream()}
#
#    batch = db.batch()
#    count = 0
#
#    for tx in txs:
#        tx_id = str(tx.get("transactionId") or "").strip()
#        if not tx_id or tx_id in existing_ids:
#            continue
#
#        # CBOJ schema: amount is {amount, currency}
#        amt_obj = tx.get("amount") or {}
#        raw_amount = amt_obj.get("amount")
#        try:
#            amount = float(raw_amount) if raw_amount is not None else 0.0
#        except Exception:
#            amount = 0.0
#        currency = amt_obj.get("currency") or "JOD"
#
#        # CBOJ uses transactionDirection (credit/debit)
#        direction = (tx.get("transactionDirection") or "debit").lower()
#        if direction not in ("debit", "credit"):
#            direction = "debit"
#
#        settlement_dt = tx.get("settlementDateTime") or tx.get("presentementDateTime")
#
#        doc_data = {
#            "accountId": account_id,
#            "amount": amount,
#            "currency": currency,
#            "type": direction,
#            "date": settlement_dt,
#            "transactionType": tx.get("transactionType"),
#            "status": tx.get("status"),
#            "source": "openBanking",
#            "category": None,
#            "provider": CBOJ_PROVIDER_LABEL,
#            "sandbox": CBOJ_SANDBOX,
#            "raw": tx,
#            "syncedAt": firestore.SERVER_TIMESTAMP,
#        }
#
#        batch.set(tx_ref.document(tx_id), doc_data, merge=False)
#        count += 1
#
#    batch.commit()
#    return {"status": "success", "transactions_synced": count}
#
#
#@app.get("/banks/capital/get_transaction/{uid}/{account_id}/{transaction_id}")
#def capital_get_transaction(uid: str, account_id: str, transaction_id: str):
#    #GET /accounts/{accountId}/transactions/{transactionId
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/{account_id}/transactions/{transaction_id}"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_beneficiaries/{uid}")
#def capital_get_beneficiaries(uid: str):
#    #GET /beneficiaries
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/beneficiaries"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_beneficiary/{uid}/{beneficiary_id}")
#def capital_get_beneficiary(uid: str, beneficiary_id: str):
#    #]GET /beneficiaries/{beneficiaryId 
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/beneficiaries/{beneficiary_id}"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_sosps/{uid}/{account_id}")
#def capital_get_sosps(uid: str, account_id: str):
#     #GET /accounts/{accountId}/sosp - Standing Orders & Scheduled Payments
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/{account_id}/sosp"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_sosp/{uid}/{account_id}/{sosp_id}")
#def capital_get_sosp(uid: str, account_id: str, sosp_id: str):
#    #GET /accounts/{accountId}/sosp/{sospId 
#    psu_token = _cboj_ensure_psu_token(uid)
#    headers = _cboj_headers_psu(psu_token)
#
#    url = f"{CBOJ_API_BASE}/accounts/{account_id}/sosp/{sosp_id}"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.get("/banks/capital/get_consent/{uid}")
#def capital_get_consent(uid: str):
#    #GET /account-access-consents/{consentRef} - Check consent status
#    st = _cboj_read_provider_state(uid)
#    consent_ref = st.get("consentRef")
#    if not consent_ref:
#        raise HTTPException(status_code=400, detail="No consent found for this user")
#
#    tpp = _cboj_tpp_token()
#    tpp_access = tpp.get("access_token", "")
#    headers = {
#        "Authorization": f"Bearer {tpp_access}",
#        "Accept": "application/json",
#        "x-interactions-id": str(uuid.uuid4()),
#    }
#
#    url = f"{CBOJ_API_BASE}/account-access-consents/{consent_ref}"
#    r = requests.get(url, headers=headers, timeout=25)
#    r.raise_for_status()
#    return {"status": "success", "data": r.json()}
#
#
#@app.delete("/banks/capital/revoke_consent/{uid}")
#def capital_revoke_consent(uid: str):
#    #DELETE /account-access-consents/{consentRef} - Revoke consent
#    st = _cboj_read_provider_state(uid)
#    consent_ref = st.get("consentRef")
#    if not consent_ref:
#        raise HTTPException(status_code=400, detail="No consent found for this user")
#
#    tpp = _cboj_tpp_token()
#    tpp_access = tpp.get("access_token", "")
#    headers = {
#        "Authorization": f"Bearer {tpp_access}",
#        "Accept": "application/json",
#        "x-interactions-id": str(uuid.uuid4()),
#    }
#
#    url = f"{CBOJ_API_BASE}/account-access-consents/{consent_ref}"
#    r = requests.delete(url, headers=headers, timeout=25)
#    r.raise_for_status()
#
#    _cboj_write_provider_state(uid, {
#        "linked": False,
#        "consentRef": None,
#        "tokens": None,
#        "revokedAt": firestore.SERVER_TIMESTAMP,
#        "updatedAt": firestore.SERVER_TIMESTAMP,
#    })
#
#    return {"status": "success", "message": "Consent revoked"}
#
#
#if __name__ == "__main__":
#    port = int(os.environ.get("PORT", 10000))  # Render sets PORT automatically
#    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
#