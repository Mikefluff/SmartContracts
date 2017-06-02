const ChronoBankPlatform = artifacts.require('./ChronoBankPlatform.sol')
const ChronoBankPlatformEmitter = artifacts.require('./ChronoBankPlatformEmitter.sol')
const EventsHistory = artifacts.require('./EventsHistory.sol')
const ChronoBankAssetProxy = artifacts.require('./ChronoBankAssetProxy.sol')
const ChronoBankAssetWithFeeProxy = artifacts.require('./ChronoBankAssetWithFeeProxy.sol')
const ChronoBankAsset = artifacts.require('./ChronoBankAsset.sol')
const ChronoBankAssetWithFee = artifacts.require('./ChronoBankAssetWithFee.sol')
const ChronoMint = artifacts.require('./ChronoMint.sol')
const ChronoMintEmitter = artifacts.require("./ChronoMintEmitter.sol");
const ContractsManager = artifacts.require('./ContractsManager.sol')
const Exchange = artifacts.require('./Exchange.sol')
const ERC20Manager = artifacts.require("./ERC20Manager.sol");
const ExchangeManager = artifacts.require("./ExchangeManager.sol");
const AssetsManager = artifacts.require("./AssetsManager");
const Shareable = artifacts.require("./PendingManager.sol");
const TimeHolder = artifacts.require('./TimeHolder.sol')
const Rewards = artifacts.require('./Rewards.sol')
const UserStorage = artifacts.require('./UserStorage.sol');
const UserManager = artifacts.require("./UserManager.sol");
const ProxyFactory = artifacts.require("./ProxyFactory.sol");
const Vote = artifacts.require('./Vote.sol')
const bytes32fromBase58 = require('../test/helpers/bytes32fromBase58')

function bytes32(stringOrNumber) {
  var zeros = '000000000000000000000000000000000000000000000000000000000000000';
  if (typeof stringOrNumber === "string") {
    return (web3.toHex(stringOrNumber) + zeros).substr(0, 66);
  }
  var hexNumber = stringOrNumber.toString(16);
  return '0x' + (zeros + hexNumber).substring(hexNumber.length - 1);
}

const SYMBOL = 'TIME'
const SYMBOL2 = 'LHT'
const NAME = 'Time Token'
const DESCRIPTION = 'ChronoBank Time Shares'
const NAME2 = 'Labour-hour Token'
const DESCRIPTION2 = 'ChronoBank Lht Assets'
const BASE_UNIT = 8
const IS_REISSUABLE = true
const IS_NOT_REISSUABLE = false
const fakeArgs = [0, 0, 0, 0, 0, 0, 0, 0]
const BALANCE_ETH = 1000

const contractTypes = {
  LOCManager: 0, // LOCManager
  PendingManager: 1, // PendingManager
  UserManager: 2, // UserManager
  ERC20Manager: 3, // ERC20Manager
  ExchangeManager: 4, // ExchangeManager
  TrackersManager: 5, // TrackersManager
  Voting: 6, // Voting
  Rewards: 7, // Rewards
  AssetsManager: 8, // AssetsManager
  TimeHolder:  9 //TimeHolder
}

let assetsManager
let chronoBankPlatform
let chronoMint
let contractsManager
let timeHolder
let shareable
let eventsHistory
let erc20Manager
let chronoBankPlatformEmitter
let rewards
let userManager
let exchangeManager
let chronoBankAsset
let chronoBankAssetProxy
let chronoBankAssetWithFee
let chronoBankAssetWithFeeProxy

let accounts
let params
let paramsGas

var getAcc = function () {
  return new Promise(function (resolve, reject) {
    web3.eth.getAccounts((err, acc) => {
      console.log(acc);
      resolve(acc);
    })
  })
}

var exit = function () {
  process.exit()
}

module.exports = (callback) => {
  return getAcc()
    .then(r => {
      accounts = r
      params = {from: accounts[0]}
      paramsGas = {from: accounts[0], gas: 3000000}
      return UserStorage.deployed()
    }).then(function (instance) {
      userStorage = instance
      return instance.addOwner(UserManager.address)
    }).then(function () {
      return UserManager.deployed()
    }).then(function (instance) {
      userManager = instance
      return instance.init(UserStorage.address, ContractsManager.address)
    }).then(function () {
      return ContractsManager.deployed()
    }).then(function (instance) {
      contractsManager = instance
      return Shareable.deployed()
    }).then(function (instance) {
      shareable = instance
      return instance.init(ContractsManager.address)
    }).then(function () {
      return ChronoMint.deployed()
    }).then(function (instance) {
      chronoMint = instance
      return instance.init(ContractsManager.address)
    }).then(function () {
      return ChronoBankPlatform.deployed()
    }).then(function (instance) {
      platform = instance
      return ChronoBankAsset.deployed()
    }).then(function (instance) {
      timeContract = instance
      return ChronoBankAssetWithFee.deployed()
    }).then(function (instance) {
      lhContract = instance;
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      timeProxyContract = instance;
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(function(instance) {
      lhProxyContract = instance;
      return ChronoBankPlatform.deployed()
    }).then(function (instance) {
      chronoBankPlatform = instance;
      return Shareable.deployed()
    }).then(function (instance) {
      shareable = instance;
      return AssetsManager.deployed()
    }).then(function (instance) {
      assetsManager = instance;
      return assetsManager.init(chronoBankPlatform.address, contractsManager.address, ProxyFactory.address)
    }).then(function () {
      return ERC20Manager.deployed()
    }).then(function (instance) {
      erc20Manager = instance;
      return erc20Manager.init(ContractsManager.address)
    }).then(function () {
      return ExchangeManager.deployed()
    }).then(function (instance) {
      exchangeManager = instance;
      return exchangeManager.init(ContractsManager.address)
    }).then(function () {
      return Rewards.deployed()
    }).then(function (instance) {
      rewards = instance;
      return rewards.init(ContractsManager.address, 0)
    }).then(function (instance) {
      return rewards.addAsset(ChronoBankAssetWithFeeProxy.address)
    }).then(function () {
      return rewards.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return Vote.deployed()
    }).then(function (instance) {
      vote = instance;
      return instance.init(ContractsManager.address)
    }).then(function () {
      return TimeHolder.deployed()
    }).then(function (instance) {
      timeHolder = instance;
      return instance.init(ContractsManager.address, ChronoBankAssetProxy.address)
    }).then(function () {
      return timeHolder.addListener(rewards.address)
    }).then(function () {
      return timeHolder.addListener(vote.address)
    }).then(function () {
      return ChronoBankPlatform.deployed()
    }).then(i => {
      chronoBankPlatform = i
      return ChronoBankAsset.deployed()
    }).then(i => {
      chronoBankAsset = i
      return ChronoBankAssetWithFee.deployed()
    }).then(i => {
      chronoBankAssetWithFee = i
      return ChronoBankAssetProxy.deployed()
    }).then(i => {
      chronoBankAssetProxy = i
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(i => {
      chronoBankAssetWithFeeProxy = i
      return ChronoBankPlatformEmitter.deployed()
    }).then(i => {
      chronoBankPlatformEmitter = i
      return ChronoMintEmitter.deployed()
    }).then(i => {
      chronoMintEmitter = i;
      return EventsHistory.deployed()
    }).then(i => {
      eventsHistory = i
      return chronoBankPlatform.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      return chronoMint.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      return userManager.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      return eventsHistory.addEmitter(chronoMintEmitter.contract.newLOC.getData.apply(this, fakeArgs).slice(0, 10), ChronoMintEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(() => {
      return eventsHistory.addEmitter(chronoMintEmitter.contract.hashUpdate.getData.apply(this, fakeArgs).slice(0, 10), ChronoMintEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(() => {
      return eventsHistory.addEmitter(chronoMintEmitter.contract.cbeUpdate.getData.apply(this, fakeArgs).slice(0, 10), ChronoMintEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitTransfer.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitIssue.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitRevoke.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitOwnershipChange.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitApprove.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitRecovery.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitError.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addVersion(chronoMint.address, 'Origin', 'Initial version.')
    }).then(() => {
      return eventsHistory.addVersion(userManager.address, 'Origin', 'Initial version.')
    }).then(() => {
      return eventsHistory.addVersion(chronoBankPlatform.address, 'Origin', 'Initial version.')
    }).then(() => {
      return chronoBankPlatform.issueAsset(SYMBOL, 1000000000000, NAME, DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE, paramsGas)
    }).then(() => {
      return chronoBankPlatform.setProxy(ChronoBankAssetProxy.address, SYMBOL, params)
    }).then(() => {
      return chronoBankAssetProxy.init(ChronoBankPlatform.address, SYMBOL, NAME, params)
    }).then(() => {
      return chronoBankAssetProxy.proposeUpgrade(ChronoBankAsset.address, params)
    }).then(() => {
      return chronoBankAsset.init(ChronoBankAssetProxy.address, params)
    }).then(r => {
      return chronoBankAssetProxy.transfer(assetsManager.address, 500000000000, params)
    }).then(r => {
      return chronoBankPlatform.changeOwnership(SYMBOL, assetsManager.address, params)
    }).then(r => {
      return chronoBankPlatform.issueAsset(SYMBOL2, 0, NAME2, DESCRIPTION2, BASE_UNIT, IS_REISSUABLE, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      return chronoBankPlatform.setProxy(ChronoBankAssetWithFeeProxy.address, SYMBOL2, params)
    }).then(() => {
      return chronoBankAssetWithFeeProxy.init(ChronoBankPlatform.address, SYMBOL2, NAME2, params)
    }).then(() => {
      return chronoBankAssetWithFeeProxy.proposeUpgrade(ChronoBankAssetWithFee.address, params)
    }).then(() => {
      return chronoBankAssetWithFee.init(ChronoBankAssetWithFeeProxy.address, params)
    }).then(() => {
      return chronoBankAssetWithFee.setupFee(Rewards.address, 100, {from: accounts[0]})
    }).then(() => {
      return chronoBankPlatform.changeOwnership(SYMBOL2, assetsManager.address, params)
    }).then(() => {
      return chronoBankPlatform.changeContractOwnership(assetsManager.address, {from: accounts[0]})
    }).then(() => {
      return assetsManager.claimPlatformOwnership({from: accounts[0]})
    }).then(() => {
      return assetsManager.addAsset(chronoBankAssetProxy.address,SYMBOL, accounts[0], {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      return assetsManager.addAsset(chronoBankAssetWithFeeProxy.address,SYMBOL2, chronoMint.address, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      exit()
    }).catch(function (e) {
      console.log(e)
    })
}
