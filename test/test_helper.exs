# Fund a shared wallet for tests
if :integration not in ExUnit.configuration()[:exclude] do
  client = BTx.TestUtils.new_client(retry_opts: [max_retries: 10])
  wallet = "btx-shared-test-wallet"

  # Step 1: Create and load a wallet
  with {:ok, _} <- BTx.RPC.Wallets.create_wallet(client, wallet_name: wallet, avoid_reuse: true) do
    # Step 2: Generate blocks to get some funds (coinbase needs 100 confirmations to spend)
    address = BTx.RPC.Wallets.get_new_address!(client, wallet_name: wallet)

    # Generate 101 blocks to make coinbase spendable
    BTx.RPC.Mining.generate_to_address!(client, nblocks: 101, address: address)

    # Step 3: Check that we have spendable balance
    BTx.TestUtils.wait_until(fn ->
      if BTx.RPC.Wallets.get_balance!(client, wallet_name: wallet) == 0.0 do
        raise "Wallet #{wallet} has no balance"
      end
    end)
  end

  # Step 4: Load the wallet
  BTx.RPC.Wallets.load_wallet(client, filename: wallet)
end

# Start the test suite
ExUnit.start()
