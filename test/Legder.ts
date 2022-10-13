import { expect } from "chai";
import * as hrt from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Legder__factory, Legder } from '../typechain-types';

const ethers = hrt.ethers;

describe("Token contract", function () {
    let legder: Legder;
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
	let addrs: SignerWithAddress[]

    beforeEach(async function() {
        [owner, alice, bob, ...addrs] = await ethers.getSigners();
        const legderFactory = (await ethers.getContractFactory("Legder", owner)) as Legder__factory;
        legder = await legderFactory.deploy("CNY", 6);
    })

    describe("claim test", function() {
        it("basics", async function() {
            await legder.connect(bob).setTrust(alice.address, true);
            await legder.connect(alice).setTrust(bob.address, true);
            await legder.connect(alice).claim(bob.address, 10e6);
            await legder.connect(bob).claim(alice.address, 20e6);
            
        })
    })
});