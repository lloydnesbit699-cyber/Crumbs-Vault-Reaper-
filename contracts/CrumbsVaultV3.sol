pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CrumbsVaultV3 is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    // ============================
    // Vault State
    // ============================
    address public vaultReceiver;
    uint256 public maxWithdrawLimit;
    uint256 public lastRotationTimestamp;
    uint256 public rotationInterval;

    address[] public farmingWallets;
    address public latestWallet;

    // ============================
    // Bot System
    // ============================
    enum BotRole { None, Admin, Farming, Promo, Trader }

    struct Bot {
        BotRole role;
        bool active;
        uint256 lastExecution;
        uint256 cooldown;
    }

    mapping(address => Bot) public bots;

    // ============================
    // Multisig
    // ============================
    address[] public multisigApprovers;
    uint256 public multisigThreshold;
    mapping(bytes32 => uint256) public multisigApprovals;
    mapping(bytes32 => bool) public multisigExecuted;

    // ============================
    // Events
    // ============================
    event Deposited(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event WalletRotated(address indexed newWallet);
    event BotExecuted(address indexed bot, BotRole role, string action);
    event MultisigProposed(bytes32 indexed id, address target);
    event MultisigApproved(bytes32 indexed id, address approver);
    event MultisigExecuted(bytes32 indexed id);

    // ============================
    // Initializer
    // ============================
    function initialize(
        address _owner,
        address _vaultReceiver,
        uint256 _maxWithdrawLimit
    ) public initializer {
        __Ownable_init(_owner);
        __Pausable_init();
        __UUPSUpgradeable_init();

        vaultReceiver = _vaultReceiver;
        maxWithdrawLimit = _maxWithdrawLimit;
        rotationInterval = 1 hours;
    }

    // ============================
    // UUPS Authorization
    // ============================
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ============================
    // Deposit
    // ============================
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    // ============================
    // Withdraw
    // ============================
    function withdraw(uint256 amount) external onlyOwner whenNotPaused {
        require(amount <= maxWithdrawLimit || maxWithdrawLimit == 0, "Limit exceeded");
        (bool ok, ) = vaultReceiver.call{value: amount}("");
        require(ok, "Withdraw failed");
        emit Withdraw(vaultReceiver, amount);
    }

    // ============================
    // Wallet Rotation
    // ============================
    function rotateWallet() public whenNotPaused {
        require(farmingWallets.length > 0, "No wallets");

        uint256 index = (block.timestamp / rotationInterval) % farmingWallets.length;
        latestWallet = farmingWallets[index];
        lastRotationTimestamp = block.timestamp;

        emit WalletRotated(latestWallet);
    }

    function getFarmingWallets() external view returns (address[] memory) {
        return farmingWallets;
    }

    // ============================
    // Bot System
    // ============================
    modifier onlyBotRole(BotRole role) {
        Bot storage b = bots[msg.sender];
        require(b.active, "Inactive bot");
        require(b.role == role, "Wrong role");
        require(block.timestamp >= b.lastExecution + b.cooldown, "Cooldown");
        _;
        b.lastExecution = block.timestamp;
    }

    function registerBot(address bot, BotRole role, uint256 cooldown) external onlyOwner {
        bots[bot] = Bot(role, true, 0, cooldown);
    }

    function disableBot(address bot) external onlyOwner {
        bots[bot].active = false;
    }

    // ============================
    // Multisig
    // ============================
    function proposeMultisigAction(address target, bytes calldata data) external returns (bytes32) {
        bytes32 id = keccak256(abi.encode(target, data, block.timestamp));
        emit MultisigProposed(id, target);
        return id;
    }

    function approveMultisig(bytes32 id) external {
        require(isApprover(msg.sender), "Not approver");
        multisigApprovals[id] += 1;
        emit MultisigApproved(id, msg.sender);
    }

    function executeMultisig(address target, bytes calldata data, bytes32 id) external {
        require(!multisigExecuted[id], "Already executed");
        require(multisigApprovals[id] >= multisigThreshold, "Not enough approvals");

        multisigExecuted[id] = true;

        (bool ok, ) = target.call(data);
        require(ok, "Execution failed");

        emit MultisigExecuted(id);
    }

    function isApprover(address a) public view returns (bool) {
        for (uint256 i = 0; i < multisigApprovers.length; i++) {
            if (multisigApprovers[i] == a) return true;
        }
        return false;
    }

    // ============================
    // Pause Controls
    // ============================
    function pauseVault() external onlyOwner {
        _pause();
    }

    function unpauseVault() external onlyOwner {
        _unpause();
    }
}
