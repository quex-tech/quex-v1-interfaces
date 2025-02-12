// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct ECKey {
    uint256 x;
    uint256 y;
    uint256 notBefore;
    uint256 notAfter;
}

struct QEReport {
    bytes16 CPUSVN;
    bytes4 MISCSELECT;
    bytes16 attributes;
    bytes MRENCLAVE;
    bytes32 MRSIGNER;
    bytes2 ISVProdID;
    bytes2 ISVSVN;
    bytes32 REPORT_DATA1;
    bytes32 REPORT_DATA2;
}

struct TDQuote {
    bytes20 USER_DATA;
    bytes16 TEE_TCB_SVN;
    bytes MRSEAM;
    bytes MRSIGNERSEAM;
    bytes8 SEAMATTRIBUTES;
    bytes8 TDATTRIBUTES;
    bytes8 XFAM;
    bytes MRTD;
    bytes MRCONFIGID;
    bytes MROWNER;
    bytes MROWNERCONFIG;
    bytes RTMR0;
    bytes RTMR1;
    bytes RTMR2;
    bytes RTMR3;
    bytes32 REPORT_DATA1;
    bytes32 REPORT_DATA2;
}

interface ITrustDomainRegistry {
    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory extensions,
        uint256 r,
        uint256 s
    ) external;

    function addPCK(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory notAfter,
        bytes memory extensions,
        uint256 authority,
        uint256 r,
        uint256 s
    ) external;

    function addQE(
        QEReport memory qeReport,
        uint256 platformSerial,
        uint256 pckSerial,
        uint256 r,
        uint256 s
    ) external returns (uint256 qeId);

    function addTD(
        TDQuote memory tdQuote,
        uint qeId,
        uint256 x,
        uint256 y,
        bytes32 authentication_data,
        uint256 r,
        uint256 s
    ) external returns (address tdAddress);

    function getRootKey() external view returns(ECKey memory);
    
    function getPlatformCAKey(uint256 serial) external view returns(ECKey memory);

    function getPCK(uint256 platformSerial, uint256 pckSerial) external view returns (ECKey memory);

    function isTDValid(address tdAddress) external view returns (bool);

    function getTD(address tdAddress) external view returns (TDQuote memory);

    function getQE(uint256 qeId) external view returns (QEReport memory);

    function getQEId(address tdAddress) external view returns (uint256 qeId);

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial);
}

interface ITrustDomainRegistryExtended is ITrustDomainRegistry {
    function addRootKey(ECKey memory key) external;

    function revokePCK(uint256 platformSerial, uint256 pckSerial) external;

    function revokePlatformCA(uint256 serial) external;
}
