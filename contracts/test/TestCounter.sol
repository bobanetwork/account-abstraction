// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

//sample "receiver" contract, for testing "exec" from account.

//interface IHybridAccount {
//  function CallOffchain(bytes32, bytes memory) external returns (uint32, bytes memory);
//}
import "../samples/HybridAccount.sol";

contract TestCounter {
    mapping(address => uint256) public counters;

    address payable immutable helperAddr;
    
    constructor(address payable _helperAddr) {
      helperAddr = _helperAddr;
    }
    
    function count(uint32 a, uint32 b, address ha_addr) public {
    
       //HybridAccount HA = HybridAccount(helperAddr);
       HybridAccount HA = HybridAccount(payable(ha_addr));
       uint256 x;
       uint256 y;
       if (b == 0) {
           counters[msg.sender] = counters[msg.sender] + a;
	   return;
       }
       bytes memory req = abi.encodeWithSignature("addsub2(uint32,uint32)", a, b);
       bytes32 userKey = bytes32(abi.encode(msg.sender));
       (uint32 error, bytes memory ret) = HA.CallOffchain(userKey, req);

       if (error == 0) {
           (x,y) = abi.decode(ret,(uint256,uint256)); // x=(a+b), y=(a-b)

           this.gasWaster(x, "abcd1234");
           counters[msg.sender] = counters[msg.sender] + y;
       } else if (b >= 10) {
           revert(string(ret));
       } else if (error == 1) {
           counters[msg.sender] = counters[msg.sender] + 100;
       } else {
           //revert(string(ret));
           counters[msg.sender] = counters[msg.sender] + 1000;
       }

    }

    function countFail() public pure {
        revert("count failed");
    }

    function justemit() public {
        emit CalledFrom(msg.sender);
    }

    event CalledFrom(address sender);

    //helper method to waste gas
    // repeat - waste gas on writing storage in a loop
    // junk - dynamic buffer to stress the function size.
    mapping(uint256 => uint256) public xxx;
    uint256 public offset;

    function gasWaster(uint256 repeat, string calldata /*junk*/) external {
        for (uint256 i = 1; i <= repeat; i++) {
            offset++;
            xxx[offset] = i;
        }
    }
}
