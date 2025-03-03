;; game-items-contract
;; handles in-game item purchases, ownership, trading and rentals

;; Constants
(define-constant MAX_RENTAL_DURATION u5000)
(define-constant MIN_RENTAL_PRICE u1000000)
(define-constant PLATFORM_FEE_PERCENT u5)
(define-constant PLATFORM_ADDRESS 'SP000000000000000000002Q6VF78)

;; Error codes
(define-constant ERR_INSUFFICIENT_BALANCE (err u100))
(define-constant ERR_ITEM_NOT_FOUND (err u101)) 
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_ITEM_NOT_FOR_SALE (err u103))
(define-constant ERR_ITEM_NOT_FOR_TRADE (err u104))
(define-constant ERR_INVALID_TRADE (err u105))
(define-constant ERR_ITEM_RENTED (err u106))
(define-constant ERR_RENTAL_EXPIRED (err u107))
(define-constant ERR_INVALID_RENTAL (err u108))
(define-constant ERR_RENTAL_NOT_ACTIVE (err u109))
(define-constant ERR_INVALID_EXTENSION (err u110))
(define-constant ERR_INVALID_PRICE (err u111))
(define-constant ERR_INVALID_DURATION (err u112))

;; Data maps
(define-map items 
    uint ;; item-id
    {
        name: (string-ascii 50),
        price: uint,
        for-sale: bool,
        for-trade: bool,
        owner: principal,
        rented-to: (optional principal),
        rental-end-height: (optional uint),
        rental-price: (optional uint),
        rental-history: (list 10 {
            renter: principal,
            start-height: uint,
            end-height: uint
        })
    }
)

;; Read-only functions
(define-read-only (is-item-available-for-rent (item-id uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (and 
        (is-some (get rental-price item))
        (is-none (get rented-to item))
    ))
)

(define-read-only (calculate-rental-fee (price uint) (duration uint))
    (let (
        (base-fee (* price duration))
        (platform-fee (/ (* base-fee PLATFORM_FEE_PERCENT) u100))
    )
    {
        total-fee: base-fee,
        platform-fee: platform-fee,
        owner-fee: (- base-fee platform-fee)
    })
)

;; Enhanced Rental Functions
(define-public (set-rental-price (item-id uint) (price uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        (asserts! (>= price MIN_RENTAL_PRICE) ERR_INVALID_PRICE)
        
        (map-set items item-id
            (merge item {
                rental-price: (some price)
            })
        )
        (ok true)
    ))
)

(define-public (rent-item (item-id uint) (renter principal) (duration uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
        (rental-price (unwrap! (get rental-price item) ERR_INVALID_RENTAL))
        (current-height block-height)
        (fees (calculate-rental-fee rental-price duration))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        (asserts! (and (> duration u0) (<= duration MAX_RENTAL_DURATION)) ERR_INVALID_DURATION)
        
        ;; Transfer rental payments
        (try! (stx-transfer? (get platform-fee fees) renter PLATFORM_ADDRESS))
        (try! (stx-transfer? (get owner-fee fees) renter (get owner item)))

        (map-set items item-id
            (merge item {
                rented-to: (some renter),
                rental-end-height: (some (+ current-height duration)),
                for-sale: false,
                for-trade: false,
                rental-history: (unwrap-panic (as-max-len? 
                    (append (get rental-history item) 
                        {
                            renter: renter,
                            start-height: current-height,
                            end-height: (+ current-height duration)
                        }
                    )
                    u10))
            })
        )
        (ok true)
    ))
)

[... rest of the original contract functions ...]
