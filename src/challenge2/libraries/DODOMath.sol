// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

library DODOMath {
    using FixedPointMathLib for uint256;
    uint256 constant ONE = 1e18;
    function generalIntegrate(
       uint256 V0, 
       uint256 V1,
       uint256 V2,
       uint256 i,
       uint256 k 
    ) internal pure returns (uint256) {
        require(V1 >= V2, "underflow");
        uint256 fairAmount = i.mulWadUp(V1 - V2);
        uint256 V0_sq = V0.mulWadUp(V0);
        uint256 V1_V2 = V1.mulWadUp(V2);
        uint256 VS = V0_sq.divWadUp(V1_V2);

        uint256 pelnaty = k.mulWadUp(VS);
        return fairAmount.mulWadUp(ONE - k + pelnaty);
    }

    function solveQuadraticFunctionForTrade(
        uint256 Q0, 
        uint256 Q1,
        uint256 ideltaB, //must be decimal 1e18
        bool deltaBSig,
        uint256 k
    ) internal pure returns (uint256) {
        uint256 ONE = 1e18;
        uint256 a = ONE - k;
        
        // ==========================================
        // BƯỚC 1: Tính các thành phần phụ trợ (Chuẩn WAD)
        // ==========================================
        uint256 Q0_sq = Q0.mulWadUp(Q0);
        uint256 k_Q0_sq_div_Q1 = k.mulWadUp(Q0_sq).divWadUp(Q1);
        uint256 a_Q1 = a.mulWadUp(Q1);

        // ==========================================
        // BƯỚC 2: Phân tách phe CỘNG và phe TRỪ để tránh Underflow
        // ==========================================
        uint256 addSide = a_Q1;
        uint256 subSide = k_Q0_sq_div_Q1;
        
        if (deltaBSig) {
            addSide = addSide + ideltaB;
        } else {
            subSide = subSide + ideltaB;
        }

        uint256 b_abs;
        bool minus_b_is_positive; 
        
        if (addSide >= subSide) {
            b_abs = addSide - subSide;
            minus_b_is_positive = true;
        } else {
            b_abs = subSide - addSide;
            minus_b_is_positive = false;
        }

        uint256 b_sq = b_abs.mulWadUp(b_abs);
        uint256 four_ac = 4 * a.mulWadUp(k).mulWadUp(Q0_sq);
        uint256 delta = b_sq + four_ac;

        uint256 sq_delta = (delta * ONE).sqrt();

        uint256 numerator;
        if (minus_b_is_positive) {
            numerator = sq_delta + b_abs;
        } else {
            numerator = sq_delta - b_abs; 
        }

        uint256 denominator = 2 * a;
        
        if (deltaBSig) {
            return numerator.divWad(denominator); 
        } else {
            return numerator.divWadUp(denominator);
        }
    }

    function solveQuadraticFunctionForTarget(
        uint256 V1,
        uint256 k,
        uint256 fairAmount
    ) internal pure returns (uint256 V0) {
        uint256 sqrt = ONE + (4 * k.mulWadUp(fairAmount)).divWadUp(V1);
        sqrt = (sqrt * ONE).sqrt();
        uint256 x = (sqrt - ONE).divWadUp(2 * k);
        return V1.mulWadUp(ONE + x);
    }
}