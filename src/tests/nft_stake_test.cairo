use reddio_cairo::ERC20::ERC20;
use reddio_cairo::ERC20::IERC20Dispatcher;
use reddio_cairo::ERC20::IERC20DispatcherTrait;

use reddio_cairo::ERC721::ERC721;
use reddio_cairo::ERC721::IERC721Dispatcher;
use reddio_cairo::ERC721::IERC721DispatcherTrait;

use reddio_cairo::nft_stake::NFTStake;
use reddio_cairo::nft_stake::INFTStakeDispatcher;
use reddio_cairo::nft_stake::INFTStakeDispatcherTrait;

use integer::u256_from_felt252;

use debug::PrintTrait;

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

const NFT_NAME: felt252 = 'Reddio Test ERC721 Token';
const NFT_SYMBOL: felt252 = 'Reddio721';

fn setUp() -> (
    ContractAddress, ContractAddress, INFTStakeDispatcher, IERC20Dispatcher, IERC721Dispatcher
) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    // deploy erc20 token
    let mut calldata = array![NAME, SYMBOL, DECIMALS.into()];

    let (erc20_address, _) = deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc20_token = IERC20Dispatcher { contract_address: erc20_address };

    // deploy erc721 nft token
    calldata = array![NFT_NAME, NFT_SYMBOL];

    let (erc721_address, _) = deploy_syscall(
        ERC721::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc721_token = IERC721Dispatcher { contract_address: erc721_address };

    // deploy nft stake contract
    calldata = array![];

    let (nft_stake_address, _) = deploy_syscall(
        NFTStake::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut nft_stake_contract = INFTStakeDispatcher { contract_address: nft_stake_address };

    nft_stake_contract.initialize(erc20_address.into(), erc721_address.into(), 60, 10);

    (caller, nft_stake_address, nft_stake_contract, erc20_token, erc721_token)
}

#[test]
#[available_gas(2000000)]
fn test_init() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
}

#[test]
#[available_gas(8000000)]
fn test_admin_deposit() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    let approve_amount: u256 = u256_from_felt252(100000000000000000000000);
    erc20_contract.approve(nft_stake_address, approve_amount);

    let amount: u256 = u256_from_felt252(2000);
    erc20_contract.mint(caller, amount);

    nft_stake_contract.deposit_reward_tokens(amount);
}

#[test]
#[available_gas(8000000)]
fn test_admin_withdraw() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    let approve_amount: u256 = u256_from_felt252(100000000000000000000000);
    erc20_contract.approve(nft_stake_address, approve_amount);

    let amount: u256 = u256_from_felt252(2000);
    erc20_contract.mint(caller, amount);

    nft_stake_contract.deposit_reward_tokens(amount);
    nft_stake_contract.withdraw_reward_tokens(amount);
}

#[test]
#[available_gas(8000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
fn test_fail_deposit() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    let approve_amount: u256 = u256_from_felt252(100000000000000000000000);
    erc20_contract.approve(nft_stake_address, approve_amount);

    let amount: u256 = u256_from_felt252(2000);
    erc20_contract.mint(caller, amount);
    // let deposit amount larger than mint amount to fail
    nft_stake_contract.deposit_reward_tokens(u256_from_felt252(2001));
}

#[test]
#[available_gas(8000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
fn test_fail_admin_withdraw() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    let approve_amount: u256 = u256_from_felt252(100000000000000000000000);
    erc20_contract.approve(nft_stake_address, approve_amount);

    let amount: u256 = u256_from_felt252(2000);
    erc20_contract.mint(caller, amount);

    nft_stake_contract.deposit_reward_tokens(amount);
    // let withdraw amount larger than deposited amount to fail
    nft_stake_contract.withdraw_reward_tokens(u256_from_felt252(2001));
}

#[test]
#[available_gas(8000000)]
fn test_set_time_unit() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    nft_stake_contract.set_time_unit(80);
}

#[test]
#[available_gas(8000000)]
#[should_panic(expected: ('Time-unit unchanged.', 'ENTRYPOINT_FAILED',))]
fn test_fail_set_time_unit() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    nft_stake_contract.set_time_unit(60);
}

#[test]
#[available_gas(8000000)]
fn test_set_rewards_per_unit_time() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    nft_stake_contract.set_rewards_per_unit_time(20);
}

#[test]
#[available_gas(8000000)]
#[should_panic(expected: ('Reward unchanged.', 'ENTRYPOINT_FAILED',))]
fn test_fail_set_rewards_per_unit_time() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    nft_stake_contract.set_rewards_per_unit_time(10);
}

#[test]
#[available_gas(8000000)]
fn test_stake() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    erc721_contract.mint(caller, 0);
    erc721_contract.set_approval_for_all(nft_stake_address, true);

    let mut token_ids = ArrayTrait::<u256>::new();
    token_ids.append(0_u256);
    nft_stake_contract.stake(token_ids);

    let owner = erc721_contract.owner_of(0_u256);
    assert(owner == nft_stake_address, 'invalid stake 1');
    assert(erc721_contract.balance_of(caller) == 0, 'invalid stake 2');
    assert(erc721_contract.balance_of(nft_stake_address) == 1, 'invalid stake 3');
}

#[test]
#[available_gas(10000000)]
fn test_withdraw() {
    let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
    erc721_contract.mint(caller, 0);
    erc721_contract.set_approval_for_all(nft_stake_address, true);

    let mut token_ids = ArrayTrait::<u256>::new();
    token_ids.append(0_u256);
    nft_stake_contract.stake(token_ids.clone());

    nft_stake_contract.withdraw(token_ids.clone());
}
// #[test]
// #[available_gas(10000000)]
// fn test_claim_rewards() {
//     let (caller, nft_stake_address, nft_stake_contract, erc20_contract, erc721_contract) = setUp();
//     erc721_contract.mint(caller, 0);
//     erc721_contract.set_approval_for_all(nft_stake_address, true);

//     let mut token_ids = ArrayTrait::<u256>::new();
//     token_ids.append(0_u256);
//     nft_stake_contract.stake(token_ids.clone());
//     // todo mock time?
//     nft_stake_contract.claim_rewards();
// }


