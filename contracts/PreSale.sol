pragma solidity ^0.4.11;


import './FlipCrowdsale.sol';
import './FlipToken.sol';


/*
 * PreSale is
 *  - capped at 6.8 million tokens
 *  - 3 ether minimum purchase amount
 *  - exchange rate varies with purchase amount
 */
contract PreSale is FlipCrowdsale {
    using SafeMath for uint256;

    uint256 public constant PRESALE_TOKEN_CAP = 238 * (10**4) * (10 ** uint256(18)); // 2.38 million tokens
    uint256 public minPurchaseAmt = 3 ether;

    function PreSale(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    FlipCrowdsale(_token, _startTime, _endTime, _ethWallet)
    {
    }

    function setMinPurchaseAmt(uint256 _wei) onlyOwner public {
        require(_wei >= 0);
        minPurchaseAmt = _wei;
    }

    function tokensRemaining() constant public returns (uint256) {
        return PRESALE_TOKEN_CAP.sub(tokensSold);
    }

    /*
     * internal functions
     */

    function applyExchangeRate(uint256 _wei) constant internal returns (uint256) {
        // white paper (6.3 Token Pre-Sale) specifies rates based on purchase value
        // those values here hard-coded here
        require(_wei >= minPurchaseAmt);
        uint256 tokens;
        if(_wei >= 5000 ether) {
            tokens = _wei.mul(340);
        } else if(_wei >= 3000 ether) {
            tokens = _wei.mul(320);
        } else if(_wei >= 1000 ether) {
            tokens = _wei.mul(300);
        } else if(_wei >= 100 ether) {
            tokens = _wei.mul(280);
        } else {
            tokens = _wei.mul(260);
        }
        // check token cap
        uint256 remaining = tokensRemaining();
        require(remaining >= tokens);
        // if remaining tokens cannot be purchased (at min rate) then gift to current buyer ... it's a sellout!
        uint256 min_tokens_purchasable = minPurchaseAmt.mul(260);
        remaining = remaining.sub(tokens);
        if(remaining < min_tokens_purchasable) {
            tokens = tokens.add(remaining);
        }
        return tokens;
    }

}
