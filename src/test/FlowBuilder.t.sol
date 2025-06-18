// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../libraries/FlowBuilder.sol";
import "../interfaces/oracles/IRequestOraclePool.sol";
import "../interfaces/core/IFlowRegistry.sol";

contract FlowBuilderTest is Test {
    using FlowBuilder for FlowBuilder.FlowConfig;

    address public constant TEST_CONSUMER = address(0x87654321);
    bytes4 public constant TEST_CALLBACK = bytes4(keccak256("testCallback()"));

    address public constant TEST_QUEX_CORE = address(0x1234);
    address public constant TEST_ORACLE_POOL = address(0x5678);

    function testCreateBasicFlow() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        assertEq(config.flowRegistry, TEST_QUEX_CORE);
        assertEq(config.oraclePool, TEST_ORACLE_POOL);
        assertEq(config.request.host, "api.example.com");
        assertEq(config.request.path, "/test");
        assertEq(uint8(config.request.method), uint8(RequestMethod.Get));
        assertEq(config.responseSchema, "uint256");
        assertEq(config.jqFilter, ".");
        assertEq(config.gasLimit, 500000);
    }

    function testWithFilter() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        config = FlowBuilder.withFilter(config, ".data.value");
        assertEq(config.jqFilter, ".data.value");
    }

    function testWithSchema() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        config = FlowBuilder.withSchema(config, "string");
        assertEq(config.responseSchema, "string");
    }

    function testWithCallback() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        config = FlowBuilder.withCallback(config, TEST_CONSUMER, TEST_CALLBACK);
        assertEq(config.consumer, TEST_CONSUMER);
        assertEq(config.callback, TEST_CALLBACK);
    }

    function testWithGasLimit() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        config = FlowBuilder.withGasLimit(config, 1000000);
        assertEq(config.gasLimit, 1000000);
    }

    function testWithMethod() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        config = FlowBuilder.withMethod(config, RequestMethod.Post);
        assertEq(uint8(config.request.method), uint8(RequestMethod.Post));
    }

    function testWithHeaders() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        RequestHeader[] memory headers = new RequestHeader[](1);
        headers[0] = RequestHeader({key: "Content-Type", value: "application/json"});

        config = FlowBuilder.withHeaders(config, headers);
        assertEq(config.request.headers[0].key, "Content-Type");
        assertEq(config.request.headers[0].value, "application/json");
    }

    function testWithQueryParameters() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        QueryParameter[] memory params = new QueryParameter[](1);
        params[0] = QueryParameter({key: "key", value: "value"});

        config = FlowBuilder.withQueryParameters(config, params);
        assertEq(config.request.parameters[0].key, "key");
        assertEq(config.request.parameters[0].value, "value");
    }

    function testWithBody() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        bytes memory body = bytes('{"key": "value"}');
        config = FlowBuilder.withBody(config, body);
        assertEq(keccak256(config.request.body), keccak256(body));
    }

    function testWithTdAddress() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        address tdAddress = address(0x12345678);
        config = FlowBuilder.withTdAddress(config, tdAddress);
        assertEq(config.patch.tdAddress, tdAddress);
    }

    function testWithPrivatePathSuffix() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        bytes memory pathSuffix = bytes("/private");
        config = FlowBuilder.withPrivatePathSuffix(config, pathSuffix);
        assertEq(keccak256(config.patch.pathSuffix), keccak256(pathSuffix));
    }

    function testWithPrivateHeaders() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        RequestHeaderPatch[] memory headers = new RequestHeaderPatch[](1);
        headers[0] = RequestHeaderPatch({key: "Authorization", ciphertext: bytes("Bearer token")});

        config = FlowBuilder.withPrivateHeaders(config, headers);
        assertEq(config.patch.headers[0].key, "Authorization");
        assertEq(keccak256(config.patch.headers[0].ciphertext), keccak256(bytes("Bearer token")));
    }

    function testWithPrivateQueryParameters() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        QueryParameterPatch[] memory params = new QueryParameterPatch[](1);
        params[0] = QueryParameterPatch({key: "apiKey", ciphertext: bytes("secret")});

        config = FlowBuilder.withPrivateQueryParameters(config, params);
        assertEq(config.patch.parameters[0].key, "apiKey");
        assertEq(keccak256(config.patch.parameters[0].ciphertext), keccak256(bytes("secret")));
    }

    function testWithPrivateBody() public {
        FlowBuilder.FlowConfig memory config =
            FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, "api.example.com", "/test");

        bytes memory body = bytes('{"secret": "value"}');
        config = FlowBuilder.withPrivateBody(config, body);
        assertEq(keccak256(config.patch.body), keccak256(body));
    }

    function testBuildFlow() public {
        // Request
        string memory host = "api.example.com";
        string memory path = "/test";
        RequestMethod method = RequestMethod.Post;
        RequestHeader[] memory headers = new RequestHeader[](1);
        headers[0] = RequestHeader({key: "Content-Type", value: "application/json"});
        QueryParameter[] memory parameters = new QueryParameter[](1);
        parameters[0] = QueryParameter({key: "key", value: "value"});
        bytes memory body = bytes('{"key": "value"}');

        // Private Patch
        bytes memory pathSuffix = bytes("/private");
        RequestHeaderPatch[] memory headersPatch = new RequestHeaderPatch[](1);
        headersPatch[0] = RequestHeaderPatch({key: "Authorization", ciphertext: bytes("Bearer token")});
        QueryParameterPatch[] memory parametersPatch = new QueryParameterPatch[](1);
        parametersPatch[0] = QueryParameterPatch({key: "apiKey", ciphertext: bytes("secret")});
        bytes memory bodyPatch = bytes('{"secret": "value"}');
        address tdAddress = address(0x12345678);

        // Response Schema
        string memory schema = "uint256";
        string memory filter = ".data.value";

        FlowBuilder.FlowConfig memory config = FlowBuilder.create(TEST_QUEX_CORE, TEST_ORACLE_POOL, host, path);

        config = config.withCallback(TEST_CONSUMER, TEST_CALLBACK).withGasLimit(1000000).withSchema(schema).withFilter(
            filter
        ).withMethod(method).withHeaders(headers).withQueryParameters(parameters).withBody(body).withTdAddress(
            tdAddress
        ).withPrivatePathSuffix(pathSuffix).withPrivateHeaders(headersPatch).withPrivateQueryParameters(parametersPatch)
            .withPrivateBody(bodyPatch);

        uint256 actionId = 1;

        HTTPRequest memory request =
            HTTPRequest({host: host, path: path, method: method, headers: headers, parameters: parameters, body: body});

        HTTPPrivatePatch memory patch = HTTPPrivatePatch({
            pathSuffix: pathSuffix,
            headers: headersPatch,
            parameters: parametersPatch,
            body: bodyPatch,
            tdAddress: tdAddress
        });

        bytes32 requestId = keccak256(abi.encode(request));
        bytes32 patchId = keccak256(abi.encode(patch));
        bytes32 schemaId = keccak256(abi.encode(schema));
        bytes32 filterId = keccak256(abi.encode(filter));

        Flow memory flow = Flow({
            gasLimit: config.gasLimit,
            actionId: actionId,
            pool: config.oraclePool,
            consumer: config.consumer,
            callback: config.callback
        });

        vm.mockCall(
            TEST_ORACLE_POOL,
            abi.encodeWithSelector(IRequestOraclePool.addRequest.selector, request),
            abi.encode(requestId)
        );
        vm.mockCall(
            TEST_ORACLE_POOL,
            abi.encodeWithSelector(IRequestOraclePool.addPrivatePatch.selector, patch),
            abi.encode(patchId)
        );
        vm.mockCall(
            TEST_ORACLE_POOL,
            abi.encodeWithSelector(IRequestOraclePool.addResponseSchema.selector, schema),
            abi.encode(schemaId)
        );
        vm.mockCall(
            TEST_ORACLE_POOL,
            abi.encodeWithSelector(IRequestOraclePool.addJqFilter.selector, filter),
            abi.encode(filterId)
        );
        vm.mockCall(
            TEST_ORACLE_POOL,
            abi.encodeWithSelector(IRequestOraclePool.addActionByParts.selector, requestId, patchId, schemaId, filterId),
            abi.encode(actionId)
        );
        vm.mockCall(TEST_QUEX_CORE, abi.encodeWithSelector(IFlowRegistry.createFlow.selector, flow), abi.encode(1));

        uint256 flowId = FlowBuilder.build(config);
        assertEq(flowId, 1);
    }
}
