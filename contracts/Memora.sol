// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MemoraNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address immutable _judge;

    uint256 _BUFFER_PERIOD = 5 minutes; // 5 minutes buffer

    enum AccountAction {
        MANAGE_ACCOUNT,
        CLOSE_ACCOUNT
    }

    struct TokenInfo {
        address judge;
        address heir;
        bool isTriggerDeclared;
        bool isHeirSigned;
        address minter;
        string prompt;
        AccountAction actions;
        uint256 triggerTimestamp; // New field to store the trigger timestamp
    }

    struct MinterData {
        uint256 tokenId;
        address minter;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;
    MinterData[] private minterInfo;
    mapping(address => bool) private isMinter;

    event JudgeDeclaredTriggered(uint256 indexed tokenId);
    event HeirSigned(uint256 indexed tokenId);
    event NFTInherited(uint256 indexed tokenId, address indexed heir);
    event TriggerDisabled(uint256 indexed tokenId);
    event BufferChanged(uint256 indexed bufferPeriod);

    constructor(
        string memory name,
        string memory symbol,
        address _Judge
    ) ERC721(name, symbol) Ownable() {
        _judge = _Judge;
    }

    function mint(
        address heir,
        uint256 choice,
        string memory prompt,
        string memory tokenURI
    ) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        AccountAction actions;

        if (choice == 0) {
            actions = AccountAction.MANAGE_ACCOUNT;
        } else {
            actions = AccountAction.CLOSE_ACCOUNT;
        }

        // Store token information
        tokenInfo[newTokenId] = TokenInfo({
            judge: _judge,
            heir: heir,
            isTriggerDeclared: false,
            isHeirSigned: false,
            minter: msg.sender,
            prompt: prompt,
            actions: actions,
            triggerTimestamp: 0 // Set default value to 0
        });

        // Store the minter information
        minterInfo.push(MinterData({tokenId: newTokenId, minter: msg.sender}));

        isMinter[msg.sender] = true;

        return newTokenId;
    }

    function declareTrigger(uint256 tokenId) public {
        require(
            msg.sender == tokenInfo[tokenId].judge,
            "Only the judge can declare trigger"
        );
        require(
            !tokenInfo[tokenId].isTriggerDeclared,
            "Already declared triggered"
        );

        // Set trigger as declared and store the timestamp
        tokenInfo[tokenId].isTriggerDeclared = true;
        tokenInfo[tokenId].triggerTimestamp = block.timestamp; // Store the timestamp
        emit JudgeDeclaredTriggered(tokenId);
        (tokenId);
    }

    function heirSign(uint256 tokenId) public {
        require(
            msg.sender == tokenInfo[tokenId].heir,
            "Only the heir can sign"
        );
        require(
            tokenInfo[tokenId].isTriggerDeclared,
            "Judge hasn't declared triggered yet"
        );
        require(!tokenInfo[tokenId].isHeirSigned, "Heir has already signed");
        require(
            block.timestamp >=
                tokenInfo[tokenId].triggerTimestamp + _BUFFER_PERIOD,
            "Buffer period has not passed yet" // Check if 5 minutes have passed
        );

        tokenInfo[tokenId].isHeirSigned = true;
        emit HeirSigned(tokenId);

        if (
            tokenInfo[tokenId].isTriggerDeclared &&
            tokenInfo[tokenId].isHeirSigned &&
            (tokenInfo[tokenId].actions == AccountAction.MANAGE_ACCOUNT)
        ) {
            address heir = tokenInfo[tokenId].heir;
            _transfer(ownerOf(tokenId), heir, tokenId);
            emit NFTInherited(tokenId, heir);
        } else if (
            tokenInfo[tokenId].isTriggerDeclared &&
            tokenInfo[tokenId].isHeirSigned &&
            (tokenInfo[tokenId].actions == AccountAction.CLOSE_ACCOUNT)
        ) {
            _burn(tokenId);
            minterInfo[tokenId] = MinterData({tokenId: 0, minter: msg.sender});
        }
    }

    function getAllMinters() public view returns (MinterData[] memory) {
        return minterInfo;
    }

    function getTriggeredNFTsForHeir(address heir)
        public
        view
        returns (uint256[] memory)
    {
        uint256 triggeredCount = 0;

        // First, count how many NFTs are triggered for this heir
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (
                tokenInfo[i + 1].heir == heir &&
                tokenInfo[i + 1].isTriggerDeclared &&
                !tokenInfo[i + 1].isHeirSigned
            ) {
                triggeredCount++;
            }
        }

        // Create an array with the correct size
        uint256[] memory triggeredTokens = new uint256[](triggeredCount);
        uint256 index = 0;

        // Populate the array with the triggered token IDs
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (
                tokenInfo[i + 1].heir == heir &&
                tokenInfo[i + 1].isTriggerDeclared &&
                !tokenInfo[i + 1].isHeirSigned
            ) {
                triggeredTokens[index] = i + 1;
                index++;
            }
        }

        return triggeredTokens;
    }

    function disableTrigger(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the token owner can disable the trigger"
        );
        require(
            tokenInfo[tokenId].isTriggerDeclared,
            "Trigger has not been declared yet"
        );
        require(!tokenInfo[tokenId].isHeirSigned, "Heir has already signed");

        // Revert the trigger declaration
        tokenInfo[tokenId].isTriggerDeclared = false;
        tokenInfo[tokenId].triggerTimestamp = 0;

        emit TriggerDisabled(tokenId);
    }

    function changeBuffer(uint256 _buffer_period) public onlyOwner {
        _BUFFER_PERIOD = _buffer_period;

        emit BufferChanged(_buffer_period);
    }

    function getNFTsMintedByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 mintedCount = 0;

        // First, count how many NFTs were minted by this owner
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (tokenInfo[i + 1].minter == owner) {
                mintedCount++;
            }
        }

        // Create an array with the correct size
        uint256[] memory mintedTokens = new uint256[](mintedCount);
        uint256 index = 0;

        // Populate the array with the token IDs minted by this owner
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            if (tokenInfo[i + 1].minter == owner) {
                mintedTokens[index] = i + 1;
                index++;
            }
        }

        return mintedTokens;
    }
}
