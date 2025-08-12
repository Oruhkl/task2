// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;
import {Handler} from "test/invariant/Handlers.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IAavePool } from "src/interfaces/IAavePool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Invariant is Handler {
    constructor() payable {
        setup();
    }

    // // Invariant 1: Collateralization ratio >= 169%
    // function invariant_collateralizationRatio() public {
    //     uint256 collateralInEuros = kittyPool.getUserMeowllateralInEuros(user);
    //     uint256 debt = kittyPool.getKittyCoinMeownted(user);
    //     uint256 requiredCollateral = debt * 169 / 100;
    //     assert(collateralInEuros >= requiredCollateral);
    // }

    // // Invariant 2: Vault accounting consistency
    // function invariant_vaultAccounting() public {
    //     uint256 totalMeowllateral = wethVault.getTotalMeowllateral();
    //     uint256 calculatedMeowllateral;
    //     uint256 totalCattyNip = wethVault.totalCattyNip();
    //     if (totalCattyNip > 0) {
    //         calculatedMeowllateral = wethVault.getUserMeowllateral(user) * totalCattyNip / wethVault.userToCattyNip(user);
    //     }
    //     assert(totalMeowllateral == calculatedMeowllateral || totalCattyNip == 0);
    // }

    // Invariant 3: KittyCoin supply matches total debt
    function invariant_kittyCoinSupply() public {
        uint256 totalSupply = kittyCoin.totalSupply();
        uint256 totalDebt = kittyPool.getKittyCoinMeownted(msg.sender);
        assert(totalSupply == totalDebt);
    }

    // Invariant 4: Non-negative balances
    function invariant_nonNegativeBalances() public {
        assert(wethVault.userToCattyNip(msg.sender) >= 0);
        assert(wethVault.totalCattyNip() >= 0);
        assert(wethVault.totalMeowllateralInVault() >= 0);
        assert(kittyPool.getKittyCoinMeownted(msg.sender) >= 0);
    }

    // Invariant 5: Vault token consistency
    function invariant_vaultTokenConsistency() public {
        assert(kittyPool.getTokenToVault(weth) == address(wethVault));
        assert(wethVault.i_token() == weth);
    }

    // Invariant 6: Aave interaction integrity
    function invariant_aaveInteraction() public {
        uint256 totalMeowllateralInVault = wethVault.totalMeowllateralInVault();
        uint256 aaveCollateral = wethVault.getTotalMeowllateralInAave();
        (uint256 aaveBalance, , , , , ) = IAavePool(aavePool).getUserAccountData(address(wethVault));
        assert(totalMeowllateralInVault + aaveCollateral >= aaveBalance);
    }

    // Invariant 7: Liquidation safety
    function invariant_liquidationSafety() public {
        // Simulate collateral deposit and borrowing
        vm.startPrank(msg.sender);
        IERC20(weth).approve(address(kittyPool), 100 ether);
        kittyPool.depawsitMeowllateral(weth, 100 ether);
        kittyPool.meowintKittyCoin(50 ether);
        vm.stopPrank();

        // Check if position is liquidatable (based on mainnet price feed)
        (, int256 price, , , ) = AggregatorV3Interface(ethUsdPriceFeed).latestRoundData();
        require(price > 0, "Invalid price feed");
        uint256 ethPrice = uint256(price) / 1e8; // Adjust for 8 decimals
        uint256 collateralInEuros = (100 ether * ethPrice) / 1e18; // Convert to euros
        uint256 debt = kittyPool.getKittyCoinMeownted(msg.sender);
        uint256 requiredCollateral = (debt * 169) / 100;

        if (collateralInEuros < requiredCollateral) {
            vm.startPrank(address(0xdead));
            kittyPool.purrgeBadPawsition(msg.sender);
            vm.stopPrank();
            assert(kittyPool.getKittyCoinMeownted(msg.sender) == 0);
        }
    }
    // Invariant 8: Debt consistency with KittyCoin balance
    function invariant_debtConsistency() public {
        uint256 userDebt = kittyPool.getKittyCoinMeownted(msg.sender);
        uint256 userKittyCoinBalance = kittyCoin.balanceOf(msg.sender);
        assert(userDebt == userKittyCoinBalance);
    }

    // Invariant 9: Total CattyNip consistency
    function invariant_totalCattyNipConsistency() public {
        uint256 userCattyNip = wethVault.userToCattyNip(msg.sender);
        uint256 totalCattyNip = wethVault.totalCattyNip();
        assert(totalCattyNip >= userCattyNip);
    }

    // Invariant 10: Collateral in Euros calculation positivity
    function invariant_collateralInEurosPositivity() public {
        uint256 collateralInEuros = kittyPool.getUserMeowllateralInEuros(msg.sender);
        assert(collateralInEuros >= 0);
    }
    // Invariant 11: Has enough Meowllateral
    function invariant_hasEnoughMeowllateral() public {
        assert(kittyPool.hasEnoughMeowllateral(msg.sender) == true);
    }

    // Helper function for testing deposits
    modifier userDepositsCollateral(uint256 toDeposit) {
        vm.startPrank(msg.sender);
        IERC20(weth).approve(address(kittyPool), toDeposit);
        kittyPool.depawsitMeowllateral(weth, toDeposit);
        vm.stopPrank();
        _;
    }

    function testDeposit(uint256 toDeposit) external userDepositsCollateral(toDeposit) {
        uint256 kittyCoinBalanceBefore = kittyCoin.balanceOf(msg.sender);
        uint256 wethVaultBalanceBefore = wethVault.totalMeowllateralInVault();

        uint256 kittyCoinBalanceAfter = kittyCoin.balanceOf(msg.sender);
        uint256 wethVaultBalanceAfter = wethVault.totalMeowllateralInVault();

        assert(kittyCoinBalanceAfter <= kittyCoinBalanceBefore); // KittyCoin may not increase
        assert(wethVaultBalanceAfter >= wethVaultBalanceBefore); // Vault collateral should increase
    }

    function testMintKittyCoin(uint256 amountToMint) external userDepositsCollateral(10 ether) {
        uint256 kittyCoinBalanceBefore = kittyCoin.balanceOf(msg.sender);
        uint256 wethVaultBalanceBefore = wethVault.totalMeowllateralInVault();

        kittyPool.meowintKittyCoin(amountToMint);

        uint256 kittyCoinBalanceAfter = kittyCoin.balanceOf(msg.sender);
        uint256 wethVaultBalanceAfter = wethVault.totalMeowllateralInVault();

        assert(kittyCoinBalanceAfter >= kittyCoinBalanceBefore + amountToMint); // KittyCoin should increase
        assert(wethVaultBalanceAfter == wethVaultBalanceBefore); // Vault collateral should not change
    }


}