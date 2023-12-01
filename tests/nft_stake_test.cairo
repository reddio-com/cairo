use starknet::ContractAddress;
use starknet::contract_address_const;

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use openzeppelin::token::erc20::interface::ERC20ABIDispatcher;
use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
use reddio_cairo::ERC20::IERC20MintDispatcher;
use reddio_cairo::ERC20::IERC20MintDispatcherTrait;

use openzeppelin::token::erc721::interface::ERC721ABIDispatcher;
use openzeppelin::token::erc721::interface::ERC721ABIDispatcherTrait;
use reddio_cairo::ERC721::IERC721MintDispatcher;
use reddio_cairo::ERC721::IERC721MintDispatcherTrait;

use reddio_cairo::nft_stake::INFTStakeDispatcher;
use reddio_cairo::nft_stake::INFTStakeDispatcherTrait;

const ERC20_NAME: felt252 = 'Reddio Test Token';
const ERC20_SYMBOL: felt252 = 'RTT';

const ERC721_NAME: felt252 = 'Reddio Test ERC721 Token';
const ERC721_SYMBOL: felt252 = 'Reddio721';

fn deploy_contract() -> (ContractAddress, ContractAddress, ContractAddress, INFTStakeDispatcher) {
    let erc20_class = declare('ERC20');
    let erc20_args = array![ERC20_NAME, ERC20_SYMBOL];
    let erc20_address = erc20_class.deploy(@erc20_args).unwrap();

    let erc721_class = declare('ERC721');
    let erc721_args = array![ERC721_NAME, ERC721_SYMBOL];
    let erc721_address = erc721_class.deploy(@erc721_args).unwrap();

    let stake_class = declare('NFTStake');
    let stake_args = array![];
    let stake_address = stake_class.deploy(@stake_args).unwrap();

    let stake_contract = INFTStakeDispatcher { contract_address: stake_address };

    stake_contract.initialize(erc20_address, erc721_address, 60, 10);

    (erc20_address, erc721_address, stake_address, stake_contract)
}
#[test]
fn test_init() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
}
#[test]
fn test_admin_deposit() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    let approve_amount: u256 = 100000000000000000000000_u256;
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };
    let caller = contract_address_const::<'caller'>();

    start_prank(erc20_address, caller);
    erc20_contract.approve(stake_address, approve_amount);

    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let amount: u256 = 2000_u256;
    erc20_mintable.mint(caller, amount);
    stop_prank(erc20_address);

    start_prank(stake_address, caller);
    stake_contract.deposit_reward_tokens(amount);
}

#[test]
fn test_admin_withdraw() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();

    let approve_amount: u256 = 100000000000000000000000_u256;
    let caller = contract_address_const::<'caller'>();
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };
    start_prank(erc20_address, caller);
    erc20_contract.approve(stake_address, approve_amount);
    stop_prank(erc20_address);

    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let amount: u256 = 2000_u256;
    erc20_mintable.mint(caller, amount);

    start_prank(stake_address, caller);
    stake_contract.deposit_reward_tokens(amount);
    stake_contract.withdraw_reward_tokens(amount);
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_fail_deposit() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();

    let approve_amount: u256 = 100000000000000000000000_u256;
    let caller = contract_address_const::<'caller'>();
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };
    start_prank(erc20_address, caller);
    erc20_contract.approve(stake_address, approve_amount);
    stop_prank(erc20_address);

    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let amount: u256 = 2000_u256;
    erc20_mintable.mint(caller, amount);
    start_prank(stake_address, caller);
    // let deposit amount larger than mint amount to fail
    stake_contract.deposit_reward_tokens(2001_u256);
}
#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn test_fail_admin_withdraw() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    let approve_amount: u256 = 100000000000000000000000_u256;
    let caller = contract_address_const::<'caller'>();
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };
    start_prank(erc20_address, caller);
    erc20_contract.approve(stake_address, approve_amount);
    stop_prank(erc20_address);

    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let amount: u256 = 2000_u256;
    erc20_mintable.mint(caller, amount);

    start_prank(stake_address, caller);
    stake_contract.deposit_reward_tokens(amount);
    // let withdraw amount larger than deposited amount to fail
    stake_contract.withdraw_reward_tokens(2001_u256);
}

#[test]
fn test_set_time_unit() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    stake_contract.set_time_unit(80);
}

#[test]
#[should_panic(expected: ('Time-unit unchanged.',))]
fn test_fail_set_time_unit() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    stake_contract.set_time_unit(60);
}

#[test]
fn test_set_rewards_per_unit_time() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    stake_contract.set_rewards_per_unit_time(20);
}

#[test]
#[should_panic(expected: ('Reward unchanged.',))]
fn test_fail_set_rewards_per_unit_time() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    stake_contract.set_rewards_per_unit_time(10);
}

#[test]
fn test_stake() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let caller = contract_address_const::<'caller'>();
    erc721_mintable.mint(caller, 0);
    start_prank(erc721_address, caller);
    erc721_contract.set_approval_for_all(stake_address, true);
    stop_prank(erc721_address);

    let mut token_ids = ArrayTrait::<u256>::new();
    token_ids.append(0_u256);
    start_prank(stake_address, caller);
    stake_contract.stake(token_ids);

    let owner = erc721_contract.owner_of(0_u256);
    assert(owner == stake_address, 'invalid stake 1');
    assert(erc721_contract.balance_of(caller) == 0, 'invalid stake 2');
    assert(erc721_contract.balance_of(stake_address) == 1, 'invalid stake 3');
}

#[test]
fn test_withdraw() {
    let (erc20_address, erc721_address, stake_address, stake_contract) = deploy_contract();
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let caller = contract_address_const::<'caller'>();

    erc721_mintable.mint(caller, 0);
    start_prank(erc721_address, caller);
    erc721_contract.set_approval_for_all(stake_address, true);
    stop_prank(erc721_address);

    let mut token_ids = ArrayTrait::<u256>::new();
    token_ids.append(0_u256);
    start_prank(stake_address, caller);
    stake_contract.stake(token_ids.clone());

    stake_contract.withdraw(token_ids.clone());
}
// #[test]
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


