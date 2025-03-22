# BAB Contracts

## BABFactory.sol
This is the factory contract that to create BAB token.


### `Config`
The config of BAB factory

`Config.protocolFeeRecipient`: The address that receive protocol fee of BAB

`Config.weth`: The address of WETH token

`Config.nonfungiblePositionManager`: The nonfungiblePositionManager address of DEX

`Config.swapRouter`: The nonfungiblePositionManager address of  of DEX

`Config.bondingCurve`: The adderss of bonding curve contract which is used for calculate price

`Config.tradeCreatorFeeBps`: The percentage of graduate fee that give to token creator

`Config.lpCreatorFeeBps`: The percentage LP fee that give to token creator

`Config.createTokenFee`: The fee required to create a token

### `createToken(string memory name, string memory symbol, address validator, string memory tokenUri, bytes32 _salt) external payable returns (address)`
This method is to create a BAB token with specific name, symbol and tokenURI. Sender can also pass value to this method to buy initial token. It will return the address of the created BAB token

`name`: The name of the token

`symbol`: The symbol of the token

`validator`: The address of validator contract of the token, which will be called in token's `buy` function

`tokenUri`: The tokenUri of the token, it should be a link to a json file that include image, description, twitter, telegram and website param.

`_salt`: The salt that used to call `new BAB`, it is used for control the address of token.

## BABTValidator.sol

This is the contract that to verify sender has a BABT token. 

### `BABTToken`
The address of BABT token

### `validate(address sender, uint256 value, bytes32 data) public view returns (bool)`
The function to verify whether an address has BABT token. This method will be called in BAB.sol's buy function.

`sender`: The sender of the transaction

`value`: The value of the transaction, which is not used in this contract

`data`: The placeholder params that to expand other types of validator

## TestValidator.sol

This is the contract that to test validator can works correctly since there is no BABT on testnet. The functions in this contract is same as BABTValidator.sol.

## BondingCurve.sol

The utility contract that to calcute the price of a BAB token transaction which has not gradute. The price of each token is an exponential function. f(x) = A * exp(Bx)

### `A` and `B`
The params for token's price formula

### `getEthSellQuote(uint256 currentSupply, uint256 ethOrderSize) external pure returns (uint256)`
Get the amount of token someone should sell if he want to receive specific ETH under specific totalSupply

`currentSupply`: The current total supply of a token

`ethOrderSize`: The amount of ETH to receive

### `getTokenSellQuote(uint256 currentSupply, uint256 tokensToSell) external pure returns (uint256)`
Get the ETH to receive when someone want to sell specific amount of token under specific totalSupply

`currentSupply`: The current total supply of a token

`tokensToSell`: The amount of tokens to sell

### `getEthBuyQuote(uint256 currentSupply, uint256 ethOrderSize) external pure returns (uint256)`
Get the amount of token when someone want to buy with specific ETH of token under specific totalSupply

`currentSupply`: The current total supply of a token

`ethOrderSize`: The amount of ETH to pay

### `getTokenBuyQuote(uint256 currentSupply, uint256 tokenOrderSize) external pure returns (uint256)`
Get the amount of ETH when someone want to buy specific amount of token under specific totalSupply

`currentSupply`: The current total supply of a token

`tokenOrderSize`: The amount of tokens to receive

## BAB.sol

This is the contract of BAB token. It has two phase. In phase 1, user can mint and burn token with the price that calculated in BondingCurve.sol and user cannot add token to DEX's pool. In this phase, only address having BABT token can mint this token. When 800 million token is minted, the contract will add the ETH it received and 200 million token to the DEX's pool and enter phase 2. In this phase, anyone can trade to this token either from this contract or directly from DEX.

### `constructor(string memory name, string memory symbol, string memory _tokenURI, address _factory, address _tokenCreator, address _validator)`
This function is the contructor of a BAB token. It defines the name, symbol and tokenURI of a token. This function will also create the pool of this token and WETH on DEX and prevent anyone tranfer token to pool address in `_update` function. Therefore, the price when this token is graduate will be as our expected.

`name`: The name of the token

`symbol`: The symbol of the token

`tokenUri`: The tokenUri of the token, it should be a link to a json file that include image, description, twitter, telegram and website param.

`_factory`: The address of BAB factory contract

`_tokenCreator`: The address the create this token from factory contract

`validator`: The address of validator contract



### `buy(address recipient, address refundRecipient, uint256 minOrderSize, uint160 sqrtPriceLimitX96, bytes32 data)`
This function is to buy this token.

When this token has not graduate, the function will call validator contract's `validate` function to verify the sender has permission to buy this token. In production, we will set the validator contract to BABTValidator.sol. The amount of token that he will receive is calculated in BondingCurve.sol. If one transaction will cause the total supply of this token equal or greater then 800 million, he will only receive (800 millon - totalSupply before transaction), and remaing eth will return to sender, and this token will graduate and add the ETH it received and 200 million token to DEX's pool.

The this token has graduate, the contract will simply call the DEX's `exactInputSingle` function that to process a transaction. Then, the contract will automatically distribute the LP fee to procotol and token creator.

`recipient`: The address to receive the token

`refundRecipient`: The address to receive the refund

`minOrderSize`: The minimum token that send want to receiv. If the trueOrderSize caluculated in BondingCurve is smaller that this value, this transaction will be reverted.

`sqrtPriceLimitX96`: The `sqrtPriceLimitX96` that passed to DEX's `exactInputSingle` function

`data`: A placeholder param to recored customer message.


### `sell(uint256 tokensToSell, address recipient, uint256 minPayoutSize, uint160 sqrtPriceLimitX96)`
This function is to sell this token.

Then this token has not graduate, this function will burn sender's token and receive ETH with amount the calucated in BondingCurve.sol.

The this token has graduate, the contract will simply call the DEX's `exactInputSingle` function that to process a transaction.

`tokensToSell`: The amount of token that send want to sell

`recipient`: The address to receive ETH

`minPayoutSize`: The mimimun ETH that send want to receive of this transaction. If the trueOrderSize caluculated in BondingCurve is smaller that this value, this transaction will be reverted.

`sqrtPriceLimitX96`: The `sqrtPriceLimitX96` that passed to DEX's `exactInputSingle` function


### `claimSecondaryRewards`
This function is to collect all the LP fee on DEX and distribute them to protocol and token creator.