## 🧩 Stakeholder-to-Contract Interaction

| Stakeholder Script    | Interacts With                      | Purpose / Functions Called |
|-----------------------|-------------------------------------|-----------------------------|
| `regulator.py`        | `MaterialTrackingContract`          | `mintMaterial()`, `setBurnerApproval()` |
|                       |                                     | *Owns the material contract; acts as system authority* |
|                       |                                     |                             |
| `manufacturer.py`     | `MaterialTrackingContract`          | `getMaterial()`, `balanceOf()` |
|                       | `MintContract`                      | `mintProduct()`             |
|                       | `OwnershipControl` (optional)       | `assignInitial()`           |
|                       |                                     | *Creates NFTs using raw materials; links to product metadata* |
|                       |                                     |                             |
| `retailer.py`         | `OwnershipControl`                  | `firstSale()`               |
|                       |                                     | *Transfers NFT from retailer to first consumer* |
|                       |                                     |                             |
| `consumer_a.py`       | `OpenSale`                          | `transfer()`                |
|                       | `MintContract`                      | `getMaterialsForProduct()`  |
|                       | `MaterialTrackingContract`          | `getMaterial()`             |
|                       |                                     | *Buys NFT and resells it; verifies material traceability* |
|                       |                                     |                             |
| `consumer_b.py`       | `MintContract`                      | `getMaterialsForProduct()`  |
|                       | `MaterialTrackingContract`          | `getMaterial()`             |
|                       |                                     | *Receives NFT via resale; verifies product origin* |
