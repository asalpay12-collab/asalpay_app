# Crypto Wallets API

API for managing crypto wallets (e.g. deposit/withdrawal addresses) linked to networks.

---

## Base URL

```
/api/admin/crypto/wallets
```

Example (local): `http://localhost:5000/api/admin/crypto/wallets`

---

## Authentication

All endpoints require:

- **Authentication:** Valid access token (cookie `accessToken` or `Authorization: Bearer <token>`).
- **Authorization:** Permission on route `crypto/wallets` for the required action (`view`, `create`, `edit`, `delete`).

Unauthenticated requests receive `401`. Insufficient permissions receive `403`.

---

## Response envelope

- **Success:** `{ "success": true, "data": ... }`
- **Error:** `{ "success": false, "error": "<message>" }`

---

## Endpoints

### 1. List wallets

**GET** `/api/admin/crypto/wallets`

Returns all wallets, ordered by `name` then `network_id`.

**Query parameters**

| Parameter | Type   | Description                                          |
|-----------|--------|------------------------------------------------------|
| `active`  | string | Optional. `true` = only active wallets. Omit = all. |

**Example request**

```http
GET /api/admin/crypto/wallets
GET /api/admin/crypto/wallets?active=true
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "USDT TRC20",
      "network_id": 1,
      "icon": "usdt-trc20.png",
      "is_active": true,
      "created_at": "2025-03-04T12:00:00.000Z"
    }
  ]
}
```

---

### 2. Get wallet by ID

**GET** `/api/admin/crypto/wallets/:id`

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Wallet ID     |

**Example request**

```http
GET /api/admin/crypto/wallets/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "USDT TRC20",
    "network_id": 1,
    "icon": "usdt-trc20.png",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Wallet not found"
}
```

---

### 3. Create wallet

**POST** `/api/admin/crypto/wallets`

**Required permission:** `create` on `crypto/wallets`.

**Request body (JSON)**

| Field        | Type    | Required | Description                        |
|-------------|---------|----------|------------------------------------|
| `name`      | string  | Yes      | Wallet name (max 20 chars; trimmed) |
| `network_id`| number  | Yes      | Network ID (e.g. from crypto_networks) |
| `icon`      | string  | No       | Optional icon identifier or path   |
| `is_active` | boolean | No       | Default `true`                     |

**Example request**

```http
POST /api/admin/crypto/wallets
Content-Type: application/json

{
  "name": "USDT TRC20",
  "network_id": 1,
  "icon": "usdt-trc20.png",
  "is_active": true
}
```

**Success response** `201 Created`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "USDT TRC20",
    "network_id": 1,
    "icon": "usdt-trc20.png",
    "is_active": true,
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — missing required fields

  ```json
  { "success": false, "error": "name and network_id are required" }
  ```

- `409 Conflict` — duplicate name + network

  ```json
  { "success": false, "error": "A wallet with this name and network already exists" }
  ```

---

### 4. Update wallet

**PUT** `/api/admin/crypto/wallets/:id`

**Required permission:** `edit` on `crypto/wallets`.

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Wallet ID     |

**Request body (JSON)**  
All fields optional; only sent fields are updated.

| Field        | Type    | Description                        |
|-------------|---------|------------------------------------|
| `name`      | string  | Wallet name (max 20 chars; trimmed) |
| `network_id`| number  | Network ID                         |
| `icon`      | string  | Icon identifier or path; empty string clears |
| `is_active` | boolean | Active flag                        |

**Example request**

```http
PUT /api/admin/crypto/wallets/1
Content-Type: application/json

{
  "name": "USDT TRC20 Updated",
  "is_active": false
}
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "USDT TRC20 Updated",
    "network_id": 1,
    "icon": "usdt-trc20.png",
    "is_active": false,
    "created_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `404 Not Found` — wallet not found  
  `{ "success": false, "error": "Wallet not found" }`
- `409 Conflict` — duplicate name + network  
  `{ "success": false, "error": "A wallet with this name and network already exists" }`

---

### 5. Delete wallet

**DELETE** `/api/admin/crypto/wallets/:id`

**Required permission:** `delete` on `crypto/wallets`.

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Wallet ID     |

**Example request**

```http
DELETE /api/admin/crypto/wallets/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "message": "Wallet deleted"
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Wallet not found"
}
```

---

## Data model (wallet)

| Field        | Type    | Description                    |
|-------------|---------|--------------------------------|
| `id`        | number  | Primary key                    |
| `name`      | string  | Wallet name (max 20 chars)     |
| `network_id`| number  | FK to crypto_networks         |
| `icon`      | string  | Icon (nullable)                |
| `is_active` | boolean | Whether the wallet is active  |
| `created_at`| string  | ISO 8601 timestamp             |

Uniqueness: `(name, network_id)` must be unique.

---

## Frontend proxy (Next.js)

When using the Next.js app, the frontend calls the same paths under the app origin; the Next.js API routes proxy to the backend:

- **GET/POST** `/api/admin/crypto/wallets` → backend `GET/POST /api/admin/crypto/wallets`
- **GET/PUT/DELETE** `/api/admin/crypto/wallets/[id]` → backend `GET/PUT/DELETE /api/admin/crypto/wallets/:id`

Cookies are forwarded so authentication is preserved.
