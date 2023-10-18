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

use starknet::contract_address_const;
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

fn setUp() -> (ContractAddress, ContractAddress, IMarketplaceDispatcher) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    // deploy nft marketplace
    let mut calldata = array![];

    let (market_address, _) = deploy_syscall(
        Marketplace::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut market = IMarketplaceDispatcher { contract_address: market_address };

    // // deploy erc721 nft token
    // calldata = array![NFT_NAME, NFT_SYMBOL];

    // let (erc721_address, _) = deploy_syscall(
    //     ERC721::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    // )
    //     .unwrap();

    // let mut erc721_token = IERC721Dispatcher { contract_address: erc721_address };

    // // deploy nft stake contract
    // calldata = array![];

    // let (nft_stake_address, _) = deploy_syscall(
    //     NFTStake::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    // )
    //     .unwrap();

    // let mut nft_stake_contract = INFTStakeDispatcher { contract_address: nft_stake_address };

    // nft_stake_contract.initialize(erc20_address.into(), erc721_address.into(), 60, 10);

    (caller, market_address, market)
}


#[test]
#[available_gas(2000000)]
fn test_init() {
    let (caller, market_address, market) = setUp();
}

#[test]
#[available_gas(2000000)]
fn test_create_listing() {
    let (caller, market_address, market) = setUp();
    set_block_timestamp(1697558532);
    market
        .create_listing(
            contract_address_const::<1>(), 1, 1807595297, 10, 1, contract_address_const::<1>(), 0, 1
        );
}
