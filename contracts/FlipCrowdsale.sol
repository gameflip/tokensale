pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoTokens.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoContracts.sol';
import 'zeppelin-solidity/contracts/ownership/Contactable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './FlipToken.sol';


/*
 * FlipCrowdsale is the base class for both the PreSale and MainSale.
 * It is a Crowdsale that is:
 *  - time capped by start and end dates
 *  - value capped by number of tokens sold (and not ether raised)
 *  - supports a variable exchange rate by allowing sub-classes to override applyExchangeRate()
 *  - pause() and unpause() to control token purchases
 *  - finalize() transfers token ownership to this.owner
 *  - attempts to reject ERC20 token transfers to itself and allows token transfer out
 *  - allows child contract ownership to be transferred to this.owner
 *  - allows wallet which receives sales proceeds to be updated
 */
contract FlipCrowdsale is Contactable, Pausable, HasNoContracts, HasNoTokens, FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public tokensSold = 0;

    // ignore the Crowdsale.rate and dynamically compute rate based on other factors (e.g. purchase amount, time, etc)
    function FlipCrowdsale(MintableToken _token, uint256 _startTime, uint256 _endTime, address _ethWallet)
    Ownable()
    Pausable()
    Contactable()
    HasNoTokens()
    HasNoContracts()
    Crowdsale(_startTime, _endTime, 1, _ethWallet)
    FinalizableCrowdsale()
    {
        // deployment must set token.owner = FlipCrowdsale.address to allow minting
        token = _token;
        contactInformation = 'https://tokensale.gameflip.com/';
    }

    function setWallet(address _wallet) onlyOwner public {
        require(_wallet != 0x0);
        wallet = _wallet;
    }

    // over-ridden low level token purchase function so that we
    // can control the token-per-wei exchange rate dynamically
    function buyTokens(address beneficiary) public payable whenNotPaused {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = applyExchangeRate(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function tokenTransferOwnership(address newOwner) public onlyOwner {
        require(hasEnded());
        token.transferOwnership(newOwner);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        // do not allow self ownership
        require(newOwner != address(this));
        super.transferOwnership(newOwner);
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        bool capReached = tokensRemaining() == 0;
        return super.hasEnded() || capReached;
    }

    // sub-classes must override to control tokens sales cap
    function tokensRemaining() constant public returns (uint256);


    /*
     * internal functions
     */
    function createTokenContract() internal returns (MintableToken) {
        return token;
    }

    // sub-classes must override to customize token-per-wei exchange rate
    function applyExchangeRate(uint256 _wei) constant internal returns (uint256);

    /**
       * @dev Can be overridden to add finalization logic. The overriding function
       * should call super.finalization() to ensure the chain of finalization is
       * executed entirely.
       */
    function finalization() internal {
        // if we own the token, pass ownership to our owner when finalized
        if(address(token) != address(0) && token.owner() == address(this) && owner != address(0)) {
            token.transferOwnership(owner);
        }
        super.finalization();
    }
}
