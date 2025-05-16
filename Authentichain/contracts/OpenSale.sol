// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title IMintContract
 * @dev Minimal ERC721 interface for transfers
 */
interface IMintContract {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title IOwnershipControl
 * @dev Interface to verify and update ownership on transfer
 */
interface IOwnershipControl {
    function transferProduct(uint256 tokenId, address newOwner) external;
    function verifiedOwner(uint256 tokenId) external view returns (address);
}

/**
 * @title OpenSale
 * @notice A fixed-price resale platform for luxury product NFTs.
 * @dev Integrates with MintContract (ERC721) and OwnershipControl for full traceability.
 */
contract OpenSale is Ownable, ReentrancyGuard {
    struct Listing {
        uint256 price;        // in wei
        address seller;
    }

    /// Token ID => Listing
    mapping(uint256 => Listing) public listings;

    IMintContract public mintContract;
    IOwnershipControl public ownershipControl;

    // ========== EVENTS ==========

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Purchased(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event Cancelled(uint256 indexed tokenId, address indexed seller);

    // ========== CONSTRUCTOR ==========

    constructor(address _mintContract, address _ownershipControl) Ownable(msg.sender) {
        require(_mintContract != address(0), "Invalid MintContract");
        require(_ownershipControl != address(0), "Invalid OwnershipControl");
        mintContract = IMintContract(_mintContract);
        ownershipControl = IOwnershipControl(_ownershipControl);
    }

    // ========== CORE FUNCTIONS ==========

    /**
     * @notice List a product NFT for sale
     * @param tokenId Token to list
     * @param price Price in wei
     */
    function listForSale(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(
            ownershipControl.verifiedOwner(tokenId) == msg.sender,
            "Only the verified owner can list"
        );

        listings[tokenId] = Listing(price, msg.sender);
        emit Listed(tokenId, msg.sender, price);
    }

    /**
     * @notice Purchase a listed product NFT
     * @param tokenId Token to purchase
     */
    function purchase(uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "Token not listed");
        require(msg.value == listing.price, "Incorrect payment amount");

        // Remove listing before transfer to prevent reentrancy
        delete listings[tokenId];

        // Transfer payment to seller
        payable(listing.seller).transfer(msg.value);

        // Transfer NFT and update verified ownership
        ownershipControl.transferProduct(tokenId, msg.sender);

        emit Purchased(tokenId, msg.sender, listing.price);
    }

    /**
     * @notice Cancel an active listing
     * @param tokenId Token to cancel
     */
    function cancelListing(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "You are not the seller");
        delete listings[tokenId];
        emit Cancelled(tokenId, msg.sender);
    }

    // ========== VIEWS ==========

    /**
     * @notice Get listing details
     * @param tokenId Token to query
     * @return Listing struct (price and seller)
     */
    function getListing(uint256 tokenId) external view returns (Listing memory) {
        return listings[tokenId];
    }
}

// === OPTIONAL EXTENSION #1: Listing Expiration ===
// Add a 'uint256 expiresAt' to Listing struct.
// In purchase(), check: require(block.timestamp <= listing.expiresAt, "Listing expired").
// Add optional input to listForSale(..., uint256 durationSeconds).

// === OPTIONAL EXTENSION #2: Resale Royalties ===
// Add 'uint256 royaltyPercentage' (e.g., 500 = 5%).
// Store manufacturer address per product ID in MintContract.
// In purchase(), calculate royalty = (msg.value * royaltyPercentage) / 10000.
// Transfer royalty to manufacturer, and the rest to seller.
