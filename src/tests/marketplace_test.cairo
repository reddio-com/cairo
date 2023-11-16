use reddio_cairo::ERC20::ERC20;
use reddio_cairo::ERC20::IERC20Dispatcher;
use reddio_cairo::ERC20::IERC20DispatcherTrait;

use reddio_cairo::ERC721::ERC721;
use reddio_cairo::ERC721::IERC721Dispatcher;
use reddio_cairo::ERC721::IERC721DispatcherTrait;

use reddio_cairo::ERC1155::ERC1155;
use reddio_cairo::ERC1155::IERC1155Dispatcher;
use reddio_cairo::ERC1155::IERC1155DispatcherTrait;

use reddio_cairo::marketplace::Marketplace;
use reddio_cairo::marketplace::IMarketplaceDispatcher;
use reddio_cairo::marketplace::IMarketplaceDispatcherTrait;

use integer::u256_from_felt252;

use debug::PrintTrait;

use array::ArrayTrait;
use traits::Into;
use result::ResultTrait;
use traits::TryInto;
use option::OptionTrait;

use starknet::{contract_address_const, get_contract_address};
use starknet::contract_address::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};
use starknet::syscalls::deploy_syscall;
use starknet::SyscallResultTrait;
use starknet::class_hash::Felt252TryIntoClassHash;

const NAME: felt252 = 'Reddio Test Token';
const SYMBOL: felt252 = 'RTT';
const DECIMALS: u8 = 18_u8;

const NFT_NAME: felt252 = 'Reddio Test ERC721 Token';
const NFT_SYMBOL: felt252 = 'Reddio721';

const URI: felt252 = 'reddio.com';

fn setUp() -> (
    ContractAddress,
    ContractAddress,
    IMarketplaceDispatcher,
    ContractAddress,
    IERC20Dispatcher,
    ContractAddress,
    IERC721Dispatcher,
    ContractAddress,
    IERC1155Dispatcher
) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    // deploy nft marketplace
    let mut calldata = array![];

    let (market_address, _) = deploy_syscall(
        Marketplace::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut market = IMarketplaceDispatcher { contract_address: market_address };

    calldata = array![NAME, SYMBOL, DECIMALS.into()];

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

    calldata = array![URI];

    let (erc1155_address, _) = deploy_syscall(
        ERC1155::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };

    (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    )
}


#[test]
#[available_gas(2000000)]
fn test_init() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();
}

#[test]
#[available_gas(8000000)]
fn test_create_listing_erc721() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();
    set_block_timestamp(1697558532);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc721_token.mint(alice, token_id);
    set_contract_address(alice);
    erc721_token.approve(market_address, token_id);
    market
        .create_listing(
            erc721_address, 0_u256, 1807595297_u256, 10_u256, 1_u256, erc20_address, 0_u256, 0_u256
        );
}

#[test]
#[available_gas(8000000)]
fn test_create_listing_erc1155() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();
    set_block_timestamp(1697558532);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc1155_token.mint(alice, token_id, 3);
    set_contract_address(alice);
    erc1155_token.set_approval_for_all(market_address, true);
    market
        .create_listing(
            erc1155_address,
            token_id,
            1807595297_u256,
            10_u256,
            1_u256,
            erc20_address,
            0_u256,
            1_u256
        );
}

#[test]
#[available_gas(8000000)]
fn test_cancel_direct_listing_erc721() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();
    set_block_timestamp(1697558532);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc721_token.mint(alice, token_id);
    set_contract_address(alice);
    erc721_token.approve(market_address, token_id);
    market
        .create_listing(
            erc721_address, 0_u256, 1807595297_u256, 10_u256, 1_u256, erc20_address, 0_u256, 0_u256
        );

    market.cancel_direct_listing(0_u256);
}

#[test]
#[available_gas(8000000)]
fn test_cancel_direct_listing_erc1155() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();
    set_block_timestamp(1697558532);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc1155_token.mint(alice, token_id, 3);
    set_contract_address(alice);
    erc1155_token.set_approval_for_all(market_address, true);
    market
        .create_listing(
            erc1155_address,
            token_id,
            1807595297_u256,
            10_u256,
            1_u256,
            erc20_address,
            0_u256,
            1_u256
        );

    market.cancel_direct_listing(0_u256);
}

#[test]
#[available_gas(8000000)]
fn test_buy_erc721() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();

    let startTime = 1697558532;
    set_block_timestamp(startTime);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc721_token.mint(alice, token_id);
    set_contract_address(alice);
    erc721_token.approve(market_address, token_id);
    market
        .create_listing(
            erc721_address,
            token_id,
            startTime.into(),
            86400_u256,
            1_u256,
            erc20_address,
            100_u256,
            0_u256
        );

    let bob: ContractAddress = contract_address_const::<3>();
    erc20_token.mint(bob, u256_from_felt252(2000));

    set_contract_address(bob);
    set_block_timestamp(startTime + 1);
    erc20_token.approve(market_address, 100);
    market.buy(0, bob, 1, erc20_address, 100);

    assert(erc721_token.owner_of(0) == bob, 'nft token transfer failed');
    assert(erc20_token.balance_of(alice) == 100, 'currency transfer failed');
}

#[test]
#[available_gas(8000000)]
fn test_buy_erc1155() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();
    let startTime = 1697558532;
    set_block_timestamp(startTime);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc1155_token.mint(alice, token_id, 3);
    set_contract_address(alice);
    erc1155_token.set_approval_for_all(market_address, true);
    market
        .create_listing(
            erc1155_address,
            token_id,
            startTime.into(),
            86400_u256,
            1_u256,
            erc20_address,
            100_u256,
            1_u256
        );

    let bob: ContractAddress = contract_address_const::<3>();
    erc20_token.mint(bob, u256_from_felt252(2000));

    set_contract_address(bob);
    set_block_timestamp(startTime + 1);
    erc20_token.approve(market_address, 2000);
    market.buy(0, bob, 1, erc20_address, 100);

    assert(erc1155_token.balance_of(bob, token_id) == 1, 'nft token transfer failed 1');
    assert(erc1155_token.balance_of(alice, token_id) == 2, 'nft token transfer failed 2');
    assert(erc20_token.balance_of(alice) == 100, 'currency transfer failed');
}

#[test]
#[available_gas(8000000)]
fn test_offer_erc721() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();

    let startTime = 1697558532;
    set_block_timestamp(startTime);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc721_token.mint(alice, token_id);
    set_contract_address(alice);
    erc721_token.approve(market_address, token_id);
    market
        .create_listing(
            erc721_address,
            token_id,
            startTime.into(),
            86400_u256,
            1_u256,
            erc20_address,
            100_u256,
            0_u256
        );

    let bob: ContractAddress = contract_address_const::<3>();
    erc20_token.mint(bob, u256_from_felt252(2000));

    set_contract_address(bob);
    set_block_timestamp(startTime + 1);
    erc20_token.approve(market_address, 100);

    market.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    market.offer(0, 1, erc20_address, 0, (startTime + 3600).into());
}

#[test]
#[available_gas(10000000)]
fn test_offer_deal_erc721() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();

    let startTime = 1697558532;
    set_block_timestamp(startTime);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc721_token.mint(alice, token_id);
    set_contract_address(alice);
    erc721_token.approve(market_address, token_id);
    market
        .create_listing(
            erc721_address,
            token_id,
            startTime.into(),
            86400_u256,
            1_u256,
            erc20_address,
            100_u256,
            0_u256
        );

    let bob: ContractAddress = contract_address_const::<3>();
    erc20_token.mint(bob, u256_from_felt252(2000));

    set_contract_address(bob);
    set_block_timestamp(startTime + 1);
    erc20_token.approve(market_address, 100);

    market.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    set_contract_address(alice);
    market.accept_offer(0, bob, erc20_address, 90);

    assert(erc721_token.owner_of(0) == bob, 'nft token transfer failed');
    assert(erc20_token.balance_of(alice) == 90, 'currency transfer failed');
}

#[test]
#[available_gas(8000000)]
fn test_offer_erc1155() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();

    let startTime = 1697558532;
    set_block_timestamp(startTime);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc1155_token.mint(alice, token_id, 3);
    set_contract_address(alice);
    erc1155_token.set_approval_for_all(market_address, true);
    market
        .create_listing(
            erc1155_address,
            token_id,
            startTime.into(),
            86400_u256,
            1_u256,
            erc20_address,
            100_u256,
            1_u256
        );

    let bob: ContractAddress = contract_address_const::<3>();
    erc20_token.mint(bob, u256_from_felt252(2000));

    set_contract_address(bob);
    set_block_timestamp(startTime + 1);
    erc20_token.approve(market_address, 2000);

    market.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    market.offer(0, 0, erc20_address, 0, (startTime + 3600).into());
}

#[test]
#[available_gas(10000000)]
fn test_offer_deal_erc1155() {
    let (
        caller,
        market_address,
        market,
        erc20_address,
        erc20_token,
        erc721_address,
        erc721_token,
        erc1155_address,
        erc1155_token
    ) =
        setUp();

    let startTime = 1697558532;
    set_block_timestamp(startTime);
    let alice: ContractAddress = contract_address_const::<2>();
    let token_id = 0_u256;
    erc1155_token.mint(alice, token_id, 3);
    set_contract_address(alice);
    erc1155_token.set_approval_for_all(market_address, true);
    market
        .create_listing(
            erc1155_address,
            token_id,
            startTime.into(),
            86400_u256,
            1_u256,
            erc20_address,
            100_u256,
            1_u256
        );

    let bob: ContractAddress = contract_address_const::<3>();
    erc20_token.mint(bob, u256_from_felt252(2000));

    set_contract_address(bob);
    set_block_timestamp(startTime + 1);
    erc20_token.approve(market_address, 2000);

    market.offer(0, 1, erc20_address, 90, (startTime + 3600).into());

    set_contract_address(alice);
    market.accept_offer(0, bob, erc20_address, 90);

    assert(erc1155_token.balance_of(alice, token_id) == 2, 'nft token transfer failed 1');
    assert(erc1155_token.balance_of(bob, token_id) == 1, 'nft token transfer failed 2');
    assert(erc20_token.balance_of(alice) == 90, 'currency transfer failed');
}
