contract Latch
{
	struct Transfer {
		uint224 amount;
		uint32 nonce;
		address dest;
	}
	
	enum State {
		None,
		Requested,
		Confirmed
	}
	
	struct Account {
		uint224 balance;
		uint32 nonce;
		uint32 unconfirmedSince;
		State state;
		Transfer pending;
	}
	
	function Latch() {
		owner = msg.sender;
	}
	
	modifier only_owner { if (msg.sender == owner) _ }
	
	function adopt(address _newOwner) only_owner {
		owner = _newOwner;
	}
	
	function transfer(uint32 nonce, address dest, uint224 amount) {
		var from = msg.sender;
		if (accounts[from].balance < amount || accounts[from].nonce != nonce)
			return;
		var t = Transfer(amount, nonce, dest);
		var p = accounts[from].pending;
		if (accounts[from].state == State.Confirmed && p.nonce == nonce && p.dest == dest && p.amount == amount)
			enact(from, p);
		else if (accounts[from].state == State.None) {
			accounts[from].state == State.Requested;
			accounts[from].unconfirmedSince = uint32(now);
			accounts[from].pending = t;
		}
	}
	
	function confirm(address from, uint224 amount, uint32 nonce, address dest) only_owner {
		if (accounts[from].balance < amount || accounts[from].nonce != nonce)
			return;
		var t = Transfer(amount, nonce, dest);
		var p = accounts[from].pending;
		if (accounts[from].state == State.Requested && p.nonce == nonce && p.dest == dest && p.amount == amount)
			enact(from, p);
		else {
			accounts[from].state = State.Confirmed;
			accounts[from].pending = t;
		}
	}
	
	function force() {
		var from = msg.sender;
		
	}
	
	function enact(address from, Transfer _t) internal {
		_t.dest.send(_t.amount);
		accounts[from].nonce = _t.nonce + 1;
		accounts[from].unconfirmedSince = 0;
		delete accounts[from].pending;
	}
	
	mapping ( address => Account ) accounts;
	address owner;
}
