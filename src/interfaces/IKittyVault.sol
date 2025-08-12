// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKittyVault {
    function executeDepawsit(address user, uint256 ameownt) external;
    function executeWhiskdrawal(address user, uint256 cattyNipToWithdraw) external;
    function purrrCollateralToAave(uint256 ameowntToSupply) external;
    function purrrCollateralFromAave(uint256 ameowntToWhiskdraw) external;
    function getUserVaultMeowllateralInEuros(address user) external view returns (uint256);
    function getUserMeowllateral(address user) external view returns (uint256);
    function getTotalMeowllateral() external view returns (uint256);
    function getTotalMeowllateralInAave() external view returns (uint256);
    function totalMeowllateralInVault() external view returns (uint256);
    function totalCattyNip() external view returns (uint256);
    function userToCattyNip(address user) external view returns (uint256);
    function i_token() external view returns (address);
}