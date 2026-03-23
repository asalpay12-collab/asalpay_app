# Crypto Rates API

API for managing buy/sell rates for crypto wallets. A **wallet can have multiple active rates**, each applying to a different **amount range** (min_amount–max_amount). For example, BEP20 might have one rate for 10–1000 and another for 1001–10000. When creating a transaction, use the **for-amount** endpoint to get the rate that applies to the transaction amount.

---

## Base URL

```
/api/admin/crypto/rates
```

Example (local): `http://localhost:5000/api/admin/crypto/rates`

---

## Authentication

All endpoints require:

- **Authentication:** Valid access token (cookie `accessToken` or `Authorization: Bearer <token>`).
- **Authorization:** Permission on route `crypto/rates` for the required action (`view`, `create`, `edit`, `delete`).

Unauthenticated requests receive `401`. Insufficient permissions receive `403`.

---

## Response envelope

- **Success:** `{ "success": true, "data": ... }`
- **Error:** `{ "success": false, "error": "<message>" }`

---

## Endpoints

### 1. List rates

**GET** `/api/admin/crypto/rates`

Returns rates, ordered by `rate_date` DESC then `wallet_id` ASC. **Filtering when reading is by `is_active` and optional `wallet_id` only;** `rate_date` is not used as a filter—it is only stored with each rate record (create/update).

**Query parameters**

| Parameter   | Type   | Description                                           |
|------------|--------|-------------------------------------------------------|
| `wallet_id`| number | Optional. Filter by wallet ID                         |
| `active`   | string | Optional. `true` = only active rates (`is_active = true`). Omit = all. |

**Example request**

```http
GET /api/admin/crypto/rates
GET /api/admin/crypto/rates?wallet_id=1
GET /api/admin/crypto/rates?active=true
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "wallet_id": 1,
      "rate_date": "2025-03-04",
      "buy_rate": 1.02,
      "sell_rate": 0.98,
      "min_amount": 10,
      "max_amount": 10000,
      "is_active": true,
      "created_by": 1,
      "created_at": "2025-03-04T12:00:00.000Z",
      "updated_at": "2025-03-04T12:00:00.000Z"
    }
  ]
}
```

---

### 2. Get rate for amount (for transactions)

**GET** `/api/admin/crypto/rates/for-amount`

Returns the **active rate** for a wallet that applies to the given **amount** (fiat amount). Use this when creating a buy/sell transaction to get the correct rate and `rate_id` for the transaction amount. If multiple rates match (overlapping ranges), the rate with the **narrowest range** is returned.

**Query parameters**

| Parameter   | Type   | Required | Description                                                                 |
|------------|--------|----------|-----------------------------------------------------------------------------|
| `wallet_id`| number | Yes      | Wallet ID                                                                   |
| `amount`   | number | Yes      | Fiat amount (used to find the rate whose min_amount ≤ amount ≤ max_amount) |
| `type`     | string | No       | `buy` or `sell`; default `buy`. Response includes a `rate` field (buy_rate or sell_rate). |

**Example request**

```http
GET /api/admin/crypto/rates/for-amount?wallet_id=1&amount=500&type=buy
GET /api/admin/crypto/rates/for-amount?wallet_id=1&amount=5000&type=sell
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_id": 1,
    "rate_date": "2025-03-04",
    "buy_rate": 1.02,
    "sell_rate": 0.98,
    "min_amount": 10,
    "max_amount": 1000,
    "rate": 1.02,
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

The `rate` field is either `buy_rate` or `sell_rate` depending on `type`. Use this rate and the returned `id` as `rate_id` when creating the transaction.


**Error responses**

- `400 Bad Request` — missing `wallet_id` or `amount`, or invalid `type`  
  `{ "success": false, "error": "wallet_id and amount are required" }` or `"type must be buy or sell"`
- `404 Not Found` — no active rate found for that wallet and amount  
  `{ "success": false, "error": "No active rate found for this wallet and amount range" }`

---

### 3. Get rate by ID

**GET** `/api/admin/crypto/rates/:id`

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Rate ID        |

**Example request**

```http
GET /api/admin/crypto/rates/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_id": 1,
    "rate_date": "2025-03-04",
    "buy_rate": 1.02,
    "sell_rate": 0.98,
    "min_amount": 10,
    "max_amount": 10000,
    "is_active": true,
    "created_by": 1,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Rate not found"
}
```

---

### 4. Create rate

**POST** `/api/admin/crypto/rates`

**Required permission:** `create` on `crypto/rates`.

**Request body (JSON)**

| Field       | Type    | Required | Description                                      |
|-------------|---------|----------|--------------------------------------------------|
| `wallet_id` | number  | Yes      | Wallet ID this rate applies to                   |
| `rate_date` | string  | Yes      | Date for the rate (e.g. YYYY-MM-DD)              |
| `buy_rate`  | number  | Yes      | Buy rate; must be non-negative                   |
| `sell_rate` | number  | Yes      | Sell rate; must be non-negative                  |
| `min_amount`| number  | No       | Minimum amount (nullable)                        |
| `max_amount`| number  | No       | Maximum amount (nullable)                        |
| `is_active` | boolean | No       | Default `true`                                   |

**Example request**

```http
POST /api/admin/crypto/rates
Content-Type: application/json

{
  "wallet_id": 1,
  "rate_date": "2025-03-04",
  "buy_rate": 1.02,
  "sell_rate": 0.98,
  "min_amount": 10,
  "max_amount": 10000,
  "is_active": true
}
```

**Success response** `201 Created`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_id": 1,
    "rate_date": "2025-03-04",
    "buy_rate": 1.02,
    "sell_rate": 0.98,
    "min_amount": 10,
    "max_amount": 10000,
    "is_active": true,
    "created_by": 1,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — missing required fields

  ```json
  { "success": false, "error": "wallet_id, rate_date, buy_rate and sell_rate are required" }
  ```

- `400 Bad Request` — negative rates

  ```json
  { "success": false, "error": "buy_rate and sell_rate must be non-negative" }
  ```

- `401 Unauthorized` — no user context

  ```json
  { "success": false, "error": "Authentication required to create rate" }
  ```

---

### 5. Update rate

**PUT** `/api/admin/crypto/rates/:id`

**Required permission:** `edit` on `crypto/rates`.

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Rate ID        |

**Request body (JSON)**  
All fields optional; only sent fields are updated.

| Field        | Type    | Description                        |
|--------------|---------|------------------------------------|
| `wallet_id`  | number  | Wallet ID                          |
| `rate_date`  | string  | Date (e.g. YYYY-MM-DD)             |
| `buy_rate`   | number  | Buy rate; must be non-negative     |
| `sell_rate`  | number  | Sell rate; must be non-negative    |
| `min_amount` | number  | Min amount; null or empty to clear |
| `max_amount` | number  | Max amount; null or empty to clear |
| `is_active`  | boolean | Active flag                        |

**Example request**

```http
PUT /api/admin/crypto/rates/1
Content-Type: application/json

{
  "buy_rate": 1.03,
  "sell_rate": 0.97,
  "is_active": false
}
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_id": 1,
    "rate_date": "2025-03-04",
    "buy_rate": 1.03,
    "sell_rate": 0.97,
    "min_amount": 10,
    "max_amount": 10000,
    "is_active": false,
    "created_by": 1,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:05:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — negative buy_rate or sell_rate  
  `{ "success": false, "error": "buy_rate must be non-negative" }` or `"sell_rate must be non-negative"`
- `404 Not Found` — rate not found  
  `{ "success": false, "error": "Rate not found" }`

---

### 6. Delete rate

**DELETE** `/api/admin/crypto/rates/:id`

**Required permission:** `delete` on `crypto/rates`.

Rates that are used by any transaction (stored via `rate_id` on the transaction) cannot be deleted.

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Rate ID        |

**Example request**

```http
DELETE /api/admin/crypto/rates/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "message": "Rate deleted"
}
```

**Error responses**

- `404 Not Found` — rate not found  
  `{ "success": false, "error": "Rate not found" }`
- `409 Conflict` — rate is used by one or more transactions and cannot be deleted  
  `{ "success": false, "error": "Cannot delete rate: it is used by one or more transactions. Remove or reassign those transactions first." }`

---

## Data model (rate)

| Field        | Type    | Description                          |
|--------------|---------|--------------------------------------|
| `id`         | number  | Primary key                          |
| `wallet_id`  | number  | FK to crypto_wallets                 |
| `rate_date`  | string  | Date (YYYY-MM-DD); stored with the rate but not used to filter list (list filter is `is_active` only, plus optional `wallet_id`) |
| `buy_rate`   | number  | Buy rate (non-negative)              |
| `sell_rate`  | number  | Sell rate (non-negative)             |
| `min_amount` | number  | Minimum amount (nullable)            |
| `max_amount` | number  | Maximum amount (nullable)            |
| `is_active`  | boolean | Whether the rate is active           |
| `created_by` | number  | User ID who created (on create only) |
| `created_at` | string  | ISO 8601 timestamp                   |
| `updated_at` | string  | ISO 8601 timestamp                   |

Multiple rates per wallet are allowed; they are differentiated by **amount range** (`min_amount`, `max_amount`). For example, one rate for 10–1000 and another for 1001–10000. When selecting a rate for a transaction, use **GET /for-amount** with `wallet_id` and `amount`.

---

## Amount range (min_amount / max_amount)

Rates can define an optional **amount range** via `min_amount` and `max_amount` (both nullable):

- **min_amount:** If set, this rate applies only when the transaction amount (e.g. fiat amount) is **≥** this value.
- **max_amount:** If set, this rate applies only when the transaction amount is **≤** this value.
- If both are null, the rate applies to any amount.

**Use with Transactions:** When creating a transaction, call **`GET /api/admin/crypto/rates/for-amount?wallet_id={id}&amount={fiat_amount}&type=buy`** (or `type=sell`) to get the rate that applies to that amount. The response includes `id` (use as `rate_id`), `rate` (use as the transaction `rate`), and buy/sell rates. Then create the transaction with that `rate_id` and `rate`. Spread can be computed as `|buy_rate - sell_rate| * crypto_amount`. Rates linked to any transaction cannot be deleted (delete returns 409).

---

## Frontend proxy (Next.js)

When using the Next.js app, the frontend calls the same paths under the app origin; the Next.js API routes proxy to the backend:

- **GET/POST** `/api/admin/crypto/rates` → backend `GET/POST /api/admin/crypto/rates`
- **GET/PUT/DELETE** `/api/admin/crypto/rates/[id]` → backend `GET/PUT/DELETE /api/admin/crypto/rates/:id`

Cookies are forwarded so authentication is preserved.
