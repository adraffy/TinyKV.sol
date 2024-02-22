# TinyKV.sol

*Make `sstore()` Great Again!*


Instead of using storage variables, just use:

```solidity
function setTiny(uint256 slot, bytes memory v) internal;
function getTiny(uint256 slot) internal view returns (bool empty, bytes memory v);
```

Uses only 4-bytes for `length`:
```solidity
uint256 slot = 1;
mapping (uint256 => bytes) map;
map[slot] = new bytes(33) // 3 slots!
setTiny(slot, new bytes(33)) // 2 slots

// storage layout:
// [00000000_00000000...00000000]               //   null  | 0 slot
// [00000000_00000000...00000001]               // "empty" | 1 slot
// [00000001_XX000000...00000000]              //  1 byte  | 1 slot
// [0000001C_XXXXXXXX...XXXXXXXX]              // 28 bytes | 1 slot
// [0000001D_XXXXXXXX...XXXXXXXX][XX000000...] // 29 bytes | 2 slots
```
* store [28 bytes](https://goerli.etherscan.io/tx/0x4731b409cb116289bcadeefb994dc0228c8dec28f37c18b74415b19b466147c2)
* store [29 bytes](https://goerli.etherscan.io/tx/0x410c96526163f3e585070e5eafa514a590902acc97c1720c74abd98548e4a1ff)

### Idea: Getter Reflection

Before:
```solidity
function text(bytes32 node, string calldata key) external view returns (string memory) {
	return string(records[node][key]);
}
```
After: 
```solidity
function text(bytes32, string calldata) external view returns (string memory) {
	return string(reflect());
}
function reflect() internal view returns (bytes memory) {
	return getTiny(uint256(keccak256(msg.data))); // use the incoming call as the key!
}
```