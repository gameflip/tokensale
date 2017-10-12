pragma solidity ^0.4.11;


import './FlipToken.sol';
import 'zeppelin-solidity/contracts/token/TokenTimelock.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoTokens.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoEther.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoContracts.sol';
import 'zeppelin-solidity/contracts/ownership/Contactable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/*
 * Timelocks create and hold references to TokenTimelock contracts for the FLIP Tokens
 * set-aside for network, gameflip, and partner uses.
 */
contract Timelocks is Contactable, HasNoTokens, HasNoEther, HasNoContracts {
    using SafeMath for uint256;

    FlipToken public token;
    TokenTimelock public network_20171215;
    TokenTimelock public network_20180401;
    TokenTimelock public network_20180701;
    TokenTimelock public network_20181001;
    TokenTimelock public gameflip_20180101;
    TokenTimelock public gameflip_20190101;
    TokenTimelock public gameflip_20200101;
    TokenTimelock public partner_20180101;
    TokenTimelock public unsoldTimelock;
    address public unsoldBeneficiary;

    uint256 public constant ONE_TOKENS = (10**18);
    uint256 public constant MILLION_TOKENS = (10**6) * ONE_TOKENS;
    // special token grants
    // white paper section 6.5(a)
    uint256 public constant NETWORK_TOKENS = 40 * MILLION_TOKENS;
    // white paper section 6.5(b)
    uint256 public constant GAMEFLIP_TOKENS = 14 * MILLION_TOKENS;
    // white paper section 6.5(c)
    uint256 public constant PARTNER_TOKENS = 2800000 * ONE_TOKENS;


    function Timelocks(FlipToken _token)
    Ownable()
    Contactable()
    HasNoContracts()
    HasNoTokens()
    HasNoEther()
    {
        require(address(_token) != 0x0);
        contactInformation = 'https://tokensale.gameflip.com/';
        token = _token;
    }

    // one-time-use method to create special tokens specified in white paper
    // specifically section 6.5 Other Tokens
    // must be run after creation and before minting begins
    function createReservedTokens(address _network, address _gameflip, address _partner) onlyOwner public {
        require(_network != 0x0);
        require(_gameflip != 0x0);
        require(_partner != 0x0);
        require(address(token) != 0x0);
        require(token.totalSupply() == 0);

        unsoldBeneficiary = _network;

        // token release dates from white paper Table 4.6 and section 6.5
        uint64 dt_20171215 = 1513296000; //Date.parse('2017-12-15T00:00:00Z')/1000
        uint64 dt_20180101 = 1514764800; //Date.parse('2018-01-01T00:00:00Z')/1000
        uint64 dt_20180401 = 1522540800; //Date.parse('2018-04-01T00:00:00Z')/1000
        uint64 dt_20180701 = 1530403200; //Date.parse('2018-07-01T00:00:00Z')/1000
        uint64 dt_20181001 = 1538352000; //Date.parse('2018-10-01T00:00:00Z')/1000
        uint64 dt_20190101 = 1546300800; //Date.parse('2019-01-01T00:00:00Z')/1000
        uint64 dt_20200101 = 1577836800; //Date.parse('2020-01-01T00:00:00Z')/1000

        // Network Growth
        network_20171215 = mintAndGrant(_network, 10 * MILLION_TOKENS, dt_20171215);
        network_20180401 = mintAndGrant(_network, 10 * MILLION_TOKENS, dt_20180401);
        network_20180701 = mintAndGrant(_network, 10 * MILLION_TOKENS, dt_20180701);
        network_20181001 = mintAndGrant(_network, 10 * MILLION_TOKENS, dt_20181001);

        // gameflip tokens
        gameflip_20180101 = mintAndGrant(_gameflip, 2 * MILLION_TOKENS, dt_20180101);
        gameflip_20190101 = mintAndGrant(_gameflip, 4 * MILLION_TOKENS, dt_20190101);
        gameflip_20200101 = mintAndGrant(_gameflip, 8 * MILLION_TOKENS, dt_20200101);

        // partner tokens
        partner_20180101 = mintAndGrant(_partner, PARTNER_TOKENS, dt_20180101);
    }

    function grantUnsold() onlyOwner public {
        uint256 unsoldTokens = token.TOTAL_TOKENS().sub(token.totalSupply());
        if(unsoldTokens > 0) {
            uint64 dt_20180701 = 1530403200; //Date.parse('2018-07-01T00:00:00Z')/1000
            unsoldTimelock = mintAndGrant(unsoldBeneficiary, unsoldTokens, dt_20180701);
        }
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

    /*
     * Internal methods
     */

    function mintAndGrant(address _to, uint256 _value, uint64 _unlock) internal returns (TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(token, _to, _unlock);
        token.mint(timelock, _value);
        return timelock;
    }

}
