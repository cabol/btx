# Fund a shared wallet for tests
if :integration not in ExUnit.configuration()[:exclude] do
  client = BTx.TestUtils.new_client()
  wallet = "btx-shared-test-wallet"

  # Step 1: Create and load a wallet
  with {:ok, _} <-
         BTx.RPC.Wallets.create_wallet(client, [wallet_name: wallet, avoid_reuse: true],
           retries: 10
         ) do
    # Step 2: Generate blocks to get some funds (coinbase needs 100 confirmations to spend)
    address = BTx.RPC.Wallets.get_new_address!(client, [wallet_name: wallet], retries: 10)

    # Generate 101 blocks to make coinbase spendable
    BTx.RPC.Mining.generate_to_address!(client, [nblocks: 101, address: address], retries: 10)

    # Step 3: Check that we have spendable balance
    BTx.TestUtils.wait_until(fn ->
      if BTx.RPC.Wallets.get_balance!(client, [wallet_name: wallet], retries: 10) == 0.0 do
        raise "Wallet #{wallet} has no balance"
      end
    end)
  end

  # Step 4: Load the wallet
  BTx.RPC.Wallets.load_wallet(client, [filename: wallet], retries: 10)
end

# Start the test suite
ExUnit.start()
