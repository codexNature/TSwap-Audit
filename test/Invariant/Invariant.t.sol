// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "../../test/Invariant/Handler.t.sol";

contract Invariant is StdInvariant, Test {
  //these pools have 2 assets
  ERC20Mock poolToken;
  ERC20Mock weth;

  //We are gonna need the contracts. 

  PoolFactory factory;
  TSwapPool pool;
  Handler handler;

  int256 constant STARTING_X = 100e18; //starting ERC20 / poolToken
  int256 constant STARTING_Y = 59e18; //starting weth   
  function setUp() public {
      weth = new ERC20Mock();
      poolToken = new ERC20Mock();
      factory = new PoolFactory(address(weth));
      pool = TSwapPool(factory.createPool(address(poolToken)));

      //Create those initial x & y balances
      poolToken.mint(address(this), uint256(STARTING_X));
      weth.mint(address(this), uint256(STARTING_Y)); //minting the token then approve it's deposit below.


      poolToken.approve(address(pool), type(uint256).max);
      weth.approve(address(pool), type(uint256).max); //approvong the deposit that is gonna happen below

      pool.deposit(
        uint256(STARTING_Y), 
        uint256(STARTING_Y),
        uint256(STARTING_X), 
        uint64(block.timestamp)
        );

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({addr:address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSameX() public view {
        //assert() //_bound
        //The Change in the pool size of weth should follow this function:
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }

     function statefulFuzz_constantProductFormulaStaysTheSameY() public view {
        //assert() //_bound
        //The Change in the pool size of weth should follow this function:
        assertEq(handler.actualDeltaY(), handler.expectedDeltaY());
    }
}