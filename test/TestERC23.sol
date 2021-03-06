pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MobileGoToken.sol";
import "../contracts/ContractReceiver.sol";
import "./helpers/ContractReceiverOverrider.sol";


// Contract that isn't working with ERC223 tokens
contract ContractNonReceiver {
}

// Proxy contract for testing throws
contract ThrowProxy {
  address public target;
  bytes data;
  function ThrowProxy(address _target) {
    target = _target;
  }

  //prime the data using the fallback function.
  function() {
    data = msg.data;
  }

  function tokenFallback(address _from, uint _value, bytes _data) {
  }

  function execute() returns (bool) {
    return target.call(data);
  }
}

contract TestERC23 {
  function testInitialBalanceUsingDeployedContract() {
    MobileGoToken token = MobileGoToken(DeployedAddresses.MobileGoToken());

    uint expected = 10000000000000000;

    Assert.equal(token.balanceOf(tx.origin), expected, "Owner should have 10000000000000000 MetaCoin initially");
  }

  function testTraspasingWithDataToValidContract() {
    MobileGoToken token = new MobileGoToken();

    ContractReceiver receiver = new ContractReceiver();
    uint expected = 10000000000000000;
    bytes memory empty;

    Assert.equal(token.balanceOf(address(this)), expected, "Owner should have 10000000000000000 MetaCoin initially");
    Assert.isTrue(token.transfer(address(receiver), 5000000000000000, empty), 'Transfer success');
    Assert.equal(token.balanceOf(address(this)), 5000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
    Assert.equal(token.balanceOf(address(receiver)), 5000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
  }

  function testTraspasingWithDataToInvalidContract() {
    MobileGoToken token = new MobileGoToken();
    ContractNonReceiver nonReceiver = new ContractNonReceiver();

    ThrowProxy throwProxy = new ThrowProxy(address(token));

    uint expected = 10000000000000000;
    bytes memory empty;

    Assert.equal(token.balanceOf(address(this)), expected, "Owner should have 10000000000000000 MetaCoin initially");
    /* Proxy Contract will execute and catch the throw so it needs the balance */
    Assert.isTrue(token.transfer(address(throwProxy), 10000000000000000), 'Transfer to Proxy success');
    MobileGoToken(address(throwProxy)).transfer(address(nonReceiver), 5000000000000000, empty);
    bool r = throwProxy.execute.gas(200000)();
    Assert.isFalse(r, "Should be false, as it should throw");
    Assert.equal(token.balanceOf(address(throwProxy)), 10000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
    Assert.equal(token.balanceOf(address(nonReceiver)), 0, "Owner should have 5000000000000000 MetaCoin initially");
  }

  function testTraspasingWithoutDataToValidContract() {
    MobileGoToken token = new MobileGoToken();

    ContractReceiver receiver = new ContractReceiver();
    uint expected = 10000000000000000;

    Assert.equal(token.balanceOf(address(this)), expected, "Owner should have 10000000000000000 MetaCoin initially");
    Assert.isTrue(token.transfer(address(receiver), 5000000000000000), 'Transfer success');
    Assert.equal(token.balanceOf(address(this)), 5000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
    Assert.equal(token.balanceOf(address(receiver)), 5000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
  }

  function testTraspasingWithoutDataToValidContract2() {
    MobileGoToken token = new MobileGoToken();

    ContractReceiverOverrider receiver = new ContractReceiverOverrider();
    uint expected = 10000000000000000;

    Assert.equal(token.balanceOf(address(this)), expected, "Owner should have 10000000000000000 MetaCoin initially");
    Assert.isTrue(token.transfer(address(receiver), 5000000000000000), 'Transfer success');
    Assert.equal(token.balanceOf(address(this)), 5000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
    Assert.equal(token.balanceOf(address(receiver)), 5000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
  }

  function testTraspasingWithoutDataToInvalidContract() {
    MobileGoToken token = new MobileGoToken();
    ContractNonReceiver nonReceiver = new ContractNonReceiver();

    ThrowProxy throwProxy = new ThrowProxy(address(token));

    uint expected = 10000000000000000;

    Assert.equal(token.balanceOf(address(this)), expected, "Owner should have 10000000000000000 MetaCoin initially");
    /* Proxy Contract will execute and catch the throw so it needs the balance */
    Assert.isTrue(token.transfer(address(throwProxy), 10000000000000000), 'Transfer to Proxy success');
    MobileGoToken(address(throwProxy)).transfer(address(nonReceiver), 5000000000000000);
    bool r = throwProxy.execute.gas(200000)();
    Assert.isFalse(r, "Should be false, as it should throw");
    Assert.equal(token.balanceOf(address(throwProxy)), 10000000000000000, "Owner should have 5000000000000000 MetaCoin initially");
    Assert.equal(token.balanceOf(address(nonReceiver)), 0, "Owner should have 5000000000000000 MetaCoin initially");
  }
}
