// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { RACEPortal } from "../L1/RACEPortal.sol";

/**
 * @title PortalSender
 * @notice The PortalSender is a simple intermediate contract that will transfer the balance of the
 *         L1StandardBridge to the RACEPortal during the Bedrock migration.
 */
contract PortalSender {
    /**
     * @notice Address of the RACEPortal contract.
     */
    RACEPortal public immutable PORTAL;

    /**
     * @param _portal Address of the RACEPortal contract.
     */
    constructor(RACEPortal _portal) {
        PORTAL = _portal;
    }

    /**
     * @notice Sends balance of this contract to the RACEPortal.
     */
    function donate() public {
        PORTAL.donateETH{ value: address(this).balance }();
    }
}
