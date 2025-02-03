// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CUPT {
    bool public paused;
    string public constant name = "CUPT";
    string public constant symbol = "CUPT";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelistedContracts;

    // Add pause event
    event Paused(address account);
    event Unpaused(address account);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Blacklisted(address indexed account, bool status);
    event Whitelisted(address indexed account, bool status);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Add whenNotPaused modifier
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Add whenPaused modifier
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply = 3750000000 * 10 ** 6;
        balanceOf[msg.sender] = totalSupply;
        paused = false; // Initialize as unpaused
    }

    // Add pause/unpause functions
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Account is blacklisted");
        _;
    }

    function blacklist(address account, bool status) external onlyOwner {
        require(blacklisted[account] != status, "Already in this state");
        blacklisted[account] = status;
        emit Blacklisted(account, status);
    }

    function isWhitelisted(address _contract) external view returns (bool) {
        return whitelistedContracts[_contract];
    }

    function addToWhitelist(address _contract) external onlyOwner {
        require(isContract(_contract), "Not a contract");
        whitelistedContracts[_contract] = true;
        emit Whitelisted(_contract, true);
    }

    function removeFromWhitelist(address _contract) external onlyOwner {
        require(whitelistedContracts[_contract], "Not in whitelist");
        whitelistedContracts[_contract] = false;
        emit Whitelisted(_contract, false);
    }

    function transfer(
        address to,
        uint256 value
    )
        public
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        uint256 senderBalance = balanceOf[msg.sender];
        require(to != address(0), "Cannot transfer to zero address");
        require(senderBalance >= value, "Insufficient balance");

        senderBalance -= value;
        balanceOf[msg.sender] = senderBalance;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) public whenNotPaused returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        require(
            value == 0 || allowance[msg.sender][spender] == 0,
            "Reset allowance to zero first"
        );

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        whenNotPaused
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be positive");

        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(to, amount);
    }

    function burn(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
    }

    // Add these to your current token contract
    // To support future staking/LP features
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
