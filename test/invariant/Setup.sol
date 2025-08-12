// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.26;

import {KittyPool} from "src/KittyPool.sol";
import {KittyCoin} from "src/KittyCoin.sol";
import {KittyVault} from "src/KittyVault.sol";
import {WETH} from "test/invariant/utils/WETH.sol";
import {StdCheats} from "test/invariant/utils/StdCheats.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Setup {
    KittyPool public kittyPool;
    KittyCoin public kittyCoin;
    KittyVault public wethVault;
    WETH public weth;
    address public aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address public euroPriceFeed = 0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910;
    address public ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address public meowntainer = 0x1234567890123456789012345678901234567890;
    address[] public testUsers = [
        address(0x1111111111111111111111111111111111111111),
        address(0x2222222222222222222222222222222222222222),
        address(0x3333333333333333333333333333333333333333)
    ];
    StdCheats public vm = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    uint256 public constant PRECISION = 1e18;
    function setup() internal {
        // Deploy the mock WETH contract
        weth = new WETH();

        // Deploy KittyPool with the meowntainer and required parameters
        kittyPool = new KittyPool(meowntainer, euroPriceFeed, aavePool);

        // Create a KittyVault for WETH
        vm.prank(meowntainer);
        kittyPool.meownufactureKittyVault(address(weth), ethUsdPriceFeed);

        // Initialize KittyCoin and WETH vault
        kittyCoin = KittyCoin(kittyPool.getKittyCoin());
        wethVault = KittyVault(kittyPool.getTokenToVault(address(weth)));

        // Mint WETH to test users and approve KittyPool
        uint256 initialWethAmount = 1000000000e18; // 1000 WETH for each user
        for (uint256 i = 0; i < testUsers.length; i++) {
            vm.startPrank(meowntainer);
            weth.mint(testUsers[i], initialWethAmount);
            vm.stopPrank();
            vm.startPrank(testUsers[i]);
            IERC20(address(weth)).approve(address(kittyPool), initialWethAmount);
            IERC20(weth).approve(address(wethVault), initialWethAmount);
            vm.stopPrank();
        }
    }
}