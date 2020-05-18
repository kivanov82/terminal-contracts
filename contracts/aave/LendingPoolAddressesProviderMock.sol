pragma solidity ^0.5.8;

import "./ILendingPoolAddressesProvider.sol";

contract LendingPoolAddressesProviderMock is ILendingPoolAddressesProvider {

    function getLendingPool() public view returns (address) {
        return address(0);
    }

    function setLendingPoolImpl(address _pool) public {

    }

    function getLendingPoolCore() public view returns (address payable) {
        return address(0);
    }

    function setLendingPoolCoreImpl(address _lendingPoolCore) public {

    }

    function getLendingPoolConfigurator() public view returns (address) {
        return address(0);
    }

    function setLendingPoolConfiguratorImpl(address _configurator) public {

    }

    function getLendingPoolDataProvider() public view returns (address) {
        return address(0);
    }

    function setLendingPoolDataProviderImpl(address _provider) public {

    }

    function getLendingPoolParametersProvider() public view returns (address) {
        return address(0);
    }

    function setLendingPoolParametersProviderImpl(address _parametersProvider) public {

    }

    function getTokenDistributor() public view returns (address) {
        return address(0);
    }

    function setTokenDistributor(address _tokenDistributor) public {

    }


    function getFeeProvider() public view returns (address) {
        return address(0);
    }

    function setFeeProviderImpl(address _feeProvider) public {

    }

    function getLendingPoolLiquidationManager() public view returns (address) {
        return address(0);
    }

    function setLendingPoolLiquidationManager(address _manager) public {

    }

    function getLendingPoolManager() public view returns (address) {
        return address(0);
    }

    function setLendingPoolManager(address _lendingPoolManager) public {

    }

    function getPriceOracle() public view returns (address) {
        return address(0);
    }

    function setPriceOracle(address _priceOracle) public {

    }

    function getLendingRateOracle() public view returns (address) {
        return address(0);
    }

    function setLendingRateOracle(address _lendingRateOracle) public {

    }
}