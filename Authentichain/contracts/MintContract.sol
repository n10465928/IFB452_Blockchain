// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// OpenZeppelin ERC721 implementation with URI support per token
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IMaterialTracking
 * @dev Interface for interacting with the MaterialTrackingContract (ERC1155-based).
 *      Allows querying material data and consuming material tokens via burning.
 */
interface IMaterialTracking {
    function getMaterial(uint256 id) external view returns (
        string memory origin,
        string memory supplier,
        uint256 weight,
        string memory purity,
        string memory certHash
    );

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burnMaterialFrom(address from, uint256 id, uint256 amount) external;
}

/**
 * @title IOwnershipControl
 * @dev Interface to call registerInitialOwnership() from OwnershipControl
 */
interface IOwnershipControl {
    function registerInitialOwnership(uint256 tokenId, address owner) external;
}

/**
 * @title MintContract
 * @notice Mints unique ERC721 NFTs representing luxury goods made from traceable materials.
 * @dev - Each NFT is linked to material IDs (ERC1155) from MaterialTrackingContract.
 *      - Minting is permissioned and materials are burned on mint to enforce provenance.
 *      - Automatically registers initial ownership in OwnershipControl.
 */
contract MintContract is ERC721URIStorage, Ownable {
    /// Tracks the next available product token ID (incremented with each mint)
    uint256 private nextProductId = 1;

    /// Reference to the deployed MaterialTrackingContract
    IMaterialTracking public materialContract;

    /// Reference to the deployed OwnershipControl contract
    IOwnershipControl public ownershipControl;

    /// Maps product ID to the array of material token IDs used in its manufacture
    mapping(uint256 => uint256[]) public productToMaterials;

    /// Mapping of approved manufacturer addresses allowed to mint NFTs
    mapping(address => bool) public approvedManufacturers;

    // ========== EVENTS ==========

    /// Emitted when a new product NFT is minted
    event ProductMinted(
        uint256 indexed tokenId,
        address indexed to,
        string metadataURI
    );

    /// Emitted when material IDs are linked to a newly minted product
    event MaterialsConsumed(
        uint256 indexed tokenId,
        address indexed manufacturer,
        uint256[] materialIds
    );

    // ========== CONSTRUCTOR ==========

    /**
     * @notice Initializes the NFT with a name and symbol, and sets the material contract reference
     * @param _materialContract Address of the deployed MaterialTrackingContract
     */
    constructor(address _materialContract)
        ERC721("AuthentichainProduct", "AUTH-P")
        Ownable(msg.sender)
    {
        materialContract = IMaterialTracking(_materialContract);
    }

    // ========== ACCESS CONTROL ==========

    /**
     * @notice Approves or revokes a manufacturer to mint product NFTs
     * @dev Only the contract owner can update approvals (e.g., regulator)
     * @param manufacturer Address to grant or revoke minting permission
     * @param approved True to approve, false to revoke
     */
    function setManufacturerApproval(address manufacturer, bool approved) external onlyOwner {
        require(manufacturer != address(0), "Invalid manufacturer address");
        approvedManufacturers[manufacturer] = approved;
    }

    /**
     * @notice Sets the OwnershipControl contract used for auto-registering NFT ownership
     * @param _ownershipControl Address of deployed OwnershipControl contract
     */
    function setOwnershipControl(address _ownershipControl) external onlyOwner {
        require(_ownershipControl != address(0), "Invalid address");
        ownershipControl = IOwnershipControl(_ownershipControl);
    }

    // ========== MINTING ==========

    /**
     * @notice Mints a new luxury product NFT after verifying and consuming raw materials
     * @dev - Only approved manufacturers can mint
     *      - 1 unit of each material ID is burned from caller’s balance
     *      - NFT is minted to `to` address and metadata URI is stored
     * @param to Address to receive the new product NFT
     * @param materialIds Array of ERC1155 material token IDs used to build the product
     * @param metadataURI IPFS URI or HTTPS URL pointing to off-chain metadata JSON
     */
    function mintProduct(
        address to,
        uint256[] memory materialIds,
        string memory metadataURI
    ) external {
        require(approvedManufacturers[msg.sender], "Not an approved manufacturer");
        require(materialIds.length > 0, "At least one material is required");

        // Step 1: Validate the manufacturer owns all required materials
        for (uint256 i = 0; i < materialIds.length; i++) {
            uint256 balance = materialContract.balanceOf(msg.sender, materialIds[i]);
            require(balance > 0, "Missing required material token");
        }

        // Step 2: Burn 1 unit of each material to simulate physical consumption
        for (uint256 i = 0; i < materialIds.length; i++) {
            materialContract.burnMaterialFrom(msg.sender, materialIds[i], 1);
        }

        // Step 3: Mint the new NFT and assign metadata URI
        uint256 tokenId = nextProductId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);

        // Step 4: Register the first owner in OwnershipControl (optional integration)
        if (address(ownershipControl) != address(0)) {
            ownershipControl.registerInitialOwnership(tokenId, to);
        }

        // Step 5: Link the product to its source materials for traceability
        productToMaterials[tokenId] = materialIds;

        // Emit events for tracking in dApps or external indexers
        emit ProductMinted(tokenId, to, metadataURI);
        emit MaterialsConsumed(tokenId, msg.sender, materialIds);

        // Increment token ID counter for next mint
        nextProductId++;
    }

    // ========== VIEWS ==========

    /**
     * @notice Returns the raw materials linked to a product NFT
     * @param productId The ERC721 token ID of the product
     * @return Array of ERC1155 material token IDs used in minting
     */
    function getMaterialsForProduct(uint256 productId) external view returns (uint256[] memory) {
        return productToMaterials[productId];
    }

    /**
     * @notice Updates the reference to the MaterialTrackingContract (upgrade safe)
     * @dev Can only be called by the contract owner
     * @param newAddress Address of the new material contract
     */
    function updateMaterialContract(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid contract address");
        materialContract = IMaterialTracking(newAddress);
    }
}
