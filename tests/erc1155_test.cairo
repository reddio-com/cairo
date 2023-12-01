use starknet::ContractAddress;
use starknet::contract_address_const;

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use reddio_cairo::ERC1155::IERC1155Dispatcher;
use reddio_cairo::ERC1155::IERC1155DispatcherTrait;

const NAME: felt252 = 'Reddio Test ERC1155 Token';
const SYMBOL: felt252 = 'Reddio1155';
const URI: felt252 = 'reddio.com';

fn deploy_contract(name: felt252) -> (ContractAddress, IERC1155Dispatcher) {
    let contract = declare(name);
    let args = array![URI];
    let erc1155_address = contract.deploy(@args).unwrap();
    let erc1155_contract = IERC1155Dispatcher { contract_address: erc1155_address };
    (erc1155_address, erc1155_contract)
}

#[test]
fn test_mint() {
    let (erc1155_address, erc1155_contract) = deploy_contract('ERC1155');
    let alice: ContractAddress = contract_address_const::<'alice'>();

    assert(erc1155_contract.balance_of(alice, 1) == 0, 'Invalid mint');
    erc1155_contract.mint(alice, 1, 10);
    assert(erc1155_contract.balance_of(alice, 1) == 10, 'Invalid mint');

    erc1155_contract.mint(alice, 1, 10);
    assert(erc1155_contract.balance_of(alice, 1) == 20, 'Invalid mint');
}
#[test]
fn test_mint_batch() {
    let (erc1155_address, erc1155_contract) = deploy_contract('ERC1155');
    let alice: ContractAddress = contract_address_const::<'alice'>();

    assert(erc1155_contract.balance_of(alice, 1) == 0, 'Invalid mint');
    assert(erc1155_contract.balance_of(alice, 2) == 0, 'Invalid mint');

    erc1155_contract.mint_batch(alice, array![1, 2], array![10, 20]);

    assert(erc1155_contract.balance_of(alice, 1) == 10, 'Invalid mint');
    assert(erc1155_contract.balance_of(alice, 2) == 20, 'Invalid mint');
}

#[test]
fn test_approval_for_all() {
    let (erc1155_address, erc1155_contract) = deploy_contract('ERC1155');
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    start_prank(erc1155_address, caller);
    erc1155_contract.set_approval_for_all(alice, true);
    assert(erc1155_contract.is_approved_for_all(caller, alice), 'Not approved');

    erc1155_contract.set_approval_for_all(alice, false);
    assert(!erc1155_contract.is_approved_for_all(caller, alice), 'Approved');
}

#[test]
fn test_transfer_from() {
    let (erc1155_address, erc1155_contract) = deploy_contract('ERC1155');
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    start_prank(erc1155_address, caller);

    assert(erc1155_contract.balance_of(caller, 1) == 0, 'Invalid mints');
    assert(erc1155_contract.balance_of(alice, 1) == 0, 'Invalid mints');

    erc1155_contract.mint(caller, 1, 10);
    erc1155_contract.safe_transfer_from(caller, alice, 1, 5, ArrayTrait::<felt252>::new().span());

    assert(erc1155_contract.balance_of(caller, 1) == 5, 'Invalid mints');
    assert(erc1155_contract.balance_of(alice, 1) == 5, 'Invalid mints');
}

#[test]
fn test_batch_transfer_from() {
    let (erc1155_address, erc1155_contract) = deploy_contract('ERC1155');
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    erc1155_contract.mint_batch(caller, array![1, 2], array![10, 20]);
    assert(erc1155_contract.balance_of(caller, 1) == 10, 'Invalid mints');
    assert(erc1155_contract.balance_of(caller, 2) == 20, 'Invalid mints');

    start_prank(erc1155_address, caller);
    erc1155_contract
        .safe_batch_transfer_from(
            caller, alice, array![1, 2], array![5, 10], ArrayTrait::<felt252>::new().span()
        );

    assert(erc1155_contract.balance_of(caller, 1) == 5, 'Invalid mints');
    assert(erc1155_contract.balance_of(caller, 2) == 10, 'Invalid mints');

    assert(erc1155_contract.balance_of(alice, 1) == 5, 'Invalid mints');
    assert(erc1155_contract.balance_of(alice, 2) == 10, 'Invalid mints');
}


