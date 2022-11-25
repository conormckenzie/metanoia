const hre = require("hardhat");
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-etherscan");

const prompt = require('prompt-sync')();

const fs = require("fs");
const path = require('path')
const fsPromises = require('fs/promises')

const console = require("console");

const consoleMethods = require("../../utils.js");
const { readJWKFile, arDriveFactory } = require("ardrive-core-js");
consoleMethods.addConsoleMethods();

const timer = async ms => new Promise( res => setTimeout(res, ms));

let metadata;
let _err;

// ----- FILENAME VARIABLES
const pathprefix_metadata = "../../data/mixies/mixieData/_metadataV3_";
const path_manifest = `../../data/mixies/manifests/Mixies_1_1000.json`;

// ----- ETHERS VARIABLES
// let _gasLimit = 90000000; // fluctuates with each tx
// let _gasPrice = (60 * (10**9));

// ----- ATTRIBUTE FILTERS
const onlyPublicVariables = true;
const onlyPrivateVariables = false;

// ----- ATTRIBUTE CONSTANTS
const fixedDescription = "Metanoia is an alternative nation native to web3, where everyone will be able to gain access and own a slice of the power and economic opportunities previously only made available to the political elite, the well connected or the rich. The Founding Citizen NFTs, represented in the form of Mixies, allows holders to get special perks and privileges from Metanoia. Learn more about Founding Citizen NFT benefits: https://medium.com/metanoia-country/founding-citizen-nft-sale-b7e1524a5e69";


async function main() {
    // (0) network & function: testnet, testing 1
        // address: 0x45A2239D5e66240c4EA3955E0C1fd544f8b0Aad9
        // name: MixiesBaseV0_1
    // (1) network & function: testnet, testing 2
        // address: 0x31799Ba040b675fe8C0aF95FB403191668043aa5
        // name: MixiesBaseV1_0
    // (2) network & function, MAINNET, LIVE
        // address: 0x27154f3441F191bd3e87D65D8eE2166eef259008
        // name: MixiesBaseV1_0
    let presets = [
        {address: "0x45A2239D5e66240c4EA3955E0C1fd544f8b0Aad9", name: "MixiesBaseV0_1"},
        {address: "0x31799Ba040b675fe8C0aF95FB403191668043aa5", name: "MixiesBaseV1_0"},
        {address: "0x27154f3441F191bd3e87D65D8eE2166eef259008", name: "MixiesBaseV1_0"},
    ]

    const n = parseInt(prompt('Use defaults? Input (#) or \'n\': '));
    const validPreset = n >= 0 && n < presets.length;

    const contractAddress = validPreset ? presets[n].address : prompt('Address of deployed Mixie contract: ');
    const contractName = validPreset ? presets[n].name : prompt('Name of deployed Mixie contract: ');
    const firstEdition = parseInt(prompt(`First edition: `)); 
    const lastEdition = parseInt(prompt(`Last edition: `));

    const contract = await hre.ethers.getContractAt(contractName, contractAddress);

    let metadatas = [];
    let imageUris = [];
    let manifest = await path.resolve(__dirname, path_manifest);
    let _setUintAttribute = [];
    let _setStringAttribute = [];

    let _err;
    do {
        try {
            const manifest_data = await fsPromises.readFile(manifest);
            const manifest_obj = JSON.parse(manifest_data);
            
        } catch (err) {
            console.logWhereInline("err:" + err);
            _err = err;
        }
    } while (_err)
    const manifest_data = await fsPromises.readFile(manifest);
    const manifest_obj = JSON.parse(manifest_data);
    console.logWhereInline("CP0B")
    for (let i = firstEdition; i <= lastEdition; i++) {
        metadatas[i] = await path.resolve(__dirname, `${pathprefix_metadata}${i}.json`);
    }
    for (let i = firstEdition; i <= lastEdition; i++) {
        metadatas[i] = await path.resolve(__dirname, `${pathprefix_metadata}${i}.json`);

        console.logWhereInline(metadatas[i]);
        try {
            const data = await fsPromises.readFile(metadatas[i]);
            const obj = JSON.parse(data);
            
        } catch (err) {
            if (i!==0) { console.logWhereInline("err:" + err); }
        }
        if (i==0) { continue; }

        const data = await fsPromises.readFile(metadatas[i]);
        const obj = JSON.parse(data);

        // ----- Load the attributes into the contract -----

        const uintNames = [
            "Torso",
            "Head",
            "Left Arm",
            "Right Arm",
            "Background"
        ];

        const stringNames = [
            "name",
            "Category",
            "Category Item",
            "Type",
            "Palette",
            "Suit",
            "Fluff",
            "Ears",
            "Eyes",
            "Nose",
            "Mouth",
            "Cheeks",
            "Tail",
            "Tapered",
            "Accessory",
            "Wings",
            "Background Effect",
            "Foreground Cloud",
            "Background Cloud"
        ]

        // ----- Phase 1: basic metadata & image

        // uint nftId_, string memory attributeName, bool checked, <type> value
        // _setUintAttribute[i] = [];
        // _setStringAttribute[i] = [];
        // for (let j = 0; j < obj.attributes.length; j++) {
        //     if (onlyPublicVariables && obj.attributes[j].public !== true) { continue; }
        //     if (onlyPrivateVariables && obj.attributes[j].public !== false) { continue; }
        //     do {
        //         _err = false;
        //         try {
        //             if (uintNames.includes(obj.attributes[j].name)) {
        //                 // _setUintAttribute[i][j] = 
        //                 //     contract.setUintAttribute(i, obj.attributes[j].name, true, obj.attributes[j].value);
        //                 await contract.setUintAttribute(i, obj.attributes[j].name, true, obj.attributes[j].value);
        //             }
        //             else if (stringNames.includes(obj.attributes[j].name)) {
        //                 // _setStringAttribute[i][j] = 
        //                 //     contract.setStringAttribute(i, obj.attributes[j].name, true, obj.attributes[j].value);
        //                 await contract.setStringAttribute(i, obj.attributes[j].name, true, obj.attributes[j].value);
        //             }
        //             else {
        //                 throw "name is not in the list of stringNames or uintNames!";
        //             }
        //         } catch (err) {
        //             console.error(err);
        //             _err = err;
        //         }
        //     } while (_err)
            

        //     console.logWhereInline(`id:${i}, attributeId:${j}`);
        //     console.logWhereInline(`waiting 2.1 seconds...`)
        //     await timer(2100);
        //     console.logWhereInline(`Done waiting!`)
        // }

        // // image is not private
        // if (!onlyPrivateVariables) {
        //     // // get arweave link to the ADULT image for this Mixie
        //     // let txid = manifest_obj.paths[`images/${i}.png`].id;
        //     // let imageUri = `https://arweave.net/${txid}`
        //     // // _setStringAttribute[i][obj.attributes.length] = contract.setStringAttribute(i, "image", true, imageUri);
        //     // await contract.setStringAttribute(i, "image", true, imageUri);

        //     // NOTE: This is for the Baby Mixie picture, not the adult Mixie pictures
        //     do {
        //         _err = false;
        //         try {
        //             await contract.setStringAttribute(
        //                 i, "image", true, 
        //                 "https://arweave.net/NX2Tv1luYiUkUo_zVTxmJGK8CnUd1XIqW97S92xvoB8"
        //             );
        //         } catch (err) {
        //             console.error(err);
        //             _err = err;
        //         }
        //     } while (_err)
            
        //     console.logWhereInline(`waiting 2.1 seconds...`)
        //     await timer(2100);
        //     console.logWhereInline(`Done waiting!`)
        // }

        // ----- Phase 2 - fixed description and evolution

        // description and evolution are not private
        if (!onlyPrivateVariables) {
            do {
                _err = false;
                try {
                    await contract.setStringAttribute(i, "description", true, fixedDescription);
                    await timer(2100);
                    await contract.setStringAttribute(i, "Evolution", true, "Baby form");
                    await timer(2100);
                    console.logWhereInline(`Description and Evolution fixed for Mixie ${i}`)
                } catch (err) {
                    console.error(err);
                    _err = err;
                }
            } while (_err)
        }

        // console.logWhereInline(`{ image: '${imageUri}'`);
        console.logWhereInline(obj.attributes);

        // console.logWhereInline(`awaiting edition ${i }...`);
        // for (let j = 0; j < obj.attributes.length + 1; j++) {
        //     await _setStringAttribute[i][j];
        //     await _setUintAttribute[i][j];
        // }
        // console.logWhereInline(`edition ${i} complete!`);
    }

    
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});