use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct ERC721Receiver {
    contract_address: ContractAddress
}

trait ERC721ReceiverTrait {
    fn on_erc721_received(
        self: @ERC721Receiver,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252;
}

impl ERC721ReceiverImpl of ERC721ReceiverTrait {
    fn on_erc721_received(
        self: @ERC721Receiver,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252 {
        ''
    }
}
