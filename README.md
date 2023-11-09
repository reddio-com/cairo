# Reddio Cairo
This is the Reddio Cairo repo which contains Cairo smart contract templates.

## Install Scarb
```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
```
For Windows, follow manual setup in the [Scarb documentation](https://docs.swmansion.com/scarb/download.html?ref=blog.reddio.com#windows).

Restart the terminal and check if Scarb is installed correctly:

```bash
scarb --version
```

## Compile & Build

```bash
scarb build
```

Then you will get the `target` directory, which contains the compiled sierra files.

## Install Starkli

If you're on Linux/macOS/WSL/Android, you can install stakrliup by running the following command:
```bash
curl https://get.starkli.sh | sh
```

You might need to restart your shell session for the starkliup command to become available. Once it's available, run the starkliup command:
```bash
starkliup
```

Running the commands installs starkli for you, and upgrades it to the latest release if it's already installed.

`starkliup` detects your device's platform and automatically downloads the right prebuilt binary. It also sets up shell completions. You might need to restart your shell session for the completions to start working.

## Account Creation

Generate keystore:
```bash
starkli signer keystore new /path/to/keystore
```
then a keystore file will be created at `/path/to/keystore`.

You can then use it via the `--keystore <PATH>` option for commands expecting a signer.

Alternatively, you can set the `STARKNET_KEYSTORE` environment variable to make command invocations easier:

```bash
export STARKNET_KEYSTORE="/path/to/keystore"
```

Before creating an account, you must first decide on the variant to use. As of this writing, the only supported variant is `oz`, the OpenZeppelin account contract.

All variants come with an init subcommand that creates an account file ready to be deployed. For example, to create an `oz` account:

```bash
starkli account oz init /path/to/account
```

## Account deployment
Once you have an account file, you can deploy the account contract with the `starkli account deploy` command. This command sends a `DEPLOY_ACCOUNT` transaction, which requires the account to be funded with some `ETH` for paying for the transaction fee.

> You can get some test funds [here](https://faucet.goerli.starknet.io/).

For example, to deploy the account we just created:

```bash
starkli account deploy /path/to/account
```

When run, the command shows the address where the contract will be deployed on, and instructs the user to fund the account before proceeding. Here's an example command output:

```bash
The estimated account deployment fee is 0.000011483579723913 ETH. However, to avoid failure, fund at least:
    0.000017225369585869 ETH
to the following address:
    0x01cf4d57ba01109f018dec3ea079a38fc08b789e03de4df937ddb9e8a0ff853a
Press [ENTER] once you've funded the address.
```

Once the account deployment transaction is confirmed, the account file will be update to reflect the deployment status. It can then be used for commands where an account is expected. You can pass the account either with the `--account` parameter, or with the `STARKNET_ACCOUNT` environment variable.

## Account fetching
Account fetching allows recreating the account file from on-chain data alone. This could be helpful when:

+ the account file is lost; or
+ migrating an account from another tool/application.

The `starkli account fetch` commands creates an account file using just the address provided:

```bash
starkli account fetch <ADDRESS> --output /path/to/account
```

Running the command above creates the account file at `/path/to/account`.

## Declaring classes
In Starknet, all deployed contracts are instances of certain declared classes. Therefore, the first step of deploying a contract is declaring a class, if it hasn't been declared already.

With Starkli, this is done with the `starkli declare` command.

Before declare, you should set environment variables for Starkli:

```bash
export STARKNET_ACCOUNT=/path/to/keystore
export STARKNET_KEYSTORE=/path/to/account
```

After `scarb build`, you will get the `*.sierra.json` file in the `target` directory, which we'll use to declare the contract class:

```bash
starkli declare *.sierra.json
```

such as:
```bash
starkli declare target/dev/reddio_cairo_Marketplace.sierra.json
```

You may get an error:
```bash
Not declaring class as it's already declared.
```

This is because the class has been declared by someone else before and a class cannot be declared twice in Starknet. You can just deploy it using the current declared class or write a new unique contract.

Once the declaration is successful, Starkli displays the class hash declared. The class hash is needed for deploying contracts.

## Deploying contracts
Once you obtain a class hash by declaring a class, it's ready to deploy instances of the class.

With Starkli, this is done with the `starkli deploy` command.

To deploy a contract with class hash `<CLAS_HASH>`, simply run:

```bash
starkli deploy <CLASS_HASH> <CTOR_ARGS>
```

where `<CTOR_ARGS>` is the list of constructor arguments, if any.

Note that string parameters should be cast to hexadecimal in CLI.

## Invoking contracts

With Starkli, this is done with the `starkli invoke` command.

The basic format of a `starkli invoke` command is the following:

```bash
starkli invoke <ADDRESS> <SELECTOR> <ARGS>
```

For example, to transfer `100 Wei` of the `ETH` token to the address `0x1234`, one can run:

```bash
starkli invoke 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 transfer 0x1234 100:u256
```

For more information about starkli, touch [here](https://book.starkli.rs/).
