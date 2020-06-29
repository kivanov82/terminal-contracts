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
    const HOLDER_1 = accounts[2];
    const HOLDER_2 = accounts[3];

    const timestamp_1 = 1577836800; //01/01/2020 @ 12:00am (UTC)
    const timestamp_2 = 1577836800; //01/01/2020 @ 3:00am (UTC)

    before("run initial setup ", async () => {

        console.log(`Starting TrainDelay tests...`);

        underwriter = await Underwriter.deployed();
        underwriter2 = await Underwriter.new();
        trainDelay = await TrainDelay.deployed();
        await underwriter2.addSigner(trainDelay.address);
        vault = await Vault.at(await trainDelay.vault.call());


        //fund the vault
        await web3.eth.sendTransaction({from: OWNER, to: vault.address, value: web3.utils.toWei('5', 'ether')});

    })

    it("vault should be able to receive funds", async () => {
        let vaultBefore = Number(await web3.eth.getBalance(vault.address));
        await web3.eth.sendTransaction({from: OWNER, to: trainDelay.address, value: web3.utils.toWei('1', 'ether')});
        let vaultAfter = Number(await web3.eth.getBalance(vault.address));
        assert.strictEqual(vaultAfter, vaultBefore + Number(web3.utils.toWei("1", "ether")));
    })

    it("vault should be able to withdraw funds", async () => {
        let intermediaryBalanceBefore = Number(await web3.eth.getBalance(EXTRA_OWNER));
        let vaultBefore = Number(await web3.eth.getBalance(vault.address));

        await trainDelay.withdrawVault(web3.utils.toWei('1', 'ether'), EXTRA_OWNER);

        let intermediaryBalanceAfter = Number(await web3.eth.getBalance(EXTRA_OWNER));
        let vaultAfter = Number(await web3.eth.getBalance(vault.address));

        assert.strictEqual(vaultAfter, vaultBefore - Number(web3.utils.toWei("1", "ether")));
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
            await trainDelay.applyForPolicy(web3.utils.asciiToHex('IC123'),
                web3.utils.asciiToHex('PARIS'),
                web3.utils.asciiToHex('STP'),
                timestamp_1, timestamp_2, 60,
                {value: web3.utils.toWei('100', 'finney')});
            assert.ok(false, 'paused!');
        } catch (error) {
            assert.ok(error.reason === 'Pausable: paused' ? true : false, 'expected');
        }

        await trainDelay.unpause();
    })

    it("should create application and accept multiple policies per trip per account", async () => {
        let vaultBefore = Number(await web3.eth.getBalance(vault.address));

        let tx1 = await trainDelay.applyForPolicy(web3.utils.asciiToHex('IC123'),
            web3.utils.asciiToHex('PARIS'),
            web3.utils.asciiToHex('STP'), timestamp_1, timestamp_2, 60,
            {from: HOLDER_1, value: web3.utils.toWei('100', 'finney')});
        truffleAssert.eventEmitted(tx1, 'ApplicationCreated', (ev) => {
            return ev.holder === HOLDER_1;
        }, 'ApplicationCreated should be emitted with correct parameters');

        await trainDelay.applyForPolicy(web3.utils.asciiToHex('IC123'), web3.utils.asciiToHex('PARIS'), web3.utils.asciiToHex('STP'), timestamp_1, timestamp_2, 60, {
            from: HOLDER_1,
            value: web3.utils.toWei('100', 'finney')
        });

        let vaultAfter = Number(await web3.eth.getBalance(vault.address));
        assert.strictEqual(vaultAfter, vaultBefore + Number(web3.utils.toWei("200", "finney")));
    })

    it("should process positive resolution", async () => {
        let tx1 = await trainDelay.applyForPolicy(web3.utils.asciiToHex('THALYS4567'), web3.utils.asciiToHex('PARIS'), web3.utils.asciiToHex('STP'), timestamp_1, timestamp_2, 60, {
            from: HOLDER_2,
            value: web3.utils.toWei('100', 'finney')
        });
        let tripId;
        truffleAssert.eventEmitted(tx1, 'ApplicationCreated', (ev) => {
            tripId = ev.tripId;
            return true;
        }, 'ApplicationCreated should be emitted with correct parameters');

        let holderBalanceBefore = Number(await web3.eth.getBalance(HOLDER_2));
        let tx2 = await trainDelay.claimTripDelegated(tripId, '0x');
        let holderBalanceAfter = Number(await web3.eth.getBalance(HOLDER_2));

        assert.strictEqual(holderBalanceAfter, holderBalanceBefore);
    })

    it("should process claims", async () => {
        let tx1 = await trainDelay.applyForPolicy(web3.utils.asciiToHex('THALYS1234'), web3.utils.asciiToHex('PARIS'), web3.utils.asciiToHex('STP'), timestamp_1, timestamp_2, 60, {
            from: HOLDER_2,
            value: web3.utils.toWei('100', 'finney')
        });
        let tripId;
        truffleAssert.eventEmitted(tx1, 'ApplicationCreated', (ev) => {
            tripId = ev.tripId;
            return true;
        }, 'ApplicationCreated should be emitted with correct parameters');

        let holderBalanceBefore = Number(await web3.eth.getBalance(HOLDER_2));
        let tx2 = await trainDelay.claimTripDelegated(tripId, web3.utils.asciiToHex('60'));
        truffleAssert.eventEmitted(tx2, 'ApplicationResolved', (ev) => {
            console.log("Payout processed: +" + ev.payout);
            return ev.holder === HOLDER_2;
        }, 'ApplicationCreated should be emitted with correct parameters');

        let holderBalanceAfter = Number(await web3.eth.getBalance(HOLDER_2));

        assert.ok(holderBalanceAfter > holderBalanceBefore, 'Payout hasn\'t been processed!');
    })

    it("should handle fraud applications", async () => {
        let tx1 = await trainDelay.applyForPolicy(web3.utils.asciiToHex('THALYS12345'), web3.utils.asciiToHex('PARIS'), web3.utils.asciiToHex('STP'), timestamp_1, timestamp_2, 60, {
            from: HOLDER_2,
            value: web3.utils.toWei('100', 'finney')
        });
        let tripId;
        let index;
        truffleAssert.eventEmitted(tx1, 'ApplicationCreated', (ev) => {
            tripId = ev.tripId;
            index = ev.tripIndex;
            return true;
        }, 'ApplicationCreated should be emitted with correct parameters');

        //custodial invalidation kicks in
        await trainDelay.invalidateApplication(tripId, index);

        let tx2 = await trainDelay.claimTripDelegated(tripId, web3.utils.asciiToHex('60'));

        //processed, but only the premium itself is given back
        truffleAssert.eventEmitted(tx2, 'ApplicationResolved', (ev) => {
            assert.strictEqual(Number(ev.payout), Number(web3.utils.toWei('100', 'finney')));
            return true;
        }, 'ApplicationCreated should be emitted with correct parameters');

    })

    it("should process no-data claims", async () => {
        let tx1 = await trainDelay.applyForPolicy(web3.utils.asciiToHex('THALYS1'), web3.utils.asciiToHex('PARIS'), web3.utils.asciiToHex('STP'), timestamp_1, timestamp_2, 60, {
            from: HOLDER_2,
            value: web3.utils.toWei('100', 'finney')
        });
        let tripId;
        truffleAssert.eventEmitted(tx1, 'ApplicationCreated', (ev) => {
            tripId = ev.tripId;
            return true;
        }, 'ApplicationCreated should be emitted with correct parameters');

        let tx2 = await trainDelay.claimTripDelegated(tripId, web3.utils.asciiToHex('-1'));

        //processed, but only the premium itself is given back
        truffleAssert.eventEmitted(tx2, 'ApplicationResolved', (ev) => {
            assert.strictEqual(Number(ev.payout), Number(web3.utils.toWei('100', 'finney')));
            return true;
        }, 'ApplicationCreated should be emitted with correct parameters');
    })


});