use starknet::ContractAddress;
use starknet::contract_address_const;

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use openzeppelin::token::erc721::interface::ERC721ABIDispatcher;
use openzeppelin::token::erc721::interface::ERC721ABIDispatcherTrait;
use reddio_cairo::ERC721::IERC721MintDispatcher;
use reddio_cairo::ERC721::IERC721MintDispatcherTrait;

fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);
    let args = array![NAME, SYMBOL];
    contract.deploy(@args).unwrap()
}

const NAME: felt252 = 'Reddio Test ERC721 Token';
const SYMBOL: felt252 = 'Reddio721';

#[test]
fn test_init() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };

    assert(erc721_token.name() == NAME, 'Invalid name');
    assert(erc721_token.symbol() == SYMBOL, 'Invalid symbol');
}

#[test]
fn test_mint() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();

    erc721_mintable.mint(alice, 0_u256);
    assert(erc721_token.balance_of(alice) == 1_u256, 'invalid mint');

    erc721_mintable.mint(alice, 1_u256);
    assert(erc721_token.balance_of(alice) == 2_u256, 'invalid mint');
}
#[test]
#[should_panic(expected: ('ERC721: token already minted',))]
fn test_fail_mint_duplicate() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();

    erc721_mintable.mint(alice, 0_u256);
    erc721_mintable.mint(alice, 0_u256);
}

#[test]
fn test_approve() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    erc721_mintable.mint(caller, 1_u256);
    start_prank(contract_address, caller);
    erc721_token.approve(alice, 1_u256);
    stop_prank(contract_address);

    assert(erc721_token.get_approved(1_u256) == alice, 'Not approved');
}

#[test]
fn test_approval_for_all() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    assert(!erc721_token.is_approved_for_all(caller, alice), 'Approved');
    start_prank(contract_address, caller);
    erc721_token.set_approval_for_all(alice, true);
    assert(erc721_token.is_approved_for_all(caller, alice), 'Not approved');

    erc721_token.set_approval_for_all(alice, false);
    stop_prank(contract_address);
    assert(!erc721_token.is_approved_for_all(caller, alice), 'Approved');
}

#[test]
fn test_owner() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<2>();

    erc721_mintable.mint(alice, 1_u256);
    assert(erc721_token.owner_of(1_u256) == alice, 'Invalid owner');
}

#[test]
fn test_transfer_from() {
    let contract_address = deploy_contract('ERC721');
    let erc721_token = ERC721ABIDispatcher { contract_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let token_id = 1_u256;

    start_prank(contract_address, caller);
    erc721_mintable.mint(caller, token_id);
    erc721_token.transfer_from(caller, alice, token_id);

    start_prank(contract_address, alice);
    erc721_token.approve(caller, token_id);

    start_prank(contract_address, caller);
    erc721_token.transfer_from(alice, caller, token_id);
}

