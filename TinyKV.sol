/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract TinyKV {

	// header: first 4 bytes
	//  0 => 0 : []
	//  1 => 1 : [0x00000001_XX000000000000000000000000000000000000000000000000000000]
	// 28 => 1 : [0x0000001C_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX]
	// 29 => 2 : [0x0000001D_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX]0xXX00000000000000000000000000000000000000000000000000000000000000]
	function tinySlots(uint256 size) public pure returns (uint256) {
		unchecked {
			return size > 0 ? (size + 35) >> 5 : 0;
		}
	}

	function setTiny(uint256 slot, bytes memory v) external {
		unchecked {
			uint256 head;
			assembly { head := sload(slot) }
			uint256 size;
			assembly { size := mload(v) }
			uint256 n0 = tinySlots(head >> 224);
			uint256 n1 = tinySlots(size);
			assembly {
				// overwrite
				if gt(n1, 0) {
					sstore(slot, or(shl(224, size), shr(32, mload(add(v, 32)))))
					let ptr := add(v, 60)
					for { let i := 1 } lt(i, n1) { i := add(i, 1) } { 
						sstore(add(slot, i), mload(ptr))
						ptr := add(ptr, 32)
					}
				}
				// clear unused
				for { let i := n1 } lt(i, n0) { i := add(i, 1) } { 
					sstore(add(slot, i), 0) 
				}
			}
		}
	}

	function getTiny(uint256 slot) external view returns (bytes memory v) {
		unchecked {
			uint256 head;
			assembly { head := sload(slot) }
			uint256 size = head >> 224;
			if (size > 0) {
				v = new bytes(size);
				uint256 n = tinySlots(size);
				assembly {
					mstore(add(v, 32), shl(32, head))
					let p := add(v, 60)
					let i := 1
					for {} lt(i, n) {} {
						mstore(p, sload(add(slot, i)))
						p := add(p, 32)
						i := add(i, 1)
					}
				}
			}
		}
	}


}