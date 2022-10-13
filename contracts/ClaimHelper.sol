// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

library ClaimHelper {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Claim {
        bytes32 receipt;
        uint256 nonce;
        uint256 amount;
        address respondent;
        address claimant;
    }

    struct ClaimMap {
        mapping(bytes32 => Claim) claims;
        mapping(address => Claiments) claiments;
    }

    struct Claiments {
        EnumerableSet.AddressSet claiments;
        mapping(address => bytes32[]) receipts;
    }

    function addClaim(ClaimMap storage self, Claim memory claim) internal {
        self.claims[claim.receipt] = claim;
        self.claiments[claim.respondent].claiments.add(claim.claimant);
        self.claiments[claim.respondent].receipts[claim.claimant].push(claim.receipt);
    }

    function getClaim(ClaimMap storage self, bytes32 receipt) internal view returns (Claim memory) {
        return self.claims[receipt];
    }

    function deleteClaim(ClaimMap storage self, bytes32 receipt) internal {
        Claim memory claim = self.claims[receipt];
        self.claiments[claim.respondent].claiments.remove(claim.claimant);
        bytes32[] memory receipts = self.claiments[claim.respondent].receipts[claim.claimant];
        for (uint256 i = 0; i < receipts.length; i++) {
            if (receipts[i] == receipt) {
                delete self.claiments[claim.respondent].receipts[claim.claimant][i];
                break;
            }
        }
        delete self.claims[receipt];
    }

    function getClaims(
        ClaimMap storage self,
        address respondent,
        address claimant
    ) internal view returns (bytes32[] memory) {
        return self.claiments[respondent].receipts[claimant];
    }

    function deleteClaims(
        ClaimMap storage self,
        address respondent,
        address claimant
    ) internal {
        self.claiments[respondent].claiments.remove(claimant);
        delete self.claiments[respondent].receipts[claimant];
    }

    function getClaimants(ClaimMap storage self, address respondent) internal view returns (address[] memory) {
        return self.claiments[respondent].claiments.values();
    }
}
