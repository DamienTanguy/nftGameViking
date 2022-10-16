// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol'; //best for non fongible token
import '@openzeppelin/contracts/access/Ownable.sol';

contract nftGameViking is ERC721, Ownable {

    enum characterType { VIKING, GALLIC }

    uint nextId = 0; //symbolize the id of the token --> uint of the mapping

    struct Character {
        uint8 attack;
        uint8 defense;
        uint life;
        uint32 experience;
        uint lastHeal;
        uint lastFight;
        characterType characterType;
    }

    mapping(uint => Character) private characterList;

    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    function getTokenDetails(uint _tokenId) public view returns(Character memory){
        return characterList[_tokenId];
    }

    function mint(characterType _type) public {
        require(balanceOf(msg.sender) <= 4 ,"You can't mint anymore");
        require(_type == characterType.VIKING || _type == characterType.GALLIC, "The type doesn't exist");
        if(_type == characterType.VIKING){
            Character memory newCharacter = Character(12, 45, 100, 1, block.timestamp, block.timestamp, characterType.VIKING);
            characterList[nextId] = newCharacter;
            _safeMint(msg.sender, nextId);
            nextId++;
        }
        if(_type == characterType.GALLIC){
            Character memory newCharacter = Character(10, 40, 120, 1, block.timestamp, block.timestamp, characterType.GALLIC);
            characterList[nextId] = newCharacter;
            _safeMint(msg.sender, nextId);
            nextId++;
        }
    }

    function heal(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        /*require(characterList[_tokenId].lastHeal + 60 < block.timestamp, "You have to wait to heal again");
        require(characterList[_tokenId].life > 0, "You are dead, you can't heal");
        characterList[_tokenId].lastHeal = block.timestamp;
        characterList[_tokenId].life +=50;*/
        //SAVING OF GAS WITH THAT SOLUTION --> 
        Character storage thisCharacter = characterList[_tokenId];
        require(thisCharacter.lastHeal + 60 < block.timestamp, "To soon to heal.");
        require(thisCharacter.life > 0, "Cant't heal someone that is dead.");
        thisCharacter.lastHeal = block.timestamp;
        thisCharacter.life += 50;
    }

    function fight(uint _tokenId1, uint _tokenId2) public payable {
        require(characterList[_tokenId1].lastFight + 60 < block.timestamp && characterList[_tokenId2].lastFight + 60 < block.timestamp, "Must wait before next fight");
        require(ownerOf(_tokenId1) == msg.sender, "Not your character"); //the caller of the function should be the owner of the character
        require(ownerOf(_tokenId1) != ownerOf(_tokenId2), "You cannot fight your own character.");
        require(characterList[_tokenId1].life > 0 && characterList[_tokenId2].life > 0, "You can only fight living character.");

        //Calculation
        uint substractLifeToCharacter2 = (characterList[_tokenId1].attack * characterList[_tokenId1].experience) - (characterList[_tokenId2].defense / 4);
        uint substractLifeToCharacter1 = (characterList[_tokenId2].attack * characterList[_tokenId2].experience) - (characterList[_tokenId1].defense / 4);

        //update of the timestamp 
        characterList[_tokenId1].lastFight = block.timestamp;
        characterList[_tokenId2].lastFight = block.timestamp;

        //the character 1 attack and kill the character 2
        if(characterList[_tokenId2].life - substractLifeToCharacter2 <= 0) {
            characterList[_tokenId2].life = 0;
            characterList[_tokenId1].experience++;
        }
        else {
            //the character 1 attack but don't kill the character 2, the character 2 attack and kill the character 1 
            if(characterList[_tokenId2].life - substractLifeToCharacter2 > 0 && characterList[_tokenId1].life - substractLifeToCharacter1 <= 0) {
                characterList[_tokenId2].life -= substractLifeToCharacter2;
                characterList[_tokenId1].life = 0;
                characterList[_tokenId2].experience++;
            }
            //the character 1 attack but don't kill the character 2, the character 2 attack but don't kill the character 1, and the fight stop
            else {
                characterList[_tokenId2].life -= substractLifeToCharacter2;
                characterList[_tokenId1].life -= substractLifeToCharacter1;
                if(substractLifeToCharacter1 > substractLifeToCharacter2) {
                    characterList[_tokenId2].experience++;
                }
                else if(substractLifeToCharacter2 > substractLifeToCharacter1) {
                    characterList[_tokenId1].experience++;
                }
                else {
                    characterList[_tokenId1].experience++;
                    characterList[_tokenId2].experience++;

                }
            }
        }
    }

    function _beforeTokenTransfer(address, address, uint256 _tokenId) internal override {
        Character storage characterToTransfert = characterList[_tokenId];
        require(characterToTransfert.life > 0, "You can't transfer a dead character");
    }

}
