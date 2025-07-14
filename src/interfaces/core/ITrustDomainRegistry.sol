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
    event PlatformCAAdded(uint256 serial);
    event PCKAdded(uint256 platformSerial, uint256 pckSerial);
    event QEReportAdded(uint256 qeId);
    event TDReportAdded(uint256 tdId);

    event PlatformCARevoked(uint256 serial);
    event PCKRevoked(uint256 platformSerial, uint256 pckSerial);
    event QEReportRevoked(uint256 qeId);
    event TDReportRevoked(uint256 tdId);

    function addPlatformCAKey(
        uint256 x,
        uint256 y,
        uint256 serial,
        bytes memory notBefore,
        bytes memory notAfter,
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

    function addQE(QEReport memory qeReport, uint256 platformSerial, uint256 pckSerial, uint256 r, uint256 s)
        external
        returns (uint256 qeId);

    function addTD(
        TDQuote memory tdQuote,
        uint256 qeId,
        uint256 x,
        uint256 y,
        bytes32 authentication_data,
        uint256 r,
        uint256 s
    ) external returns (uint256 tdId);

    function getRootKey() external view returns (ECKey memory);

    function getPlatformCAKey(uint256 serial) external view returns (ECKey memory);

    function getPCK(uint256 platformSerial, uint256 pckSerial) external view returns (ECKey memory);

    function isTDValid(uint256 tdId) external view returns (bool);

    function getTDSignerAddress(uint256 tdId) external view returns (address);

    function getTD(uint256 tdId) external view returns (TDQuote memory);

    function getQE(uint256 qeId) external view returns (QEReport memory);

    function getQEId(uint256 tdId) external view returns (uint256 qeId);

    function getQEAuthority(uint256 qeId) external view returns (uint256 platformSerial, uint256 pckSerial);

}
