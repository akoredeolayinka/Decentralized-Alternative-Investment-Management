;; Investor Verification Contract
;; Validates accredited participants in the investment platform

(define-data-var admin principal tx-sender)

;; Map to store verified investors
(define-map verified-investors principal
  {
    is-verified: bool,
    verification-date: uint,
    verification-expiry: uint,
    investor-type: (string-utf8 20)
  }
)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-VERIFIED (err u101))
(define-constant ERR-NOT-VERIFIED (err u102))

;; Read-only function to check if an investor is verified
(define-read-only (is-investor-verified (investor principal))
  (default-to false (get is-verified (map-get? verified-investors investor)))
)

;; Read-only function to get investor details
(define-read-only (get-investor-details (investor principal))
  (map-get? verified-investors investor)
)

;; Function to verify an investor
(define-public (verify-investor
    (investor principal)
    (investor-type (string-utf8 20))
    (verification-period uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? verified-investors investor)) ERR-ALREADY-VERIFIED)

    (map-set verified-investors investor {
      is-verified: true,
      verification-date: block-height,
      verification-expiry: (+ block-height verification-period),
      investor-type: investor-type
    })
    (ok true)
  )
)

;; Function to revoke verification
(define-public (revoke-verification (investor principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? verified-investors investor)) ERR-NOT-VERIFIED)

    (map-delete verified-investors investor)
    (ok true)
  )
)

;; Function to update verification expiry
(define-public (extend-verification (investor principal) (new-expiry uint))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? verified-investors investor)) ERR-NOT-VERIFIED)

    (let ((investor-data (unwrap-panic (map-get? verified-investors investor))))
      (map-set verified-investors investor (merge investor-data {verification-expiry: new-expiry}))
    )
    (ok true)
  )
)

;; Admin functions
(define-read-only (is-admin (caller principal))
  (is-eq caller (var-get admin))
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)
