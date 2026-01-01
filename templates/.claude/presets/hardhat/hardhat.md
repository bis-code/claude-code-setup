# Hardhat/Solidity Development Rules

## Smart Contract Guidelines

### Security First
- Always check for reentrancy vulnerabilities
- Use OpenZeppelin contracts where possible
- Follow checks-effects-interactions pattern
- Never use `tx.origin` for authorization
- Be explicit about function visibility
- Use `SafeMath` or Solidity 0.8+ for arithmetic

### Testing
- Write tests for all contract functions
- Test edge cases and failure modes
- Use hardhat's `expect` assertions
- Test gas consumption for critical paths
- Mock external contracts when needed

### Code Style
- Use NatSpec comments for all public functions
- Follow Solidity style guide
- Keep contracts focused and modular
- Use events for state changes
- Validate all inputs

### Deployment
- Use deployment scripts, not console
- Verify contracts on block explorer
- Document constructor arguments
- Test on testnet before mainnet
- Keep deployment logs

### Common Patterns
```solidity
// Reentrancy guard
modifier nonReentrant() {
    require(!locked, "No reentrancy");
    locked = true;
    _;
    locked = false;
}

// Access control
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}
```

## Hardhat Specifics

### Configuration
- Use TypeScript for configs and scripts
- Configure multiple networks
- Set up gas reporter
- Enable optimizer for production

### Testing Commands
```bash
npx hardhat test
npx hardhat coverage
npx hardhat test --network hardhat
```

### Deployment
```bash
npx hardhat run scripts/deploy.ts --network <network>
npx hardhat verify --network <network> <address> <args>
```
