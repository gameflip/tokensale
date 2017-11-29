pragma solidity ^0.4.11;


import './FlipCrowdsale.sol';
import './FlipToken.sol';

/*
 * MainSale is
 *  - token capped at FlipToken.TOTAL_TOKENS minus those sold in PreSale and special token grants
 *  - 0.1 ether minimum purchase amount
 *  - exchange rate varies with time of sale
 */
contract MainSale is FlipCrowdsale {
    using SafeMath for uint256;

    function MainSale(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    FlipCrowdsale(_token, _startTime, _endTime, _ethWallet)
    {
    }

    function tokensRemaining() constant public returns (uint256) {
        FlipToken tok = FlipToken(token);
        return tok.TOTAL_TOKENS().sub(tok.totalSupply());
    }

    function setEndTime(uint256 _endTime) onlyOwner public {
        require(!hasEnded());
        require(_endTime >= now);
        require(_endTime >= startTime);
        endTime = _endTime;
    }

    /*
     * internal functions
     */
    function applyExchangeRate(uint256 _wei) constant internal returns (uint256) {
        // white paper (6.4 Token Main Sale) specifies rates based on purchase time
        uint256 minPurchaseAmt = 100 finney;
        require(_wei >= minPurchaseAmt);
        // compute token-per-wei rate based on current date
        uint256 period = endTime.sub(startTime).div(4);
        uint256 nowts = now;

        uint256 rate;
        // checks for before startTime and after endTime are handled elsewhere
        if(nowts < startTime.add(period)) {
            rate = 250;
        } else if(nowts < startTime.add(period).add(period)) {
            rate = 230;
        } else if(nowts < startTime.add(period).add(period).add(period)) {
            rate = 220;
        } else {
            rate = 200;
        }

        uint256 tokens = _wei.mul(rate);
        // check token cap
        uint256 remaining = tokensRemaining();
        require(remaining >= tokens);
        // if remaining tokens cannot be purchased (at current rate) then gift to current buyer ... it's a sellout!
        uint256 min_tokens_purchasable = minPurchaseAmt.mul(rate);
        remaining = remaining.sub(tokens);
        if(remaining < min_tokens_purchasable) {
            tokens = tokens.add(remaining);
        }
        return tokens;
    }
}
