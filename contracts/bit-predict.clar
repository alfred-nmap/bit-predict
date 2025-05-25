;; Title: BitPredict - Decentralized Price Prediction Markets on Stacks
;; Summary: A trustless prediction market protocol enabling Bitcoin-backed price forecasting
;; Description: BitPredict harnesses Bitcoin's security through Stacks Layer 2 to create
;;              decentralized prediction markets. Users stake STX tokens to predict asset
;;              price movements, with oracle-verified outcomes and automated reward
;;              distribution. Features include multi-market support, proportional payouts,
;;              anti-manipulation safeguards, and transparent fee structures optimized
;;              for Bitcoin's monetary sovereignty and Stacks' smart contract capabilities.

;; CONSTANTS & CONFIGURATION

;; Administrative Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))

;; Error Constants - Comprehensive Error Handling
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PREDICTION (err u102))
(define-constant ERR_MARKET_CLOSED (err u103))
(define-constant ERR_ALREADY_CLAIMED (err u104))
(define-constant ERR_INSUFFICIENT_BALANCE (err u105))
(define-constant ERR_INVALID_PARAMETER (err u106))

;; STATE VARIABLES - PLATFORM CONFIGURATION

;; Oracle Management - Trusted Price Feed Source
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Economic Parameters
(define-data-var minimum-stake uint u1000000) ;; 1 STX (1,000,000 microSTX) minimum
(define-data-var fee-percentage uint u2) ;; 2% platform sustainability fee
(define-data-var market-counter uint u0) ;; Global market identifier tracker

;; DATA STRUCTURES - MARKET & USER STATE

;; Market State - Core Market Information
(define-map markets
  uint
  {
    start-price: uint, ;; Initial asset price at market creation
    end-price: uint, ;; Final settlement price (0 until resolved)
    total-up-stake: uint, ;; Total STX staked on price increase
    total-down-stake: uint, ;; Total STX staked on price decrease
    start-block: uint, ;; Block height when predictions open
    end-block: uint, ;; Block height when market closes
    resolved: bool, ;; Settlement status flag
  }
)

;; User Position Tracking - Individual Prediction Records
(define-map user-predictions
  {
    market-id: uint,
    user: principal,
  }
  {
    prediction: (string-ascii 4), ;; "up" or "down" position
    stake: uint, ;; STX amount wagered
    claimed: bool, ;; Payout claim status
  }
)

;; CORE MARKET FUNCTIONS

;; Market Creation - Initialize New Prediction Market
;; Creates a time-bounded prediction market with specified parameters
;; Only callable by contract owner to ensure market integrity
(define-public (create-market
    (start-price uint)
    (start-block uint)
    (end-block uint)
  )
  (let ((market-id (var-get market-counter)))
    ;; Access Control & Parameter Validation
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (> end-block start-block) ERR_INVALID_PARAMETER)
    (asserts! (> start-price u0) ERR_INVALID_PARAMETER)
    ;; Initialize Market State
    (map-set markets market-id {
      start-price: start-price,
      end-price: u0,
      total-up-stake: u0,
      total-down-stake: u0,
      start-block: start-block,
      end-block: end-block,
      resolved: false,
    })
    ;; Increment Global Counter
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Prediction Placement - Stake STX on Price Direction
;; Allows users to stake STX tokens on predicted price movement
;; Enforces timing constraints and minimum stake requirements
(define-public (make-prediction
    (market-id uint)
    (prediction (string-ascii 4))
    (stake uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR_NOT_FOUND))
      (current-block stacks-block-height)
    )
    ;; Market Timing Validation
    (asserts!
      (and
        (>= current-block (get start-block market))
        (< current-block (get end-block market))
      )
      ERR_MARKET_CLOSED
    )
    ;; Prediction & Stake Validation
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down"))
      ERR_INVALID_PREDICTION
    )
    (asserts! (>= stake (var-get minimum-stake)) ERR_INVALID_PREDICTION)
    (asserts! (<= stake (stx-get-balance tx-sender)) ERR_INSUFFICIENT_BALANCE)
    ;; Transfer Stake to Contract Custody
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    ;; Record User Position
    (map-set user-predictions {
      market-id: market-id,
      user: tx-sender,
    } {
      prediction: prediction,
      stake: stake,
      claimed: false,
    })
    ;; Update Market Totals
    (map-set markets market-id
      (merge market {
        total-up-stake: (if (is-eq prediction "up")
          (+ (get total-up-stake market) stake)
          (get total-up-stake market)
        ),
        total-down-stake: (if (is-eq prediction "down")
          (+ (get total-down-stake market) stake)
          (get total-down-stake market)
        ),
      })
    )
    (ok true)
  )
)