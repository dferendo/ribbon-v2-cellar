// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Math} from "src/utils/Math.sol";

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

contract MockSwapRouter {
    using Path for bytes;
    using Math for uint256;

    uint256 public constant EXCHANGE_RATE = 0.95e18;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256) {
        ERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        uint256 amountOut = params.amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(params.tokenIn).decimals();
        uint8 toDecimals = ERC20(params.tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= params.amountOutMinimum, "amountOutMin invariant failed");

        ERC20(params.tokenOut).transfer(params.recipient, amountOut);
        return amountOut;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params) external payable returns (uint256) {
        (address tokenIn, address tokenOut,) = params.path.decodeFirstPool();

        while (params.path.hasMultiplePools()) {
            params.path = params.path.skipToken();
            (, tokenOut,) = params.path.decodeFirstPool();
        }

        ERC20(tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        uint256 amountOut = params.amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= params.amountOutMinimum, "amountOutMin invariant failed");

        ERC20(tokenOut).transfer(params.recipient, amountOut);
        return amountOut;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256
    ) external returns (uint256[] memory) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= amountOutMin, "amountOutMin invariant failed");

        ERC20(tokenOut).transfer(to, amountOut);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountOut;

        return amounts;
    }

    function exchange_multiple(address[9] memory _route, uint256[3][4] memory, uint256 _amount, uint256 _expected)
        external
        returns (uint256)
    {
        address tokenIn = _route[0];

        address tokenOut;
        for (uint256 i;; i += 2) {
            if (i == 8 || _route[i + 1] == address(0)) {
                tokenOut = _route[i];
                break;
            }
        }

        ERC20(tokenIn).transferFrom(msg.sender, address(this), _amount);

        uint256 amountOut = _amount.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= _expected, "received less than expected");

        ERC20(tokenOut).transfer(msg.sender, amountOut);

        return amountOut;
    }

    function quote(uint256 amountIn, address[] calldata path) external view returns (uint256) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        uint256 amountOut = amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        return amountOut.changeDecimals(fromDecimals, toDecimals);
    }

    receive() external payable {}
}
