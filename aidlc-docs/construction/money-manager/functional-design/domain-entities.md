# Domain Entities — money-manager

All monetary values are **integer minor units** (e.g., cents). `kind` enums shared where noted.

## Enums
```
TransactionKind = income | expense
CategoryKind    = income | expense
WalletType      = cash | bank | card | other
BudgetStatus    = ok | warn | over
ThemeMode       = system | light | dark
```

## Wallet
| Field | Type | Notes |
|---|---|---|
| id | int | PK, autoincrement |
| name | String | required, unique (case-insensitive), 1..40 chars |
| type | WalletType | default `cash` |
| iconCodePoint | int | Material icon |
| colorValue | int | ARGB |
| archived | bool | default false; archived hidden from pickers |

Derived: `balanceMinor` = Σ(income txns) − Σ(expense txns) for this wallet.

## Category
| Field | Type | Notes |
|---|---|---|
| id | int | PK |
| name | String | required, unique per kind, 1..40 chars |
| kind | CategoryKind | income or expense |
| iconCodePoint | int | Material icon |
| colorValue | int | ARGB |
| isDefault | bool | true for seeded categories |
| archived | bool | default false |

## TransactionEntry
| Field | Type | Notes |
|---|---|---|
| id | int | PK |
| amountMinor | int | > 0 (sign implied by kind) |
| kind | TransactionKind | income or expense |
| categoryId | int | FK → Category; category.kind must match kind |
| walletId | int | FK → Wallet |
| date | DateTime | date of transaction (time optional) |
| note | String? | optional, ≤ 200 chars |
| createdAt | DateTime | audit, set on insert |

## Budget
| Field | Type | Notes |
|---|---|---|
| id | int | PK |
| categoryId | int | FK → Category (expense kind only) |
| limitMinor | int | > 0 |
| month | String | `YYYY-MM` |
| — | — | UNIQUE(categoryId, month) |

Derived (via BudgetCalculator): spentMinor, remainingMinor, percent, status.

## AppSettings (not a DB table — key/value)
| Field | Type | Default |
|---|---|---|
| currencyCode | String | device locale currency or `USD` |
| themeMode | ThemeMode | system |
| appLockEnabled | bool | false |

## Relationships
```text
Wallet   1 ──── * TransactionEntry
Category 1 ──── * TransactionEntry
Category 1 ──── 0..* Budget   (one per month via unique constraint)
```

## Referential Rules
- Delete Wallet/Category with referencing transactions → blocked; offer archive instead.
- Delete Budget → free (no dependents).
- Category.kind must equal Transaction.kind on assignment.
