const ChronoBankPlatform = artifacts.require('./ChronoBankPlatform.sol')
const ChronoBankPlatformEmitter = artifacts.require('./ChronoBankPlatformEmitter.sol')
const EventsHistory = artifacts.require('./EventsHistory.sol')
const ChronoBankAssetProxy = artifacts.require('./ChronoBankAssetProxy.sol')
const ChronoBankAssetWithFeeProxy = artifacts.require('./ChronoBankAssetWithFeeProxy.sol')
const ChronoBankAsset = artifacts.require('./ChronoBankAsset.sol')
const ChronoBankAssetWithFee = artifacts.require('./ChronoBankAssetWithFee.sol')
const LOCManager = artifacts.require('./LOCManager.sol')
const ContractsManager = artifacts.require('./ContractsManager.sol')
const Exchange = artifacts.require('./Exchange.sol')
const ERC20Manager = artifacts.require("./ERC20Manager.sol");
const ExchangeManager = artifacts.require("./ExchangeManager.sol");
const AssetsManager = artifacts.require("./AssetsManager");
const Shareable = artifacts.require("./PendingManager.sol");
const TimeHolder = artifacts.require('./TimeHolder.sol')
const Rewards = artifacts.require('./Rewards.sol')
const Storage = artifacts.require('./Storage.sol');
const UserManager = artifacts.require("./UserManager.sol");
const ManagerMock = artifacts.require('./ManagerMock.sol');
const ProxyFactory = artifacts.require("./ProxyFactory.sol");
const Vote = artifacts.require('./Vote.sol')

const TIME_SYMBOL = 'TIME'
const TIME_NAME = 'Time Token'
const TIME_DESCRIPTION = 'ChronoBank Time Shares'

const LHT_SYMBOL = 'LHT'
const LHT_NAME = 'Labour-hour Token'
const LHT_DESCRIPTION = 'ChronoBank Lht Assets'

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
  TimeHolder: 9 //TimeHolder
}

let storage
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
let vote
let chronoMintEmitter

let accounts
let params
let paramsGas

var getAcc = function () {
  console.log('setup accounts')
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

var setup = function (callback) {
  return getAcc().then(r => {
    accounts = r
    params = {from: accounts[0]}
    paramsGas = {from: accounts[0], gas: 3000000}
    console.log('--done')
  }).then(() => {
    console.log('deploy contracts')
    return Promise.all([
      Storage.deployed(),
      UserManager.deployed(),
      ContractsManager.deployed(),
      Shareable.deployed(),
      LOCManager.deployed(),
      ChronoBankPlatform.deployed(),
      ChronoBankAsset.deployed(),
      ChronoBankAssetWithFee.deployed(),
      ChronoBankAssetProxy.deployed(),
      ChronoBankAssetWithFeeProxy.deployed(),
      AssetsManager.deployed(),
      ERC20Manager.deployed(),
      ExchangeManager.deployed(),
      Rewards.deployed(),
      Vote.deployed(),
      TimeHolder.deployed(),
      ChronoBankPlatformEmitter.deployed(),
      EventsHistory.deployed()
    ])
  }).then((instances) => {
    [
      storage,
      userManager,
      contractsManager,
      shareable,
      chronoMint,
      chronoBankPlatform,
      chronoBankAsset,
      chronoBankAssetWithFee,
      chronoBankAssetProxy,
      chronoBankAssetWithFeeProxy,
      assetsManager,
      erc20Manager,
      exchangeManager,
      rewards,
      vote,
      timeHolder,
      chronoBankPlatformEmitter,
      eventsHistory
    ] = instances

  }).then(() => {
    console.log('setup storage')
    return storage.setManager(ManagerMock.address)
  }).then(() => {
    console.log('link addresses')
    return Promise.all([
      storage.setManager(ManagerMock.address),
      contractsManager.init(),
      userManager.init(ContractsManager.address),
      shareable.init(ContractsManager.address),
      chronoMint.init(ContractsManager.address),
      assetsManager.init(chronoBankPlatform.address, contractsManager.address, ProxyFactory.address),
      erc20Manager.init(ContractsManager.address),
      exchangeManager.init(ContractsManager.address),
      rewards.init(ContractsManager.address, 0),
      vote.init(ContractsManager.address),
      timeHolder.init(ContractsManager.address, ChronoBankAssetProxy.address),
      chronoBankAsset.init(ChronoBankAssetProxy.address, params),
      chronoBankAssetWithFee.init(ChronoBankAssetWithFeeProxy.address, params),
      chronoBankAssetProxy.init(ChronoBankPlatform.address, TIME_SYMBOL, TIME_NAME, params),
      chronoBankAssetWithFeeProxy.init(ChronoBankPlatform.address, LHT_SYMBOL, LHT_NAME, params)
    ])
  }).then(() => {
    console.log('setup rewards')
    console.log('--addAsset')
    return rewards.addAsset(ChronoBankAssetWithFeeProxy.address)
  }).then(() => {
    console.log('setup timeHolder')
    console.log('--add reward listener')
    return timeHolder.addListener(rewards.address).then(() => {
      console.log('--add vote listener')
      return timeHolder.addListener(vote.address)
    }).catch(e => console.error('timeHolder error', e))
  }).then(() => {
    console.log('setup event history')
    console.log('--add to chronoBankPlatform')
    return chronoBankPlatform.setupEventsHistory(
      EventsHistory.address,
      paramsGas)
    }).then(() => {
      const platformEvent = [
        'emitTransfer',
        'emitIssue',
        'emitRevoke',
        'emitOwnershipChange',
        'emitApprove',
        'emitRecovery',
        'emitError'
      ]
      return Promise.all(platformEvent.map(event => {
        console.log(`--addEmitter chronoBankPlatformEmitter.${event}`)
        return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract[event].getData.apply(this, fakeArgs).slice(0, 10),
          chronoBankPlatformEmitter.address,
          paramsGas
        )
      })).catch(e => console.error('emitter error', e))
    }).then(() => {
      console.log('--update version in chronoBankPlatform')
      return eventsHistory.addVersion(chronoBankPlatform.address, 'Origin', 'Initial version.')
    }).catch(e => console.error(e => 'eventHistory error', e))
  .then(() => {
    console.log('chronoBankPlatform.issueAsset')
    console.log('--issue TIME')
    return chronoBankPlatform.issueAsset(TIME_SYMBOL, 1000000000000, TIME_NAME, TIME_DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE, paramsGas
    ).then(() => {
      console.log('--issue LHT')
      return chronoBankPlatform.issueAsset(LHT_SYMBOL, 0, LHT_NAME, LHT_DESCRIPTION, BASE_UNIT, IS_REISSUABLE, paramsGas)
    })
  }).then(() => {
    console.log('chronoBankPlatform.setProxy')
    return chronoBankPlatform.setProxy(ChronoBankAssetProxy.address, TIME_SYMBOL, params)
  }).then(() => {
    console.log('chronoBankAssetProxy.proposeUpgrade')
    return chronoBankAssetProxy.proposeUpgrade(ChronoBankAsset.address, params)
  }).then(() => {
    console.log('chronoBankAssetProxy.transfer')
    return chronoBankAssetProxy.transfer(assetsManager.address, 1000000000000, params)
  }).then(() => {
    console.log('chronoBankPlatform.changeOwnership')
    return chronoBankPlatform.changeOwnership(TIME_SYMBOL, assetsManager.address, params)
  }).then(() => {
    console.log('chronoBankPlatform.setProxy')
    return chronoBankPlatform.setProxy(ChronoBankAssetWithFeeProxy.address, LHT_SYMBOL, params)
  }).then(() => {
    console.log('chronoBankAssetWithFeeProxy.proposeUpgrade')
    return chronoBankAssetWithFeeProxy.proposeUpgrade(ChronoBankAssetWithFee.address, params)
  }).then(() => {
    console.log('chronoBankAssetWithFee.setupFee')
    return chronoBankAssetWithFee.setupFee(Rewards.address, 100, {from: accounts[0]})
  }).then(() => {
    console.log('chronoBankPlatform.changeOwnership')
    return chronoBankPlatform.changeOwnership(LHT_SYMBOL, assetsManager.address, params)
  }).then(() => {
    console.log('chronoBankPlatform.changeContractOwnership')
    return chronoBankPlatform.changeContractOwnership(assetsManager.address, {from: accounts[0]})
  }).then(() => {
    console.log('assetsManager.claimPlatformOwnership')
    return assetsManager.claimPlatformOwnership({from: accounts[0]})
  }).then(() => {
    console.log('assetsManager.addAsset TIME')
    return assetsManager.addAsset(chronoBankAssetProxy.address, TIME_SYMBOL, accounts[0], paramsGas)
  }).then(() => {
    console.log('assetsManager.addAsset LHT')
    return assetsManager.addAsset(chronoBankAssetWithFeeProxy.address, LHT_SYMBOL, chronoMint.address, paramsGas)
  }).then(() => {
    callback()
  }).catch(function (e) {
    console.log(e)
  })
}

module.exports.setup = setup
module.exports.contractTypes = contractTypes

module.exports = (callback) => {
  return setup(callback)
}