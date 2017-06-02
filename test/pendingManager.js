var FakeCoin = artifacts.require("./FakeCoin.sol");
var FakeCoin2 = artifacts.require("./FakeCoin2.sol");
var ChronoBankPlatform = artifacts.require("./ChronoBankPlatform.sol");
var ChronoBankPlatformEmitter = artifacts.require("./ChronoBankPlatformEmitter.sol");
var EventsHistory = artifacts.require("./EventsHistory.sol");
var ChronoBankAssetProxy = artifacts.require("./ChronoBankAssetProxy.sol");
var ChronoBankAssetWithFeeProxy = artifacts.require("./ChronoBankAssetWithFeeProxy.sol");
var ChronoBankAsset = artifacts.require("./ChronoBankAsset.sol");
var ChronoBankAssetWithFee = artifacts.require("./ChronoBankAssetWithFee.sol");
var ChronoMintEmitter = artifacts.require("./ChronoMintEmitter.sol");
var Exchange = artifacts.require("./Exchange.sol");
var Rewards = artifacts.require("./Rewards.sol");
var ChronoMint = artifacts.require("./ChronoMint.sol");
var AssetsManager = artifacts.require("./AssetsManager");
var ContractsManager = artifacts.require("./ContractsManager.sol");
var ProxyFactory = artifacts.require("./ProxyFactory.sol");
var ERC20Manager = artifacts.require("./ERC20Manager.sol");
var ExchangeManager = artifacts.require("./ExchangeManager.sol");
var UserManager = artifacts.require("./UserManager.sol");
var UserStorage = artifacts.require("./UserStorage.sol");
var Shareable = artifacts.require("./PendingManager.sol");
var LOC = artifacts.require("./LOC.sol");
var TimeHolder = artifacts.require("./TimeHolder.sol");
var RateTracker = artifacts.require("./KrakenPriceTicker.sol");
var Reverter = require('./helpers/reverter');
var bytes32 = require('./helpers/bytes32');
var bytes32fromBase58 = require('./helpers/bytes32fromBase58');
var Require = require("truffle-require");
var Config = require("truffle-config");
var eventsHelper = require('./helpers/eventsHelper');

contract('Pending Manager', function(accounts) {
  var owner = accounts[0];
  var owner1 = accounts[1];
  var owner2 = accounts[2];
  var owner3 = accounts[3];
  var owner4 = accounts[4];
  var owner5 = accounts[5];
  var nonOwner = accounts[6];
  var locController1 = accounts[7];
  var locController2 = accounts[7];
  var conf_sign;
  var conf_sign2;
  var conf_sign3;
  var assetsManager;
  var coin;
  var coin2;
  var chronoMint;
  var chronoMintEmitter;
  var chronoBankPlatform;
  var chronoBankPlatformEmitter;
  var contractsManager;
  var eventsHistory;
  var shareable;
  var platform;
  var timeContract;
  var lhContract;
  var timeProxyContract;
  var lhProxyContract;
  var erc20Manager;
  var exchangeManager;
  var rewards;
  var userManager;
  var userStorage;
  var timeHolder;
  var rateTracker;
  var txId;
  var watcher;
  var loc_contracts = [];
  var labor_hour_token_contracts = [];
  var Status = {maintenance:0,active:1, suspended:2, bankrupt:3};
  var unix = Math.round(+new Date()/1000);

  const SYMBOL = 'TIME';
  const SYMBOL2 = 'LHT';
  const NAME = 'Time Token';
  const DESCRIPTION = 'ChronoBank Time Shares';
  const NAME2 = 'Labour-hour Token';
  const DESCRIPTION2 = 'ChronoBank Lht Assets';
  const BASE_UNIT = 2;
  const IS_REISSUABLE = true;
  const IS_NOT_REISSUABLE = false;
  const BALANCE_ETH = 1000;
  const fakeArgs = [0,0,0,0,0,0,0,0];

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

  before('setup', function(done) {
    FakeCoin.deployed().then(function(instance) {
      coin = instance
      return FakeCoin2.deployed()
    }).then(function(instance) {
      coin2 = instance
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
      return TimeHolder.deployed()
    }).then(function (instance) {
      timeHolder = instance;
      return instance.init(ContractsManager.address, ChronoBankAssetProxy.address)
    }).then(function () {
      return timeHolder.addListener(rewards.address)
    }).then(function () {
      return ChronoBankPlatformEmitter.deployed()
    }).then(function (instance) {
      chronoBankPlatformEmitter = instance;
      return ChronoMintEmitter.deployed()
    }).then(function (instance) {
      chronoMintEmitter = instance;
      return EventsHistory.deployed()
    }).then(function (instance) {
      eventsHistory = instance;
      return chronoBankPlatform.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return chronoMint.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return userManager.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return pendingManager.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoMintEmitter.contract.newLOC.getData.apply(this, fakeArgs).slice(0, 10), ChronoMintEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoMintEmitter.contract.hashUpdate.getData.apply(this, fakeArgs).slice(0, 10), ChronoMintEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitTransfer.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitIssue.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitRevoke.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitOwnershipChange.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitApprove.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitRecovery.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addEmitter(chronoBankPlatformEmitter.contract.emitError.getData.apply(this, fakeArgs).slice(0, 10), ChronoBankPlatformEmitter.address, {
        from: accounts[0],
        gas: 3000000
      });
    }).then(function () {
      return eventsHistory.addVersion(chronoBankPlatform.address, "Origin", "Initial version.");
    }).then(function () {
      return eventsHistory.addVersion(chronoMint.address, "Origin", "Initial version.");
    }).then(function () {
      return eventsHistory.addVersion(userManager.address, "Origin", "Initial version.");
    }).then(function () {
      return chronoBankPlatform.issueAsset(SYMBOL, 200000000000, NAME, DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(function (r) {
      return chronoBankPlatform.setProxy(ChronoBankAssetProxy.address, SYMBOL, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankPlatform.address, SYMBOL, NAME, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      return instance.proposeUpgrade(ChronoBankAsset.address, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAsset.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankAssetProxy.address, {from: accounts[0]})
    }).then(function (r) {
      return ChronoBankAssetProxy.deployed()
    }).then(function (instance) {
      return instance.transfer(assetsManager.address, 200000000000, {from: accounts[0]})
    }).then(function (r) {
      return chronoBankPlatform.changeOwnership(SYMBOL, assetsManager.address, {from: accounts[0]})
    }).then(function (r) {
      return chronoBankPlatform.issueAsset(SYMBOL2, 0, NAME2, DESCRIPTION2, BASE_UNIT, IS_REISSUABLE, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(function () {
      return chronoBankPlatform.setProxy(ChronoBankAssetWithFeeProxy.address, SYMBOL2, {from: accounts[0]})
    }).then(function () {
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankPlatform.address, SYMBOL2, NAME2, {from: accounts[0]})
    }).then(function () {
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(function (instance) {
      return instance.proposeUpgrade(ChronoBankAssetWithFee.address, {from: accounts[0]})
    }).then(function () {
      return ChronoBankAssetWithFee.deployed()
    }).then(function (instance) {
      return instance.init(ChronoBankAssetWithFeeProxy.address, {from: accounts[0]})
    }).then(function (instance) {
      return ChronoBankAssetWithFee.deployed()
    }).then(function (instance) {
      return instance.setupFee(Rewards.address, 100, {from: accounts[0]})
    }).then(function () {
      return ChronoBankPlatform.deployed()
    }).then(function (instance) {
      return instance.changeOwnership(SYMBOL2, assetsManager.address, {from: accounts[0]})
    }).then(function () {
      return chronoBankPlatform.changeContractOwnership(assetsManager.address, {from: accounts[0]})
    }).then(function () {
      return assetsManager.claimPlatformOwnership({from: accounts[0]})
    }).then(function(instance) {
      return ChronoBankPlatformEmitter.at(EventsHistory.address)
    }).then(function (instance) {
      var events = instance.Error({fromBlock: "latest"});
      events.watch(function(error, result) {
        // This will catch all Transfer events, regardless of how they originated.
        if (error == null) {
          console.log(result.args);
        }
      })
    }).then(function () {
      //web3.eth.sendTransaction({to: Exchange.address, value: BALANCE_ETH, from: accounts[0]});
      done();
    }).catch(function (e) { console.log(e); });
    //reverter.snapshot(done);
  });

  context("with one CBE key", function(){

    it("shows owner as a CBE key.", function() {
      return chronoMint.isAuthorized.call(owner).then(function(r) {
        assert.isOk(r);
      });
    });

    it("doesn't show owner1 as a CBE key.", function() {
      return chronoMint.isAuthorized.call(owner1).then(function(r) {
        assert.isNotOk(r);
      });
    });

    it("doesn't allows non CBE key to add another CBE key.", function() {
      return userManager.addCBE(owner1,0x0,{from:owner1}).then(function() {
        return userManager.isAuthorized.call(owner1).then(function(r){
          assert.isNotOk(r);
        });
      });
    });

    it("shouldn't allow setRequired signatures 2.", function() {
      return userManager.setRequired(2).then(function() {
        return userManager.required.call({from: owner}).then(function(r) {
          assert.equal(r, 1);
        });
      });
    });

    it("allows one CBE key to add another CBE key.", function() {
      return userManager.addCBE(owner1,0x0).then(function() {
        return userManager.isAuthorized.call(owner1).then(function(r){
          assert.isOk(r);
        });
      });
    });

    it("should allow setRequired signatures 2.", function() {
      return userManager.setRequired(2).then(function() {
        return userManager.required.call({from: owner}).then(function(r) {
          assert.equal(r, 2);
        });
      });
    });

  });

  context("with two CBE keys", function(){

    it("shows owner as a CBE key.", function() {
      return chronoMint.isAuthorized.call(owner).then(function(r) {
        assert.isOk(r);
      });
    });

    it("shows owner1 as a CBE key.", function() {
      return chronoMint.isAuthorized.call(owner1).then(function(r) {
        assert.isOk(r);
      });
    });

    it("doesn't show owner2 as a CBE key.", function() {
      return chronoMint.isAuthorized.call(owner2).then(function(r) {
        assert.isNotOk(r);
      });
    });

    it("pending operation counter should be 0", function() {
      return shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("allows to propose pending operation", function() {
      eventsHelper.setupEvents(shareable);
      watcher = shareable.Confirmation();
      return userManager.addCBE(owner2, 0x0, {from:owner}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        shareable.pendingsCount.call({from: owner}).then(function(r) {
          assert.equal(r,1);
        });
      });
    });

    it("allows to revoke last confirmation and remove pending operation", function() {
      return shareable.revoke(conf_sign, {from:owner}).then(function() {
        shareable.pendingsCount.call({from: owner}).then(function(r) {
          assert.equal(r,0);
        });
      });
    });

    it("allows one CBE key to add another CBE key", function() {
      return userManager.addCBE(owner2, 0x0, {from:owner}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign, {from:owner1}).then(function() {
          return chronoMint.isAuthorized.call(owner2).then(function(r){
            assert.isOk(r);
          });
        });
      });
    });

    it("pending operation counter should be 0", function() {
      return shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("should allow setRequired signatures 3.", function() {
      return userManager.setRequired(3).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign,{from:owner1}).then(function() {
          return userManager.required.call({from: owner}).then(function(r) {
            assert.equal(r, 3);
          });
        });
      });
    });

  });

  context("with three CBE keys", function(){

    it("allows 2 votes for the new key to grant authorization.", function() {
      return userManager.addCBE(owner3, 0x0, {from: owner2}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign,{from:owner}).then(function() {
          return shareable.confirm(conf_sign,{from:owner1}).then(function() {
            return chronoMint.isAuthorized.call(owner3).then(function(r){
              assert.isOk(r);
            });
          });
        });
      });
    });

    it("pending operation counter should be 0", function() {
      return shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("should allow set required signers to be 4", function() {
      return userManager.setRequired(4).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign,{from:owner1}).then(function() {
          return shareable.confirm(conf_sign,{from:owner2}).then(function() {
            return userManager.required.call({from: owner}).then(function(r) {
              assert.equal(r, 4);
            });
          });
        });
      });
    });

  });

  context("with four CBE keys", function(){

    it("allows 3 votes for the new key to grant authorization.", function() {
      return userManager.addCBE(owner4, 0x0, {from: owner3}).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign,{from:owner}).then(function() {
          return shareable.confirm(conf_sign,{from:owner1}).then(function() {
            return shareable.confirm(conf_sign,{from:owner2}).then(function() {
              //  return shareable.confirm(conf_sign,{from:owner3}).then(function() {
              return chronoMint.isAuthorized.call(owner3).then(function(r){
                assert.isOk(r);
              });
              //    });
            });
          });
        });
      });
    });

    it("pending operation counter should be 0", function() {
      return shareable.pendingsCount.call({from: owner}).then(function(r) {
        assert.equal(r, 0);
      });
    });

    it("should allow set required signers to be 5", function() {
      return userManager.setRequired(5).then(function(txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign,{from:owner1}).then(function() {
          return shareable.confirm(conf_sign,{from:owner2}).then(function() {
            return shareable.confirm(conf_sign,{from:owner3}).then(function() {
              return userManager.required.call({from: owner}).then(function(r2) {
                assert.equal(r2, 5);
              });
            });
          });
        });
      });
    });

  });

  context("with five CBE keys", function() {
    it("collects 4 vote to addCBE and granting auth.", function () {
      return userManager.addCBE(owner5, 0x0, {from: owner4}).then(function (txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign, {from: owner}).then(function () {
          return shareable.confirm(conf_sign, {from: owner1}).then(function () {
            return shareable.confirm(conf_sign, {from: owner2}).then(function () {
              return shareable.confirm(conf_sign, {from: owner3}).then(function () {
                return chronoMint.isAuthorized.call(owner5).then(function (r) {
                  assert.isOk(r);
                });
              });
            });
          });
        });
      });
    });

    it("can show all members", function () {
      return userStorage.getCBEMembers.call().then(function (r) {
        assert.equal(r[0][0], owner);
        assert.equal(r[0][1], owner1);
        assert.equal(r[0][2], owner2);
      });
    });

    it("required signers should be 6", function () {
      return userManager.setRequired(6).then(function (txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign = events[0].args.hash;
        return shareable.confirm(conf_sign, {from: owner1}).then(function () {
          return shareable.confirm(conf_sign, {from: owner2}).then(function () {
            return shareable.confirm(conf_sign, {from: owner3}).then(function () {
              return shareable.confirm(conf_sign, {from: owner4}).then(function () {
                return userManager.required.call({from: owner}).then(function (r) {
                  assert.equal(r, 6);
                });
              });
            });
          });
        });
      });
    });


    it("pending operation counter should be 0", function () {
      return shareable.pendingsCount.call({from: owner}).then(function (r) {
        assert.equal(r, 0);
      });
    });


    it("allows a CBE to propose revocation of an authorized key.", function () {
      return userManager.revokeCBE(owner5, {from: owner}).then(function (txHash) {
        return eventsHelper.getEvents(txHash, watcher);
      }).then(function(events) {
        console.log(events[0].args.hash);
        conf_sign2 = events[0].args.hash;
        return userManager.isAuthorized.call(owner5).then(function (r) {
          assert.isOk(r);
        });
      });
    });

    it("check confirmation yet needed should be 5", function () {
      return shareable.pendingYetNeeded.call(conf_sign2).then(function (r) {
        assert.equal(r, 5);
      });
    });

    it("should increment pending operation counter ", function () {
      return shareable.pendingsCount.call({from: owner}).then(function (r) {
        assert.equal(r, 1);
      });
    });

    it("allows 5 CBE member vote for the revocation to revoke authorization.", function () {
      return shareable.confirm(conf_sign2, {from: owner1}).then(function () {
        return shareable.confirm(conf_sign2, {from: owner2}).then(function () {
          return shareable.confirm(conf_sign2, {from: owner3}).then(function () {
            return shareable.confirm(conf_sign2, {from: owner4}).then(function () {
              return shareable.confirm(conf_sign2, {from: owner5}).then(function () {
                return chronoMint.isAuthorized.call(owner5).then(function (r) {
                  assert.isNotOk(r);
                });
              });
            });
          });
        });
      });
    });

    it("required signers should be 5", function () {
      return userManager.required.call({from: owner}).then(function (r) {
        assert.equal(r, 5);
      });
    });

    it("should decrement pending operation counter ", function () {
      return shareable.pendingsCount.call({from: owner}).then(function (r) {
        assert.equal(r, 0);
      });
    });

  });
});
