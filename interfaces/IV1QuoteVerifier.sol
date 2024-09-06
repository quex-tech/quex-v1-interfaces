// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

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
    bytes MRCONFIGD;
    bytes MROWNER;
    bytes MROWNERCONFIG;
    bytes RTMR0;
    bytes RTMR1;
    bytes RTMR2;
    bytes RTMR3;
    bytes32 REPORT_DATA1;
    bytes32 REPORT_DATA2;
}

interface IV1QuoteVerifier {
    function addQE(
        QEReport memory qe_report, 
        uint256 platform_serial,
        uint256 pck_serial,
        uint256 r,
        uint256 s
    ) external returns (uint256 qe_id);
    function addTD(
        TDQuote memory td_quote, 
        uint qe_id,
        uint256 x,
        uint256 y,
        bytes32 authentication_data,
        uint256 r,
        uint256 s
    ) external returns (uint256 td_id);
    function getTD(uint256 td_id) external view returns (TDQuote memory);
    function getQE(uint256 qe_id) external view returns (QEReport memory);
    function getQEID(uint256 td_id) external view returns (uint256 qe_id);
    function getQEAuthority(uint256 qe_id) external view returns (uint256 platform_serial, uint256 pck_serial);
}
