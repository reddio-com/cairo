use starknet::ContractAddress;

#[starknet::contract]
mod AirdropERC20 {
    use openzeppelin::token::erc20::interface::ERC20ABIDispatcher;
    use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use array::ArrayTrait;

    #[storage]
    struct Storage {
        owner: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnerChanged: OwnerChanged,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerChanged {
        old_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _owner: ContractAddress,) {
        self.owner.write(_owner);
    }

    #[abi(embed_v0)]
    fn airdrop(
        ref self: ContractState,
        token_address: ContractAddress,
        token_owner: ContractAddress,
        recipients: Array::<ContractAddress>,
        amounts: Array::<u256>
    ) {
        assert(self.owner.read() == get_caller_address(), 'Owner required');
        let len = amounts.len();
        assert(len == recipients.len(), 'length mismatch');
        let token = ERC20ABIDispatcher { contract_address: token_address };
        let mut i: usize = 0;
        loop {
            if i >= len {
                break ();
            }
            token.transfer_from(token_owner, *recipients.at(i), *amounts.at(i));
            i += 1;
        }
    }

    #[abi(embed_v0)]
    fn change_owner(ref self: ContractState, new_owner: ContractAddress) {
        assert(self.owner.read() == get_caller_address(), 'Owner required');
        let old_owner = self.owner.read();
        self.owner.write(new_owner);
        self.emit(Event::OwnerChanged(OwnerChanged { old_owner, new_owner }));
    }
}
