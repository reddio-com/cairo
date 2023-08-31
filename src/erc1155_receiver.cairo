// const SUCCESS: felt252 = 123123;
// const FAILURE: felt252 = 456456;
// // using 721 id from openzeppelin here
// const IERC1155_RECEIVER_ID: felt252 =
//     0x3a0dff5f70d80458ad14ae37bb182a728e3c8cdda0402a5daa86620bdf910bc;

// use starknet::ContractAddress;

// #[starknet::interface]
// trait IERC1155Receiver<TContractState> {
//     fn on_erc1155_received(
//         ref self: TContractState,
//         operator: ContractAddress,
//         from: ContractAddress,
//         id: u256,
//         value: u256,
//         data: Span<felt252>
//     ) -> felt252;

//     fn on_erc1155_batch_received(
//         ref self: TContractState,
//         operator: ContractAddress,
//         from: ContractAddress,
//         ids: Array<u256>,
//         values: Array<u256>,
//         data: Span<felt252>
//     ) -> felt252;
// }

// #[starknet::contract]
// mod ERC1155Receiver {

//     use array::SpanTrait;
//     use starknet::ContractAddress;

//     #[storage]
//     struct Storage {}

//     impl ERC1155ReceiverImpl of super::IERC1155Receiver<ContractState> {
//         fn on_erc1155_received(
//             ref self: ContractState,
//             operator: ContractAddress,
//             from: ContractAddress,
//             id: u256,
//             value: u256,
//             data: Span<felt252>
//         ) -> felt252 {
//             if *data.at(0) == super::SUCCESS {
//                 super::IERC1155_RECEIVER_ID
//             } else {
//                 0
//             }
//         }

//         fn on_erc1155_batch_received(
//             ref self: ContractState,
//             operator: ContractAddress,
//             from: ContractAddress,
//             ids: Array<u256>,
//             values: Array<u256>,
//             data: Span<felt252>
//         ) -> felt252 {
//             if *data.at(0) == super::SUCCESS {
//                 super::IERC1155_RECEIVER_ID
//             } else {
//                 0
//             }
//         }
//     }
// }

use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct ERC1155Receiver {
    contract_address: ContractAddress
}

trait ERC1155ReceiverTrait {
    fn on_erc1155_received(
        self: @ERC1155Receiver,
        operator: ContractAddress,
        from: ContractAddress,
        id: u256,
        value: u256,
        data: Span<felt252>
    ) -> felt252;

    fn on_erc1155_batch_received(
        self: @ERC1155Receiver,
        operator: ContractAddress,
        from: ContractAddress,
        ids: Array<u256>,
        values: Array<u256>,
        data: Span<felt252>
    ) -> felt252;
}

impl ERC1155ReceiverImpl of ERC1155ReceiverTrait {
    fn on_erc1155_received(
        self: @ERC1155Receiver,
        operator: ContractAddress,
        from: ContractAddress,
        id: u256,
        value: u256,
        data: Span<felt252>
    ) -> felt252 {
        ''
    }

    fn on_erc1155_batch_received(
        self: @ERC1155Receiver,
        operator: ContractAddress,
        from: ContractAddress,
        ids: Array<u256>,
        values: Array<u256>,
        data: Span<felt252>
    ) -> felt252 {
        ''
    }
}
