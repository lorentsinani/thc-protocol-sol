//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlEnumerable} from
    "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ThriveProtocolCommunity is Ownable {
    using SafeERC20 for IERC20;

    AccessControlEnumerable public accessControlEnumerable;

    string private name;

    address private rewardsAdmin;
    address private treasuryAdmin;
    address private validationsAdmin;
    address private foundationAdmin;

    uint256 private rewardsPercentage;
    uint256 private treasuryPercentage;
    uint256 private validationsPercentage;
    uint256 private foundationPercentage;

    mapping(address admin => mapping(address token => uint256 amount)) public
        balances;

    /**
     * @dev Emitted when a user transfer tokens from the contract
     */
    event Transfer(
        address indexed _from,
        address indexed _to,
        address indexed _token,
        uint256 _amount
    );

    /**
     * @param _owner The address of contract owner
     * @param _name The name of the community
     * @param _admins The array with addresses of admins
     * @param _percentages The array with value of percents for distribution
     * @param _accessControlEnumerable The address of access control enumerable contract
     */
    constructor(
        address _owner,
        string memory _name,
        address[4] memory _admins,
        uint256[4] memory _percentages,
        address _accessControlEnumerable
    ) Ownable(_owner) {
        name = _name;

        accessControlEnumerable =
            AccessControlEnumerable(_accessControlEnumerable);

        // accessControlEnumerable.grantRole(
        //     accessControlEnumerable.DEFAULT_ADMIN_ROLE(), msg.sender
        // );

        _setAdmins(_admins[0], _admins[1], _admins[2], _admins[3]);

        _setPercentage(
            _percentages[0], _percentages[1], _percentages[2], _percentages[3]
        );
    }

    /**
     * @dev Modifier to only allow execution by admins.
     * If the caller is not an admin, reverts with a corresponding message
     */
    modifier onlyAdmin() {
        require(
            accessControlEnumerable.hasRole(
                accessControlEnumerable.DEFAULT_ADMIN_ROLE(), msg.sender
            ),
            "ThriveProtocolCommunity: must have admin role"
        );
        _;
    }

    /**
     * @notice Transfers _amount of the _token to the smart contract
     * and increases the balances of administrators of treasury,
     * validations, rewards and foundations in the following percentages for the _token
     * @param _token The address of ERC20 contract
     * @param _amount The amount of token to deposit
     */
    function deposit(address _token, uint256 _amount) public {
        balances[treasuryAdmin][_token] += (_amount * treasuryPercentage) / 100;
        balances[validationsAdmin][_token] +=
            (_amount * validationsPercentage) / 100;
        balances[foundationAdmin][_token] +=
            (_amount * foundationPercentage) / 100;
        balances[rewardsAdmin][_token] += (_amount * rewardsPercentage) / 100;

        uint256 dust = _amount
            - (
                balances[rewardsAdmin][_token] + balances[treasuryAdmin][_token]
                    + balances[validationsAdmin][_token]
                    + balances[foundationAdmin][_token]
            );
        balances[rewardsAdmin][_token] += dust;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Transfers _amount of the _token to the smart contract
     * and increases the balance of the validators administrator account by _amount for the respective _token
     * @param _token The address of ERC20 contract
     * @param _amount The amount of token to deposit
     */
    function validationsDeposit(address _token, uint256 _amount) public {
        balances[validationsAdmin][_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Transfers _amount of the _token to the message caller's account
     * @param _token The address of ERC20 contract
     * @param _amount The amount of token to withdraw
     */
    function withdraw(address _token, uint256 _amount) public {
        require(balances[msg.sender][_token] >= _amount, "Insufficient balance");
        balances[msg.sender][_token] -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Transfer(address(this), msg.sender, _token, _amount);
    }

    /**
     * @notice Transfers _amount of the _token to address _to
     * @param _token The address of ERC20 contract
     * @param _amount The amount of token to withdraw
     */
    function transfer(address _to, address _token, uint256 _amount) public {
        require(balances[msg.sender][_token] >= _amount, "Insufficient balance");
        balances[msg.sender][_token] -= _amount;
        IERC20(_token).safeTransfer(_to, _amount);
        emit Transfer(address(this), _to, _token, _amount);
    }

    /**
     * @notice Sets the admins' addresses
     * can call only DEFAULT_ADMIN account
     * @param _rewardsAdmin The address of the account who has administrator rights for the funds allocated for rewards
     * @param _treasuryAdmin The address of the account who has administrator rights for the funds allocated for DAO treasury
     * @param _validationsAdmin The address of the account who has administrator rights for the funds allocated for validations
     * @param _foundationAdmin The address of the account who has administrator rights for the funds allocated for the foundation
     */
    function setAdmins(
        address _rewardsAdmin,
        address _treasuryAdmin,
        address _validationsAdmin,
        address _foundationAdmin
    ) external onlyAdmin {
        _setAdmins(
            _rewardsAdmin, _treasuryAdmin, _validationsAdmin, _foundationAdmin
        );
    }

    /**
     * @notice Sets the percentages for distribution
     * can call only DEFAULT_ADMIN account
     * @param _rewardsPercentage The percentage for the rewards admin
     * @param _treasuryPercentage The percentage for the treasury admin
     * @param _validationsPercentage The percentage for the validations admin
     * @param _foundationPercentage The percentage for the foundation admin
     */
    function setPercentage(
        uint256 _rewardsPercentage,
        uint256 _treasuryPercentage,
        uint256 _validationsPercentage,
        uint256 _foundationPercentage
    ) external onlyAdmin {
        require(
            _rewardsPercentage + _treasuryPercentage + _validationsPercentage
                + _foundationPercentage == 100,
            "Percentages must add up to 100"
        );

        _setPercentage(
            _rewardsPercentage,
            _treasuryPercentage,
            _validationsPercentage,
            _foundationPercentage
        );
    }

    /**
     * @dev Sets the AccessControlEnumerable contract address.
     * Only the owner of this contract can call this function.
     *
     * @param _accessControlEnumerable The address of the new AccessControlEnumerable contract.
     */
    function setAccessControlEnumerable(address _accessControlEnumerable)
        external
        onlyOwner
    {
        accessControlEnumerable =
            AccessControlEnumerable(_accessControlEnumerable);
    }

    /**
     * @notice Returns the name of the community
     * @return The name of community
     */
    function getName() public view returns (string memory) {
        return name;
    }

    /**
     * @notice Returns the address of the account who has administrator rights for the funds allocated for rewards
     * @return The address of rewards admin
     */
    function getRewardsAdmin() public view returns (address) {
        return rewardsAdmin;
    }

    /**
     * @notice Returns the address of the account who has administrator rights for the funds allocated for DAO treasury
     * @return The address of treasuty admin
     */
    function getTreasuryAdmin() public view returns (address) {
        return treasuryAdmin;
    }

    /**
     * @notice Returns the address of the account who has administrator rights for the funds allocated for validations
     * @return The address of validations admin
     */
    function getValidationsAdmin() public view returns (address) {
        return validationsAdmin;
    }

    /**
     * @notice Returns the address of the account who has administrator rights for the funds allocated for the foundation
     * @return The address of foundation admin
     */
    function getFoundationAdmin() public view returns (address) {
        return foundationAdmin;
    }

    /**
     * @notice Returns the percentage for the rewards
     * @return The value of rewards percentage
     */
    function getRewardsPercentage() public view returns (uint256) {
        return rewardsPercentage;
    }

    /**
     * @notice Returns the percentage for the treasury
     * @return The value of treasuty percentage
     */
    function getTreasuryPercentage() public view returns (uint256) {
        return treasuryPercentage;
    }

    /**
     * @notice Returns the percentage for the validations
     * @return The value of validations percentage
     */
    function getValidationsPercentage() public view returns (uint256) {
        return validationsPercentage;
    }

    /**
     * @notice Returns the percentage for the the foundation
     * @return The address of foundation admin
     */
    function getFoundationPercentage() public view returns (uint256) {
        return foundationPercentage;
    }

    /**
     * @notice Sets the admins' addresses
     * @param _rewardsAdmin The address of the account who has administrator rights for the funds allocated for rewards
     * @param _treasuryAdmin The address of the account who has administrator rights for the funds allocated for DAO treasury
     * @param _validationsAdmin The address of the account who has administrator rights for the funds allocated for validations
     * @param _foundationAdmin The address of the account who has administrator rights for the funds allocated for the foundation
     */
    function _setAdmins(
        address _rewardsAdmin,
        address _treasuryAdmin,
        address _validationsAdmin,
        address _foundationAdmin
    ) internal {
        rewardsAdmin = _rewardsAdmin;
        treasuryAdmin = _treasuryAdmin;
        validationsAdmin = _validationsAdmin;
        foundationAdmin = _foundationAdmin;
    }

    /**
     * @notice Sets the percentages for distribution
     * @param _rewardsPercentage The percentage for the rewards admin
     * @param _treasuryPercentage The percentage for the treasury admin
     * @param _validationsPercentage The percentage for the validations admin
     * @param _foundationPercentage The percentage for the foundation admin
     */
    function _setPercentage(
        uint256 _rewardsPercentage,
        uint256 _treasuryPercentage,
        uint256 _validationsPercentage,
        uint256 _foundationPercentage
    ) internal {
        rewardsPercentage = _rewardsPercentage;
        treasuryPercentage = _treasuryPercentage;
        validationsPercentage = _validationsPercentage;
        foundationPercentage = _foundationPercentage;
    }
}
