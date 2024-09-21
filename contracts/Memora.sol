// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MemoraNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address immutable _judge;

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
    }

    struct MinterData {
        uint tokenId;
        address minter;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;
    MinterData[] private minterInfo;
    mapping(address => bool) private isMinter;

    event JudgeDeclaredDeceased(uint256 tokenId);
    event HeirSigned(uint256 tokenId);
    event NFTInherited(uint256 tokenId, address heir);

    constructor(string memory name, string memory symbol, address _Judge) ERC721(name, symbol) Ownable(){
        _judge = _Judge;
    }

    function mint(address heir, uint choice, string memory prompt, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        AccountAction actions;

        if(choice == 0){
            actions = AccountAction.MANAGE_ACCOUNT;
        }
        else{
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
            actions: actions
        });

        // Store the minter information
        minterInfo.push(MinterData({
            tokenId: newTokenId,
            minter: msg.sender
        }));

        isMinter[msg.sender] = true;

        return newTokenId;
    }

    function declareTrigger(uint256 tokenId) public {
        require(msg.sender == tokenInfo[tokenId].judge, "Only the judge can declare trigger");
        require(!tokenInfo[tokenId].isTriggerDeclared, "Already declared triggered");

        tokenInfo[tokenId].isTriggerDeclared = true;
        emit JudgeDeclaredDeceased(tokenId);
    }

    function heirSign(uint256 tokenId) public {
        require(msg.sender == tokenInfo[tokenId].heir, "Only the heir can sign");
        require(tokenInfo[tokenId].isTriggerDeclared, "Judge hasn't declared deceased yet");
        require(!tokenInfo[tokenId].isHeirSigned, "Heir has already signed");

        tokenInfo[tokenId].isHeirSigned = true;
        emit HeirSigned(tokenId);

        if (tokenInfo[tokenId].isTriggerDeclared && tokenInfo[tokenId].isHeirSigned && (tokenInfo[tokenId].actions == AccountAction.MANAGE_ACCOUNT)) {
            address heir = tokenInfo[tokenId].heir;
            _transfer(ownerOf(tokenId), heir, tokenId);
            emit NFTInherited(tokenId, heir);
        }
        else if (tokenInfo[tokenId].isTriggerDeclared && tokenInfo[tokenId].isHeirSigned && (tokenInfo[tokenId].actions == AccountAction.CLOSE_ACCOUNT)) {
            _burn(tokenId);
        } // handle edge case of token Id burned but the token owner is not removed from the list of owners
    }

    function getAllMinters() public view returns (MinterData[] memory) {
        return minterInfo;
    }
    
   
}
