use starknet::ContractAddress;

#[starknet::interface]
trait IMarketplace<TContractState> {
    fn create_listing(
        ref self: TContractState,
        assetContract: ContractAddress,
        tokenId: u256,
        startTime: u256,
        secondsUntilEndTime: u256,
        quantityToList: u256,
        currencyToAccept: ContractAddress,
        buyoutPricePerToken: u256,
        tokenTypeOfListing: u256,
    );
    fn cancel_direct_listing(ref self: TContractState, _listingId: u256);
    fn buy(
        ref self: TContractState,
        _listingId: u256,
        _buyFor: ContractAddress,
        _quantityToBuy: u256,
        _currency: ContractAddress,
        _totalPrice: u256,
    );
    fn accept_offer(
        ref self: TContractState,
        _listingId: u256,
        _offeror: ContractAddress,
        _currency: ContractAddress,
        _pricePerToken: u256
    );
    fn offer(
        ref self: TContractState,
        _listingId: u256,
        _quantityWanted: u256,
        _currency: ContractAddress,
        _pricePerToken: u256,
        _expirationTimestamp: u256
    );
    fn update_listing(
        ref self: TContractState,
        _listingId: u256,
        _quantityToList: u256,
        _reservePricePerToken: u256,
        _buyoutPricePerToken: u256,
        _currencyToAccept: ContractAddress,
        _startTime: u256,
        _secondsUntilEndTime: u256,
    );
    fn get_total_listings(self: @TContractState) -> u256;
}

#[starknet::interface]
trait IERC20<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
}

#[starknet::interface]
trait IERC721<TContractState> {
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
}

#[starknet::interface]
trait IERC1155<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress, id: u256) -> u256;
    fn is_approved_for_all(
        self: @TContractState, account: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        amount: u256,
        data: Span<felt252>
    );
}

#[starknet::contract]
mod Marketplace {
    use reddio_cairo::marketplace::IMarketplace;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::info::get_block_timestamp;
    use starknet::contract_address_const;
    use starknet::syscalls::replace_class_syscall;
    use starknet::class_hash::ClassHash;
    use core::traits::Into;

    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    use super::IERC721Dispatcher;
    use super::IERC721DispatcherTrait;
    use super::IERC1155Dispatcher;
    use super::IERC1155DispatcherTrait;

    const ERC721: u256 = 0;
    const ERC1155: u256 = 1;


    #[storage]
    struct Storage {
        operator: ContractAddress,
        total_listings: u256,
        listings: LegacyMap::<u256, Listing>,
        offers: LegacyMap::<(u256, ContractAddress), Offer>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ListingAdded: ListingAdded,
        ListingUpdated: ListingUpdated,
        ListingRemoved: ListingRemoved,
        NewOffer: NewOffer,
        NewSale: NewSale,
    }

    #[derive(Drop, starknet::Event)]
    struct NewSale {
        #[key]
        listingId: u256,
        #[key]
        assetContract: ContractAddress,
        #[key]
        lister: ContractAddress,
        buyer: ContractAddress,
        quantityBought: u256,
        totalPricePaid: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ListingAdded {
        #[key]
        listingId: u256,
        #[key]
        assetContract: ContractAddress,
        #[key]
        lister: ContractAddress,
        listing: Listing,
    }
    #[derive(Drop, starknet::Event)]
    struct ListingUpdated {
        #[key]
        listingId: u256,
        #[key]
        listingCreator: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct ListingRemoved {
        #[key]
        listingId: u256,
        #[key]
        listingCreator: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct NewOffer {
        // todo listingType
        #[key]
        listingId: u256,
        #[key]
        offeror: ContractAddress,
        quantityWanted: u256,
        totalOfferAmount: u256,
        currency: ContractAddress,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Offer {
        listingId: u256,
        offeror: ContractAddress,
        quantityWanted: u256,
        currency: ContractAddress,
        pricePerToken: u256,
        expirationTimestamp: u256,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Listing {
        listingId: u256,
        tokenOwner: ContractAddress,
        assetContract: ContractAddress,
        tokenId: u256,
        startTime: u256,
        endTime: u256,
        quantity: u256,
        currency: ContractAddress,
        buyoutPricePerToken: u256,
        // 0 -> erc721, 1 -> erc1155
        tokenType: u256,
    // todo reservePricePerToken tokenType listingType
    }

    #[constructor]
    fn constructor(ref self: ContractState,) {
        self.operator.write(get_caller_address());
    }

    #[external(v0)]
    fn upgrade(self: @ContractState, new_class_hash: ClassHash) {
        assert(!new_class_hash.is_zero(), 'Class hash cannot be zero');
        assert(get_caller_address() == self.operator.read(), 'Operator required');
        replace_class_syscall(new_class_hash);
    }

    #[abi(embed_v0)]
    impl IMarketplaceImpl of super::IMarketplace<ContractState> {
        fn create_listing(
            ref self: ContractState,
            assetContract: ContractAddress,
            tokenId: u256,
            startTime: u256,
            secondsUntilEndTime: u256,
            quantityToList: u256,
            currencyToAccept: ContractAddress,
            buyoutPricePerToken: u256,
            tokenTypeOfListing: u256,
        ) {
            let listingId = self.total_listings.read();
            self.total_listings.write(listingId + 1);

            let tokenOwner = get_caller_address();
            let tokenAmountToList = self.get_safe_quantity(tokenTypeOfListing, quantityToList);
            assert(tokenAmountToList > 0, 'QUANTITY');
            // hasRole
            let mut _startTime = startTime;
            let currentTime = get_block_timestamp().into();
            if (_startTime < currentTime) {
                assert(currentTime - _startTime < 3600, 'ST');
                _startTime = currentTime;
            }

            self
                .validate_ownership_and_approval(
                    tokenOwner, assetContract, tokenId, tokenAmountToList, tokenTypeOfListing
                );

            let newListing = Listing {
                listingId: listingId,
                tokenOwner: tokenOwner,
                assetContract: assetContract,
                tokenId: tokenId,
                startTime: _startTime,
                endTime: _startTime + secondsUntilEndTime,
                quantity: tokenAmountToList,
                currency: currencyToAccept,
                buyoutPricePerToken: buyoutPricePerToken,
                // 0 -> erc721, 1 -> erc1155
                tokenType: tokenTypeOfListing,
            };

            self.listings.write(listingId, newListing);
            self
                .emit(
                    Event::ListingAdded(
                        ListingAdded {
                            listingId, assetContract, lister: tokenOwner, listing: newListing,
                        }
                    )
                );
        }

        fn cancel_direct_listing(ref self: ContractState, _listingId: u256) {
            self.only_listing_creator(_listingId);
            let targetListing = self.listings.read(_listingId);
            let empty_listing = Listing {
                listingId: 0,
                tokenOwner: contract_address_const::<0>(),
                assetContract: contract_address_const::<0>(),
                tokenId: 0,
                startTime: 0,
                endTime: 0,
                quantity: 0,
                currency: contract_address_const::<0>(),
                buyoutPricePerToken: 0,
                // 0 -> erc721, 1 -> erc1155
                // make to default here
                tokenType: 0,
            };
            self.listings.write(_listingId, empty_listing);
            self
                .emit(
                    Event::ListingRemoved(
                        ListingRemoved {
                            listingId: _listingId, listingCreator: targetListing.tokenOwner
                        }
                    )
                );
        }


        fn offer(
            ref self: ContractState,
            _listingId: u256,
            _quantityWanted: u256,
            _currency: ContractAddress,
            _pricePerToken: u256,
            _expirationTimestamp: u256
        ) {
            self.only_existing_listing(_listingId);
            let targetListing = self.listings.read(_listingId);
            assert(
                targetListing.endTime > get_block_timestamp().into()
                    && targetListing.startTime < get_block_timestamp().into(),
                'inactive listing.'
            );
            let mut newOffer = Offer {
                listingId: _listingId,
                offeror: get_caller_address(),
                quantityWanted: _quantityWanted,
                currency: _currency,
                pricePerToken: _pricePerToken,
                expirationTimestamp: _expirationTimestamp
            };

            newOffer
                .quantityWanted = self
                .get_safe_quantity(targetListing.tokenType, _quantityWanted);
            self.handle_offer(targetListing, newOffer);
        }

        fn accept_offer(
            ref self: ContractState,
            _listingId: u256,
            _offeror: ContractAddress,
            _currency: ContractAddress,
            _pricePerToken: u256
        ) {
            self.only_listing_creator(_listingId);
            self.only_existing_listing(_listingId);
            let targetOffer = self.offers.read((_listingId, _offeror));
            let targetListing = self.listings.read(_listingId);

            assert(
                _currency == targetOffer.currency && _pricePerToken == targetOffer.pricePerToken,
                '!PRICE'
            );
            assert(targetOffer.expirationTimestamp > get_block_timestamp().into(), 'EXPIRED');
            let emptyOffer = Offer {
                listingId: 0,
                offeror: contract_address_const::<0>(),
                quantityWanted: 0,
                currency: contract_address_const::<0>(),
                pricePerToken: 0,
                expirationTimestamp: 0,
            };

            self.offers.write((_listingId, _offeror), emptyOffer);

            self
                .execute_sale(
                    targetListing,
                    _offeror,
                    _offeror,
                    targetOffer.currency,
                    targetOffer.pricePerToken * targetOffer.quantityWanted,
                    targetOffer.quantityWanted
                );
        }

        fn buy(
            ref self: ContractState,
            _listingId: u256,
            _buyFor: ContractAddress,
            _quantityToBuy: u256,
            _currency: ContractAddress,
            _totalPrice: u256,
        ) {
            self.only_existing_listing(_listingId);
            let targetListing = self.listings.read(_listingId);
            let payer = get_caller_address();

            assert(
                _currency == targetListing.currency
                    && _totalPrice == (targetListing.buyoutPricePerToken * _quantityToBuy),
                '!PRICE'
            );

            self
                .execute_sale(
                    targetListing,
                    payer,
                    _buyFor,
                    targetListing.currency,
                    targetListing.buyoutPricePerToken * _quantityToBuy,
                    _quantityToBuy
                );
        }

        fn update_listing(
            ref self: ContractState,
            _listingId: u256,
            _quantityToList: u256,
            _reservePricePerToken: u256,
            _buyoutPricePerToken: u256,
            _currencyToAccept: ContractAddress,
            mut _startTime: u256,
            _secondsUntilEndTime: u256,
        ) {
            self.only_listing_creator(_listingId);
            let targetListing = self.listings.read(_listingId);
            let safeNewQuantity = self.get_safe_quantity(targetListing.tokenType, _quantityToList);
            assert(safeNewQuantity != 0, 'QUANTITY');

            let timestamp: u256 = get_block_timestamp().into();
            if (_startTime < timestamp) {
                assert(timestamp - _startTime < 3600, 'ST');
                _startTime = timestamp;
            }
            let newStartTime = if _startTime == 0 {
                targetListing.startTime
            } else {
                _startTime
            };
            self
                .listings
                .write(
                    _listingId,
                    Listing {
                        listingId: _listingId,
                        tokenOwner: get_caller_address(),
                        assetContract: targetListing.assetContract,
                        tokenId: targetListing.tokenId,
                        startTime: newStartTime,
                        endTime: if _secondsUntilEndTime == 0 {
                            targetListing.endTime
                        } else {
                            newStartTime + _secondsUntilEndTime
                        },
                        quantity: safeNewQuantity,
                        currency: _currencyToAccept,
                        buyoutPricePerToken: _buyoutPricePerToken,
                        tokenType: targetListing.tokenType,
                    }
                );
            if (targetListing.quantity != safeNewQuantity) {
                self
                    .validate_ownership_and_approval(
                        targetListing.tokenOwner,
                        targetListing.assetContract,
                        targetListing.tokenId,
                        safeNewQuantity,
                        targetListing.tokenType
                    );
            }

            self
                .emit(
                    Event::ListingUpdated(
                        ListingUpdated {
                            listingId: _listingId, listingCreator: targetListing.tokenOwner,
                        }
                    )
                );
        }

        fn get_total_listings(self: @ContractState) -> u256 {
            self.total_listings.read()
        }
    }

    #[generate_trait]
    impl StorageImpl of StorageTrait {
        fn get_safe_quantity(
            self: @ContractState, _tokenType: u256, _quantityToCheck: u256
        ) -> u256 {
            if _quantityToCheck == 0 {
                0
            } else {
                if _tokenType == ERC721 {
                    1
                } else {
                    _quantityToCheck
                }
            }
        }

        fn validate_ownership_and_approval(
            self: @ContractState,
            _tokenOwner: ContractAddress,
            _assetContract: ContractAddress,
            _tokenId: u256,
            _quantity: u256,
            _tokenType: u256
        ) {
            let market = get_contract_address();
            let mut isValid: bool = false;
            if (_tokenType == ERC1155) {
                let token = IERC1155Dispatcher { contract_address: _assetContract };
                isValid = token.balance_of(_tokenOwner, _tokenId) >= _quantity
                    && token.is_approved_for_all(_tokenOwner, market);
            } else if (_tokenType == ERC721) {
                let token = IERC721Dispatcher { contract_address: _assetContract };
                isValid = token.owner_of(_tokenId) == _tokenOwner
                    && token.get_approved(_tokenId) == market
                        || token.is_approved_for_all(_tokenOwner, market);
            }

            assert(isValid, '!BALNFT');
        }

        fn handle_offer(ref self: ContractState, _targetListing: Listing, _newOffer: Offer) {
            assert(
                _newOffer.quantityWanted <= _targetListing.quantity && _targetListing.quantity > 0,
                'insufficient tokens in listing.'
            );
            self
                .validate_ERC20_bal_and_allowance(
                    _newOffer.offeror,
                    _newOffer.currency,
                    _newOffer.pricePerToken * _newOffer.quantityWanted
                );

            self.offers.write((_targetListing.listingId, _newOffer.offeror), _newOffer);
            self
                .emit(
                    Event::NewOffer(
                        NewOffer {
                            listingId: _targetListing.listingId,
                            offeror: _newOffer.offeror,
                            quantityWanted: _newOffer.quantityWanted,
                            totalOfferAmount: _newOffer.pricePerToken * _newOffer.quantityWanted,
                            currency: _newOffer.currency
                        }
                    )
                );
        }

        fn validate_ERC20_bal_and_allowance(
            ref self: ContractState,
            _addrToCheck: ContractAddress,
            _currency: ContractAddress,
            _currencyAmountToCheckAgainst: u256
        ) {
            let token = IERC20Dispatcher { contract_address: _currency };
            assert(
                token.balance_of(_addrToCheck) >= _currencyAmountToCheckAgainst
                    && token
                        .allowance(
                            _addrToCheck, get_contract_address()
                        ) >= _currencyAmountToCheckAgainst,
                '!BAL20'
            );
        }

        fn execute_sale(
            ref self: ContractState,
            mut _targetListing: Listing,
            _payer: ContractAddress,
            _receiver: ContractAddress,
            _currency: ContractAddress,
            _currencyAmountToTransfer: u256,
            _listingTokenAmountToTransfer: u256,
        ) {
            self
                .validate_direct_listing_sale(
                    _targetListing,
                    _payer,
                    _listingTokenAmountToTransfer,
                    _currency,
                    _currencyAmountToTransfer
                );

            _targetListing.quantity -= _listingTokenAmountToTransfer;
            self.listings.write(_targetListing.listingId, _targetListing);
            self
                .payout(
                    _payer,
                    _targetListing.tokenOwner,
                    _currency,
                    _currencyAmountToTransfer,
                    _targetListing
                );
            self
                .transfer_listing_tokens(
                    _targetListing.tokenOwner,
                    _receiver,
                    _listingTokenAmountToTransfer,
                    _targetListing
                );
            self
                .emit(
                    Event::NewSale(
                        NewSale {
                            listingId: _targetListing.listingId,
                            assetContract: _targetListing.assetContract,
                            lister: _targetListing.tokenOwner,
                            buyer: _receiver,
                            quantityBought: _listingTokenAmountToTransfer,
                            totalPricePaid: _currencyAmountToTransfer,
                        }
                    )
                );
        }

        fn validate_direct_listing_sale(
            ref self: ContractState,
            _listing: Listing,
            _payer: ContractAddress,
            _quantityToBuy: u256,
            _currency: ContractAddress,
            settledTotalPrice: u256,
        ) {
            assert(
                _listing.quantity > 0 && _quantityToBuy > 0 && _quantityToBuy <= _listing.quantity,
                'invalid amount of tokens.'
            );
            assert(
                get_block_timestamp().into() < _listing.endTime
                    && get_block_timestamp().into() > _listing.startTime,
                'not within sale window.'
            );
            self.validate_ERC20_bal_and_allowance(_payer, _currency, settledTotalPrice);
            self
                .validate_ownership_and_approval(
                    _listing.tokenOwner,
                    _listing.assetContract,
                    _listing.tokenId,
                    _quantityToBuy,
                    _listing.tokenType
                );
        }

        fn payout(
            ref self: ContractState,
            _payer: ContractAddress,
            _payee: ContractAddress,
            _currencyToUse: ContractAddress,
            _totalPayoutAmount: u256,
            _listing: Listing,
        ) {
            self.safe_transfer_ERC20(_currencyToUse, _payer, _payee, _totalPayoutAmount);
        }

        fn transfer_listing_tokens(
            ref self: ContractState,
            _from: ContractAddress,
            _to: ContractAddress,
            _quantity: u256,
            _listing: Listing,
        ) {
            if _listing.tokenType == ERC1155 {
                let token = IERC1155Dispatcher { contract_address: _listing.assetContract };
                token
                    .safe_transfer_from(
                        _from, _to, _listing.tokenId, _quantity, ArrayTrait::<felt252>::new().span()
                    );
            } else if _listing.tokenType == ERC721 {
                let token = IERC721Dispatcher { contract_address: _listing.assetContract };
                token.transfer_from(_from, _to, _listing.tokenId);
            }
        }

        fn safe_transfer_ERC20(
            ref self: ContractState,
            _currency: ContractAddress,
            _from: ContractAddress,
            _to: ContractAddress,
            _amount: u256,
        ) {
            if (_amount == 0) || (_from == _to) {
                return;
            }

            let token = IERC20Dispatcher { contract_address: _currency };
            if _from == get_contract_address() {
                token.transfer(_to, _amount);
            } else {
                token.transfer_from(_from, _to, _amount);
            }
        }

        fn only_listing_creator(self: @ContractState, _listingId: u256) {
            assert(self.listings.read(_listingId).tokenOwner == get_caller_address(), '!OWNER');
        }

        fn only_existing_listing(self: @ContractState, _listingId: u256) {
            assert(
                self.listings.read(_listingId).assetContract != contract_address_const::<0>(), 'DNE'
            );
        }
    }
}
