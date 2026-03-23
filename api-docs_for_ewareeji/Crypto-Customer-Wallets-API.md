# Crypto Customer Wallets API

API for **customer wallets**: crypto wallet addresses registered by customers (e.g. via the mobile app). The admin frontend **lists** customer wallets and can **update** their information (address, active flag, etc.) via PUT. **Registration** is done from the mobile application using the POST endpoint.

---

## Base URL

```
/api/admin/crypto/customer-wallets
```

Example (local): `http://localhost:5000/api/admin/crypto/customer-wallets`

---

## Authentication

All endpoints require:

- **Authentication:** Valid access token in `Authorization: Bearer <token>` header (Bearer-only; cookies are not used).
- **Authorization:** Permission on route `crypto/customer-wallets` for the required action (`view` for GET, `create` for POST, `edit` for PUT).

Unauthenticated requests receive `401`. Insufficient permissions receive `403`.

---

## Response envelope

- **Success:** `{ "success": true, "data": ... }`
- **Error:** `{ "success": false, "error": "<message>" }`

---

## Dependencies

- **Wallets:** Customer wallets reference **wallets** from the [Crypto Wallets API](Crypto-Wallets-API.md). `wallet_id` must be a valid `crypto_wallets.id`.
- **wallet_account_id:** Reserved for future use; has no effect on business logic at the moment. Send `0` or omit if not used.

---

## Endpoints

### 1. List customer wallets

**GET** `/api/admin/crypto/customer-wallets`

Returns all customer wallet records with joined wallet and network info (for display). Ordered by `created_at` descending.

**Required permission:** `view` on `crypto/customer-wallets`.

**Query parameters**

| Parameter | Type   | Description                                            |
|-----------|--------|--------------------------------------------------------|
| `active`  | string | Optional. `true` = only active records. Omit = all.   |

**Example request**

```http
GET /api/admin/crypto/customer-wallets
GET /api/admin/crypto/customer-wallets?active=true
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "wallet_account_id": 0,
      "wallet_id": 1,
      "customer_wallet_name": "My USDT wallet",
      "wallet_address": "TXYZabc...def123",
      "is_active": true,
      "created_at": "2025-03-04T12:00:00.000Z",
      "wallet_name": "USDT TRC20",
      "network_code": "TRC20",
      "network_name": "Tron (TRC20)"
    }
  ]
}
```

---

### 2. List customer wallets by account (by customer)

**GET** `/api/admin/crypto/customer-wallets/by-account/:wallet_account_id`

Returns all customer wallet records for one customer, using `wallet_account_id` (unique per customer). Same response shape as list; ordered by `created_at` descending.

**Required permission:** `view` on `crypto/customer-wallets`.

**Path parameters**

| Name               | Type   | Description                                      |
|--------------------|--------|--------------------------------------------------|
| `wallet_account_id`| number | Customer account id; all wallets with this id are returned. |

**Query parameters**

| Parameter | Type   | Description                                            |
|-----------|--------|--------------------------------------------------------|
| `active`  | string | Optional. `true` = only active records. Omit = all.   |

**Example request**

```http
GET /api/admin/crypto/customer-wallets/by-account/42
GET /api/admin/crypto/customer-wallets/by-account/42?active=true
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "wallet_account_id": 42,
      "wallet_id": 1,
      "customer_wallet_name": "My USDT wallet",
      "wallet_address": "TXYZabc...def123",
      "is_active": true,
      "created_at": "2025-03-04T12:00:00.000Z",
      "wallet_name": "USDT TRC20",
      "network_code": "TRC20",
      "network_name": "Tron (TRC20)"
    }
  ]
}
```

**Error response** `400 Bad Request` — missing `wallet_account_id`

```json
{ "success": false, "error": "wallet_account_id is required" }
```

---

### 3. Get customer wallet by ID

**GET** `/api/admin/crypto/customer-wallets/:id`

Returns one customer wallet with joined wallet and network info.

**Required permission:** `view` on `crypto/customer-wallets`.

**Path parameters**

| Name | Type   | Description              |
|------|--------|--------------------------|
| `id` | number | Customer wallet ID (bigint) |

**Example request**

```http
GET /api/admin/crypto/customer-wallets/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 0,
    "wallet_id": 1,
    "customer_wallet_name": "My USDT wallet",
    "wallet_address": "TXYZabc...def123",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z",
    "wallet_name": "USDT TRC20",
    "network_code": "TRC20",
    "network_name": "Tron (TRC20)"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Customer wallet not found"
}
```

---

### 4. Create customer wallet (mobile app)

**POST** `/api/admin/crypto/customer-wallets`

Registers a new customer wallet. Intended for use by the **mobile application**; the admin frontend does not offer a create form.

**Required permission:** `create` on `crypto/customer-wallets`.

**Request body (JSON)**

| Field            | Type    | Required | Description                                      |
|------------------|---------|----------|--------------------------------------------------|
| `wallet_id`      | number  | Yes      | ID of the wallet (from [Crypto Wallets](Crypto-Wallets-API.md)) |
| `wallet_address` | string  | Yes      | Customer’s crypto wallet address                 |
| `customer_wallet_name`| string  | No       | Optional display name for the wallet            |
| `wallet_account_id` | number | No       | Reserved; default `0`. No effect for now.        |
| `is_active`      | boolean | No       | Default `true`                                   |

**Example request**

```http
POST /api/admin/crypto/customer-wallets
Content-Type: application/json

{
  "wallet_account_id": 0,
  "wallet_id": 1,
  "customer_wallet_name": "My USDT wallet",
  "wallet_address": "TXYZabc...def123",
  "is_active": true
}
```

**Success response** `201 Created`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 0,
    "wallet_id": 1,
    "customer_wallet_name": "My USDT wallet",
    "wallet_address": "TXYZabc...def123",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z",
    "wallet_name": "USDT TRC20",
    "network_code": "TRC20",
    "network_name": "Tron (TRC20)"
  }
}
```

**Error responses**

- `400 Bad Request` — missing or invalid fields

  ```json
  { "success": false, "error": "Wallet is required" }
  { "success": false, "error": "Wallet address is required" }
  { "success": false, "error": "Invalid wallet" }
  ```

---

### 5. Update customer wallet by ID

**PUT** `/api/admin/crypto/customer-wallets/:id`

Updates an existing customer wallet. Only provided fields are updated; omit fields to leave them unchanged.

**Required permission:** `edit` on `crypto/customer-wallets`.

**Path parameters**

| Name | Type   | Description                |
|------|--------|----------------------------|
| `id` | number | Customer wallet ID (bigint) |

**Request body (JSON)** — all fields optional; send only what you want to change

| Field             | Type    | Required | Description                                                |
|-------------------|---------|----------|------------------------------------------------------------|
| `customer_wallet_name`| string  | No       | Display name for the wallet (empty string clears it)      |
| `wallet_address`  | string  | No       | New wallet address (must be non-empty if provided)         |
| `is_active`       | boolean | No       | Whether the record is active                              |
| `wallet_id`       | number  | No       | ID of the wallet (from [Crypto Wallets](Crypto-Wallets-API.md)); must exist |
| `wallet_account_id` | number | No     | Reserved; default `0`                                      |

**Example request**

```http
PUT /api/admin/crypto/customer-wallets/1
Content-Type: application/json

{
  "wallet_address": "TXYZnew...address456",
  "is_active": true
}
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_account_id": 0,
    "wallet_id": 1,
    "customer_wallet_name": "My USDT wallet",
    "wallet_address": "TXYZnew...address456",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z",
    "wallet_name": "USDT TRC20",
    "network_code": "TRC20",
    "network_name": "Tron (TRC20)"
  }
}
```

**Error responses**

- `400 Bad Request` — validation error

  ```json
  { "success": false, "error": "Wallet address cannot be empty" }
  { "success": false, "error": "Invalid wallet" }
  ```

- `404 Not Found` — customer wallet not found

  ```json
  { "success": false, "error": "Customer wallet not found" }
  ```

---

## Data model (customer_wallets)

| Field             | Type    | Description                                    |
|-------------------|---------|------------------------------------------------|
| `id`              | bigint  | Primary key (auto-generated)                   |
| `wallet_account_id` | bigint | Reserved for future use; no effect now         |
| `wallet_id`       | integer | FK to `crypto_wallets.id`                       |
| `customer_wallet_name`| string  | Optional display name (max 255)                |
| `wallet_address`  | string  | Customer’s wallet address (max 255)            |
| `is_active`       | boolean | Whether the record is active (default true)    |
| `created_at`      | string  | ISO 8601 timestamp                             |

List and get-by-id responses also include joined fields:

| Field          | Type   | Description                    |
|----------------|--------|--------------------------------|
| `wallet_name`  | string | From `crypto_wallets.name`     |
| `network_code` | string | From `networks.code`           |
| `network_name` | string | From `networks.name`           |

---

## Frontend (admin)

- **Screen:** Admin crypto → **Customer wallets** (list; edit supported via PUT).
- **Proxy:** GET `/api/admin/crypto/customer-wallets`, GET `/api/admin/crypto/customer-wallets/by-account/[wallet_account_id]`, GET `/api/admin/crypto/customer-wallets/[id]`, and PUT `/api/admin/crypto/customer-wallets/[id]` proxy to the backend. The proxy forwards the request’s `Authorization` header (Bearer token) and JSON body (for PUT) to the backend, consistent with other crypto API proxies.

---

## Database schema (reference)

```sql
CREATE TABLE IF NOT EXISTS public.customer_wallets (
  id BIGSERIAL PRIMARY KEY,
  wallet_account_id BIGINT NOT NULL DEFAULT 0,
  wallet_id INTEGER NOT NULL,
  customer_wallet_name VARCHAR(255),
  wallet_address VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_customer_wallet_wallet FOREIGN KEY (wallet_id)
    REFERENCES public.crypto_wallets (id) ON DELETE CASCADE
);
```
