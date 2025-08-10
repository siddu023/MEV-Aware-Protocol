// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

interface IOracle {
    function getPrice(address asset) external view returns (uint256);

}

interface IBorrower {
    function debt() external view returns (uint256);
    function collateral() external view returns (uint256);
    function liquidaate() external;
    }

    contract BackrunLiquidator {
        IOracle public oracle;
        uint256 public constant COOLDOWN = 10;

        struct LiquidationWindow {
            uint256 triggeredAt;
            bool marked;
        }

        mapping(address => LiquidationWindow) public pending;

        constructor(address _oracle) {
            oracle = IOracle(_oracle);
        }

        function markLiquidation(address borrower, uint256 collateralPrice) external  {
            IBorrower b = IBorrower(borrower);
            uint256 debt = b.debt();
            uint256 col = b.collateral();

            uint256 value = col * collateralPrice;
            require(value < debt, "Not Liquidatable");

            pending[borrower] = LiquidationWindow({
                triggeredAt : block.number,
                marked : true
            });
        }

        function executeLiquidation(address borrower) external {
            LiquidationWindow memory win = pending[borrower];
            require(win.marked, "Not Marked");
            require(block.number >= win.triggeredAt + COOLDOWN, " cooldown active");

            IBorrower(borrower).liquidate();
            delete pending[borrower];
        }

    }