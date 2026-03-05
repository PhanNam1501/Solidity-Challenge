// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BitMath} from "../libraries/Bitmath.sol";
library TickBitmap {
    function position(int24 pos) private pure returns (int16 bitPos, uint8 wordPos) {
        bitPos = int16(pos >> 8);
        wordPos = uint8(int8(pos % 256));
    }

    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0, "Not can use this tick");
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        require(tick % tickSpacing == 0, "Not can use this tick");
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        
        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = mask & self[wordPos];
            initialized = masked != 0 ? true : false;

            next =  initialized 
                ? (compressed - int24(int8(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(int8(bitPos))) * tickSpacing;
        } else {
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            initialized = masked != 0;
            next = initialized
                ? (compressed + 1 + int24(int8(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed + 1 + int24(int8(type(uint8).max - bitPos))) * tickSpacing;
        }
    }
}