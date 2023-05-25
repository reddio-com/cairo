#[abi]
trait IERC20 {
    fn transfer_from(
        sender: starknet::ContractAddress, 
        recipient: starknet::ContractAddress, 
        amount: u256
    );
}

#[contract]
mod AirdropERC20 {

    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use array::ArrayTrait;

    struct Storage {
        owner: ContractAddress
    }

    #[event]
    fn OwnerChanged(old_owner: ContractAddress, new_owner: ContractAddress) {}

    #[constructor]
    fn constructor(owner: ContractAddress) {
        owner::write(get_caller_address());
    }

    #[external]
    fn airdrop(
        token_address: ContractAddress,
        token_owner: ContractAddress,
        recipients: Array::<ContractAddress>,
        amounts: Array::<u256>
    ) {
        assert(owner::read() == get_caller_address(), 'Owner required');
        let len = amounts.len();
        assert(len == recipients.len(), 'length mismatch');
        let token = IERC20Dispatcher {contract_address: token_address };
        let mut i: usize = 0;
        loop {
            if i >= len {
                break();
            }
            token.transfer_from(token_owner, *recipients.at(i), *amounts.at(i));
            i += 1;
        }
    }

    #[external]
    fn change_owner(new_owner: ContractAddress) {
        assert(owner::read() == get_caller_address(), 'Owner required');
        let old_owner = owner::read();
        owner::write(new_owner);
        OwnerChanged(old_owner, new_owner);
    }
}
