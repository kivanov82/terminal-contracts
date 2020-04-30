const truffleAssert = require('truffle-assertions');

var TrainDelay = artifacts.require("TrainDelay");
var Underwriter = artifacts.require("Underwriter");
var Vault = artifacts.require("Vault");

contract('TrainDelay', async (accounts) => {
    let trainDelay;
    let underwriter;
    let underwriter2;
    let vault;

    const OWNER = accounts[0];
    const EXTRA_OWNER = accounts[1];

    const timestamp_1 = 1577836800; //01/01/2020 @ 12:00am (UTC)
    const timestamp_2 = 1577836800; //01/01/2020 @ 3:00am (UTC)

    before("run initial setup ", async () => {

        console.log(`Starting TrainDelay tests...`);

        underwriter = await Underwriter.deployed();
        underwriter2 = await Underwriter.new();
        trainDelay = await TrainDelay.deployed();
        vault = await Vault.at(await trainDelay.vault.call());

    })

    it("vault should be able to receive funds", async () => {
        await web3.eth.sendTransaction({from: OWNER, to: trainDelay.address, value: web3.utils.toWei('1', 'ether')});
        let vaultAfter = (await web3.eth.getBalance(vault.address)).toString();
        assert.strictEqual(vaultAfter, web3.utils.toWei("1", "ether"));
    })

    it("vault should be able to withdraw funds", async () => {
        let intermediaryBalanceBefore = Number(await web3.eth.getBalance(EXTRA_OWNER));

        await trainDelay.withdrawVault(web3.utils.toWei('1', 'ether'), EXTRA_OWNER);

        let intermediaryBalanceAfter = Number(await web3.eth.getBalance(EXTRA_OWNER));
        let vaultAfter = (await web3.eth.getBalance(vault.address)).toString();

        assert.strictEqual(vaultAfter, "0");
        assert.strictEqual(intermediaryBalanceAfter.toString(), (intermediaryBalanceBefore + Number(web3.utils.toWei('1', 'ether'))).toString());
    })

    it("should replace underwriter", async () => {
        let underwiterBefore = (await trainDelay.underwriter.call()).toString();
        await trainDelay.replaceUnderwriter(underwriter2.address);
        let underwriterAfter = (await trainDelay.underwriter.call()).toString();

        assert.notStrictEqual(underwiterBefore, underwriterAfter);
    })

    it("should pause the product", async () => {
        await trainDelay.pause();
        assert.strictEqual(await trainDelay.paused(), true);
        try {
            await trainDelay.applyForPolicy(web3.utils.asciiToHex('IC123'), 10000, timestamp_1, timestamp_2, 50000, 60);
            assert.ok(false, 'paused!');
        } catch (error) {
            assert.ok(error.reason === 'Pausable: paused' ? true : false, 'expected');
        }

        await trainDelay.unpause();
    })


});