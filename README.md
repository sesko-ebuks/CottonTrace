# CottonTrace

A supply chain tracking smart contract for cotton farming and fair trade verification built on the Stacks blockchain using Clarity.

## Overview

CottonTrace enables transparent tracking of cotton from farm to consumer, ensuring fair trade practices and supply chain integrity. The contract provides a comprehensive system for registering farms, tracking cotton batches throughout the supply chain, managing certifications, and maintaining an immutable record of all supply chain events.

## Features

- **Farm Registration**: Register cotton farms with location, certification levels, and ownership details
- **Cotton Batch Tracking**: Track individual cotton batches from harvest through processing and delivery
- **Supply Chain Events**: Record detailed events throughout the cotton supply chain journey
- **Fair Trade Certification**: Issue, manage, and verify fair trade certifications for farms
- **Transparency**: Immutable record of all transactions and events on the blockchain
- **Status Management**: Real-time tracking of batch status (harvested, processed, shipped, delivered)
- **Quality Grading**: Track cotton quality grades and certification status

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Testing Framework**: Vitest with Clarinet SDK

### Contract Architecture

The contract uses several data structures:

- **Farms**: Store farm registration details and certification levels
- **Cotton Batches**: Track individual cotton lots with quantity, quality, and status
- **Supply Chain Events**: Record all events in the cotton's journey
- **Certifications**: Manage fair trade and other certifications
- **Event Counters**: Track the number of events per batch

## Installation

### Prerequisites

- Node.js (v16 or higher)
- Clarinet CLI
- Stacks CLI (optional)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CottonTrace
```

2. Install dependencies:
```bash
cd CottonTrace_contract
npm install
```

3. Run tests:
```bash
npm test
```

4. Watch for changes during development:
```bash
npm run test:watch
```

## Usage Examples

### Register a Farm

```clarity
(contract-call? .CottonTrace register-farm
    "Green Valley Farm"
    "Texas, USA"
    "Organic Certified")
```

### Register a Cotton Batch

```clarity
(contract-call? .CottonTrace register-cotton-batch
    u1          ;; farm-id
    u1000       ;; quantity in kg
    "Grade A"   ;; quality grade
    "Organic")  ;; certification status
```

### Add Supply Chain Event

```clarity
(contract-call? .CottonTrace add-supply-chain-event
    u1                    ;; batch-id
    "processed"           ;; event type
    "Processing Plant 1"  ;; location
    "Cotton ginned and baled") ;; notes
```

### Issue Certification

```clarity
(contract-call? .CottonTrace issue-certification
    u1                  ;; farm-id
    "Fair Trade"        ;; certification type
    u144000)            ;; expiry block height
```

## Contract Functions

### Public Functions

#### Farm Management
- `register-farm(name, location, certification-level)` - Register a new cotton farm
- Parameters:
  - `name`: Farm name (string-ascii 100)
  - `location`: Farm location (string-ascii 200)
  - `certification-level`: Certification level (string-ascii 50)
- Returns: Farm ID on success

#### Batch Management
- `register-cotton-batch(farm-id, quantity-kg, quality-grade, certification-status)` - Register a new cotton batch
- Parameters:
  - `farm-id`: ID of the farm (uint)
  - `quantity-kg`: Quantity in kilograms (uint)
  - `quality-grade`: Quality grade (string-ascii 20)
  - `certification-status`: Certification status (string-ascii 50)
- Returns: Batch ID on success

#### Supply Chain Tracking
- `add-supply-chain-event(batch-id, event-type, location, notes)` - Add a supply chain event
- Parameters:
  - `batch-id`: ID of the cotton batch (uint)
  - `event-type`: Type of event (string-ascii 50)
  - `location`: Location of event (string-ascii 200)
  - `notes`: Additional notes (string-ascii 500)
- Returns: Event ID on success

#### Certification Management
- `issue-certification(farm-id, cert-type, expiry-date)` - Issue a new certification
- `revoke-certification(cert-id)` - Revoke an existing certification

### Read-Only Functions

- `get-farm(farm-id)` - Get farm details
- `get-cotton-batch(batch-id)` - Get cotton batch details
- `get-supply-chain-event(batch-id, event-id)` - Get specific supply chain event
- `get-batch-event-count(batch-id)` - Get number of events for a batch
- `get-certification(cert-id)` - Get certification details
- `get-next-batch-id()` - Get next available batch ID
- `get-next-farm-id()` - Get next available farm ID
- `get-next-cert-id()` - Get next available certification ID
- `is-farm-certified(farm-id, cert-type)` - Check if farm has specific certification
- `get-batch-history-count(batch-id)` - Get count of supply chain events for a batch

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contract CottonTrace ./contracts/CottonTrace.clar
```

### Testnet Deployment

1. Configure your Clarinet.toml file with testnet settings
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Ensure thorough testing on testnet
2. Configure mainnet settings in Clarinet.toml
3. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Error Codes

The contract defines the following error codes:

- `ERR_UNAUTHORIZED (u100)` - Caller is not authorized for this operation
- `ERR_NOT_FOUND (u101)` - Requested resource does not exist
- `ERR_ALREADY_EXISTS (u102)` - Resource already exists
- `ERR_INVALID_STATUS (u103)` - Invalid status for the operation
- `ERR_INVALID_PARAMS (u104)` - Invalid parameters provided

## Security Notes

### Access Control
- Farm registration is open to any principal
- Only farm owners can register batches for their farms
- Supply chain events can be added by any authorized handler
- Only certification issuers can revoke their own certifications

### Data Integrity
- All data is stored immutably on the blockchain
- Event timestamps use block height for consistency
- Batch status updates are automatic based on event types
- Input validation prevents empty or invalid data

### Best Practices
- Always verify farm existence before registering batches
- Use meaningful event types for supply chain tracking
- Set appropriate expiry dates for certifications
- Implement proper access controls in your application layer

## Testing

The project includes a test suite using Vitest and the Clarinet SDK. Tests cover:

- Contract initialization
- Farm registration functionality
- Cotton batch creation and tracking
- Supply chain event recording
- Certification management
- Error handling

Run tests with:
```bash
npm test
```

Generate coverage reports:
```bash
npm run test:report
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the ISC License.