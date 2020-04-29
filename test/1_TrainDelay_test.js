const truffleAssert = require('truffle-assertions');

var TrainDelay = artifacts.require("TrainDelay");
var Vault = artifacts.require("Vault");

contract('TrainDelay', async (accounts) => {
    let trainDelay;
    let vault;

    const OWNER = accounts[0];
    const EXTRA_OWNER = accounts[1];

    before("run initial setup ", async () => {

        console.log(`Starting EthKids...`);

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

});