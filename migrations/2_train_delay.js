var TrainDelay = artifacts.require("TrainDelay");
var Underwriter = artifacts.require("Underwriter");
var ReInsuranceVault = artifacts.require("ReInsuranceVault");
var LendingPoolAddressesProviderMock = artifacts.require("LendingPoolAddressesProviderMock");

const empty_address = '0x0000000000000000000000000000000000000000';

function getAaveForNetwork(network, accounts) {
    if (network == 'development') {
        return {
            aDai: empty_address,
            aaveProvider: empty_address,
            aaveReferral: 0,
            dai: empty_address,
        }
    } else if (network == 'development-fork') {
        return {
            aDai: '0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d',
            aaveProvider: '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8',
            aaveReferral: 0,
            dai: '0x6b175474e89094c44da98b954eedeac495271d0f',
        }
    } else if (network == 'rinkeby') {
        return {
            aDai: empty_address,
            aaveProvider: empty_address,
            aaveReferral: 0,
            dai: empty_address,
        }
    } else if (network == 'ropsten') {
        return {
            aDai: '0xcB1Fe6F440c49E9290c3eb7f158534c2dC374201',
            aaveProvider: '0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728',
            aaveReferral: 0,
            dai: '0xf80A32A835F79D7787E8a8ee5721D0fEaFd78108',
        }
    } else if (network == 'live') {
        return {
            aDai: '0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d',
            aaveProvider: '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8',
            aaveReferral: 0,
            dai: '0x6b175474e89094c44da98b954eedeac495271d0f',
        }
    }
}

module.exports = async function (deployer, network, accounts) {
    console.log(`  === Deploying TrainDelay contracts to ${network}...`);

    await deployer.deploy(Underwriter);
    const underwriterInstance = await Underwriter.deployed();
    console.log('Terminal, Underwriter: NEW ' + underwriterInstance.address);

    let {aDai, aaveProvider, dai, aaveReferral} = getAaveForNetwork(network, accounts)
    if (aaveProvider === empty_address) {
        //deploy the mock
        await deployer.deploy(LendingPoolAddressesProviderMock);
        const aaveProviderInstance = await LendingPoolAddressesProviderMock.deployed();
        aaveProvider = aaveProviderInstance.address;
    }
    await deployer.deploy(TrainDelay, underwriterInstance.address, aDai, aaveProvider, dai, aaveReferral);
    const trainDelayInstance = await TrainDelay.deployed();
    await underwriterInstance.addSigner(trainDelayInstance.address);
    console.log('Terminal, TrainDelay: NEW ' + trainDelayInstance.address);

}