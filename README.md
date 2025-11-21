# GreenFuture - Environmental Crowdfunding Platform

## Overview

GreenFuture is a decentralized crowdfunding platform built on the Stacks blockchain using Clarity smart contracts. It enables communities to collectively fund environmental conservation and sustainability projects through STX token contributions.

## Purpose

GreenFuture addresses the funding gap for environmental initiatives by leveraging blockchain technology to create transparent, trustless crowdfunding mechanisms. The platform empowers project creators to launch sustainability projects and allows supporters worldwide to contribute to causes they believe in.

## Key Features

### 1. Project Creation
- Project creators can launch environmental initiatives with:
  - Project title and detailed description
  - Target funding amount (in STX)
  - Flexible deadline for fundraising
- Each project receives a unique ID for tracking

### 2. Transparent Contributions
- Community members contribute STX tokens to support projects
- All contributions are recorded immutably on the blockchain
- Track individual contributions per project and per user
- View real-time funding progress

### 3. Project Management
- **Three Project States:**
  - **Active:** Accepting contributions
  - **Completed:** Fundraising period ended, funds ready for withdrawal
  - **Cancelled:** Project cancelled, may apply for refunds

### 4. Fund Withdrawal
- Creators can only withdraw funds after:
  - Project reaches its funding goal
  - Project status is marked as completed
  - Funds are transferred directly to the creator's wallet

### 5. Platform Analytics
- View total projects created
- Track total STX raised across all projects
- Monitor individual user contribution history

## Smart Contract Functions

### Public Functions

#### `create-project`
Creates a new environmental project.
```
Parameters:
- title: Project name (max 100 characters)
- description: Project details (max 500 characters)
- target-amount: Funding goal in STX (must be > 0)
- deadline: Project deadline (must be > 0)

Returns: Project ID on success
```

#### `contribute-to-project`
Contributes STX to an active project.
```
Parameters:
- project-id: ID of target project
- amount: STX amount to contribute (must be > 0)

Returns: true on success
```

#### `complete-project`
Marks a project as completed (only creator can call).
```
Parameters:
- project-id: ID of project to complete

Returns: true on success
```

#### `cancel-project`
Cancels an active project (only creator or contract owner).
```
Parameters:
- project-id: ID of project to cancel

Returns: true on success
```

#### `withdraw-funds`
Withdraws funds from a completed project to creator's wallet.
```
Parameters:
- project-id: ID of project

Returns: true on success
Requirements:
- Project must be completed
- Funding goal must be met
- Caller must be the project creator
```

### Read-Only Functions

#### `get-project`
Retrieves complete project details.
```
Parameters:
- project-id: ID of project

Returns: Project data or none if not found
```

#### `get-user-contribution`
Retrieves a user's contribution to a specific project.
```
Parameters:
- project-id: ID of project
- user: User's wallet address

Returns: Contribution amount or none
```

#### `get-user-total-contributions`
Gets total STX contributed by a user across all projects.
```
Parameters:
- user: User's wallet address

Returns: Total contribution amount or none
```

#### `get-platform-stats`
Retrieves platform-wide statistics.
```
Returns: Object containing:
- total-projects: Number of projects created
- total-raised: Total STX raised across platform
```

#### `is-goal-met`
Checks if a project has reached its funding goal.
```
Parameters:
- project-id: ID of project

Returns: true if goal met, false otherwise
```

## Data Structures

### Project Map
```
{
  project-id: uint,
  title: string-ascii (100 chars),
  description: string-ascii (500 chars),
  creator: principal (wallet address),
  target-amount: uint (STX),
  current-amount: uint (STX raised),
  deadline: uint,
  status: uint (1=active, 2=completed, 3=cancelled),
  created-at: uint
}
```

### Contributions Map
```
{
  project-id: uint,
  contributor: principal,
  amount: uint (STX contributed)
}
```

### User Contributions Map
```
{
  user: principal,
  total-contributed: uint (total STX)
}
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u1 | ERR-UNAUTHORIZED | Caller not authorized for this action |
| u2 | ERR-INVALID-AMOUNT | Invalid amount or parameter value |
| u3 | ERR-PROJECT-NOT-FOUND | Project ID does not exist |
| u4 | ERR-PROJECT-ACTIVE | Operation requires inactive project |
| u5 | ERR-PROJECT-INACTIVE | Operation requires active project |
| u6 | ERR-ALREADY-FUNDED | User has already funded this project |
| u7 | ERR-GOAL-NOT-MET | Project funding goal not reached |
| u8 | ERR-INSUFFICIENT-BALANCE | Insufficient STX balance |

## Usage Workflow

### For Project Creators

1. **Create Project**
   - Call `create-project` with project details
   - Receive project ID

2. **Wait for Contributions**
   - Community members contribute STX
   - Monitor funding progress with `get-project`

3. **Complete Project**
   - Call `complete-project` when ready to end fundraising
   - Project status changes to "Completed"

4. **Withdraw Funds**
   - Call `withdraw-funds` to claim funds
   - Must have met funding goal
   - STX transferred to creator's wallet

### For Contributors

1. **Browse Projects**
   - View available projects using `get-project`
   - Check `is-goal-met` to verify progress

2. **Contribute**
   - Call `contribute-to-project` with amount
   - STX transferred from your wallet

3. **Track Contributions**
   - Use `get-user-contribution` for specific projects
   - Use `get-user-total-contributions` for overview

## Security Considerations

- **Authorization:** Only project creators can withdraw or complete their projects
- **Immutability:** All contributions recorded permanently on blockchain
- **Fund Safety:** Funds held in contract until explicit withdrawal
- **Goal Verification:** Withdrawal only possible after goal is met
- **Status Tracking:** Three-state system prevents conflicting operations

## Deployment

### Prerequisites
- Stacks blockchain node access
- Clarity compiler
- STX tokens for deployment

### Deployment Steps

1. Compile the contract:
   ```bash
   clarity-cli compile GreenFuture.clar
   ```

2. Deploy to testnet/mainnet:
   ```bash
   stx deploy GreenFuture.clar
   ```

3. Note the contract address for interactions

## Testing

### Test Scenarios

1. **Create multiple projects** with varying targets and deadlines
2. **Test contributions** from different wallets
3. **Verify project state** transitions (active → completed)
4. **Test fund withdrawal** with met and unmet goals
5. **Validate error handling** for edge cases

### Example Test Commands

```clarity
;; Create a solar panel project
(create-project 
  "Community Solar Panel Initiative" 
  "Install solar panels in rural areas"
  u1000000
  u52560)

;; Contribute 50 STX
(contribute-to-project u1 u50000000)

;; Check contribution
(get-user-contribution u1 tx-sender)

;; View platform stats
(get-platform-stats)
```

## Future Enhancements

- Multi-signature requirements for large withdrawals
- Refund mechanism for failed projects
- Milestone-based fund releases
- Governance token for platform decisions
- Integration with environmental impact verification oracles
- Support for multiple tokens (USDA, etc.)
- Project categorization and filtering

## Support

For issues, questions, or contributions, please visit the project repository or contact the development team.

## Contributing

We welcome contributions to improve GreenFuture! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your improvements
4. Test thoroughly
5. Submit a pull request

Together, we can build a more sustainable future! 🌍🌱