// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IBatchPlanner} from './KpkDeployerLib.sol';

/**
 * @title KpkTokenDeploymentConfig
 * @author Karpatkey
 * @notice This library contains the configuration for the KpkToken deployment
 */
library KpkTokenDeploymentConfig {
  /**
   * @notice The owners of the Karpatkey Governance Safe
   */
  function governanceSafeOwners() public pure returns (address[9] memory) {
    return [
      0x963728b46429c8415acCB03Ac5F5b2A36110d434,
      0xA4FaD769c4c7Af161692D916DE51E6280Dd7d147,
      0x168330c41a77e6737BF32FD16a6f4cFa8B9aa11c,
      0xc07A080BC73E84c3AA8963A40Bd427c78Cf42AE5,
      0xF971D72b812D0Df2Db7D6FeD49c0f5d3CF009411,
      0x0D50c737f102703fdBac7A6829EaD7FE3b20561A,
      0xF0a88b5aB06E56e0a1e4c6259f4986551200Bb3c,
      0x1a30824cfBb571Ca92Bc8e11BecfF0d9a42b5a49,
      0x72DDE1ee3E91945DF444B9AE4B97B55D66FA858C
    ];
  }

  /**
   * @notice The threshold for the Karpatkey Governance Safe
   */
  function governanceSafeThreshold() public pure returns (uint256) {
    return 5;
  }

  /**
   * @dev The allocations for the KpkToken
   */
  function getTokenAllocations(
    uint256 startTimestamp
  ) public pure returns (IBatchPlanner.AllocationData[34] memory) {
    uint256 tokenVestingStartTimestamp = 1_718_968_487; // April 1st 2024

    return [
      IBatchPlanner.AllocationData(
        0x9e951f9b138D57FAb3c3A0685C202F28804611B5, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x5076fA392D5564c95c1CB5cB683470aE3A1eAF9d, 1500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x39D787fdf7384597C7208644dBb6FDa1CcA4eBdf, 5000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xEea91102f78B2EcFc2eEc9868B6523504f9a5241, 2500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xEea91102f78B2EcFc2eEc9868B6523504f9a5241, 2500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x2bdC69b3E175154bD1E8D4Be50e1a51CffB721Bf, 500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xe705b1D26B85c9F9f91A3690079D336295F14F08, 2500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x22Be67f0715835526a06a227ba9c8AffA3F7FE5f, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xac140648435d03f784879cd789130F22Ef588Fcd, 500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xB1f881f47baB744E7283851bC090bAA626df931d, 500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xa361f522eC77c3213C7E435160a38DB1Fc45EDcc, 250 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xcE024Ad2997Aad42112E789188da62E4bE5bA05D, 200 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x99E4256100552Bfc3a22AC92561f26cb9637bEA1, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x3a3eE61F7c6e1994a2001762250A5E17B2061b6d, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x556Bd626535022cB854e297ADa4F46807da54B2c, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x0306E34A687798A63A42B506F32CB5A57c95D187, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x436f2b24D1052F14B4a7e095438a22b09F706C21, 200 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x19dBf30453d8528bFD0be878535e15715CFFF066, 250 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xE91F64cA1da165Ca8437686B69A022156550837B, 100 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x6F86e116C2E2fAe0404276ca1C2aA1F074626396, 200 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xa31f48CF048af2c6851c50E7d60a32296A01119b, 200 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x75dbc56888c676626a7Ec0e128af46f6F5B494d2, 750 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xc174b29C50d14303063a0E802B325a676AE2a853, 10_000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xcb68110C43C97b6051FEd5e2Bacc2814aDaD1688, 250 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x371880c69B9442888318e82B079BC41d85f03979, 1875 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x56264e5ec5215C3974Cfb550D3aeFA6720f5eE9D, 1875 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x418592317dCEc824603c6840E51E9c2f2B5c8156, 1000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x6e0a1dDAD894e6466d405Bb73377F0A257278D74, 2000 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xFB014896319E1650FD1426A6A4f070e9286f46F1, 1250 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x22915193F2BDe0DA4dfE317BfCE4Ddf1b6f13DE9, 500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0x74fEa3FB0eD030e9228026E7F413D66186d3D107, 500 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(
        0xE61A0e34a63f121351DAd37Cd96784165A22AA5E, 250 ether, tokenVestingStartTimestamp, false
      ),
      IBatchPlanner.AllocationData(0x849D52316331967b6fF1198e5E32A0eB168D039d, 25_000 ether, 1_642_075_200, false),
      IBatchPlanner.AllocationData(0x849D52316331967b6fF1198e5E32A0eB168D039d, 75_000 ether, startTimestamp, false)
    ];
  }
}
