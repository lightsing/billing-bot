// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ClaimHelper.sol";

contract Legder is ReentrancyGuard {
    using ClaimHelper for ClaimHelper.ClaimMap;

    event ClaimLog(
        bytes32 indexed receipt,
        uint256 nonce,
        uint256 amount,
        address indexed respondent,
        address indexed claimant
    );

    event ResolveLog(
        bytes32 indexed receipt,
        uint256 nonce,
        uint256 amount,
        address indexed respondent,
        address indexed claimant
    );

    event CreditGrantLog(address indexed respondent, address indexed claimant, uint256 diff, uint256 total);

    event CreditDecreseLog(address indexed respondent, address indexed claimant, uint256 diff, uint256 total);

    // like USD, CNY
    string public currency;
    // how many digits are after the decimal point, the value repr is times by 10^{digits}
    // for example, if the digit is 6, then 1 USD is repr as 1000000
    uint256 public digits;

    // respondent => claimant => credit
    mapping(address => mapping(address => bool)) private _trust;
    mapping(address => mapping(address => uint256)) private _credit;
    mapping(address => uint256) public nonce;

    ClaimHelper.ClaimMap private _claims;

    constructor(string memory _currency) {
        currency = _currency;
    }

    // claim others for some amount
    function claim(address respondent, uint256 amount) public nonReentrant returns (bytes32 receipt) {
        require(amount > 0, "Amount must be greater than 0");
        require(respondent != msg.sender, "You can't claim yourself");

        // can we overdraw?
        if (!_trust[respondent][msg.sender]) {
            require(_credit[respondent][msg.sender] >= amount, "You don't have enough credit");
            _credit[respondent][msg.sender] -= amount;
        }
        // increasing opposit credit anyway
        _credit[msg.sender][respondent] += amount;

        // create claim record
        uint256 currentNonce = nonce[msg.sender];
        nonce[msg.sender] += 1;

        // calculate receipt using the keccak256
        receipt = keccak256(abi.encodePacked(amount, respondent, msg.sender));

        ClaimHelper.Claim memory record = ClaimHelper.Claim(receipt, currentNonce, amount, respondent, msg.sender);
        _claims.addClaim(record);

        // emit a log
        emit ClaimLog(receipt, currentNonce, amount, respondent, msg.sender);
    }

    // grant others to allow them to claim
    function grantCredit(address claimant, uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(claimant != msg.sender, "You can't grant yourself");

        _credit[msg.sender][claimant] += amount;
        emit CreditGrantLog(msg.sender, claimant, amount, _credit[msg.sender][claimant]);
    }

    // decrease credit
    function decreaseCredit(address claimant, uint256 amount) public nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(claimant != msg.sender, "You can't decrease yourself credit");

        if (_credit[msg.sender][claimant] <= amount) {
            emit CreditDecreseLog(msg.sender, claimant, _credit[msg.sender][claimant], 0);
            _credit[msg.sender][claimant] = 0;
        } else {
            _credit[msg.sender][claimant] -= amount;
            emit CreditDecreseLog(msg.sender, claimant, amount, _credit[msg.sender][claimant]);
        }
    }

    // resolve a claim
    function resolve(bytes32 receipt) public nonReentrant {
        ClaimHelper.Claim memory record = _claims.getClaim(receipt);
        require(record.respondent == msg.sender, "You are not the respondent");

        // recover credit
        _credit[msg.sender][record.claimant] += record.amount;
        // remove record from claims
        _claims.deleteClaim(receipt);
        emit ResolveLog(receipt, record.nonce, record.amount, record.respondent, record.claimant);
    }

    // resolve all claims from a claimant
    function resolveAll(address claimant) public nonReentrant {
        require(claimant != msg.sender, "You can't resolve yourself");

        bytes32[] memory receipts = _claims.getClaims(msg.sender, claimant);
        for (uint256 i = 0; i < receipts.length; i++) {
            ClaimHelper.Claim memory record = _claims.getClaim(receipts[i]);
            // recover credit
            _credit[msg.sender][record.claimant] += record.amount;
            emit ResolveLog(receipts[i], record.nonce, record.amount, record.respondent, record.claimant);
        }
        // remove records from claims
        _claims.deleteClaims(msg.sender, claimant);
    }

    // get the credit of somebody gives you
    function getCredit(address respondent) public view returns (uint256) {
        return _credit[respondent][msg.sender];
    }

    // trust or untrust somebody
    function setTrust(address claimant, bool allow) public {
        _trust[msg.sender][claimant] = allow;
    }

    // get the trust status from somebody
    function getTrustStatus(address respondent) public view returns (bool) {
        return _trust[respondent][msg.sender];
    }

    // get your nonce
    function getNonce() public view returns (uint256) {
        return nonce[msg.sender];
    }

    function getClaim(bytes32 receipt) public view returns (ClaimHelper.Claim memory) {
        return _claims.getClaim(receipt);
    }

    function getClaimants() public view returns (address[] memory) {
        return _claims.getClaimants(msg.sender);
    }

    function getClaims(address claimant) public view returns (bytes32[] memory) {
        return _claims.getClaims(msg.sender, claimant);
    }
}
