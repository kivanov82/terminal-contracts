var TrainDelay = artifacts.require("TrainDelay");

module.exports = async function (deployer, network, accounts) {
    console.log(`  === Deploying TrainDelay contracts to ${network}...`);

    await deployer.deploy(TrainDelay);
    const trainDelayInstance = await TrainDelay.deployed();
    console.log('Terminal, TrainDelay: NEW ' + trainDelayInstance.address);
}