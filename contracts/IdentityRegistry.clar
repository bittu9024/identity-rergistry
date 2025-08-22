
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-identity-exists (err u101))
(define-constant err-identity-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-data (err u104))

;; Identity structure
(define-map identities 
  principal 
  {
    name: (string-ascii 50),
    verification-status: bool,
    timestamp: uint,
    metadata-hash: (string-ascii 64)
  })

;; Track verified identities count
(define-data-var total-verified-identities uint u0)

;; Function 1: Register Identity
;; Allows users to register their identity with basic information
(define-public (register-identity (name (string-ascii 50)) (metadata-hash (string-ascii 64)))
  (let ((existing-identity (map-get? identities tx-sender)))
    (begin
      ;; Check if identity already exists
      (asserts! (is-none existing-identity) err-identity-exists)
      
      ;; Validate input data
      (asserts! (> (len name) u0) err-invalid-data)
      (asserts! (> (len metadata-hash) u0) err-invalid-data)
      
      ;; Register the identity with unverified status
      (map-set identities tx-sender {
        name: name,
        verification-status: false,
        timestamp: block-height,
        metadata-hash: metadata-hash
      })
      
      (print {
        action: "identity-registered",
        user: tx-sender,
        name: name,
        timestamp: block-height
      })
      
      (ok true))))

;; Function 2: Verify Identity
;; Allows contract owner to verify registered identities
(define-public (verify-identity (user principal))
  (let ((identity-data (map-get? identities user)))
    (begin
      ;; Only contract owner can verify identities
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      
      ;; Check if identity exists
      (asserts! (is-some identity-data) err-identity-not-found)
      
      ;; Update identity with verified status
      (match identity-data
        current-data
        (begin
          (map-set identities user (merge current-data {verification-status: true}))
          (var-set total-verified-identities (+ (var-get total-verified-identities) u1))
          
          (print {
            action: "identity-verified",
            user: user,
            verifier: tx-sender,
            timestamp: block-height
          })
          
          (ok true))
        (err err-identity-not-found)))))

;; Read-only function to get identity information
(define-read-only (get-identity (user principal))
  (ok (map-get? identities user)))

;; Read-only function to check if identity is verified
(define-read-only (is-verified (user principal))
  (match (map-get? identities user)
    identity-data (ok (get verification-status identity-data))
    (ok false)))

;; Read-only function to get total verified identities
(define-read-only (get-total-verified)
  (ok (var-get total-verified-identities)))