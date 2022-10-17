# Solidity Challenge

- You are asked to write smart contracts for an ETH staking app.
- User can stake their ETH in a vault (Constant APR 10%)
- User gets rewarded in devUSDC (an ERC20 token you will create as well)
- Assume that devUSDC is always worth $1
- When a user stakes ETH: all of that ETH will be put as collateral in Compound (v2).
- When a user wants to Withdraw their ETH. The vault will take out the ETH the user staked (without the yields) from Compound and will give it back to the user with the devUSDC rewards
- Minimum amount to stake is 5 ETH
- To get the price of ETH you will need to use a price oracle from chainlink

# Submission - should be in the form of:

1. Github repo with the contract code
2. Typescript Tests using Hardhat with at least two users simultaneously staking/unstaking funds.
3. Deployed contracts to Goerli Testnet.
4. Verified contracts on etherscan.

# Run scripts
```
npx hardhat run scripts/deploy.ts --network goerli
```

# Deploy and Verify
DevUSDC deployed to:  0x0B884EAa34d6025C5e9AD72ABE428C21a75A2E6A

Staking deployed to:  0x62927BD311f9173d322416d798168D7a0985f9f4


