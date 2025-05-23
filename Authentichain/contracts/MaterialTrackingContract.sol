// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


// import to support older compiler
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/access/Ownable.sol";


/**
 * @title MaterialTrackingContract
 * @notice Tracks the provenance and lifecycle of raw materials using ERC1155 tokens.
 * @dev - Each material batch is tokenized as a semi-fungible asset.
 *      - Tokens can be consumed (burned) by authorized contracts (e.g., MintContract).
 *      - Off-chain metadata (origin, supplier, certs) is stored per token ID.
 *      - Provides full control to the system authority (Ownable).
 */
contract MaterialTrackingContract is ERC1155Burnable, Ownable {
    // Counter to assign unique IDs to new material batches
    uint256 public nextMaterialId = 1;

    // Struct containing material metadata for traceability and audit purposes
    struct Material {
        string origin;     // Geographic or facility origin (e.g., "Australia")
        string supplier;   // Certified supplier name or ID
        uint256 weight;    // Quantity in units (e.g., grams or kg)
        string purity;     // Grade, e.g., "99.99%"
        string certHash;   // IPFS or URL hash to certification docs
    }

    // Mapping of material token ID to its metadata
    mapping(uint256 => Material) public materials;

    // Approved external burner contracts (e.g., MintContract)
    mapping(address => bool) public authorizedBurners;

    // ========== EVENTS ==========

    event MaterialMinted(
        uint256 indexed materialId,
        string origin,
        string supplier,
        uint256 weight,
        string purity,
        string certHash,
        address indexed mintedTo
    );

    event MaterialBurned(
        uint256 indexed materialId,
        uint256 amount,
        address indexed burnedFrom,
        address indexed caller
    );

    event BurnerApprovalUpdated(
        address indexed burner,
        bool approved
    );

    // ========== CONSTRUCTOR ==========

    /**
     * @notice Initializes the contract with empty URI and sets msg.sender as system owner.
     * @dev ERC1155("") uses an empty base URI. Individual metadata is stored off-chain and indexed via ID.
     */
    //constructor() Ownable(msg.sender) ERC1155("") {}
    constructor() ERC1155("") {}


    // ========== CORE FUNCTIONALITY ==========

    /**
     * @notice Mints a new batch of material tokens to the owner
     * @dev Only the contract owner (e.g., regulator) can mint
     * @param origin Source location (e.g., country, mine, coordinates)
     * @param supplier Certified supplier name or code
     * @param weight Quantity of the material in units (used as token count)
     * @param purity Purity percentage or grade of the material
     * @param certHash IPFS or HTTPS hash pointing to certificate PDF or doc
     */
    function mintMaterial(
        string memory origin,
        string memory supplier,
        uint256 weight,
        string memory purity,
        string memory certHash
    ) public onlyOwner {
        require(weight > 0, "Weight must be greater than zero");

        uint256 materialId = nextMaterialId;

        // Register metadata for the new material token
        materials[materialId] = Material(origin, supplier, weight, purity, certHash);

        // Mint ERC1155 tokens (semi-fungible) to the contract owner
        _mint(msg.sender, materialId, weight, "");

        emit MaterialMinted(
            materialId, origin, supplier, weight, purity, certHash, msg.sender
        );

        nextMaterialId++;
    }

    /**
     * @notice Retrieves full traceability metadata for a material ID
     * @param id ERC1155 token ID
     * @return Material struct (origin, supplier, weight, purity, certHash)
     */
    function getMaterial(uint256 id) external view returns (Material memory) {
        return materials[id];
    } 

    /**
     * @notice Allows the owner to override the base URI if using dynamic metadata hosting
     * @dev Can be used if integrating with an IPFS gateway like Pinata or NFT.storage
     */
    function setBaseURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    // ========== BURN ACCESS CONTROL ==========

    /**
     * @notice Grants or revokes permission for a contract to burn material tokens
     * @dev Only the system owner (e.g., regulatory authority) can manage this list
     * @param burner Address of the external contract (e.g., MintContract)
     * @param approved True to authorize, false to revoke
     */
    function setBurnerApproval(address burner, bool approved) external onlyOwner {
        require(burner != address(0), "Cannot approve zero address");
        authorizedBurners[burner] = approved;

        emit BurnerApprovalUpdated(burner, approved);
    }

    /**
     * @notice Allows authorized contracts to burn material tokens from any holder
     * @dev Called by contracts like MintContract during product creation
     * @param from Address holding the tokens (typically a manufacturer)
     * @param id Token ID of the material batch
     * @param amount Number of tokens to burn (usually 1 per usage)
     */
    function burnMaterialFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(authorizedBurners[msg.sender], "Caller is not authorized to burn");
        require(from != address(0), "Cannot burn from zero address");

        _burn(from, id, amount);

        emit MaterialBurned(id, amount, from, msg.sender);
    }
}
