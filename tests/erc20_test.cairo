use starknet::ContractAddress;
use starknet::contract_address_const;

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use openzeppelin::token::erc20::interface::ERC20ABIDispatcher;
use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
use reddio_cairo::ERC20::IERC20MintDispatcher;
use reddio_cairo::ERC20::IERC20MintDispatcherTrait;

const NAME: felt252 = 'Reddio Test Token';
const SYMBOL: felt252 = 'RTT';

fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);
    let args = array![NAME, SYMBOL];
    contract.deploy(@args).unwrap()
}

#[test]
fn test_init() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    assert(erc20_token.name() == NAME, 'Wrong name');
    assert(erc20_token.symbol() == SYMBOL, 'Wrong symbol');
}

#[test]
fn test_approve() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    let caller = contract_address_const::<'caller'>();
    let spender: ContractAddress = contract_address_const::<'spender'>();
    let amount: u256 = 2000_u256;

    start_prank(contract_address, caller);
    erc20_token.approve(spender, amount);
    stop_prank(contract_address);

    assert(erc20_token.allowance(caller, spender) == amount, 'Approve should eq 2000');
}

#[test]
fn test_mint() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    let mintable_erc20_token = IERC20MintDispatcher { contract_address: contract_address };

    let owner: ContractAddress = contract_address_const::<'owner'>();
    let amount: u256 = 2000_u256;
    mintable_erc20_token.mint(owner, amount);

    assert(erc20_token.balance_of(owner) == amount, 'Balance should eq 2000');

    mintable_erc20_token.mint(owner, amount);
    assert(erc20_token.balance_of(owner) == amount * 2, 'Balance should eq 2000');
}

#[test]
fn test_transfer() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();
    let amount: u256 = 2000_u256;

    let mintable_erc20_token = IERC20MintDispatcher { contract_address: contract_address };

    mintable_erc20_token.mint(caller, amount);

    assert(erc20_token.balance_of(caller) == amount, 'Balance should eq 2000');
    assert(erc20_token.balance_of(alice) == 0_u256, 'Balance should eq 0');

    start_prank(contract_address, caller);
    erc20_token.transfer(alice, 1000_u256);
    stop_prank(contract_address);

    assert(erc20_token.balance_of(caller) == 1000_u256, 'Balance should eq 1000');
    assert(erc20_token.balance_of(alice) == 1000_u256, 'Balance should eq 1000');
}

#[test]
fn test_transfer_from() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();
    let bob: ContractAddress = contract_address_const::<'bob'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    let amount = 2000_u256;

    let mintable_erc20_token = IERC20MintDispatcher { contract_address: contract_address };
    mintable_erc20_token.mint(alice, amount);

    start_prank(contract_address, alice);
    erc20_token.approve(caller, amount);
    stop_prank(contract_address);

    assert(erc20_token.balance_of(alice) == amount, 'Balance should eq 2000');
    assert(erc20_token.balance_of(bob) == 0_u256, 'Balance should eq 0');

    start_prank(contract_address, caller);
    erc20_token.transfer_from(alice, bob, amount);
    stop_prank(contract_address);

    assert(erc20_token.balance_of(alice) == 0_u256, 'Balance should eq 2000');
    assert(erc20_token.balance_of(bob) == amount, 'Balance should eq 0');
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_fail_transfer() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();

    erc20_token.transfer(alice, 10_u256);
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_fail_transfer_from() {
    let contract_address = deploy_contract('ERC20');
    let erc20_token = ERC20ABIDispatcher { contract_address };

    let alice: ContractAddress = contract_address_const::<'alice'>();
    let caller: ContractAddress = contract_address_const::<'caller'>();

    erc20_token.transfer_from(alice, caller, 10_u256);
}
