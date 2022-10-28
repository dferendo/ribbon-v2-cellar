# Sommelier Cellar Contracts • [![tests](https://github.com/PeggyJV/cellar-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/PeggyJV/cellar-contracts/actions/workflows/tests.yml) [![lints](https://github.com/PeggyJV/cellar-contracts/actions/workflows/lints.yml/badge.svg)](https://github.com/PeggyJV/cellar-contracts/actions/workflows/lints.yml) ![license](https://img.shields.io/github/license/PeggyJV/cellar-contracts)

Cellar contracts for the Sommelier Network.

### Development

**Getting Started**

Before attempting to setup the repo, first make sure you have Foundry installed and updated, which can be done [here](https://github.com/foundry-rs/foundry#installation).

```bash
npm run setup
```

**Building**

Install libraries with Foundry which work with Hardhat:

```bash
forge install rari-capital/solmate # Already in this repo, just an example.
```

Whenever you install new libraries using Foundry, make sure to update your `remappings.txt` file. This repo uses `hardhat-preprocessor` and the `remappings.txt` file to allow Hardhat to resolve libraries you install with Foundry.

**Testing**

Run tests with either Hardhat or Foundry:

```bash
forge test
# or
npx hardhat test
```

Run tests on forked chains with Foundry:

```bash
forge test --fork-url ALCHEMY_API_KEY
```

Run tests for both Hardhat and Foundry:

```bash
npm run test
```

**Tasks**

Use Hardhat's task framework:

```bash
npx hardhat compile
# Before running the next command, go to `hardhat.config.ts` and uncomment "./tasks" imports.
# This is initially commented to fix initial compile errors with Hardhat.
npx hardhat example
```


forge test --match-path ./test/RibbonV2Cellar.t.sol