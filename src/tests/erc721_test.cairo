use reddio_cairo::ERC721::ERC721;
use reddio_cairo::ERC721::IERC721Dispatcher;
use reddio_cairo::ERC721::IERC721DispatcherTrait;

use integer::u256_from_felt252;

use array::ArrayTrait;
use traits::Into;
use result::ResultTrait;
use traits::TryInto;
use option::OptionTrait;

use starknet::contract_address_const;
use starknet::contract_address::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};
use starknet::syscalls::deploy_syscall;
use starknet::SyscallResultTrait;
use starknet::class_hash::Felt252TryIntoClassHash;

const NAME: felt252 = 'Reddio Test ERC721 Token';
const SYMBOL: felt252 = 'Reddio721';

fn setUp() -> (ContractAddress, IERC721Dispatcher, ContractAddress) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    let mut calldata = array![NAME, SYMBOL];

    let (erc721_address, _) = deploy_syscall(
        ERC721::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc721_token = IERC721Dispatcher { contract_address: erc721_address };

    (caller, erc721_token, erc721_address)
}

#[test]
#[available_gas(2000000)]
fn test_init() {
    let (caller, erc721_token, erc721_address) = setUp();

    assert(erc721_token.get_name() == NAME, 'Invalid name');
    assert(erc721_token.get_symbol() == SYMBOL, 'Invalid symbol');
}

#[test]
#[available_gas(2000000)]
fn test_mint() {
    let (caller, erc721_token, erc721_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc721_token.mint(alice, 0_u256);
    assert(erc721_token.balance_of(alice) == 1_u256, 'invalid mint');

    erc721_token.mint(alice, 1_u256);
    assert(erc721_token.balance_of(alice) == 2_u256, 'invalid mint');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC721: already minted', 'ENTRYPOINT_FAILED',))]
fn test_fail_mint_duplicate() {
    let (caller, erc721_token, erc721_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc721_token.mint(alice, 0_u256);
    erc721_token.mint(alice, 0_u256);
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let (caller, erc721_token, erc721_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc721_token.mint(caller, 1_u256);
    erc721_token.approve(alice, 1_u256);

    assert(erc721_token.get_approved(1_u256) == alice, 'Not approved');
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all() {
    let (caller, erc721_token, erc721_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    assert(!erc721_token.is_approved_for_all(caller, alice), 'Approved');
    erc721_token.set_approval_for_all(alice, true);
    assert(erc721_token.is_approved_for_all(caller, alice), 'Not approved');

    erc721_token.set_approval_for_all(alice, false);
    assert(!erc721_token.is_approved_for_all(caller, alice), 'Approved');
}

#[test]
#[available_gas(2000000)]
fn test_owner() {
    let (caller, erc721_token, erc721_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc721_token.mint(caller, 1_u256);
    assert(erc721_token.owner_of(1_u256) == caller, 'Invalid owner');
}

#[test]
#[available_gas(3000000)]
fn test_transfer_from() {
    let (caller, erc721_token, erc721_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 1_u256;

    erc721_token.mint(caller, token_id);
    erc721_token.transfer_from(caller, alice, token_id);

    set_contract_address(alice);
    erc721_token.approve(caller, token_id);

    set_contract_address(caller);
    erc721_token.transfer_from(alice, caller, token_id);
}
