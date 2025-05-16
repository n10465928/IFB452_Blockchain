// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// OpenZeppelin Ownable provides role-based access for the contract owner (e.g., regulator)
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IMintContract
 * @dev Minimal interface to interact with MintContract (ERC721) from OwnershipControl.
 *      Enables token ownership lookup and safe transfer execution.
 */
interface IMintContract {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title OwnershipControl
 * @notice Tracks full ownership history and controls verified transfers of NFTs representing physical goods.
 * @dev - Automatically registers ownership on mint (via MintContract call).
 *      - Only verified owners can initiate a transfer.
 *      - Optionally restricts recipients via allowlist.
 *      - Logs all ownership changes immutably on-chain.
 */
contract OwnershipControl is Ownable {
    // ========== STATE VARIABLES ==========

    /// Reference to the MintContract (implements ERC721)
    IMintContract public mintContract;

    /// Separate address verification to allow strict internal access control (for registerInitialOwnership)
    address public mintContractAddress;

    /// Mapping of token ID to its current verified owner
    mapping(uint256 => address) public verifiedOwner;

    /// Mapping of token ID to a complete chronological list of previous and current owners
    mapping(uint256 => address[]) public ownershipHistory;

    /// Optional allowlist to restrict who is eligible to receive token ownership
    mapping(address => bool) public approvedRecipients;

    // ========== EVENTS ==========

    /// Emitted when a token is first assigned to an owner
    event OwnershipRegistered(uint256 indexed tokenId, address indexed owner);

    /// Emitted on every ownership transfer via OwnershipControl
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to);

    /// Emitted when recipient allowlist status is updated
    event RecipientApprovalUpdated(address indexed recipient, bool approved);

    /// Emitted when the MintContract reference is updated
    event MintContractUpdated(address indexed newContract);

    /// Emitted when the internal MintContract address used for registration is set
    event MintContractAddressSet(address indexed mintContractAddress);

    // ========== CONSTRUCTOR ==========

    /**
     * @notice Initializes the OwnershipControl with a reference to the MintContract.
     * @dev The deployer becomes the system owner and must later assign mintContractAddress for registration.
     * @param _mintContract Address of the deployed MintContract (ERC721-compliant)
     */
    constructor(address _mintContract) Ownable(msg.sender) {
        require(_mintContract != address(0), "Invalid MintContract address");
        mintContract = IMintContract(_mintContract);
    }

    // ========== MODIFIERS ==========

    /**
     * @notice Ensures only the linked MintContract can call a sensitive function
     */
    modifier onlyMintContract() {
        require(msg.sender == mintContractAddress, "Caller is not the MintContract");
        _;
    }

    // ========== CORE FUNCTIONS ==========

    /**
     * @notice Allows the system owner to set the internal mintContractAddress used for registerInitialOwnership()
     * @dev This is separate from the mintContract interface so upgrades remain clean
     * @param _mintContract Address of the trusted MintContract
     */
    function setMintContractAddress(address _mintContract) external onlyOwner {
        require(_mintContract != address(0), "Invalid address");
        mintContractAddress = _mintContract;

        emit MintContractAddressSet(_mintContract);
    }

    /**
     * @notice Registers the first verified owner of a token after it is minted
     * @dev Only callable by MintContract. Can only be called once per token.
     * @param tokenId ERC721 token ID
     * @param owner Address of the first verified owner (recipient of mint)
     */
    function registerInitialOwnership(uint256 tokenId, address owner) external onlyMintContract {
        require(owner != address(0), "Owner cannot be zero address");
        require(verifiedOwner[tokenId] == address(0), "Token already has a verified owner");

        verifiedOwner[tokenId] = owner;
        ownershipHistory[tokenId].push(owner);

        emit OwnershipRegistered(tokenId, owner);
    }

    /**
     * @notice Transfers a product token to a new owner with full audit trail
     * @dev Caller must be the current verified owner. MintContract executes the transfer.
     * @param tokenId ERC721 token ID to transfer
     * @param newOwner New recipient address
     */
    function transferProduct(uint256 tokenId, address newOwner) external {
        address currentOwner = verifiedOwner[tokenId];
        require(currentOwner != address(0), "Token has no verified owner");
        require(msg.sender == currentOwner, "Caller is not the verified owner");
        require(newOwner != address(0), "New owner cannot be zero address");

        // Optional allowlist enforcement
        // require(approvedRecipients[newOwner], "Recipient not approved");

        // Transfer ownership via MintContract
        mintContract.safeTransferFrom(currentOwner, newOwner, tokenId);

        // Update internal verified owner and ownership history
        verifiedOwner[tokenId] = newOwner;
        ownershipHistory[tokenId].push(newOwner);

        emit OwnershipTransferred(tokenId, currentOwner, newOwner);
    }

    // ========== VIEWS ==========

    /**
     * @notice Returns the full history of ownership for a given token
     * @param tokenId Token to query
     * @return Array of historical owners in chronological order
     */
    function getOwnershipHistory(uint256 tokenId) external view returns (address[] memory) {
        return ownershipHistory[tokenId];
    }

    // ========== ADMIN FUNCTIONS ==========

    /**
     * @notice Grants or revokes approval for a specific recipient address
     * @dev Can be used to enforce whitelisting for transfers or resales
     * @param recipient The address to update
     * @param approved True to allow ownership, false to disallow
     */
    function setRecipientApproval(address recipient, bool approved) external onlyOwner {
        require(recipient != address(0), "Cannot approve zero address");
        approvedRecipients[recipient] = approved;

        emit RecipientApprovalUpdated(recipient, approved);
    }

    /**
     * @notice Updates the MintContract reference (interface)
     * @dev Used if the MintContract is upgraded and needs to be re-linked
     * @param newContract Address of the new ERC721 contract
     */
    function updateMintContract(address newContract) external onlyOwner {
        require(newContract != address(0), "Invalid contract address");
        mintContract = IMintContract(newContract);

        emit MintContractUpdated(newContract);
    }
}
