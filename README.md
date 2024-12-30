# Collateralized Loan Smart Contract

This repository contains a simple collateralized loan contract developed, deployed, and interacted with on the Ethereum blockchain using Solidity. The contract manages loans backed by Ethereum as collateral, providing a practical implementation of financial smart contracts. it shows a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.


### Dependencies

Hardhat is used to write, deploy, and test the smart contract.

### Installation

For local environments, navigate to `hardhat-js` and install the dependencies with:

```
npm install
```

Create a `.env` file based on the `.env` file provided:

```
INFURA_API_KEY=
ACCOUNT_PRIVATE_KEY=
```

Add your wallet private key and [Infura](https://www.infura.io/) API key.

## Testing

Create a new file in the `test` folder to write the tests.


```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

The contract has been deployed on the sepolia testnet 

https://sepolia.etherscan.io/tx/0xf7a010884b178ecb6ad401ed108fd9bd9aebd9d3d66e6ada525ec6ac7f0c4ea1
