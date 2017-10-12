pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/token/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/PausableToken.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoTokens.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoEther.sol';
import 'zeppelin-solidity/contracts/ownership/Contactable.sol';

/*
 * FlipToken is a ERC20 token that
 *  - caps total number at 100 million tokens
 *  - can pause and unpause token transfer (and authorization) actions
 *  - mints new tokens when purchased (rather than transferring tokens pre-granted to a holding account)
 *  - attempts to reject ERC20 token transfers to itself and allows token transfer out
 *  - attempts to reject ether sent and allows any ether held to be transferred out
 */
contract FlipToken is Contactable, HasNoTokens, HasNoEther, MintableToken, PausableToken {

    string public constant name = "FLIP Token";
    string public constant symbol = "FLP";
    uint8 public constant decimals = 18;

    uint256 public constant ONE_TOKENS = (10 ** uint256(decimals));
    uint256 public constant MILLION_TOKENS = (10**6) * ONE_TOKENS;
    uint256 public constant TOTAL_TOKENS = 100 * MILLION_TOKENS;

    function FlipToken()
    Ownable()
    Contactable()
    HasNoTokens()
    HasNoEther()
    MintableToken()
    PausableToken()
    {
        contactInformation = 'https://tokensale.gameflip.com/';
    }

    // cap minting so that totalSupply <= TOTAL_TOKENS
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply.add(_amount) <= TOTAL_TOKENS);
        return super.mint(_to, _amount);
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
}
