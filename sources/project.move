module MyModule::P2PRentals {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a rental listing
    struct RentalListing has store, key {
        item_name: vector<u8>,     // Name/description of the item
        daily_rate: u64,           // Rental rate per day in APT
        is_available: bool,        // Whether the item is currently available
        renter: address,           // Current renter's address (0x0 if available)
        rental_end_time: u64,      // Timestamp when rental expires
    }

    /// Error codes
    const E_ITEM_NOT_AVAILABLE: u64 = 1;
    const E_INSUFFICIENT_PAYMENT: u64 = 2;
    const E_NOT_RENTER: u64 = 3;
    const E_RENTAL_NOT_EXPIRED: u64 = 4;

    /// Function to create a new rental listing
    public fun create_listing(
        owner: &signer, 
        item_name: vector<u8>, 
        daily_rate: u64
    ) {
        let listing = RentalListing {
            item_name,
            daily_rate,
            is_available: true,
            renter: @0x0,
            rental_end_time: 0,
        };
        move_to(owner, listing);
    }

    /// Function to rent an item for specified number of days
    public fun rent_item(
        renter: &signer, 
        owner_address: address, 
        days: u64
    ) acquires RentalListing {
        let listing = borrow_global_mut<RentalListing>(owner_address);
        
        // Check if item is available
        assert!(listing.is_available, E_ITEM_NOT_AVAILABLE);
        
        // Calculate total payment required
        let total_payment = listing.daily_rate * days;
        
        // Transfer payment from renter to owner
        let payment = coin::withdraw<AptosCoin>(renter, total_payment);
        coin::deposit<AptosCoin>(owner_address, payment);
        
        // Update listing status
        listing.is_available = false;
        listing.renter = signer::address_of(renter);
        listing.rental_end_time = timestamp::now_seconds() + (days * 24 * 60 * 60);
    }
}