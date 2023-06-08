// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Bridge_Initializer } from "./CommonTest.t.sol";
import { LibRLP } from "./RLP.t.sol";
import { RACEMintableERC721 } from "../universal/RACEMintableERC721.sol";
import { RACEMintableERC721Factory } from "../universal/RACEMintableERC721Factory.sol";

contract RACEMintableERC721Factory_Test is ERC721Bridge_Initializer {
    RACEMintableERC721Factory internal factory;

    event RACEMintableERC721Created(
        address indexed localToken,
        address indexed remoteToken,
        address deployer
    );

    function setUp() public override {
        super.setUp();

        // Set up the token pair.
        factory = new RACEMintableERC721Factory(address(L2Bridge), 1);

        // Label the addresses for nice traces.
        vm.label(address(factory), "RACEMintableERC721Factory");
    }

    function test_constructor_succeeds() external {
        assertEq(factory.BRIDGE(), address(L2Bridge));
        assertEq(factory.REMOTE_CHAIN_ID(), 1);
    }

    function test_createRACEMintableERC721_succeeds() external {
        // Predict the address based on the factory address and nonce.
        address predicted = LibRLP.computeAddress(address(factory), 1);

        // Expect a token creation event.
        vm.expectEmit(true, true, true, true);
        emit RACEMintableERC721Created(predicted, address(1234), alice);

        // Create the token.
        vm.prank(alice);
        RACEMintableERC721 created = RACEMintableERC721(
            factory.createRACEMintableERC721(address(1234), "L2Token", "L2T")
        );

        // Token address should be correct.
        assertEq(address(created), predicted);

        // Should be marked as created by the factory.
        assertEq(factory.isRACEMintableERC721(address(created)), true);

        // Token should've been constructed correctly.
        assertEq(created.name(), "L2Token");
        assertEq(created.symbol(), "L2T");
        assertEq(created.REMOTE_TOKEN(), address(1234));
        assertEq(created.BRIDGE(), address(L2Bridge));
        assertEq(created.REMOTE_CHAIN_ID(), 1);
    }

    function test_createRACEMintableERC721_zeroRemoteToken_reverts() external {
        // Try to create a token with a zero remote token address.
        vm.expectRevert("RACEMintableERC721Factory: L1 token address cannot be address(0)");
        factory.createRACEMintableERC721(address(0), "L2Token", "L2T");
    }
}
