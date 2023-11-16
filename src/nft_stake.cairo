use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
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
trait INFTStake<TContractState> {
    fn get_rewards_per_unit_time(self: @TContractState) -> u256;
    fn get_time_unit(self: @TContractState) -> u256;
    fn initialize(
        ref self: TContractState,
        _reward_token: ContractAddress,
        _staking_token: ContractAddress,
        _time_unit: u256,
        _rewards_per_unit_time: u256
    );
    fn deposit_reward_tokens(ref self: TContractState, _amount: u256);
    fn withdraw_reward_tokens(ref self: TContractState, _amount: u256);
    fn set_time_unit(ref self: TContractState, _time_unit: u256);
    fn set_rewards_per_unit_time(ref self: TContractState, _rewards_per_unit_time: u256);
    fn stake(ref self: TContractState, _token_ids: Array<u256>);
    fn withdraw(ref self: TContractState, _token_ids: Array<u256>);
    fn claim_rewards(ref self: TContractState);
}

#[starknet::contract]
mod NFTStake {
    use core::clone::Clone;
    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    use super::IERC721Dispatcher;
    use super::IERC721DispatcherTrait;

    use core::traits::Into;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::get_contract_address;
    use starknet::get_caller_address;
    use starknet::info::get_block_timestamp;

    #[storage]
    struct Storage {
        reward_token: ContractAddress,
        reward_token_balance: u256,
        staking_token: ContractAddress,
        // Storage array is not supported so we use mapping and length here instead
        // uint256[] public indexedTokens;
        indexed_tokens: LegacyMap::<u256, u256>,
        indexed_tokens_length: u256,
        // address[] public stakersArray;
        stakers_array: LegacyMap::<u256, ContractAddress>,
        stakers_array_length: u256,
        next_condition_id: u256,
        is_indexed: LegacyMap::<u256, bool>,
        stakers: LegacyMap::<ContractAddress, Staker>,
        staker_address: LegacyMap::<u256, ContractAddress>,
        staking_conditions: LegacyMap::<u256, StakingCondition>,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Staker {
        amountStaked: u256,
        timeOfLastUpdate: u256,
        unclaimedRewards: u256,
        conditionIdOflastUpdate: u256,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct StakingCondition {
        timeUnit: u256,
        rewardsPerUnitTime: u256,
        startTimestamp: u256,
        endTimestamp: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RewardTokensDepositedByAdmin: RewardTokensDepositedByAdmin,
        RewardTokensWithdrawnByAdmin: RewardTokensWithdrawnByAdmin,
        UpdatedTimeUnit: UpdatedTimeUnit,
        UpdatedRewardsPerUnitTime: UpdatedRewardsPerUnitTime,
        RewardsClaimed: RewardsClaimed,
        TokensStaked: TokensStaked,
        TokensWithdrawn: TokensWithdrawn,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardTokensDepositedByAdmin {
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardTokensWithdrawnByAdmin {
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct UpdatedTimeUnit {
        oldTimeUnit: u256,
        newTimeUnit: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct UpdatedRewardsPerUnitTime {
        oldRewardsPerUnitTime: u256,
        newRewardsPerUnitTime: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardsClaimed {
        #[key]
        staker: ContractAddress,
        rewardAmount: u256,
    }
    #[derive(Drop, starknet::Event)]
    struct TokensStaked {
        #[key]
        staker: ContractAddress,
        tokenIds: Array<u256>,
    }
    // TokensWithdrawn
    #[derive(Drop, starknet::Event)]
    struct TokensWithdrawn {
        #[key]
        staker: ContractAddress,
        tokenIds: Array<u256>,
    }

    #[abi(embed_v0)]
    impl INFTStakeImpl of super::INFTStake<ContractState> {
        fn initialize(
            ref self: ContractState,
            _reward_token: ContractAddress,
            _staking_token: ContractAddress,
            _time_unit: u256,
            _rewards_per_unit_time: u256
        ) {
            // todo init only once
            self.reward_token.write(_reward_token);
            self.staking_token.write(_staking_token);
            self._set_staking_condition(_time_unit, _rewards_per_unit_time);
        }
        fn deposit_reward_tokens(ref self: ContractState, _amount: u256) {
            // todo check role

            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            let balance_before = reward_token.balance_of(get_contract_address());
            reward_token.transfer_from(get_caller_address(), get_contract_address(), _amount);
            let actual_amount = reward_token.balance_of(get_contract_address()) - balance_before;
            self.reward_token_balance.write(self.reward_token_balance.read() + actual_amount);
            self
                .emit(
                    Event::RewardTokensDepositedByAdmin(
                        RewardTokensDepositedByAdmin { amount: actual_amount }
                    )
                );
        }

        fn withdraw_reward_tokens(ref self: ContractState, _amount: u256) {
            // todo check role

            let new_reward_token_balance = if _amount < self.reward_token_balance.read() {
                self.reward_token_balance.read() - _amount
            } else {
                0
            };

            self.reward_token_balance.write(new_reward_token_balance);

            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            reward_token.transfer(get_caller_address(), _amount);

            self
                .emit(
                    Event::RewardTokensWithdrawnByAdmin(
                        RewardTokensWithdrawnByAdmin { amount: _amount }
                    )
                );
        }

        fn set_time_unit(ref self: ContractState, _time_unit: u256) {
            assert(self._can_set_stake_conditions(), 'Not authorized');

            let condition: StakingCondition = self
                .staking_conditions
                .read(self.next_condition_id.read() - 1);
            assert(_time_unit != condition.timeUnit, 'Time-unit unchanged.');
            self._set_staking_condition(_time_unit, condition.timeUnit);
            self
                .emit(
                    Event::UpdatedTimeUnit(
                        UpdatedTimeUnit { oldTimeUnit: condition.timeUnit, newTimeUnit: _time_unit }
                    )
                );
        }

        fn set_rewards_per_unit_time(ref self: ContractState, _rewards_per_unit_time: u256) {
            assert(self._can_set_stake_conditions(), 'Not authorized');
            let condition: StakingCondition = self
                .staking_conditions
                .read(self.next_condition_id.read() - 1);
            assert(_rewards_per_unit_time != condition.rewardsPerUnitTime, 'Reward unchanged.');
            self._set_staking_condition(condition.timeUnit, _rewards_per_unit_time);
            self
                .emit(
                    Event::UpdatedRewardsPerUnitTime(
                        UpdatedRewardsPerUnitTime {
                            oldRewardsPerUnitTime: condition.rewardsPerUnitTime,
                            newRewardsPerUnitTime: _rewards_per_unit_time
                        }
                    )
                );
        }

        fn stake(ref self: ContractState, _token_ids: Array<u256>) {
            // todo nonReentrant
            self._stake(_token_ids);
        }

        fn withdraw(ref self: ContractState, _token_ids: Array<u256>) {
            // todo nonReentrant
            self._withdraw(_token_ids);
        }

        fn claim_rewards(ref self: ContractState) {
            // todo nonReentrant
            self._claim_rewards();
        }

        fn get_time_unit(self: @ContractState) -> u256 {
            self.staking_conditions.read(self.next_condition_id.read() - 1).timeUnit
        }

        fn get_rewards_per_unit_time(self: @ContractState) -> u256 {
            self.staking_conditions.read(self.next_condition_id.read() - 1).rewardsPerUnitTime
        }
    }

    #[generate_trait]
    impl StorageImpl of StorageTrait {
        fn _can_set_stake_conditions(ref self: ContractState) -> bool {
            // todo
            true
        }

        fn _set_staking_condition(
            ref self: ContractState, _time_unit: u256, _rewards_per_unit_time: u256
        ) {
            assert(_time_unit != 0, 'time-unit can\'t be 0');
            let condition_id = self.next_condition_id.read();
            self.next_condition_id.write(self.next_condition_id.read() + 1);

            self
                .staking_conditions
                .write(
                    condition_id,
                    StakingCondition {
                        timeUnit: _time_unit,
                        rewardsPerUnitTime: _rewards_per_unit_time,
                        startTimestamp: get_block_timestamp().into(),
                        endTimestamp: 0
                    }
                );

            if (condition_id > 0) {
                let mut last = self.staking_conditions.read(condition_id - 1);
                last.endTimestamp = get_block_timestamp().into();
                self.staking_conditions.write(condition_id - 1, last);
            }
        }

        fn _stake(ref self: ContractState, _token_ids: Array<u256>) {
            let len = _token_ids.len();
            assert(len != 0, 'Staking 0 tokens');
            let _staking_token = self.staking_token.read();
            if self.stakers.read(self._stake_msg_sender()).amountStaked > 0 {
                self._update_unclaimed_rewards_for_staker(self._stake_msg_sender());
            } else {
                self
                    .stakers_array
                    .write(self.stakers_array_length.read(), self._stake_msg_sender());
                self.stakers_array_length.write(self.stakers_array_length.read() + 1);
                let mut temp = self.stakers.read(self._stake_msg_sender());
                temp.timeOfLastUpdate = get_block_timestamp().into();
                temp.conditionIdOflastUpdate = self.next_condition_id.read() - 1;
                self.stakers.write(self._stake_msg_sender(), temp);
            }

            let mut i = 0;
            let _cloned_token_ids = _token_ids.clone();
            loop {
                if i >= len {
                    break;
                }
                let token = IERC721Dispatcher { contract_address: _staking_token };
                assert(
                    (token.owner_of(*_cloned_token_ids.at(i)) == get_caller_address())
                        & ((token.get_approved(*_cloned_token_ids.at(i)) == get_contract_address())
                            | (token
                                .is_approved_for_all(
                                    get_caller_address(), get_contract_address()
                                ))),
                    'Not owned or approved'
                );

                token
                    .transfer_from(
                        get_caller_address(), get_contract_address(), *_cloned_token_ids.at(i)
                    );

                self.staker_address.write(*_cloned_token_ids.at(i), get_caller_address());

                if !self.is_indexed.read(*_cloned_token_ids.at(i)) {
                    self.is_indexed.write(*_cloned_token_ids.at(i), true);
                    // indexed_tokens: LegacyMap::<u256, u256>,
                    // indexed_tokens_length: u256,
                    self
                        .indexed_tokens
                        .write(self.indexed_tokens_length.read(), *_cloned_token_ids.at(i));
                    self.indexed_tokens_length.write(self.indexed_tokens_length.read() + 1);
                };
                i += 1;
            };
            let mut temp = self.stakers.read(get_caller_address());
            temp.amountStaked += len.into();
            self.stakers.write(get_caller_address(), temp);

            self
                .emit(
                    Event::TokensStaked(
                        TokensStaked { staker: get_caller_address(), tokenIds: _token_ids }
                    )
                );
        }

        fn _withdraw(ref self: ContractState, _token_ids: Array<u256>) {
            let _amount_staked = self.stakers.read(self._stake_msg_sender()).amountStaked;
            let len = _token_ids.len();
            assert(len != 0, 'Withdrawing 0 tokens');
            assert(_amount_staked >= len.into(), 'Withdrawing more than staked');
            let _staking_token = self.staking_token.read();

            self._update_unclaimed_rewards_for_staker(self._stake_msg_sender());
            if _amount_staked == len.into() {
                let _stakers_array_len = self.stakers_array_length.read();
                let mut i = 0;
                loop {
                    if i >= _stakers_array_len {
                        break;
                    }
                    if self.stakers_array.read(i) == get_caller_address() {
                        // stakers_array: LegacyMap::<u256, ContractAddress>,
                        // stakers_array_length: u256,
                        self
                            .stakers_array
                            .write(i, self.stakers_array.read(_stakers_array_len - 1));
                        self.stakers_array_length.write(self.stakers_array_length.read() - 1);
                        self
                            .stakers_array
                            .write(self.stakers_array_length.read(), contract_address_const::<0>());
                        break;
                    };
                    i += 1;
                };
            }

            let mut temp = self.stakers.read(get_caller_address());
            temp.amountStaked -= len.into();
            self.stakers.write(get_caller_address(), temp);

            let mut i = 0;
            let _cloned_token_ids = _token_ids.clone();
            loop {
                if i >= len {
                    break;
                }
                assert(
                    self.staker_address.read(*_cloned_token_ids.at(i)) == get_caller_address(),
                    'Not staker'
                );
                self.staker_address.write(*_cloned_token_ids.at(i), contract_address_const::<0>());
                let token = IERC721Dispatcher { contract_address: _staking_token };
                token
                    .transfer_from(
                        get_contract_address(), get_caller_address(), *_cloned_token_ids.at(i)
                    );
                i += 1;
            };

            self
                .emit(
                    Event::TokensWithdrawn(
                        TokensWithdrawn { staker: get_caller_address(), tokenIds: _token_ids }
                    )
                );
        }

        fn _stake_msg_sender(self: @ContractState) -> ContractAddress {
            get_caller_address()
        }

        fn _update_unclaimed_rewards_for_staker(ref self: ContractState, _staker: ContractAddress) {
            let rewards = self._calculate_rewards(_staker);
            let mut temp: Staker = self.stakers.read(_staker);
            temp.unclaimedRewards += rewards;
            temp.timeOfLastUpdate = get_block_timestamp().into();
            temp.conditionIdOflastUpdate = self.next_condition_id.read() - 1;
            self.stakers.write(_staker, temp);
        }

        fn _calculate_rewards(self: @ContractState, _staker: ContractAddress) -> u256 {
            let staker = self.stakers.read(_staker);
            let _staker_condition_id = staker.conditionIdOflastUpdate;
            let _next_condition_id = self.next_condition_id.read();
            let mut _rewards = 0;
            let mut i = _staker_condition_id;
            loop {
                if i >= _next_condition_id {
                    break;
                }
                let condition = self.staking_conditions.read(i);
                let start_time = if i != _staker_condition_id {
                    condition.startTimestamp
                } else {
                    staker.timeOfLastUpdate
                };
                let end_time = if condition.endTimestamp != 0 {
                    condition.endTimestamp
                } else {
                    get_block_timestamp().into()
                };
                // todo use try math instead
                let rewards_product = (end_time - start_time)
                    * staker.amountStaked
                    * condition.rewardsPerUnitTime;
                _rewards += rewards_product / condition.timeUnit;
                i += 1;
            };

            _rewards
        }

        fn _claim_rewards(ref self: ContractState) {
            let rewards = self.stakers.read(self._stake_msg_sender()).unclaimedRewards
                + self._calculate_rewards(self._stake_msg_sender());
            assert(rewards != 0, 'No rewards');

            let mut temp = self.stakers.read(self._stake_msg_sender());
            temp.timeOfLastUpdate = get_block_timestamp().into();
            temp.unclaimedRewards = 0;
            temp.conditionIdOflastUpdate = self.next_condition_id.read() - 1;
            self.stakers.write(self._stake_msg_sender(), temp);

            self._mint_rewards(self._stake_msg_sender(), rewards);
            self
                .emit(
                    Event::RewardsClaimed(
                        RewardsClaimed { staker: self._stake_msg_sender(), rewardAmount: rewards }
                    )
                );
        }

        fn _available_rewards(self: @ContractState, _user: ContractAddress) -> u256 {
            if self.stakers.read(_user).amountStaked == 0 {
                self.stakers.read(_user).unclaimedRewards
            } else {
                self.stakers.read(_user).unclaimedRewards + self._calculate_rewards(_user)
            }
        }

        fn _mint_rewards(ref self: ContractState, _staker: ContractAddress, _rewards: u256) {
            assert(_rewards <= self.reward_token_balance.read(), 'Not enough reward tokens');
            self.reward_token_balance.write(self.reward_token_balance.read() - _rewards);
            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            reward_token.transfer(_staker, _rewards);
        }
    }
}
