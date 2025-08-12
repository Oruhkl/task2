
// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;
import {KittyPool} from "src/KittyPool.sol";
import {PropertiesAsserts} from "test/invariant/utils/PropertiesHelper.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { KittyCoin } from "src/KittyCoin.sol";
import { KittyVault, IAavePool } from "src/KittyVault.sol";
import {StdCheats} from "test/invariant/utils/StdCheats.sol";

abstract contract Setup is StdInvariant {

    KittyPool kittyPool;
    KittyCoin kittyCoin;
    KittyVault wethVault;
    address aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address euroPriceFeed = 0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910;
    address ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address btcUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address usdcUsdPriceFeed = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    address weth = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
    address wbtc = 0x29f2D40B0605204364af54EC677bD022dA425d03;
    address usdc = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
    address meowntainer = 0x1234567890123456789012345678901234567890; 
    StdCheats vm = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);


    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal  {
      meowntainer = msg.sender; // Set the meowntainer to the contract deployer
      vm.deal(msg.sender, 1000000000 ether);
      kittyPool = new KittyPool(meowntainer, euroPriceFeed, aavePool); // TODO: Add parameters here
      vm.prank(meowntainer); // Start a prank to allow the meowntainer to call functions
      kittyPool.meownufactureKittyVault(weth, ethUsdPriceFeed);

      kittyCoin = KittyCoin(kittyPool.getKittyCoin());
      wethVault = KittyVault(kittyPool.getTokenToVault(weth));
      
    }

    
}