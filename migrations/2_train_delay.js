var TrainDelay = artifacts.require("TrainDelay");
var Underwriter = artifacts.require("Underwriter");

const empty_address = '0x0000000000000000000000000000000000000000';

function getAaveForNetwork(network, accounts) {
    if (network == 'development') {
        return {
            aDai: empty_address,
            aaveLendingPool: empty_address,
            aaveLendingCore: empty_address,
            dai: empty_address,
        }
    } else if (network == 'rinkeby') {
        return {
            aDai: empty_address,
            aaveLendingPool: empty_address,
            aaveLendingCore: empty_address,
            dai: empty_address,
        }
    } else if (network == 'ropsten') {
        return {
            aDai: '0xcB1Fe6F440c49E9290c3eb7f158534c2dC374201',
            aaveLendingPool: '0x9E5C7835E4b13368fd628196C4f1c6cEc89673Fa',
            aaveLendingCore: '0x4295Ee704716950A4dE7438086d6f0FBC0BA9472',
            dai: '0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108',
        }
    } else if (network == 'live') {
        return {
            aDai: empty_address,
            aaveLendingPool: empty_address,
            aaveLendingCore: empty_address,
            dai: '0x6b175474e89094c44da98b954eedeac495271d0f',
        }
    }
}

module.exports = async function (deployer, network, accounts) {
    console.log(`  === Deploying TrainDelay contracts to ${network}...`);

    await deployer.deploy(Underwriter);
    const underwriterInstance = await Underwriter.deployed();
    console.log('Terminal, Underwriter: NEW ' + underwriterInstance.address);

    const {aDai, aaveLendingPool, aaveLendingCore, dai} = getAaveForNetwork(network, accounts)
    await deployer.deploy(TrainDelay, underwriterInstance.address, aDai, aaveLendingPool, aaveLendingCore, dai);
    const trainDelayInstance = await TrainDelay.deployed();
    console.log('Terminal, TrainDelay: NEW ' + trainDelayInstance.address);

    await underwriterInstance.addSigner(trainDelayInstance.address);

}