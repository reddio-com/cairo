// compile => cargo run --bin starknet-compile -- erc721.cairo
// Current repo can not be compiled because lack of independence
#[contract]
mod erc721 {
    // same like msg.sender in Solidity, return type is ContractAddress
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    // contract address type to felt type
    use starknet::ContractAddressIntoFelt252;
    // felt to int. eg, 1.into()
    use traits::Into;
    // 2 lines below can make is_zero() of ContractAddress usable to assert if the address is 0
    use zeroable::Zeroable;
    use starknet::ContractAddressZeroable;

    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: LegacyMap::<u256, ContractAddress>,
        balances: LegacyMap::<ContractAddress, u256>,
        token_approvals: LegacyMap::<u256, ContractAddress>,
        // (owner, operator)
        operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
    }

    #[event]
    fn Approval(owner: ContractAddress, to: ContractAddress, token_id: u256) {}

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {}

    #[event]
    fn ApprovalForAll(owner: ContractAddress, operator: ContractAddress, approved: bool) {}

    #[constructor]
    fn constructor(_name: felt252, _symbol: felt252) {
        name::write(_name);
        symbol::write(_symbol);
    }

    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool) {
        // ContractAddress equation is not supported so into() is used here
        // operator != get_caller_address() will fail
        assert(operator.into() != get_caller_address().into(), 'ERC721: approve to caller');
        _set_approval_for_all(get_caller_address(), operator, approved);
    }

    #[internal]
    fn _set_approval_for_all(owner: ContractAddress, operator: ContractAddress, approved: bool) {
        assert(owner.into() != operator.into(), 'ERC721: approve to caller');
        operator_approvals::write((owner, operator), approved);
        ApprovalForAll(owner, operator, approved);
    }

    #[external]
    fn approve(to: ContractAddress, token_id: u256) {
        let owner = _owner_of(token_id);
        // Unlike Solidity, require is not supported, only assert can be used
        // The max length of error msg is 31 or there's an error
        assert(to.into() != owner.into(), 'Approval to current owner');
        // || is not supported currently
        // || is_approved_for_all(owner, get_caller_address())
        assert(get_caller_address().into() == owner.into(), 'not token owner');
        _approve(to, token_id);
    }

    #[internal]
    fn _approve(to: ContractAddress, token_id: u256) {
        token_approvals::write(token_id, to);
        Approval(owner_of(token_id), to, token_id);
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        assert(_is_approved_or_owner(from, token_id), 'ERC721: caller is not');
        _transfer(from, to, token_id);
    }

    #[internal]
    fn _exists(token_id: u256) -> bool {
        !_owner_of(token_id).is_zero()
    }

    #[internal]
    fn _owner_of(token_id: u256) -> ContractAddress {
        owners::read(token_id)
    }

    #[internal]
    fn _mint(to: ContractAddress, token_id: u256) {
        assert(!to.is_zero(), 'ERC721: mint to 0');
        assert(!_exists(token_id), 'ERC721: already minted');

        balances::write(to, balances::read(to) + 1.into());
        owners::write(token_id, to);
        // contract_address_const::<0>() => means 0 address
        Transfer(contract_address_const::<0>(), to, token_id);
    }

    #[internal]
    fn _burn(token_id: u256) {
        let owner = owner_of(token_id);
        token_approvals::write(token_id, contract_address_const::<0>());

        balances::write(owner, balances::read(owner) - 1.into());
        owners::write(token_id, contract_address_const::<0>());
        Transfer(owner, contract_address_const::<0>(), token_id);
    }

    #[internal]
    fn _require_minted(token_id: u256) {
        assert(_exists(token_id), 'ERC721: invalid token ID');
    }

    #[internal]
    fn _is_approved_or_owner(spender: ContractAddress, token_id: u256) -> bool {
        let owner = owners::read(token_id);
        // || is not supported currently
        // is_approved_for_all(owner)
        //  || get_approved(token_id).into() == spender.into()
        spender.into() == owner.into()
    }

    #[internal]
    fn _transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {
        assert(from.into() == owner_of(token_id).into(), 'ERC721: transfer from');
        assert(!to.is_zero(), 'ERC721: transfer to 0');

        token_approvals::write(token_id, contract_address_const::<0>());

        balances::write(from, balances::read(from) - 1.into());
        balances::write(to, balances::read(to) + 1.into());

        owners::write(token_id, to);

        Transfer(from, to, token_id);
    }

    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
        operator_approvals::read((owner, operator))
    }

    #[view]
    fn get_approved(token_id: u256) -> ContractAddress {
        _require_minted(token_id);
        token_approvals::read(token_id)
    }

    #[view]
    fn token_uri(token_id: u256) -> felt252 {
        _require_minted(token_id);
        let base_uri = _base_uri();
        // base_uri + felt(token_id)
        // considering how felt and u256 can be concatted.
        base_uri + ''
    }

    #[view]
    fn _base_uri() -> felt252 {
        ''
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        assert(!account.is_zero(), 'ERC721: address zero');
        balances::read(account)
    }

    #[view]
    fn owner_of(token_id: u256) -> ContractAddress {
        let owner = _owner_of(token_id);
        // both are OK!
        // assert(owner.into() != contract_address_const::<0>().into(), 'ERC721: invalid token ID');
        assert(!owner.is_zero(), 'ERC721: invalid token ID');
        owner
    }

    #[view]
    fn get_name() -> felt252 {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt252 {
        symbol::read()
    }
}