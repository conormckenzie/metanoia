"use strict";

import Web3 from "web3";

const web3 = new Web3(window.ethereum);
await window.ethereum.enable();

const raffleAirdrop = web3.eth.Contract(contract_abi, contract_address);
const api_url = "https://metanoiapi.tk/nfts/ticket-holders";

const data = await response.json();

const ticketHolders[] = data.result[];

function mintExistingByAirdrop(_id, _amount) {
   raffleAirdrop.methods.mintExistingByAirdrop.send(_id, _amount);
}

function mintNewByAirdrop(_id, _amount, _uri) {
   raffleAirdrop.methods.mintNewByAirdrop.send(_id, _amount, _uri);
}

function mintByRaffle(_id, _amount, _numberofwinners, _randomSeed) {
  raffleAirdrop.methods.mintNewByRaffle.send(_id, _amount, _numberofwinners, _randomSeed, newuri);
}

function mintNewByRaffle(_id, _amount, _numberofwinners, _randomSeed, newuri) {
  raffleAirdrop.methods.mintNewByRaffle.send(_id, _amount, _numberofwinners, _randomSeed, newuri);
}
