# Reddio Cairo
This is the Reddio Cairo repo which contains some Cairo templates.

## Compile & Build

Since Cairo is still in the early stages of development, the tools are constantly updated. Here, we use the Cairo CLI (Command Line Interface) to compile contracts.

### Configure Environment

To use the `Cairo CLI`, we need to install Rust and clone the Cairo repo.

1. Download [Rust](https://www.rust-lang.org/tools/install)

2. Install Rust:

    ```shell
    rustup override set stable && rustup update
    ```

3. Verify that Rust is installed correctly:

    ```shell
    cargo version
    ```

4. Clone the Cairo repo locally:

    ```shell
    git clone https://github.com/starkware-libs/cairo
    ```


### Compile Contracts

1. Switch to the Cairo repo folder locally:
    ```shell
    cd cairo
    ```

2. Use the following command to compile the Cairo contract into a Sierra ContractClass。 Replace `/path/to/input.cairo` with the contract file directory, and `/path/to/output.json` with the directory of the compiled output file.:

    ```shell
    cargo run --bin starknet-compile -- --single-file /path/to/input.cairo /path/to/output.json
    ```

