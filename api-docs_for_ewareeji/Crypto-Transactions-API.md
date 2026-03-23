# Crypto Transactions API

API for managing crypto transactions: buy/sell operations between customer wallets and company wallets, with fiat/crypto amounts, rate, and status.

---

## Base URL

```
/api/admin/crypto/transactions
```

Example (local): `http://localhost:5000/api/admin/crypto/transactions`

---

## Authentication

All endpoints require:

- **Authentication:** Valid access token (cookie `accessToken` or `Authorization: Bearer <token>`).
- **Authorization:** Permission on route `crypto/transactions` for the required action (`view`, `create`, `edit`, `delete`).

Unauthenticated requests receive `401`. Insufficient permissions receive `403`.

---

## Response envelope

- **Success:** `{ "success": true, "data": ... }`
- **Error:** `{ "success": false, "error": "<message>" }`

---

## Dependencies

- **Customer wallets:** Transactions reference **customer_wallets** from the [Crypto Customer Wallets API](Crypto-Customer-Wallets-API.md). Ensure customer wallet records exist before creating transactions.
- **Company wallets:** Transactions reference **company_wallets** (by `company_wallet_id` / `account_id`). Ensure company wallet records exist before creating transactions.
- **Rates:** The **rate** (and optionally **spread_amount**) for a transaction are typically derived from the [Crypto Rates API](Crypto-Rates-API.md). See *Rate and spread from Rates API* below.

---

## Rate and spread from Rates API

When recording a BUY or SELL transaction, clients usually obtain the rate from the **Rates API** rather than entering it manually:

1. **Fetch active rates** for the wallet: `GET /api/admin/crypto/rates?wallet_id={wallet_id}&active=true`.
2. **Select the rate** whose **amount range** includes the fiat amount: `min_amount <= fiat_amount <= max_amount` (null `min_amount`/`max_amount` means no lower/upper bound). If multiple rates match, use the one with the latest `rate_date`.
3. **Use** `buy_rate` for **BUY** transactions and `sell_rate` for **SELL** transactions as the transaction `rate`.
4. **Compute** `crypto_amount = fiat_amount / rate`.
5. **Compute** `spread_amount = |buy_rate - sell_rate| * crypto_amount` from the same rate row (optional but recommended).

The transaction is then created with the resulting `rate`, `crypto_amount`, and `spread_amount`.

---

## Endpoints

### 1. List transactions

**GET** `/api/admin/crypto/transactions`

Returns transactions, ordered by `created_at` DESC then `id` DESC.

**Query parameters**

| Parameter            | Type   | Description                          |
|----------------------|--------|--------------------------------------|
| `wallet_account_id`  | number | Optional. Filter by wallet account   |
| `customer_wallet_id` | number | Optional. Filter by customer wallet |
| `company_wallet_id`  | number | Optional. Filter by company wallet  |
| `type`               | string | Optional. Filter by type (buy/sell) |
| `status`             | string | Optional. Filter by status           |

**Example request**

```http
GET /api/admin/crypto/transactions
GET /api/admin/crypto/transactions?type=buy
GET /api/admin/crypto/transactions?status=pending
GET /api/admin/crypto/transactions?customer_wallet_id=1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "wallet_account_id": 1,
      "type": "BUY",
      "customer_wallet_id": 1,
      "company_wallet_id": 1,
      "fiat_amount": 1000,
      "crypto_amount": 950,
      "rate": 1.05,
      "spread_amount": 10,
      "status": "completed",
      "created_at": "2025-03-04T12:00:00.000Z"
    }
  ]
}
```

---

### 2. Get transaction by ID

**GET** `/api/admin/crypto/transactions/:id`

**Path parameters**

| Name | Type   | Description       |
|------|--------|-------------------|
| `id` | number | Transaction ID    |

**Example request**

```http
GET /api/admin/crypto/transactions/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 1,
    "type": "BUY",
    "customer_wallet_id": 1,
    "company_wallet_id": 1,
    "fiat_amount": 1000,
    "crypto_amount": 950,
    "rate": 1.05,
    "spread_amount": 10,
    "status": "completed",
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Transaction not found"
}
```

---

### 3. Create transaction

**POST** `/api/admin/crypto/transactions`

**Required permission:** `create` on `crypto/transactions`.

**Request body (JSON)**

| Field                | Type   | Required | Description                                      |
|----------------------|--------|----------|--------------------------------------------------|
| `wallet_account_id`  | number | Yes      | Wallet account ID                                |
| `type`               | string | Yes      | Transaction type: `buy`, `sell`, `BUY`, or `SELL`|
| `customer_wallet_id` | number | Yes      | Customer wallet ID (FK to customer_wallets)     |
| `company_wallet_id`  | number | Yes      | Company wallet ID (FK to company_wallets)       |
| `fiat_amount`        | number | Yes      | Fiat amount; must be non-negative               |
| `crypto_amount`      | number | Yes      | Crypto amount; must be non-negative              |
| `rate`               | number | Yes      | Rate used; must be non-negative                  |
| `spread_amount`      | number | No       | Spread amount; default `0`                       |
| `status`             | string | No       | Status; default `pending`                        |

**Example request**

```http
POST /api/admin/crypto/transactions
Content-Type: application/json

{
  "wallet_account_id": 1,
  "type": "BUY",
  "customer_wallet_id": 1,
  "company_wallet_id": 1,
  "fiat_amount": 1000,
  "crypto_amount": 950,
  "rate": 1.05,
  "spread_amount": 10,
  "status": "pending"
}
```

**Success response** `201 Created`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 1,
    "type": "BUY",
    "customer_wallet_id": 1,
    "company_wallet_id": 1,
    "fiat_amount": 1000,
    "crypto_amount": 950,
    "rate": 1.05,
    "spread_amount": 10,
    "status": "pending",
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — missing required fields

  ```json
  { "success": false, "error": "wallet_account_id, type, customer_wallet_id, company_wallet_id, fiat_amount, crypto_amount and rate are required" }
  ```

- `400 Bad Request` — negative amounts or invalid type

  ```json
  { "success": false, "error": "fiat_amount, crypto_amount and rate must be non-negative" }
  ```

  ```json
  { "success": false, "error": "type must be one of: buy, sell, BUY, SELL" }
  ```

- `500` — database/constraint errors (e.g. invalid FK)  
  `{ "success": false, "error": "<message>" }`

---

### 4. Update transaction

**PUT** `/api/admin/crypto/transactions/:id`

**Required permission:** `edit` on `crypto/transactions`.

**Path parameters**

| Name | Type   | Description       |
|------|--------|-------------------|
| `id` | number | Transaction ID    |

**Request body (JSON)**  
All fields optional; only sent fields are updated.

| Field                | Type   | Description                          |
|----------------------|--------|--------------------------------------|
| `wallet_account_id`  | number | Wallet account ID                   |
| `type`               | string | One of: buy, sell, BUY, SELL         |
| `customer_wallet_id` | number | Customer wallet ID                   |
| `company_wallet_id`  | number | Company wallet ID                    |
| `fiat_amount`        | number | Fiat amount; must be non-negative   |
| `crypto_amount`      | number | Crypto amount; must be non-negative  |
| `rate`               | number | Rate; must be non-negative          |
| `spread_amount`      | number | Spread amount; 0 or empty to clear   |
| `status`             | string | Status (e.g. pending, completed)     |

**Example request**

```http
PUT /api/admin/crypto/transactions/1
Content-Type: application/json

{
  "status": "completed",
  "spread_amount": 12
}
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 1,
    "type": "BUY",
    "customer_wallet_id": 1,
    "company_wallet_id": 1,
    "fiat_amount": 1000,
    "crypto_amount": 950,
    "rate": 1.05,
    "spread_amount": 12,
    "status": "completed",
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — negative fiat_amount, crypto_amount or rate; or invalid type  
  `{ "success": false, "error": "<message>" }`
- `404 Not Found` — transaction not found  
  `{ "success": false, "error": "Transaction not found" }`

---

### 5. Delete transaction

**DELETE** `/api/admin/crypto/transactions/:id`

**Required permission:** `delete` on `crypto/transactions`.

**Path parameters**

| Name | Type   | Description       |
|------|--------|-------------------|
| `id` | number | Transaction ID    |

**Example request**

```http
DELETE /api/admin/crypto/transactions/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "message": "Transaction deleted"
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Transaction not found"
}
```

---

### 6. Approve transaction

**POST** `/api/admin/crypto/transactions/:id/approve`

Sets the transaction status to `completed`. Only transactions with status `pending` can be approved.

**Required permission:** `edit` on `crypto/transactions`.

**Path parameters**

| Name | Type   | Description       |
|------|--------|-------------------|
| `id` | number | Transaction ID    |

**Example request**

```http
POST /api/admin/crypto/transactions/1/approve
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 1,
    "type": "BUY",
    "customer_wallet_id": 1,
    "company_wallet_id": 1,
    "fiat_amount": 1000,
    "crypto_amount": 950,
    "rate": 1.05,
    "spread_amount": 10,
    "status": "completed",
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — transaction is not pending  
  `{ "success": false, "error": "Transaction is not pending. Only pending transactions can be approved." }`
- `404 Not Found` — transaction not found  
  `{ "success": false, "error": "Transaction not found" }`

---

### 7. Reject transaction

**POST** `/api/admin/crypto/transactions/:id/reject`

Sets the transaction status to `rejected`. Only transactions with status `pending` can be rejected.

**Required permission:** `edit` on `crypto/transactions`.

**Path parameters**

| Name | Type   | Description       |
|------|--------|-------------------|
| `id` | number | Transaction ID    |

**Request body (JSON)** — optional

| Field               | Type   | Description                    |
|---------------------|--------|--------------------------------|
| `rejection_reason`  | string | Optional reason for rejection  |

**Example request**

```http
POST /api/admin/crypto/transactions/1/reject
Content-Type: application/json

{
  "rejection_reason": "Insufficient verification"
}
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 1,
    "type": "BUY",
    "customer_wallet_id": 1,
    "company_wallet_id": 1,
    "fiat_amount": 1000,
    "crypto_amount": 950,
    "rate": 1.05,
    "spread_amount": 10,
    "status": "rejected",
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — transaction is not pending  
  `{ "success": false, "error": "Transaction is not pending. Only pending transactions can be rejected." }`
- `404 Not Found` — transaction not found  
  `{ "success": false, "error": "Transaction not found" }`

---

## Data model (transaction)

| Field                | Type   | Description                                |
|----------------------|--------|--------------------------------------------|
| `id`                 | number | Primary key                                |
| `wallet_account_id`  | number | Wallet account reference                   |
| `type`               | string | Transaction type (buy/sell, BUY/SELL)      |
| `customer_wallet_id` | number | FK to customer_wallets(id)                 |
| `company_wallet_id`  | number | FK to company_wallets(account_id)          |
| `fiat_amount`        | number | Fiat amount (non-negative)                 |
| `crypto_amount`      | number | Crypto amount (non-negative)               |
| `rate`               | number | Rate used (non-negative)                   |
| `spread_amount`      | number | Spread amount; default 0. Often computed as \|buy_rate − sell_rate\| × crypto_amount from the rate row. |
| `status`             | string | e.g. pending, completed, rejected           |
| `created_at`         | string | Timestamp (set on insert)                  |

---

## Database schema reference

Table: `public.transactions`

- `id` — bigint PK, default `nextval('transactions_id_seq')`
- `wallet_account_id` — bigint NOT NULL
- `type` — transaction_type NOT NULL (enum)
- `customer_wallet_id` — bigint NOT NULL, FK → customer_wallets(id)
- `company_wallet_id` — bigint NOT NULL, FK → company_wallets(account_id)
- `fiat_amount` — numeric(18,2) NOT NULL
- `crypto_amount` — numeric(18,8) NOT NULL
- `rate` — numeric(18,8) NOT NULL
- `spread_amount` — numeric(18,8) DEFAULT 0
- `status` — transaction_status DEFAULT 'pending'
- `created_at` — timestamp DEFAULT CURRENT_TIMESTAMP

---

## Frontend proxy (Next.js)

When using the Next.js app, the frontend calls the same paths under the app origin; the Next.js API routes proxy to the backend:

- **GET/POST** `/api/admin/crypto/transactions` → backend `GET/POST /api/admin/crypto/transactions`
- **GET/PUT/DELETE** `/api/admin/crypto/transactions/[id]` → backend `GET/PUT/DELETE /api/admin/crypto/transactions/:id`
- **POST** `/api/admin/crypto/transactions/[id]/approve` → backend `POST /api/admin/crypto/transactions/:id/approve`
- **POST** `/api/admin/crypto/transactions/[id]/reject` → backend `POST /api/admin/crypto/transactions/:id/reject`

Authentication is preserved via the forwarded `Authorization` header (Bearer token).
