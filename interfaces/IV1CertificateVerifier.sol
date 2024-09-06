// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct ECKey {
    uint256 x;
    uint256 y;
    uint256 not_before;
    uint256 not_after;
}


interface IV1CertificateVerifier {
    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory not_before,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) external;
    function addPCK(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory not_before,
        bytes memory not_after,
        bytes memory extensions,
        uint256 authority,
        uint256 r,
        uint256 s
    ) external;
    function getPCK(uint256 platform_serial, uint256 pck_serial) external view returns (ECKey memory);
    function revokePCK(uint256 platform_serial, uint256 pck_serial) external;
    function revokePlatformCA(uint256 serial) external;
}
