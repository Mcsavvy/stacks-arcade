import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types,
    assertEquals,
  } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
  
  Clarinet.test({
    name: "StacksArcade: Test suite for game items marketplace with trading and rentals",
    async fn(chain: Chain, accounts: Map<string, Account>) {
      const deployer = accounts.get('deployer')!;
      const user1 = accounts.get('wallet_1')!;
      const user2 = accounts.get('wallet_2')!;
      
      // Original tests...
      // [Previous test cases 1-10 remain unchanged]

      // Test 11: Create trade offer
      const createTradeBlock = chain.mineBlock([
        // First list two items
        Tx.contractCall(
          'stacksarcade',
          'list-item',
          [
            types.ascii('Trade Item 1'),
            types.uint(100_000_000)
          ],
          user1.address
        ),
        Tx.contractCall(
          'stacksarcade',
          'list-item',
          [
            types.ascii('Trade Item 2'),
            types.uint(100_000_000)
          ],
          user2.address
        ),
        // Create trade offer
        Tx.contractCall(
          'stacksarcade',
          'create-trade-offer',
          [
            types.uint(1),
            types.uint(2),
            types.principal(user2.address),
            types.uint(100) // Expires in 100 blocks
          ],
          user1.address
        ),
      ]);
      
      assertEquals(createTradeBlock.receipts[2].result, '(ok u1)');

      // Test 12: Accept trade offer
      const acceptTradeBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'accept-trade',
          [types.uint(1)],
          user2.address
        ),
      ]);
      
      assertEquals(acceptTradeBlock.receipts[0].result, '(ok true)');

      // Test 13: Rent item
      const rentItemBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'rent-item',
          [
            types.uint(1),
            types.principal(user2.address),
            types.uint(100) // Rent for 100 blocks
          ],
          user1.address
        ),
      ]);
      
      assertEquals(rentItemBlock.receipts[0].result, '(ok true)');

      // Test 14: Try to sell rented item (should fail)
      const sellRentedBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'set-item-for-sale',
          [
            types.uint(1),
            types.bool(true)
          ],
          user1.address
        ),
      ]);
      
      assertEquals(sellRentedBlock.receipts[0].result, '(err u106)');

      // Test 15: End rental after expiry
      chain.mineEmptyBlockUntil(rentItemBlock.height + 101);
      
      const endRentalBlock = chain.mineBlock([
        Tx.contractCall(
          'stacksarcade',
          'end-rental',
          [types.uint(1)],
          user1.address
        ),
      ]);
      
      assertEquals(endRentalBlock.receipts[0].result, '(ok true)');
    },
  });
