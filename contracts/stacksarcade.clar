;; game-items-contract
;; handles in-game item purchases, ownership, trading and rentals

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

;; Enhanced Rental Functions
(define-public (set-rental-price (item-id uint) (price uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        
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
        (rental-cost (unwrap! (get rental-price item) ERR_INVALID_RENTAL))
        (current-height block-height)
    )
    (begin
        (asserts! (is-eq tx-sender (get owner item)) ERR_UNAUTHORIZED)
        (asserts! (is-none (get rented-to item)) ERR_ITEM_RENTED)
        (asserts! (> duration u0) ERR_INVALID_RENTAL)
        
        ;; Transfer rental payment
        (try! (stx-transfer? rental-cost renter (get owner item)))

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

(define-public (extend-rental (item-id uint) (additional-duration uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
        (rental-cost (unwrap! (get rental-price item) ERR_INVALID_RENTAL))
        (current-renter (unwrap! (get rented-to item) ERR_RENTAL_NOT_ACTIVE))
    )
    (begin
        (asserts! (is-eq tx-sender current-renter) ERR_UNAUTHORIZED)
        (asserts! (> additional-duration u0) ERR_INVALID_EXTENSION)
        
        ;; Transfer additional rental payment
        (try! (stx-transfer? rental-cost current-renter (get owner item)))

        (map-set items item-id
            (merge item {
                rental-end-height: (some (+ 
                    (unwrap! (get rental-end-height item) ERR_INVALID_RENTAL)
                    additional-duration
                ))
            })
        )
        (ok true)
    ))
)

(define-public (end-rental (item-id uint))
    (let (
        (item (unwrap! (map-get? items item-id) ERR_ITEM_NOT_FOUND))
        (end-height (unwrap! (get rental-end-height item) ERR_RENTAL_NOT_ACTIVE))
    )
    (begin
        (asserts! (or 
            (is-eq tx-sender (get owner item))
            (>= block-height end-height)
        ) ERR_UNAUTHORIZED)
        
        (map-set items item-id
            (merge item {
                rented-to: none,
                rental-end-height: none,
                for-sale: false,
                for-trade: false
            })
        )
        (ok true)
    ))
)
