// compile => cargo run --bin starknet-compile -- erc721.cairo
// Current repo can not be compiled because lack of independence
#[contract]
mod erc721 {
    // same like msg.sender in Solidity, return type is ContractAddress
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    // contract address type to felt type
    use starknet::contract_address_to_felt;
    // felt to int. eg, 1.into()
    use traits::Into;
    // 2 lines below can make is_zero() of ContractAddress usable to assert if the address is 0
    use zeroable::Zeroable;
    use starknet::ContractAddressZeroable;

    struct Storage {
        name: felt,
        symbol: felt,
        // map of ContractAddress -> u256 is supported, not for u256 -> ContractAddress
        // using u256 -> felt as replacement
        owners: LegacyMap::<u256, felt>,
        balances: LegacyMap::<ContractAddress, u256>,
        token_approvals: LegacyMap::<u256, felt>,
        // (owner, operator)
        operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
    }

    // owner as type felt here is because u256 => ContractAddress is not supported
    // return type from `owners` is felt
    #[event]
    fn Approval(owner: felt, to: ContractAddress, token_id: u256) {}

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {}

    #[constructor]
    fn constructor(_name: felt, _symbol: felt) {
        name::write(_name);
        symbol::write(_symbol);
    }

    #[external]
    fn set_approval_for_all(operator: ContractAddress, approved: bool) {
        // ContractAddress equation is not supported so contract_address_to_felt is used here
        // operator != get_caller_address() will fail
        assert(contract_address_to_felt(operator) != contract_address_to_felt(get_caller_address()), 'ERC721: approve to caller');
        operator_approvals::write((get_caller_address(), operator), true);
    }

    #[external]
    fn approve(to: ContractAddress, token_id: u256) {
        let owner = owner_of(token_id);
        // Unlike Solidity, require is not supported, only assert can be used
        // The max length of error msg is 31 or there's an error
        assert(contract_address_to_felt(to) != owner, 'ERC721: transfer from 011111111');
        // is_approved_for_all
        assert(contract_address_to_felt(get_caller_address()) == owner, 'not token owner');
        token_approvals::write(token_id, contract_address_to_felt(to));
        Approval(owner_of(token_id), to, token_id);
    }

    #[external]
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256) {
        assert(_is_approved_or_owner(from, token_id), 'ERC721: caller is not');
        _transfer(from, to, token_id);
    }

    #[internal]
    fn _exists(token_id: u256) -> bool {
        owners::read(token_id) != 0
    }

    #[internal]
    fn _mint(to: ContractAddress, token_id: u256) {
        assert(!to.is_zero(), 'ERC721: mint to 0');
        assert(!_exists(token_id), 'ERC721: already minted');

        balances::write(to, balances::read(to) + 1.into());
        owners::write(token_id, contract_address_to_felt(to));
        // contract_address_const::<0>() => means 0 address
        Transfer(contract_address_const::<0>(), to, token_id);
    }

    #[internal]
    fn _burn(token_id: u256) {
        let owner = owner_of(token_id);
        token_approvals::write(token_id, 0);

        balances::write(owner, balances::read(owner) - 1.into());
        owners::write(token_id, 0);
        // felt cannot be converted to type ContractAddress currently
        // Transfer(owner, contract_address_const::<0>(), token_id);
    }

    #[internal]
    fn _require_minted(token_id: u256) {
        assert(_exists(token_id), 'ERC721: invalid token ID');
    }

    #[internal]
    fn _is_approved_or_owner(spender: ContractAddress, token_id: u256) -> bool {
        let owner = owners::read(token_id);
        // is_approved_for_all(owner)
        //  || get_approved(token_id) == contract_address_to_felt(spender)
        contract_address_to_felt(spender) == owner
    }

    #[internal]
    fn _transfer(from: ContractAddress, to: ContractAddress, token_id: u256) {
        assert(contract_address_to_felt(from) == owner_of(token_id), 'ERC721: transfer from');
        // assert(contract_address_to_felt(to) != 0, 'ERC721: transfer to 0');
        assert(!to.is_zero(), 'ERC721: transfer to 0');

        token_approvals::write(token_id, 0);

        balances::write(from, balances::read(from) - 1.into());
        balances::write(to, balances::read(to) + 1.into());

        owners::write(token_id, contract_address_to_felt(to));
    }

    #[view]
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool {
        operator_approvals::read((owner, operator))
    }

    #[view]
    fn get_approved(token_id: u256) -> felt {
        _require_minted(token_id);
        token_approvals::read(token_id)
    }

    #[view]
    fn token_uri(token_id: u256) -> felt {
        _require_minted(token_id);
        let base_uri = _base_uri();
        // base_uri + felt(token_id)
        // considering how felt and u256 can be concatted.
        base_uri + ''
    }

    #[view]
    fn _base_uri() -> felt {
        ''
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        assert(!account.is_zero(), 'ERC721: address zero');
        balances::read(account)
    }

    #[view]
    fn owner_of(token_id: u256) -> felt {
        let owner = owners::read(token_id);
        assert(owner != 0, 'ERC721: invalid token ID');
        owner
    }

    #[view]
    fn get_name() -> felt {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt {
        symbol::read()
    }
}