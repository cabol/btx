## Fund a shared wallet for tests

client = BTx.TestUtils.new_client()
wallet = "btx-shared-test-wallet"

# Step 1: Create and load a wallet
with {:ok, _} <- BTx.JRPC.Wallets.create_wallet(client, wallet_name: wallet, avoid_reuse: true) do
  # Step 2: Generate blocks to get some funds (coinbase needs 100 confirmations to spend)
  address = BTx.JRPC.Wallets.get_new_address!(client, wallet_name: wallet)

  # Generate 101 blocks to make coinbase spendable
  BTx.JRPC.Mining.generate_to_address!(client, nblocks: 101, address: address)

  # Step 3: Check that we have spendable balance
  BTx.TestUtils.wait_until(fn ->
    if BTx.JRPC.Wallets.get_balance!(client, wallet_name: wallet) == 0.0 do
      raise "Wallet #{wallet} has no balance"
    end
  end)
end

# Step 4: Load the wallet
BTx.JRPC.Wallets.load_wallet(client, filename: wallet)

# Start the test suite
ExUnit.start()
