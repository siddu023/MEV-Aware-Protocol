# 🔐 MEV-Aware Protocol Suite

**Built by Sai Siddush Thungathurthy** — Smart Contract Engineer | DeFi Protocol Architect


This is a modular DeFi system designed  to **resist common MEV exploits** like sandwich attacks, backrun liquidations, and frontrun-based vault draining.

Inspired by MEV protection techniques from CoWSwap, Flashbots, and auction-based liquidations (Ajna/Euler).

---

## ⚙️ Components

### `MEVProtectedRouter.sol`
A swap router that defends against sandwich attacks by:
- Enforcing `minOut` slippage checks
- Requiring a cooldown period before swaps settle
- Routing assets to a vault instead of direct to the user

### `TimeLockedVault.sol`
A secure vault contract that:
- Delays withdrawals via block-based cooldowns
- Prevents predictable exit-based frontruns or LP griefing

### `BackrunLiquidator.sol`
A liquidation execution controller that:
- Marks eligible liquidations
- Requires a delay before execution
- Optional: extendable to auction-based execution

---

## 🛡️ Threat Model & Protections

| Attack Type         | Defense Mechanism                   | Location              |
|---------------------|--------------------------------------|------------------------|
| 🥪 Sandwich attack  | Cooldown + slippage + delayed settle| `MEVProtectedRouter`   |
| 🏃 Frontrun exit     | Vault cooldown + withdrawal delay   | `TimeLockedVault`      |
| 💣 Liquidation snipe| Delay between eligible + executable | `BackrunLiquidator`    |
| 👁️ Mempool abuse    | Optional Flashbots/private execution| Extendable              |

---

## 🔁 Flow Diagram

### Swap Flow

User → Router.requestSwap()
→ Tokens escrowed
→ Wait N blocks
→ Anyone calls executeSwap()
→ Tokens routed to vault


User deposits → Vault locks funds
User waits LOCK_PERIOD
User withdraws only after delay

Check borrower health
If unhealthy → markLiquidation()
After cooldown → executeLiquidation()



contracts/
├── MEVProtectedRouter.sol     ← Anti-sandwich entry router
├── TimeLockedVault.sol        ← Withdrawal cooldown vault
├── BackrunLiquidator.sol      ← Delay-based liquidation engine
├── Mocks/
│   ├── MockToken.sol
│   └── MockOracle.sol
