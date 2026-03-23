# Crypto Networks API

API for managing blockchain networks (e.g. TRC20, BEP20, ERC20) used for crypto operations.

---

## Base URL

```
/api/admin/crypto/networks
```

Example (local): `http://localhost:5000/api/admin/crypto/networks`

---

## Authentication

All endpoints require:

- **Authentication:** Valid access token (cookie `accessToken` or `Authorization: Bearer <token>`).
- **Authorization:** Permission on route `crypto/networks` for the required action (`view`, `create`, `edit`, `delete`).

Unauthenticated requests receive `401`. Insufficient permissions receive `403`.

---

## Response envelope

- **Success:** `{ "success": true, "data": ... }`
- **Error:** `{ "success": false, "error": "<message>" }`

---

## Endpoints

### 1. List networks

**GET** `/api/admin/crypto/networks`

Returns all networks, ordered by `display_order` then `code`.

**Query parameters**

| Parameter | Type    | Description                                      |
|-----------|--------|--------------------------------------------------|
| `active`  | string | Optional. `true` = only active networks. Omit = all. |

**Example request**

```http
GET /api/admin/crypto/networks
GET /api/admin/crypto/networks?active=true
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "TRC20",
      "name": "Tron (TRC20)",
      "blockchain": "Tron",
      "description": "USDT on Tron network",
      "is_active": true,
      "display_order": 1,
      "created_at": "2025-03-04T12:00:00.000Z",
      "updated_at": "2025-03-04T12:00:00.000Z"
    }
  ]
}
```

---

### 2. Get network by ID

**GET** `/api/admin/crypto/networks/:id`

**Path parameters**

| Name | Type   | Description   |
|------|--------|----------------|
| `id` | number | Network ID    |

**Example request**

```http
GET /api/admin/crypto/networks/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "TRC20",
    "name": "Tron (TRC20)",
    "blockchain": "Tron",
    "description": "USDT on Tron network",
    "is_active": true,
    "display_order": 1,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Network not found"
}
```

---

### 3. Create network

**POST** `/api/admin/crypto/networks`

**Required permission:** `create` on `crypto/networks`.

**Request body (JSON)**

| Field          | Type    | Required | Description                                |
|----------------|---------|----------|--------------------------------------------|
| `code`         | string  | Yes      | Short code (e.g. TRC20). Stored uppercase. |
| `name`         | string  | Yes      | Display name                               |
| `blockchain`   | string  | No       | Blockchain name                            |
| `description` | string  | No       | Optional description                       |
| `is_active`    | boolean | No       | Default `true`                             |
| `display_order`| number  | No       | Sort order; default `0`                    |

**Example request**

```http
POST /api/admin/crypto/networks
Content-Type: application/json

{
  "code": "TRC20",
  "name": "Tron (TRC20)",
  "blockchain": "Tron",
  "description": "USDT on Tron network",
  "is_active": true,
  "display_order": 1
}
```

**Success response** `201 Created`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "TRC20",
    "name": "Tron (TRC20)",
    "blockchain": "Tron",
    "description": "USDT on Tron network",
    "is_active": true,
    "display_order": 1,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:00:00.000Z"
  }
}
```

**Error responses**

- `400 Bad Request` — missing required fields

  ```json
  { "success": false, "error": "Code and name are required" }
  ```

- `409 Conflict` — code already exists

  ```json
  { "success": false, "error": "A network with this code already exists" }
  ```

---

### 4. Update network

**PUT** `/api/admin/crypto/networks/:id`

**Required permission:** `edit` on `crypto/networks`.

**Path parameters**

| Name | Type   | Description   |
|------|--------|---------------|
| `id` | number | Network ID   |

**Request body (JSON)**  
All fields optional; only sent fields are updated.

| Field           | Type    | Description                                |
|-----------------|---------|--------------------------------------------|
| `code`          | string  | Short code; stored uppercase; must be unique |
| `name`          | string  | Display name                               |
| `blockchain`    | string  | Blockchain name                            |
| `description`   | string  | Description                                 |
| `is_active`    | boolean | Active flag                                |
| `display_order` | number  | Sort order                                 |

**Example request**

```http
PUT /api/admin/crypto/networks/1
Content-Type: application/json

{
  "name": "Tron (TRC20)",
  "is_active": false,
  "display_order": 2
}
```

**Success response** `200 OK`

```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "TRC20",
    "name": "Tron (TRC20)",
    "blockchain": "Tron",
    "description": "USDT on Tron network",
    "is_active": false,
    "display_order": 2,
    "created_at": "2025-03-04T12:00:00.000Z",
    "updated_at": "2025-03-04T12:05:00.000Z"
  }
}
```

**Error responses**

- `404 Not Found` — network not found  
  `{ "success": false, "error": "Network not found" }`
- `409 Conflict` — new code already used by another network  
  `{ "success": false, "error": "A network with this code already exists" }`

---

### 5. Delete network

**DELETE** `/api/admin/crypto/networks/:id`

**Required permission:** `delete` on `crypto/networks`.

**Path parameters**

| Name | Type   | Description |
|------|--------|-------------|
| `id` | number | Network ID |

**Example request**

```http
DELETE /api/admin/crypto/networks/1
```

**Success response** `200 OK`

```json
{
  "success": true,
  "message": "Network deleted"
}
```

**Error response** `404 Not Found`

```json
{
  "success": false,
  "error": "Network not found"
}
```

---

## Data model (network)

| Field          | Type    | Description                    |
|----------------|---------|--------------------------------|
| `id`           | number  | Primary key                    |
| `code`         | string  | Unique short code (uppercase)  |
| `name`         | string  | Display name                   |
| `blockchain`   | string  | Blockchain name (nullable)     |
| `description`  | string  | Description (nullable)         |
| `is_active`    | boolean | Whether the network is active  |
| `display_order`| number  | Sort order (lower first)       |
| `created_at`   | string  | ISO 8601 timestamp              |
| `updated_at`   | string  | ISO 8601 timestamp              |

---

## Frontend proxy (Next.js)

When using the Next.js app, the frontend calls the same paths under the app origin; the Next.js API routes proxy to the backend:

- **GET/POST** `/api/admin/crypto/networks` → backend `GET/POST /api/admin/crypto/networks`
- **GET/PUT/DELETE** `/api/admin/crypto/networks/[id]` → backend `GET/PUT/DELETE /api/admin/crypto/networks/:id`

Cookies are forwarded so authentication is preserved.
