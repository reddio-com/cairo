use reddio_cairo::ERC1155::ERC1155;
use reddio_cairo::ERC1155::IERC1155Dispatcher;
use reddio_cairo::ERC1155::IERC1155DispatcherTrait;

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

const NAME: felt252 = 'Reddio Test ERC1155 Token';
const SYMBOL: felt252 = 'Reddio1155';
const URI: felt252 = 'reddio.com';

fn setUp() -> (ContractAddress, IERC1155Dispatcher, ContractAddress) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    let mut calldata = array![URI];

    let (erc1155_address, _) = deploy_syscall(
        ERC1155::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };

    (caller, erc1155_token, erc1155_address)
}

#[test]
#[available_gas(2000000)]
fn test_mint() {
    let (caller, erc1155_token, erc1155_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    assert(erc1155_token.balance_of(alice, 1) == 0, 'Invalid mint');
    erc1155_token.mint(alice, 1, 10);
    assert(erc1155_token.balance_of(alice, 1) == 10, 'Invalid mint');

    erc1155_token.mint(alice, 1, 10);
    assert(erc1155_token.balance_of(alice, 1) == 20, 'Invalid mint');
}

#[test]
#[available_gas(2000000)]
fn test_mint_batch() {
    let (caller, erc1155_token, erc1155_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    assert(erc1155_token.balance_of(alice, 1) == 0, 'Invalid mint');
    assert(erc1155_token.balance_of(alice, 2) == 0, 'Invalid mint');

    erc1155_token.mint_batch(alice, array![1, 2], array![10, 20]);

    assert(erc1155_token.balance_of(alice, 1) == 10, 'Invalid mint');
    assert(erc1155_token.balance_of(alice, 2) == 20, 'Invalid mint');
}

#[test]
#[available_gas(2000000)]
fn test_approval_for_all() {
    let (caller, erc1155_token, erc1155_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc1155_token.set_approval_for_all(alice, true);
    assert(erc1155_token.is_approved_for_all(caller, alice), 'Not approved');

    erc1155_token.set_approval_for_all(alice, false);
    assert(!erc1155_token.is_approved_for_all(caller, alice), 'Approved');
}

#[test]
#[available_gas(2000000)]
fn test_transfer_from() {
    let (caller, erc1155_token, erc1155_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    assert(erc1155_token.balance_of(caller, 1) == 0, 'Invalid mints');
    assert(erc1155_token.balance_of(alice, 1) == 0, 'Invalid mints');

    erc1155_token.mint(caller, 1, 10);
    erc1155_token.safe_transfer_from(caller, alice, 1, 5, ArrayTrait::<felt252>::new().span());

    assert(erc1155_token.balance_of(caller, 1) == 5, 'Invalid mints');
    assert(erc1155_token.balance_of(alice, 1) == 5, 'Invalid mints');
}

#[test]
#[available_gas(4000000)]
fn test_batch_transfer_from() {
    let (caller, erc1155_token, erc1155_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc1155_token.mint_batch(caller, array![1, 2], array![10, 20]);
    assert(erc1155_token.balance_of(caller, 1) == 10, 'Invalid mints');
    assert(erc1155_token.balance_of(caller, 2) == 20, 'Invalid mints');

    erc1155_token
        .safe_batch_transfer_from(
            caller, alice, array![1, 2], array![5, 10], ArrayTrait::<felt252>::new().span()
        );

    assert(erc1155_token.balance_of(caller, 1) == 5, 'Invalid mints');
    assert(erc1155_token.balance_of(caller, 2) == 10, 'Invalid mints');

    assert(erc1155_token.balance_of(alice, 1) == 5, 'Invalid mints');
    assert(erc1155_token.balance_of(alice, 2) == 10, 'Invalid mints');
}
