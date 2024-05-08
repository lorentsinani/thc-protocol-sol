// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControlEnumerable} from
    "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

/**
 * @title ThriveProtocolAccessControl
 * @notice Contract that is used to manage access control.
 */
contract ThriveProtocolAccessControl is AccessControlEnumerable {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setRoleAdmin(bytes32 _role, bytes32 _adminRole)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setRoleAdmin(_role, _adminRole);
    }
}
