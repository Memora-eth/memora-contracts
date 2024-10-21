// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MemoraBTC is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _escrowIds;
    address immutable _judge;

    uint256 _BUFFER_PERIOD = 0 minutes; // 0 minutes buffer

    enum AccountAction {
        TRANSFER_BTC
    }

    struct EscrowInfo {
        address judge;
        address heir;
        address minter;
        bool isTriggerDeclared;
        bool isHeirSigned;
        uint256 btcAmount;
        string prompt;
        AccountAction action;
        uint256 triggerTimestamp;
        uint256 farcasterID;
        string uri;  
    }

    struct MinterData {
        uint256 escrowId;
        address minter;
        uint256 fid;
    }

    mapping(uint256 => EscrowInfo) public escrowInfo;
    MinterData[] private minterInfo;

    event EscrowCreated(uint256 indexed escrowId, address indexed minter, address indexed heir, string uri);
    event JudgeDeclaredTriggered(uint256 indexed escrowId);
    event HeirSigned(uint256 indexed escrowId);
    event TriggerDisabled(uint256 indexed escrowId);
    event BufferChanged(uint256 indexed bufferPeriod);
    event BTCTransferCompleted(uint256 indexed escrowId, address indexed heir, uint256 btcAmount);

    constructor(address _Judge) Ownable(msg.sender) {
        _judge = _Judge;
    }

    function createEscrow(
        address heir,
        uint256 btcAmount,
        string memory prompt,
        uint256 farcasterID,
        string memory uri  // Added URI parameter
    ) public payable returns (uint256)  {
        require(msg.value != 0, "Please send the BTC amount to the Memora");
        require(msg.value == btcAmount, "Amount mismatch in BTC transfer");
        _escrowIds.increment();
        uint256 newEscrowId = _escrowIds.current();

        escrowInfo[newEscrowId] = EscrowInfo({
            judge: _judge,
            heir: heir,
            minter: msg.sender,
            isTriggerDeclared: false,
            isHeirSigned: false,
            btcAmount: btcAmount,
            prompt: prompt,
            action: AccountAction.TRANSFER_BTC,
            triggerTimestamp: 0,
            farcasterID: farcasterID,
            uri: uri  // Added URI
        });

        minterInfo.push(
            MinterData({
                escrowId: newEscrowId,
                minter: msg.sender,
                fid: farcasterID
            })
        );

        emit EscrowCreated(newEscrowId, msg.sender, heir, uri);  // Added URI to event

        return newEscrowId;
    }

    function declareTrigger(uint256 escrowId) public {
        require(
            msg.sender == escrowInfo[escrowId].judge,
            "Only the judge can declare trigger"
        );
        require(
            !escrowInfo[escrowId].isTriggerDeclared,
            "Already declared triggered"
        );

        escrowInfo[escrowId].isTriggerDeclared = true;
        escrowInfo[escrowId].triggerTimestamp = block.timestamp;
        emit JudgeDeclaredTriggered(escrowId);
    }

    function heirSign(uint256 escrowId) public {
        require(
            msg.sender == escrowInfo[escrowId].heir,
            "Only the heir can sign"
        );
        require(
            escrowInfo[escrowId].isTriggerDeclared,
            "Judge hasn't declared triggered yet"
        );
        require(!escrowInfo[escrowId].isHeirSigned, "Heir has already signed");
        require(
            block.timestamp >=
                escrowInfo[escrowId].triggerTimestamp + _BUFFER_PERIOD,
            "Buffer period has not passed yet"
        );

        escrowInfo[escrowId].isHeirSigned = true;
        emit HeirSigned(escrowId);

        if (escrowInfo[escrowId].action == AccountAction.TRANSFER_BTC) {
            // Transfer ETH (acting as BTC) to the heir
            (bool success, ) = payable(escrowInfo[escrowId].heir).call{
                value: escrowInfo[escrowId].btcAmount
            }("");
            require(success, "Transfer failed");
            emit BTCTransferCompleted(
                escrowId,
                escrowInfo[escrowId].heir,
                escrowInfo[escrowId].btcAmount
            );        
        }
    }

    function getAllMinters() public view returns (MinterData[] memory) {
        return minterInfo;
    }

    function getTriggeredEscrowsForHeir(address heir) public view returns (uint256[] memory) {
        uint256 triggeredCount = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (
                escrowInfo[i + 1].heir == heir &&
                escrowInfo[i + 1].isTriggerDeclared &&
                !escrowInfo[i + 1].isHeirSigned
            ) {
                triggeredCount++;
            }
        }

        uint256[] memory triggeredEscrows = new uint256[](triggeredCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (
                escrowInfo[i + 1].heir == heir &&
                escrowInfo[i + 1].isTriggerDeclared &&
                !escrowInfo[i + 1].isHeirSigned
            ) {
                triggeredEscrows[index] = i + 1;
                index++;
            }
        }

        return triggeredEscrows;
    }

    function disableTrigger(uint256 escrowId) public {
        require(
            escrowInfo[escrowId].minter == msg.sender,
            "Only the escrow creator can disable the trigger"
        );
        require(
            escrowInfo[escrowId].isTriggerDeclared,
            "Trigger has not been declared yet"
        );
        require(!escrowInfo[escrowId].isHeirSigned, "Heir has already signed");

        escrowInfo[escrowId].isTriggerDeclared = false;
        escrowInfo[escrowId].triggerTimestamp = 0;

        emit TriggerDisabled(escrowId);
    }

    function changeBuffer(uint256 _buffer_period) public onlyOwner {
        _BUFFER_PERIOD = _buffer_period;
        emit BufferChanged(_buffer_period);
    }

    function getEscrowsCreatedByOwner(address owner) public view returns (uint256[] memory) {
        uint256 createdCount = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (escrowInfo[i + 1].minter == owner) {
                createdCount++;
            }
        }

        uint256[] memory createdEscrows = new uint256[](createdCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (escrowInfo[i + 1].minter == owner) {
                createdEscrows[index] = i + 1;
                index++;
            }
        }

        return createdEscrows;
    }

    function getAllEscrowsForHeir(address heir) public view returns (uint256[] memory) {
        uint256 escrowCount = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (escrowInfo[i + 1].heir == heir) {
                escrowCount++;
            }
        }

        uint256[] memory heirEscrows = new uint256[](escrowCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (escrowInfo[i + 1].heir == heir) {
                heirEscrows[index] = i + 1;
                index++;
            }
        }

        return heirEscrows;
    }

    function getUnclaimedEscrows() public view returns (MinterData[] memory) {
        uint256 unclaimedCount = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (
                !escrowInfo[i + 1].isTriggerDeclared &&
                !escrowInfo[i + 1].isHeirSigned
            ) {
                unclaimedCount++;
            }
        }

        MinterData[] memory unclaimedMinters = new MinterData[](unclaimedCount);
        uint256 index = 0;

        for (uint256 i = 0; i < _escrowIds.current(); i++) {
            if (
                !escrowInfo[i + 1].isTriggerDeclared &&
                !escrowInfo[i + 1].isHeirSigned
            ) {
                unclaimedMinters[index] = MinterData({
                    escrowId: i + 1,
                    minter: escrowInfo[i + 1].minter,
                    fid: escrowInfo[i + 1].farcasterID
                });
                index++;
            }
        }

        return unclaimedMinters;
    }

    function getEscrowURI(uint256 escrowId) public view returns (string memory) {
        require(escrowId > 0 && escrowId <= _escrowIds.current(), "Invalid escrow ID");
        return escrowInfo[escrowId].uri;
    }
}
