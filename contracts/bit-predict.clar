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