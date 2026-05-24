CrumbsVaultV3 — Smart Farming & Automation Vault (Upgradeable)

CrumbsVaultV3 is an upgradeable, modular, automation‑driven smart contract vault designed for farming, liquidity operations, promo disbursements, and bot‑assisted execution.
It merges the stability of the original Crumbs Vault with the advanced automation engine of V2, resulting in a fully unified, production‑grade V3.

✨ Key Features

• Upgradeable architecture (UUPS‑compatible via OZ Upgradeable)
• Deterministic wallet rotation with cooldown enforcement
• Bot automation engine with roles, cooldowns, and execution logging
• Multisig governance with nonce‑based replay protection
• Promo & farming toggles for runtime control
• Staking, unstaking, harvesting, and liquidity hooks
• Withdraw limits + emergency withdraw
• SafeERC20 handling
• Clean event system for GUI dashboards
• Pi‑App ready ABI structure


---

📦 Contract Architecture

Core Modules

• Vault Core — ETH & ERC20 handling, withdraw limits, rotation
• Bot Engine — role‑based execution (Farming, Promo, Trader, Admin)
• Multisig — threshold approvals, nonce tracking, replay protection
• Farming Hooks — stake, unstake, harvest
• Liquidity Hooks — add liquidity via router
• Promo Hooks — controlled disbursement of ETH or tokens
• Upgrade Layer — initializer + storage‑safe layout


---

🧠 Bot Roles

Role	Purpose	
Admin	High‑level automation tasks	
Farming	Stake, unstake, harvest	
Promo	ETH/token disbursements	
Trader	Liquidity provisioning	
None	Unregistered	


Bots enforce:

• Cooldowns
• Active/inactive status
• Role‑based access
• Execution logging


---

🔐 Multisig Governance

CrumbsVaultV3 includes a lightweight but secure multisig:

• Add/remove approvers
• Set approval threshold
• Nonce‑based proposal IDs
• Replay protection
• Execution only after threshold met


This is ideal for:

• Upgrades
• Parameter changes
• High‑risk operations


---

🔁 Wallet Rotation

Rotation is deterministic and time‑based:

index = (block.timestamp / rotationInterval) % farmingWallets.length


Rotation updates:

• latestWallet
• vaultReceiver
• lastRotationTimestamp


Cooldown is enforced to prevent spam.

---

💰 Withdraw & Emergency Controls

• withdraw(amount) — respects maxWithdrawLimit
• emergencyWithdraw() — only when paused
• drainERC20(token) — safe token transfer
• maxWithdrawLimit — 0 = unlimited


---

📥 Deposits

Vault accepts ETH via:

• deposit()
• receive()
• fallback()


All emit Deposited.

---

🧱 Deployment

Prerequisites

• Node.js
• Hardhat or Foundry
• OpenZeppelin Upgradeable contracts


Initialize

initialize(
    ownerAddress,
    vaultReceiver,
    maxWithdrawLimit
)


Recommended Directory Structure

/contracts/CrumbsVaultV3.sol
/scripts/deploy.js
/scripts/upgrade.js
/abi/CrumbsVaultV3.json
