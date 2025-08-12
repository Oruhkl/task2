// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {KittyPool} from "src/KittyPool.sol";
import {PropertiesAsserts} from "test/invariant/utils/PropertiesHelper.sol";
import {LibAddressSet} from "test/invariant/utils/LibAddressSet.sol";
import {BeforeAfter} from "test/invariant/BeforeAfter.sol";

contract Handler is PropertiesAsserts, BeforeAfter {
    using LibAddressSet for LibAddressSet.AddressSet; // Fix: Use fully qualified struct name
    LibAddressSet.AddressSet internal _actors; // Fix: Use fully qualified struct name
    address public currentActor; // Added: Define currentActor explicitly since it's used

    function kittyPool_burnKittyCoin(address _onBehalfOf, uint256 _ameownt) public createActor updateGhosts {
        kittyPool.burnKittyCoin(_onBehalfOf, _ameownt);
    }

    function kittyPool_depawsitMeowllateral(address _token, uint256 _ameownt) public createActor updateGhosts {
        kittyPool.depawsitMeowllateral(_token, _ameownt);
    }

    function kittyPool_meowintKittyCoin(uint256 _ameownt) public createActor updateGhosts {
        kittyPool.meowintKittyCoin(_ameownt);
    }

    function kittyPool_meownufactureKittyVault(address _token, address _priceFeed) public createActor updateGhosts {
        kittyPool.meownufactureKittyVault(_token, _priceFeed);
    }

    function kittyPool_purrgeBadPawsition(address _user) public createActor updateGhosts {
        kittyPool.purrgeBadPawsition(_user);
    }

    function kittyPool_whiskdrawMeowllateral(address _token, uint256 _ameownt) public createActor updateGhosts {
        kittyPool.whiskdrawMeowllateral(_token, _ameownt);
    }

    function actors() external returns (address[] memory) {
        return _actors.addrs;
    }

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }
}