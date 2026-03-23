# Ewareeji API Docs – Summary (Mid mid)

Sharaxaad kooban ee afar document-ka API-ka crypto (networks, wallets, company-wallets, customer-wallets). Document kasta waa summary kaliya; tafatirka buuxa ka akhri file-ka asaliga ah.

---

## 1. Crypto Networks API – Summary

**Source:** [Crypto-Networks-API.md](Crypto-Networks-API.md)

**Ujeeddo:** Maareynta blockchain networks (tusaale TRC20, BEP20, ERC20) ee loo isticmaalo crypto.

**Base URL:** `GET/POST/PUT/DELETE` `/api/admin/crypto/networks`  
**Auth:** Access token (cookie ama `Authorization: Bearer`); permission `crypto/networks` (`view`, `create`, `edit`, `delete`).

**Endpoints:**
- **GET** `/api/admin/crypto/networks` – liisto dhammaan networks (query: `?active=true` optional).
- **GET** `/api/admin/crypto/networks/:id` – hal network by ID.
- **POST** `/api/admin/crypto/networks` – abuur network (required: `code`, `name`; optional: `blockchain`, `description`, `is_active`, `display_order`).
- **PUT** `/api/admin/crypto/networks/:id` – cusboonaysii; fields optional.
- **DELETE** `/api/admin/crypto/networks/:id` – tirtir network.

**Data model (network):** `id`, `code`, `name`, `blockchain`, `description`, `is_active`, `display_order`, `created_at`, `updated_at`. Uniqueness: `code`.

**Response:** Success `{ "success": true, "data": ... }`; error `{ "success": false, "error": "..." }`. 400 (validation), 404 (not found), 409 (code duplicate).

---

## 2. Crypto Wallets API – Summary

**Source:** [Crypto-Wallets-API.md](Crypto-Wallets-API.md)

**Ujeeddo:** Maareynta noocyada crypto wallet (e.g. USDT TRC20) ee la xiriira network; waa “wallet type” (e.g. deposit/withdrawal type), ma aha address.

**Base URL:** `GET/POST/PUT/DELETE` `/api/admin/crypto/wallets`  
**Auth:** Access token; permission `crypto/wallets` (`view`, `create`, `edit`, `delete`).

**Endpoints:**
- **GET** `/api/admin/crypto/wallets` – liisto wallets (query: `?active=true` optional).
- **GET** `/api/admin/crypto/wallets/:id` – hal wallet by ID.
- **POST** `/api/admin/crypto/wallets` – abuur wallet (required: `name`, `network_id`; optional: `icon`, `is_active`).
- **PUT** `/api/admin/crypto/wallets/:id` – cusboonaysii; fields optional.
- **DELETE** `/api/admin/crypto/wallets/:id` – tirtir wallet.

**Data model (wallet):** `id`, `name`, `network_id` (FK networks), `icon`, `is_active`, `created_at`. Uniqueness: `(name, network_id)`.

**Errors:** 400 (required missing), 404 (not found), 409 (name+network duplicate).

---

## 3. Crypto Company Wallets API – Summary

**Source:** [Crypto-Company-Wallets-API.md](Crypto-Company-Wallets-API.md)

**Ujeeddo:** Ciidamada shirkad (company): ciidanka crypto ee shirkadu leedahay ee loo xiriiro nooc walwal (crypto_wallets). Hal record = hal address shirkad u hal wallet type (e.g. “USDT TRC20” → ciidanka Tron ee shirkad).


**Base URL:** `GET/POST/PUT/DELETE` `/api/admin/crypto/company-wallets`  
**Auth:** Access token; permission `crypto/company-wallets` (`view`, `create`, `edit`, `delete`).

**Endpoints:**
- **GET** `/api/admin/crypto/company-wallets` – liisto company-wallet records (`?active=true` optional).
- **GET** `/api/admin/crypto/company-wallets/:id` – hal record by ID.
- **POST** `/api/admin/crypto/company-wallets` – abuur (required: `wallet_id`, `address`; optional: `is_active`). Hal address per `wallet_id`; haddii hore u jiro 409.
- **PUT** `/api/admin/crypto/company-wallets/:id` – cusboonaysii `address` iyo `is_active` (wallet_id ma beddelikaro).
- **DELETE** `/api/admin/crypto/company-wallets/:id` – tirtir.

**Data model:** `id`, `wallet_id`, `address`, `is_active`, `created_at`, `updated_at`. Xiriir: wallet_id → Crypto Wallets API.

**Errors:** 400 (invalid/missing), 404 (not found), 409 (wallet already has company address).

---

## 4. Crypto Customer Wallets API – Summary

**Source:** [Crypto-Customer-Wallets-API.md](Crypto-Customer-Wallets-API.md)

**Ujeeddo:** Ciidamada macaamiisha: ciidanka crypto ee macaamiishu diiwaangeliyaan (tusaale app-ka mobile). Admin wuxuu list-garayaa oo PUT u cusboonaysiiyaa; **diiwaangalinta (create)** waxaa sameeya **app-ka mobile** (POST).

**Base URL:** `GET/POST/PUT` `/api/admin/crypto/customer-wallets`  
**Auth:** **Bearer token** (header only; cookies lama isticmaalo). Permission: `view` (GET), `create` (POST), `edit` (PUT).

**Endpoints:**
- **GET** `/api/admin/crypto/customer-wallets` – liisto customer wallets + joined wallet/network info (`?active=true` optional).
- **GET** `/api/admin/crypto/customer-wallets/:id` – hal customer wallet by ID.
- **POST** `/api/admin/crypto/customer-wallets` – **diiwaangeli ciidamada (mobile)**. Required: `wallet_id`, `wallet_address`; optional: `wallet_account_id` (0), `is_active`.
- **PUT** `/api/admin/crypto/customer-wallets/:id` – cusboonaysii (optional: `wallet_address`, `is_active`, `wallet_id`, `wallet_account_id`).

**Data model (customer_wallets):** `id`, `wallet_account_id` (reserved), `wallet_id`, `wallet_address`, `is_active`, `created_at`. Response-ga list/get waxaa ku jira joined: `wallet_name`, `network_code`, `network_name`.

**Errors:** 400 (wallet/address required or invalid), 404 (customer wallet not found).

**Note:** Admin ma abuuraan customer wallet (create); create waa app-ka mobile (POST).

---

## 5. Ewareeji app: Select/Dropdown-yada hadda hardcoded (soo akhrisan karo API)

Fiiritaan service-ka Ewareeji (AsalPay app), select/dropdown-yadan waa kuwo hadda laga soo muujiyey liisto hardcoded; API-dan kor ku qoran ayaa laga soo akhrisan kara (position-kooda code-ka waa kore).

| No. | Screen   | Label (UI)     | Variable / data hadda      | Position (file : lines) | API loo soo akhriyo |
|-----|----------|----------------|-----------------------------|--------------------------|----------------------|
| 1   | **Setup** | Select network | `_networks` = ['TRC20','ERC20','BEP20'] | [ewareeji_setup_screen.dart](asalpay_app/lib/ewareeji/ewareeji_setup_screen.dart) **14–15** (data), **83–86** (dropdown) | **GET** `/api/admin/crypto/networks` → muuji `code` ama `name` |
| 2   | **Main**  | Market – currencies (tabs) | `_currencies` = ['USDT','USDC'] | [ewareeji_main_screen.dart](asalpay_app/lib/ewareeji/ewareeji_main_screen.dart) **26–27** (data), **378, 402–416** (tabs) | **GET** `/api/admin/crypto/wallets` → ka soo saar currency (e.g. unique prefix ee `name`: USDT, USDC) ama group by name |
| 3   | **Main**  | Market – networks + rates per currency | `_currencyNetworks` (TRC20, ERC20, BEP20 + buyRate/sellRate) | [ewareeji_main_screen.dart](asalpay_app/lib/ewareeji/ewareeji_main_screen.dart) **30–93** (data), **318–341** (cards) | **GET** `networks` + **GET** `wallets` → networks/wallets; **rates** ma jiraan 4 API-kaan – backend rate endpoint haddii jiro |
| 4   | **Buy**   | Select wallet  | `_sampleWallets` = ['Main Wallet','Trading Wallet','Savings'] | [ewareeji_buy_screen.dart](asalpay_app/lib/ewareeji/ewareeji_buy_screen.dart) **14** (data), **84–87** (dropdown) | **GET** `/api/admin/crypto/customer-wallets` (ee user-ka) → muuji `wallet_name` + `network_code` ama `wallet_address` (haddii API user-scoped yahay) |
| 5   | **Sell**  | Select wallet  | `_wallets` = ['Main Wallet','Trading Wallet'] | [ewareeji_sell_screen.dart](asalpay_app/lib/ewareeji/ewareeji_sell_screen.dart) **15** (data), **88–91** (dropdown) | **GET** `/api/admin/crypto/customer-wallets` (ee user-ka) → sida Buy |
| 6   | **Sell**  | Currency       | `_currencies` = ['USDT','USDC','BUSD'] | [ewareeji_sell_screen.dart](asalpay_app/lib/ewareeji/ewareeji_sell_screen.dart) **16** (data), **95–98** (dropdown) | **GET** `/api/admin/crypto/wallets` → ka soo saar list (e.g. by `name`: USDT TRC20 → “USDT”) |

**Quick amounts** (50, 100, 200, 500, 1000) – Buy/Sell: hadda hardcoded; API-dan crypto ma bixinan config. Haddii backend haysato config, halkaas ka soo akhri.

**Xusuusin:**
- **Setup:** “Select network” → u beddel **GET networks**; form-ka Submit waa in uu diryo **POST customer-wallets** (waa in `wallet_id` laga helaa wallets API, `wallet_address` = address).
- **Buy/Sell “Select wallet”:** waa ciidamada macaamiisha (customer wallets); API-ga customer-wallets waa GET list – backend waa in uu filter-garayaa by user (e.g. `wallet_account_id`) haddii app-ku user-by-user u shaqeynayo.
- **Rates** (buyRate, sellRate, buyRates, sellRates): 4 API-kaan ma qeexaan; haddii backend rate/price endpoint haysato, Main screen rates halkaas ka soo akhri.

---

## 6. Endpoint → meesha loo isticmaalo (screen / form)

| Endpoint | Meesha (screen / form) |
|----------|------------------------|
| **GET** `/api/admin/crypto/networks` | **Setup** – dropdown "Select network". **Main** – qaybta Market (networks per currency). |
| **GET** `/api/admin/crypto/wallets` | **Main** – tabs currencies + cards networks. **Sell** – dropdown "Currency". **Setup** – marka la confirm-garayo (wallet_id for POST). |
| **GET** `/api/admin/crypto/customer-wallets` | **Buy** – dropdown "Select wallet" (haddii API user filter haysato). **Sell** – dropdown "Select wallet" (sidaas oo kale). |
| **POST** `/api/admin/crypto/customer-wallets` | **Setup** – badhanka "Confirm setup" (diiwaangeli ciidamada: wallet_id + wallet_address). |

*Auth:* Bearer token (login username/password .env) – service-ku wuxuu isticmaalaa `/api/auth/login`.
