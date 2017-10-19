pragma solidity ^0.4.15;


import './PreSale.sol';
import './FlipToken.sol';


/*
 * PreSaleExtended is
 *  - capped at token sold limit
 *  - minimum purchase amount (ether)
 *  - exchange rate varies with purchase amount
 */
contract PreSaleExtended is PreSale {
    using SafeMath for uint256;

    uint256 public extendedTokenCap;

    function PreSaleExtended(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    PreSale(_token, _startTime, _endTime, _ethWallet)
    {
        minPurchaseAmt = 1 ether;
    }

    function setExtendedTokenCap(uint256 _extendedTokenCap) public onlyOwner returns(uint256) {
        require(_extendedTokenCap <= PRESALE_TOKEN_CAP); // not over initial presale hard-cap
        require(_extendedTokenCap > extendedTokenCap);  // not decreasing existing cap
        extendedTokenCap = _extendedTokenCap;
    }

    function tokensRemaining() constant public returns (uint256) {
        return extendedTokenCap.sub(tokensSold);
    }

}
