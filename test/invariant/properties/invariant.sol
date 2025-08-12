// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.26;

import {Handler} from "test/invariant/Handlers.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IAavePool} from "src/interfaces/IAavePool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {WETH} from "test/invariant/utils/WETH.sol";

contract Invariant is Handler {
    using Math for uint256;

    constructor()payable {
        setup();
    }

    // Invariant 1: Collateralization ratio >= 169%
    function invariant_collateralizationRatio() public {
        address user = currentActor;
        (, int256 ethPrice, , , ) = AggregatorV3Interface(ethUsdPriceFeed).latestRoundData();
        require(ethPrice > 0, "Invalid price feed");
        uint256 collateralInEuros = kittyPool.getUserMeowllateralInEuros(user);
        uint256 debt = kittyPool.getKittyCoinMeownted(user);
        if (debt == 0) {
            assert(true);
        } else {
            uint256 requiredCollateral = (debt * 169) / 100;
            assert(collateralInEuros >= requiredCollateral);
        }
    }

    // Invariant 2: Vault accounting consistency
    function invariant_vaultAccounting() public {
        uint256 totalMeowllateral = wethVault.getTotalMeowllateral();
        uint256 totalCattyNip = wethVault.totalCattyNip();
        if (totalCattyNip == 0) {
            assert(totalMeowllateral == 0);
        } else {
            uint256 userCattyNip = wethVault.userToCattyNip(currentActor);
            uint256 calculatedMeowllateral = userCattyNip.mulDiv(totalMeowllateral, totalCattyNip);
            assert(wethVault.getUserMeowllateral(currentActor) == calculatedMeowllateral);
        }
    }

    // Invariant 3: KittyCoin supply matches total debt
    function invariant_kittyCoinSupply() public {
        uint256 totalSupply = kittyCoin.totalSupply();
        uint256 totalDebt;
        address[] memory actors = _actors.addrs;
        for (uint256 i = 0; i < actors.length; i++) {
            totalDebt += kittyPool.getKittyCoinMeownted(actors[i]);
        }
        assert(totalSupply == totalDebt);
    }

    // Invariant 4: Non-negative balances
    function invariant_nonNegativeBalances() public {
        address[] memory actors = _actors.addrs;
        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];
            assert(wethVault.userToCattyNip(user) >= 0);
            assert(kittyPool.getKittyCoinMeownted(user) >= 0);
        }
        assert(wethVault.totalCattyNip() >= 0);
        assert(wethVault.getTotalMeowllateral() >= 0);
    }

    // Invariant 5: Vault token consistency
    function invariant_vaultTokenConsistency() public {
        assert(kittyPool.getTokenToVault(address(weth)) == address(wethVault));
        assert(wethVault.i_token() == address(weth));
    }

    // Invariant 6: Aave interaction integrity
    function invariant_aaveInteraction() public {
        uint256 totalMeowllateralInVault = wethVault.getTotalMeowllateral();
        uint256 aaveCollateral = wethVault.getTotalMeowllateralInAave();
        (uint256 aaveBalance, , , , , ) = IAavePool(aavePool).getUserAccountData(address(wethVault));
        (, int256 price, , , ) = AggregatorV3Interface(ethUsdPriceFeed).latestRoundData();
        require(price > 0, "Invalid price feed");
        uint256 aaveBalanceInTokens = aaveBalance.mulDiv(1e18, uint256(price) * 1e10);
        assert(totalMeowllateralInVault + aaveCollateral == aaveBalanceInTokens);
    }

    // Invariant 7: Liquidation safety
    function invariant_liquidationSafety(uint256 value) public {
        require(value > 0, "Value must be positive");
        weth.mint(msg.sender, value);
        vm.startPrank(msg.sender);
        kittyPool.depawsitMeowllateral(address(weth), value);
        kittyPool.meowintKittyCoin(value / 2);
        vm.stopPrank();

        (, int256 price, , , ) = AggregatorV3Interface(ethUsdPriceFeed).latestRoundData();
        require(price > 0, "Invalid price feed");
        uint256 ethPrice = uint256(price) / 1e8;
        uint256 collateralInEuros = (value * ethPrice) / 1e18;
        uint256 debt = kittyPool.getKittyCoinMeownted(msg.sender);
        uint256 requiredCollateral = (debt * 169) / 100;

        if (collateralInEuros < requiredCollateral) {
            vm.startPrank(address(0xdead));
            IERC20(address(kittyCoin)).approve(address(kittyPool), debt);
            kittyPool.purrgeBadPawsition(msg.sender);
            vm.stopPrank();
            assert(kittyPool.getKittyCoinMeownted(msg.sender) == 0);
        }
    }

    // Invariant 8: Debt consistency with KittyCoin balance
    function invariant_debtConsistency() public {
        address[] memory actors = _actors.addrs;
        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];
            uint256 userDebt = kittyPool.getKittyCoinMeownted(user);
            uint256 userKittyCoinBalance = kittyCoin.balanceOf(user);
            assert(userDebt == userKittyCoinBalance);
        }
    }

    // Invariant 9: Total CattyNip consistency
    function invariant_totalCattyNipConsistency() public {
        uint256 totalCattyNip = wethVault.totalCattyNip();
        uint256 sumCattyNip;
        address[] memory actors = _actors.addrs;
        for (uint256 i = 0; i < actors.length; i++) {
            sumCattyNip += wethVault.userToCattyNip(actors[i]);
        }
        assert(totalCattyNip >= sumCattyNip);
    }

    // Invariant 10: Collateral in Euros calculation positivity
    function invariant_collateralInEurosPositivity() public {
        address[] memory actors = _actors.addrs;
        for (uint256 i = 0; i < actors.length; i++) {
            uint256 collateralInEuros = kittyPool.getUserMeowllateralInEuros(actors[i]);
            assert(collateralInEuros >= 0);
        }
    }

    // Invariant 11: Has enough Meowllateral
    function invariant_hasEnoughMeowllateral() public {
        address[] memory actors = _actors.addrs;
        for (uint256 i = 0; i < actors.length; i++) {
            address user = actors[i];
            if (kittyPool.getKittyCoinMeownted(user) > 0 || kittyPool.getUserMeowllateralInEuros(user) > 0) {
                assert(kittyPool.hasEnoughMeowllateral(user));
            }
        }
    }

    // Invariant 12: Withdrawal availability when collateral is in Aave
    function invariant_withdrawalAvailability(uint256 value) public {
        require(value > 0, "Value must be positive");
        weth.mint(msg.sender, value);
        vm.startPrank(msg.sender);
        kittyPool.depawsitMeowllateral(address(weth), value);
        vm.stopPrank();

        vm.startPrank(meowntainer);
        wethVault.purrrCollateralToAave(value);
        vm.stopPrank();

        vm.startPrank(msg.sender);
        uint256 cattyNip = wethVault.userToCattyNip(msg.sender);
        kittyPool.whiskdrawMeowllateral(address(weth), cattyNip);
        assert(wethVault.userToCattyNip(msg.sender) == 0);
        assert(IERC20(address(weth)).balanceOf(msg.sender) >= value);
        vm.stopPrank();
    }

    // Invariant 13: Collateral in Euros accuracy
    function invariant_collateralInEurosAccuracy(uint256 value) public {
        require(value > 0, "Value must be positive");
        weth.mint(msg.sender, value);
        vm.startPrank(msg.sender);
        kittyPool.depawsitMeowllateral(address(weth), value);
        vm.stopPrank();

        uint256 collateralInEuros = kittyPool.getUserMeowllateralInEuros(msg.sender);
        (, int256 ethPrice, , , ) = AggregatorV3Interface(ethUsdPriceFeed).latestRoundData();
        (, int256 euroPrice, , , ) = AggregatorV3Interface(euroPriceFeed).latestRoundData();
        require(ethPrice > 0 && euroPrice > 0, "Invalid price feed");
        uint256 usdValue = value.mulDiv(uint256(ethPrice), 1e8); // ETH price in USD (8 decimals)
        uint256 expectedEuros = usdValue.mulDiv(1e18, uint256(euroPrice) * 1e10); // Convert USD to EUR
        assert(collateralInEuros / 1e10 == expectedEuros / 1e10); // Compare with 10 decimals precision
    }

    // Invariant 14: Liquidation reward
    function invariant_liquidationReward(uint256 value) public {
        require(value > 0, "Value must be positive");
        weth.mint(msg.sender, value);
        vm.startPrank(msg.sender);
        kittyPool.depawsitMeowllateral(address(weth), value);
        kittyPool.meowintKittyCoin(value / 2);
        vm.stopPrank();

        address liquidator = address(0xdead);
        uint256 initialCattyNip = wethVault.userToCattyNip(liquidator);
        uint256 initialBalance = IERC20(address(weth)).balanceOf(liquidator);
        vm.startPrank(liquidator);
        IERC20(address(kittyCoin)).approve(address(kittyPool), value / 2);
        kittyPool.purrgeBadPawsition(msg.sender);
        vm.stopPrank();

        uint256 expectedReward = (value / 2).mulDiv(0.05e18, 1e18);
        assert(wethVault.userToCattyNip(liquidator) >= initialCattyNip);
        assert(IERC20(address(weth)).balanceOf(liquidator) >= initialBalance + expectedReward);
    }

    // Invariant 15: Liquidation uses collateral amount
    function invariant_liquidationCollateralAmount(uint256 value) public {
        require(value > 0, "Value must be positive");
        weth.mint(msg.sender, value);
        vm.startPrank(msg.sender);
        kittyPool.depawsitMeowllateral(address(weth), value);
        kittyPool.meowintKittyCoin(value / 2);
        vm.stopPrank();

        uint256 initialCollateral = wethVault.getUserMeowllateral(msg.sender);
        address liquidator = address(0xdead);
        vm.startPrank(liquidator);
        IERC20(address(kittyCoin)).approve(address(kittyPool), value / 2);
        kittyPool.purrgeBadPawsition(msg.sender);
        vm.stopPrank();

        uint256 collateralReceived = IERC20(address(weth)).balanceOf(liquidator);
        uint256 expectedCollateral = (value / 2) + (value / 2).mulDiv(0.05e18, 1e18);
        assert(collateralReceived == expectedCollateral);
    }

}