var TrainDelay = artifacts.require("TrainDelay");
var Underwriter = artifacts.require("Underwriter");

module.exports = async function (deployer, network, accounts) {
    console.log(`  === Deploying TrainDelay contracts to ${network}...`);

    await deployer.deploy(Underwriter);
    const underwriterInstance = await Underwriter.deployed();
    console.log('Terminal, Underwriter: NEW ' + underwriterInstance.address);

    await deployer.deploy(TrainDelay, underwriterInstance.address);
    const trainDelayInstance = await TrainDelay.deployed();
    console.log('Terminal, TrainDelay: NEW ' + trainDelayInstance.address);

    await underwriterInstance.addSigner(trainDelayInstance.address);

}