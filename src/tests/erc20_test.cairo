use reddio_cairo::ERC20::ERC20;
use reddio_cairo::ERC20::IERC20Dispatcher;
use reddio_cairo::ERC20::IERC20DispatcherTrait;

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

const NAME: felt252 = 'Reddio Test Token';
const SYMBOL: felt252 = 'RTT';
const DECIMALS: u8 = 18_u8;

fn setUp() -> (ContractAddress, IERC20Dispatcher, ContractAddress) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    let mut calldata = array![NAME, SYMBOL, DECIMALS.into()];

    let (erc20_address, _) = deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc20_token = IERC20Dispatcher { contract_address: erc20_address };

    (caller, erc20_token, erc20_address)
}

#[test]
#[available_gas(2000000)]
fn test_init() {
    let (caller, erc20_token, erc20_address) = setUp();

    assert(erc20_token.get_name() == NAME, 'Wrong name');
    assert(erc20_token.get_symbol() == SYMBOL, 'Wrong symbol');
    assert(erc20_token.get_decimals() == DECIMALS, 'Wrong decimals');
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let (caller, erc20_token, erc20_address) = setUp();

    let spender: ContractAddress = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    erc20_token.approve(spender, amount);

    assert(erc20_token.allowance(caller, spender) == amount, 'Approve should eq 2000');
}

#[test]
#[available_gas(2000000)]
fn test_mint() {
    let (caller, erc20_token, erc20_address) = setUp();

    let owner: ContractAddress = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);
    erc20_token.mint(owner, amount);

    assert(erc20_token.balance_of(owner) == amount, 'Balance should eq 2000');

    erc20_token.mint(owner, amount);
    assert(erc20_token.balance_of(owner) == amount * 2, 'Balance should eq 2000');
}

#[test]
#[available_gas(2000000)]
fn test_transfer() {
    let (caller, erc20_token, erc20_address) = setUp();

    let alice: ContractAddress = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    erc20_token.mint(caller, amount);

    assert(erc20_token.balance_of(caller) == amount, 'Balance should eq 2000');
    assert(erc20_token.balance_of(alice) == 0_u256, 'Balance should eq 0');

    erc20_token.transfer(alice, 1000_u256);

    assert(erc20_token.balance_of(caller) == 1000_u256, 'Balance should eq 1000');
    assert(erc20_token.balance_of(alice) == 1000_u256, 'Balance should eq 1000');
}

#[test]
#[available_gas(2000000)]
fn test_transfer_from() {
    let (caller, erc20_token, erc20_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();
    let bob: ContractAddress = contract_address_const::<3>();

    let amount = 2000_u256;

    set_contract_address(alice);
    erc20_token.mint(alice, amount);
    erc20_token.approve(caller, amount);

    assert(erc20_token.balance_of(alice) == amount, 'Balance should eq 2000');
    assert(erc20_token.balance_of(bob) == 0_u256, 'Balance should eq 0');

    set_contract_address(caller);
    erc20_token.transfer_from(alice, bob, amount);

    assert(erc20_token.balance_of(alice) == 0_u256, 'Balance should eq 2000');
    assert(erc20_token.balance_of(bob) == amount, 'Balance should eq 0');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED',))]
fn test_fail_transfer() {
    let (caller, erc20_token, erc20_address) = setUp();

    let alice: ContractAddress = contract_address_const::<2>();

    erc20_token.transfer(alice, 10_u256);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED',))]
fn test_fail_transfer_from() {
    let (caller, erc20_token, erc20_address) = setUp();
    let alice: ContractAddress = contract_address_const::<2>();

    erc20_token.transfer_from(alice, caller, 10_u256);
}
