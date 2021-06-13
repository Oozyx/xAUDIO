pragma solidity ^0.6.2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract xAUDIOProxy is TransparentUpgradeableProxy {
    constructor(address logic, address proxyAdmin) public TransparentUpgradeableProxy(logic, proxyAdmin, "") {}
}
