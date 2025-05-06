;; Due Diligence Contract
;; Manages verification of investment information

(define-data-var admin principal tx-sender)

;; Due diligence data structure
(define-map due-diligence-records
  { asset-id: uint, verifier: principal }
  {
    status: (string-utf8 20), ;; "pending", "approved", "rejected"
    verification-date: uint,
    comments: (string-utf8 500),
    documents-hash: (buff 32)
  }
)

;; Map to track authorized verifiers
(define-map authorized-verifiers principal bool)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-VERIFIER (err u101))
(define-constant ERR-RECORD-EXISTS (err u102))
(define-constant ERR-RECORD-NOT-FOUND (err u103))

;; Read-only function to get due diligence record
(define-read-only (get-due-diligence-record (asset-id uint) (verifier principal))
  (map-get? due-diligence-records {asset-id: asset-id, verifier: verifier})
)

;; Read-only function to check if a principal is an authorized verifier
(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false (map-get? authorized-verifiers verifier))
)

;; Function to add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-set authorized-verifiers verifier true)
    (ok true)
  )
)

;; Function to remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-delete authorized-verifiers verifier)
    (ok true)
  )
)

;; Function to submit due diligence
(define-public (submit-due-diligence
    (asset-id uint)
    (status (string-utf8 20))
    (comments (string-utf8 500))
    (documents-hash (buff 32)))
  (begin
    (asserts! (is-authorized-verifier tx-sender) ERR-NOT-VERIFIER)
    (asserts! (is-none (map-get? due-diligence-records {asset-id: asset-id, verifier: tx-sender})) ERR-RECORD-EXISTS)

    (map-set due-diligence-records
      {asset-id: asset-id, verifier: tx-sender}
      {
        status: status,
        verification-date: block-height,
        comments: comments,
        documents-hash: documents-hash
      }
    )
    (ok true)
  )
)

;; Function to update due diligence
(define-public (update-due-diligence
    (asset-id uint)
    (status (string-utf8 20))
    (comments (string-utf8 500))
    (documents-hash (buff 32)))
  (begin
    (asserts! (is-authorized-verifier tx-sender) ERR-NOT-VERIFIER)
    (asserts! (is-some (map-get? due-diligence-records {asset-id: asset-id, verifier: tx-sender})) ERR-RECORD-NOT-FOUND)

    (map-set due-diligence-records
      {asset-id: asset-id, verifier: tx-sender}
      {
        status: status,
        verification-date: block-height,
        comments: comments,
        documents-hash: documents-hash
      }
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
