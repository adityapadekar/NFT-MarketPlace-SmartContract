// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Errors
error NFTMarketPlace__PriceMustBeAboveZero();
error NFTMarketPlace__NotApprovedForMarketPlace();
error NFTMarketPlace__AlreadyListed(address nftAddress, uint256 tokenId);
error NFTMarketPlace__NotOwner();
error NFTMarketPlace__NotListed(address nftAddress, uint256 tokenId);
error NFTMarketPlace__PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price
);
error NFTMarketPlace__NoProceeds();
error NFTMarketPlace__WithdrawFailed();

contract NFTMarketPlace {
    // types
    struct Listing {
        uint256 price;
        address seller;
    }

    // events
    event itemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // events
    event itemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // events
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // NFT contract address -> NFT tokenId -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // Seller Address -> Amount earned
    mapping(address => uint256) private s_proceeds;

    // modifiers
    modifier notListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];

        if (listing.price > 0)
            revert NFTMarketPlace__AlreadyListed(_nftAddress, _tokenId);

        _;
    }

    modifier isListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];

        if (listing.price <= 0)
            revert NFTMarketPlace__NotListed(_nftAddress, _tokenId);

        _;
    }

    modifier isOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _spender
    ) {
        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_tokenId);

        if (_spender != owner) revert NFTMarketPlace__NotOwner();

        _;
    }

    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    )
        external
        notListed(_nftAddress, _tokenId, msg.sender)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_price <= 0) revert NFTMarketPlace__PriceMustBeAboveZero();

        IERC721 nft = IERC721(_nftAddress);

        if (nft.getApproved(_tokenId) != address(this))
            revert NFTMarketPlace__NotApprovedForMarketPlace();

        s_listings[_nftAddress][_tokenId] = Listing(_price, msg.sender);

        emit itemListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    function buyItem(
        address _nftAddress,
        uint256 _tokenId
    ) external payable isListed(_nftAddress, _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (msg.value != listing.price)
            revert NFTMarketPlace__PriceNotMet(
                _nftAddress,
                _tokenId,
                listing.price
            );

        s_proceeds[listing.seller] += msg.value;

        delete (s_listings[_nftAddress][_tokenId]);

        IERC721(_nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            _tokenId
        );

        emit itemBought(msg.sender, _nftAddress, _tokenId, listing.price);
    }

    function cancelListing(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        isOwner(_nftAddress, _tokenId, msg.sender)
        isListed(_nftAddress, _tokenId)
    {
        delete s_listings[_nftAddress][_tokenId];

        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isOwner(_nftAddress, _tokenId, msg.sender)
        isListed(_nftAddress, _tokenId)
    {
        s_listings[_nftAddress][_tokenId].price = _newPrice;

        emit itemListed(msg.sender, _nftAddress, _tokenId, _newPrice);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];

        if (proceeds <= 0) revert NFTMarketPlace__NoProceeds();

        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceeds}("");

        if (!success) revert NFTMarketPlace__WithdrawFailed();
    }

    function getListing(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (Listing memory) {
        return s_listings[_nftAddress][_tokenId];
    }

    function getProceeds(address _seller) external view returns (uint256) {
        return s_proceeds[_seller];
    }
}
