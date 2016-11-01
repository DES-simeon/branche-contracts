pragma solidity ^0.4.2;

contract BrancheProportionalCrowdsale {
    address public owner;
    uint public target; uint public hardCap; uint public raised; uint public deadline;
    bool funded; bool targetHit;
    mapping(address => uint) public balances;
    mapping(address => bool) public refunded;
    event TargetHit(uint amountRaised);
    event CrowdsaleClosed(uint amountRaised);
    event FundTransfer(address backer, uint amount);
    event Refunded(address backer, uint amount);

    function BrancheProportionalCrowdsale(uint _durationInMinutes, uint _targetETH) {
        owner = msg.sender;
        deadline = now + _durationInMinutes * 1 minutes;
        target = _targetETH * 1 ether;
        // no deposit shall be over 50% of the target
        hardCap = target/2;
    }

    function _deposit() private {
        if (now >= deadline) throw;
        // Re-instate the hard-cap by uncommenting the following line
        // if (msg.value > hardCap) throw;

        balances[msg.sender] += msg.value;
        raised += msg.value;
        FundTransfer(msg.sender, msg.value);
    }

    function deposit() payable {
        _deposit();
    }

    function() payable {
        _deposit();
    }

    function withdrawRefund() {
        if (now <= deadline) throw;
        if (raised <= target) throw;
        if (refunded[msg.sender]) throw;

        uint deposit = balances[msg.sender];
        uint keep = (deposit * target) / raised;
        uint refund = deposit - keep;
        if (refund > this.balance) refund = this.balance;

        refunded[msg.sender] = true;
        Refunded(msg.sender, refund);
        if (!msg.sender.call.value(refund)()) throw;
    }

    function fundOwner() {
        if (now <= deadline) throw;
        if (funded) throw;
        funded = true;
        CrowdsaleClosed(raised);
        if (raised < target) {
            if (raised > this.balance) raised = this.balance;
            if (!owner.call.value(raised)()) throw;
        } else {
            TargetHit(raised);
            if (target > this.balance) target = this.balance;
            if (!owner.call.value(target)()) throw;
        }
    }
}
