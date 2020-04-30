const truffleAssert = require('truffle-assertions');

var Underwriter = artifacts.require("Underwriter");
var Vault = artifacts.require("Vault");

contract('Underwriter', async (accounts) => {
    let underwriter;

    const OWNER = accounts[0];

    const timestamp_1 = 1577836800; //01/01/2020 @ 12:00am (UTC)
    const timestamp_2 = 1577836800; //01/01/2020 @ 3:00am (UTC)


    before("run initial setup ", async () => {

        console.log(`Starting Underwriter tests...`);

        underwriter = await Underwriter.deployed();
    })

    it("should validate premium", async () => {
        assert.strictEqual(await underwriter.validPremium(web3.utils.toWei('1', 'finney')), false);
        assert.strictEqual(await underwriter.validPremium(web3.utils.toWei('100', 'finney')), true);
        assert.strictEqual(await underwriter.validPremium(web3.utils.toWei('1', 'ether')), false);
    })

    it("should create risk", async () => {
        let tx = await underwriter.createRisk(web3.utils.asciiToHex('IC123'), timestamp_1, timestamp_2, 50, 60);
        truffleAssert.eventEmitted(tx, 'RiskCreated', (ev) => {
            console.log('New risk! Multipliers: x' + ev.premiumMultipliers[0].toString() + ' and x' + ev.premiumMultipliers[1].toString());
            return ev.premiumMultipliers.length === 2;
        }, 'RiskCreated should be emitted with correct parameters');
    })

})