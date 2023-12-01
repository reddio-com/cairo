use starknet::ContractAddress;
use starknet::contract_address_const;

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, start_warp};

use openzeppelin::token::erc20::interface::ERC20ABIDispatcher;
use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
use reddio_cairo::ERC20::IERC20MintDispatcher;
use reddio_cairo::ERC20::IERC20MintDispatcherTrait;

use openzeppelin::token::erc721::interface::ERC721ABIDispatcher;
use openzeppelin::token::erc721::interface::ERC721ABIDispatcherTrait;
use reddio_cairo::ERC721::IERC721MintDispatcher;
use reddio_cairo::ERC721::IERC721MintDispatcherTrait;
use reddio_cairo::ERC1155::IERC1155Dispatcher;
use reddio_cairo::ERC1155::IERC1155DispatcherTrait;

use reddio_cairo::marketplace::IMarketplaceDispatcher;
use reddio_cairo::marketplace::IMarketplaceDispatcherTrait;

const ERC20_NAME: felt252 = 'Reddio Test Token';
const ERC20_SYMBOL: felt252 = 'RTT';

const ERC721_NAME: felt252 = 'Reddio Test ERC721 Token';
const ERC721_SYMBOL: felt252 = 'Reddio721';

const ERC1155_URI: felt252 = 'reddio.com';

fn deploy_contract() -> (
    ContractAddress, ContractAddress, ContractAddress, ContractAddress, IMarketplaceDispatcher
) {
    let erc20_class = declare('ERC20');
    let erc20_args = array![ERC20_NAME, ERC20_SYMBOL];
    let erc20_address = erc20_class.deploy(@erc20_args).unwrap();

    let erc721_class = declare('ERC721');
    let erc721_args = array![ERC721_NAME, ERC721_SYMBOL];
    let erc721_address = erc721_class.deploy(@erc721_args).unwrap();

    let erc1155_class = declare('ERC1155');
    let erc1155_args = array![ERC1155_URI];
    let erc1155_address = erc1155_class.deploy(@erc1155_args).unwrap();

    let market_class = declare('Marketplace');
    let market_args = array![];
    let market_address = market_class.deploy(@market_args).unwrap();

    let market_contract = IMarketplaceDispatcher { contract_address: market_address };

    (erc20_address, erc721_address, erc1155_address, market_address, market_contract)
}

#[test]
fn test_init() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();
}

#[test]
fn test_create_listing_erc721() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();
    start_warp(market_address, 1697558532);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };
    erc721_mintable.mint(alice, token_id);
    start_prank(erc721_address, alice);
    erc721_contract.approve(market_address, token_id);
    stop_prank(erc721_address);
    start_prank(market_address, alice);
    market_contract
        .create_listing(
            erc721_address, 0_u256, 1807595297_u256, 10_u256, 1_u256, erc20_address, 0_u256, 0_u256
        );
}

#[test]
fn test_create_listing_erc1155() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();
    start_warp(market_address, 1697558532);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };
    erc1155_token.mint(alice, token_id, 3);
    start_prank(erc1155_address, alice);
    erc1155_token.set_approval_for_all(market_address, true);

    start_prank(market_address, alice);
    market_contract
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
fn test_cancel_direct_listing_erc721() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();
    start_warp(market_address, 1697558532);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };

    erc721_mintable.mint(alice, token_id);
    start_prank(erc721_address, alice);
    erc721_contract.approve(market_address, token_id);

    start_prank(market_address, alice);
    market_contract
        .create_listing(
            erc721_address, 0_u256, 1807595297_u256, 10_u256, 1_u256, erc20_address, 0_u256, 0_u256
        );

    market_contract.cancel_direct_listing(0_u256);
}

#[test]
fn test_cancel_direct_listing_erc1155() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();
    start_warp(market_address, 1697558532);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };
    erc1155_token.mint(alice, token_id, 3);
    start_prank(erc1155_address, alice);
    erc1155_token.set_approval_for_all(market_address, true);
    start_prank(market_address, alice);
    market_contract
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

    market_contract.cancel_direct_listing(0_u256);
}

#[test]
fn test_buy_erc721() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();

    let startTime = 1697558532;
    start_warp(market_address, startTime);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };

    erc721_mintable.mint(alice, token_id);
    start_prank(erc721_address, alice);
    erc721_contract.approve(market_address, token_id);
    start_prank(market_address, alice);
    market_contract
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

    stop_prank(market_address);

    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };

    let bob: ContractAddress = contract_address_const::<'bob'>();
    erc20_mintable.mint(bob, 2000_u256);

    start_warp(market_address, startTime + 1);
    start_prank(erc20_address, bob);
    erc20_contract.approve(market_address, 100);
    stop_prank(erc20_address);
    start_prank(market_address, bob);
    market_contract.buy(0, bob, 1, erc20_address, 100);

    assert(erc721_contract.owner_of(0) == bob, 'nft token transfer failed');
    assert(erc20_contract.balance_of(alice) == 100, 'currency transfer failed');
}

#[test]
fn test_buy_erc1155() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();
    let startTime = 1697558532;
    start_warp(market_address, startTime);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };
    erc1155_token.mint(alice, token_id, 3);
    start_prank(erc1155_address, alice);
    erc1155_token.set_approval_for_all(market_address, true);
    stop_prank(erc1155_address);

    start_prank(market_address, alice);
    market_contract
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

    let bob: ContractAddress = contract_address_const::<'bob'>();
    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };

    erc20_mintable.mint(bob, 2000_u256);
    start_prank(erc20_address, bob);
    start_warp(market_address, startTime + 1);

    erc20_contract.approve(market_address, 2000);
    stop_prank(erc20_address);
    start_prank(market_address, bob);
    market_contract.buy(0, bob, 1, erc20_address, 100);

    assert(erc1155_token.balance_of(bob, token_id) == 1, 'nft token transfer failed 1');
    assert(erc1155_token.balance_of(alice, token_id) == 2, 'nft token transfer failed 2');
    assert(erc20_contract.balance_of(alice) == 100, 'currency transfer failed');
}

#[test]
fn test_offer_erc721() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();

    let startTime = 1697558532;
    start_warp(market_address, startTime);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };

    erc721_mintable.mint(alice, token_id);


    start_prank(erc721_address, alice);
    erc721_contract.approve(market_address, token_id);
    stop_prank(erc721_address);
    start_prank(market_address, alice);
    market_contract
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
    stop_prank(market_address);

    let bob: ContractAddress = contract_address_const::<'bob'>();
    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };

    erc20_mintable.mint(bob, 2000_u256);

    start_warp(market_address, startTime + 1);
    start_prank(erc20_address, bob);
    erc20_contract.approve(market_address, 100);
    stop_prank(erc20_address);

    start_prank(market_address, bob);
    market_contract.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    market_contract.offer(0, 1, erc20_address, 0, (startTime + 3600).into());
}

#[test]
fn test_offer_deal_erc721() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();

    let startTime = 1697558532;
    start_warp(market_address, startTime);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc721_mintable = IERC721MintDispatcher { contract_address: erc721_address };
    let erc721_contract = ERC721ABIDispatcher { contract_address: erc721_address };
    erc721_mintable.mint(alice, token_id);
    start_prank(erc721_address, alice);
    erc721_contract.approve(market_address, token_id);
    stop_prank(erc721_address);
    start_prank(market_address, alice);
    market_contract
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
    stop_prank(market_address);

    let bob: ContractAddress = contract_address_const::<'bob'>();
    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };

    erc20_mintable.mint(bob, 2000_u256);

    start_prank(erc20_address, bob);
    erc20_contract.approve(market_address, 100);
    stop_prank(erc20_address);
    start_warp(market_address, startTime + 1);

    start_prank(market_address, bob);
    market_contract.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    stop_prank(market_address);
    start_prank(market_address, alice);
    market_contract.accept_offer(0, bob, erc20_address, 90);
    stop_prank(market_address);

    assert(erc721_contract.owner_of(0) == bob, 'nft token transfer failed');
    assert(erc20_contract.balance_of(alice) == 90, 'currency transfer failed');
}

#[test]
fn test_offer_erc1155() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();

    let startTime = 1697558532;
    start_warp(market_address, startTime);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };
    erc1155_token.mint(alice, token_id, 3);

    start_prank(erc1155_address, alice);
    erc1155_token.set_approval_for_all(market_address, true);
    stop_prank(erc1155_address);
    start_prank(market_address, alice);
    market_contract
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

    let bob: ContractAddress = contract_address_const::<'bob'>();
    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };

    erc20_mintable.mint(bob, 2000_u256);

    start_prank(erc20_address, bob);
    erc20_contract.approve(market_address, 2000);
    stop_prank(erc20_address);
    start_warp(market_address, startTime + 1);
    start_prank(market_address, bob);
    market_contract.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    market_contract.offer(0, 0, erc20_address, 0, (startTime + 3600).into());
}

#[test]
fn test_offer_deal_erc1155() {
    let (erc20_address, erc721_address, erc1155_address, market_address, market_contract) =
        deploy_contract();

    let startTime = 1697558532;
    start_warp(market_address, startTime);
    let alice: ContractAddress = contract_address_const::<'alice'>();
    let token_id = 0_u256;
    let erc1155_token = IERC1155Dispatcher { contract_address: erc1155_address };
    erc1155_token.mint(alice, token_id, 3);
    start_prank(erc1155_address, alice);
    erc1155_token.set_approval_for_all(market_address, true);
    stop_prank(erc1155_address);
    start_prank(market_address, alice);
    market_contract
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
    stop_prank(market_address);

    let bob: ContractAddress = contract_address_const::<'bob'>();
    let erc20_mintable = IERC20MintDispatcher { contract_address: erc20_address };
    let erc20_contract = ERC20ABIDispatcher { contract_address: erc20_address };

    erc20_mintable.mint(bob, 2000_u256);

    start_prank(erc20_address, bob);
    erc20_contract.approve(market_address, 2000);
    stop_prank(erc20_address);

    start_warp(market_address, startTime + 1);

    start_prank(market_address, bob);
    market_contract.offer(0, 1, erc20_address, 90, (startTime + 3600).into());
    stop_prank(market_address);

    start_prank(market_address, alice);
    market_contract.accept_offer(0, bob, erc20_address, 90);
    stop_prank(market_address);

    assert(erc1155_token.balance_of(alice, token_id) == 2, 'nft token transfer failed 1');
    assert(erc1155_token.balance_of(bob, token_id) == 1, 'nft token transfer failed 2');
    assert(erc20_contract.balance_of(alice) == 90, 'currency transfer failed');
}


