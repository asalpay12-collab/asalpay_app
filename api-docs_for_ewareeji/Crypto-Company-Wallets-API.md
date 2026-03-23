# Crypto Company Wallets API

API for managing **company wallets**: the company (exchanger) crypto wallet addresses linked to each recorded wallet type (from [Crypto Wallets](Crypto-Wallets-API.md)). Each company-wallet record assigns one address to one wallet (e.g. “USDT TRC20” → company’s Tron address).

---

## Base URL

```
/api/admin/crypto/company-wallets
```

Example (local): `http://localhost:5000/api/admin/crypto/company-wallets`

---

## Authentication

All endpoints require:

- **Authentication:** Valid access token (cookie `accessToken` or `Authorization: Bearer <token>`).
- **Authorization:** Permission on route `crypto/company-wallets` for the required action (`view`, `create`, `edit`, `delete`).

Unauthenticated requests receive `401`. Insufficient permissions receive `403`.

---

## Response envelope

- **Success:** `{ "success": true, "data": ... }`
- **Error:** `{ "success": false, "error": "<message>" }`

---

## Dependencies

- **Wallets:** Company wallets reference **wallets** from the [Crypto Wallets API](Crypto-Wallets-API.md). Ensure wallets (and networks) exist before creating company-wallet records.
- **One address per wallet:** At most one company-wallet record per `wallet_id`. Creating a second for the same wallet returns `409 Conflict`.

---

## Endpoints

### 1. List company wallets

**GET** `/api/admin/crypto/company-wallets`

Returns all company-wallet records (company’s addresses per wallet type), ordered by `id`.

**Query parameters**

| Parameter | Type   | Description                                           |
|-----------|--------|-------------------------------------------------------|
| `active`  | string | Optional. `true` = only active records. Omit = all.  |

**Example request**

```http
GET /api/admin/crypto/company-wallets
GET /api/admin/crypto/company-wallets?active=true
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "wallet_id": 1,
      "address": "TXYZabc...def123",
      "is_active": true,
      "created_at": "2025-03-04T12:00:00.000Z",
      "updated_at": "2025-03-04T12:00:00.000Z"
    }
  ]
}
```

---

### 2. Get company wallet by ID

**GET** `/api/admin/crypto/company-wallets/:id`

**Path parameters**

| Name | Type   | Description              |
|------|--------|--------------------------|
| `id` | number | Company wallet ID        |

**Example request**

```http
GET /api/admin/crypto/company-wallets/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "wallet_id": 1,
    "address": "TXYZabc...def123",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Company wallet not found"
}
```

---

### 3. Create company wallet

**POST** `/api/admin/crypto/company-wallets`

**Required permission:** `create` on `crypto/company-wallets`.

Adds the company’s crypto address for a wallet. The wallet must exist and must not already have a company-wallet record.

**Request body (JSON)**

| Field       | Type    | Required | Description                                  |
|------------|---------|----------|----------------------------------------------|
| `wallet_id`| number  | Yes      | ID of the wallet (from Crypto Wallets API)  |
| `address`  | string  | Yes      | Crypto wallet address for this wallet        |
| `is_active`| boolean | No       | Default `true`                               |

**Example request**

```http
POST /api/admin/crypto/company-wallets
Content-Type: application/json

{
  "wallet_id": 1,
  "address": "TXYZabc...def123",
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
    "address": "TXYZabc...def123",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — missing or invalid fields

  ```json
  { "success": false, "error": "Wallet is required" }
  { "success": false, "error": "Address is required" }
  { "success": false, "error": "Invalid wallet" }
  ```

- `409 Conflict` — this wallet already has a company-wallet record

  ```json
  {
    "success": false,
    "error": "This wallet already has a saved address. Edit the existing one instead."
  }
  ```

---

### 4. Update company wallet

**PUT** `/api/admin/crypto/company-wallets/:id`

**Required permission:** `edit` on `crypto/company-wallets`.

**Path parameters**

| Name | Type   | Description              |
|------|--------|--------------------------|
| `id` | number | Company wallet ID        |

**Request body (JSON)**  
All fields optional; only provided fields are updated. `wallet_id` cannot be changed (edit is for address and active flag).

| Field       | Type    | Description                    |
|------------|---------|--------------------------------|
| `address`  | string  | New crypto wallet address      |
| `is_active`| boolean | Active flag                    |

**Example request**

```http
PUT /api/admin/crypto/company-wallets/1
Content-Type: application/json

{
  "address": "TNewAddress...xyz",
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
    "address": "TNewAddress...xyz",
    "is_active": false,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:05:00.000Z"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Company wallet not found"
}
```

---

### 5. Delete company wallet

**DELETE** `/api/admin/crypto/company-wallets/:id`

**Required permission:** `delete` on `crypto/company-wallets`.

**Path parameters**

| Name | Type   | Description              |
|------|--------|--------------------------|
| `id` | number | Company wallet ID        |

**Example request**

```http
DELETE /api/admin/crypto/company-wallets/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "message": "Company wallet deleted"
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Company wallet not found"
}
```

---

## Data model (company wallet)

| Field        | Type    | Description                          |
|-------------|---------|--------------------------------------|
| `id`        | number  | Primary key                          |
| `wallet_id` | number  | FK to wallet (Crypto Wallets); unique per record |
| `address`   | string  | Company’s crypto wallet address      |
| `is_active` | boolean | Whether this address is active       |
| `created_at`| string  | ISO 8601 timestamp                   |
| `updated_at`| string  | ISO 8601 timestamp                   |

---

## Frontend proxy (Next.js)

When using the Next.js app, the frontend calls the same paths under the app origin; the Next.js API routes proxy to the backend:

- **GET/POST** `/api/admin/crypto/company-wallets` → backend `GET/POST /api/admin/crypto/company-wallets`
- **GET/PUT/DELETE** `/api/admin/crypto/company-wallets/[id]` → backend `GET/PUT/DELETE /api/admin/crypto/company-wallets/:id`

Cookies are forwarded so authentication is preserved.
