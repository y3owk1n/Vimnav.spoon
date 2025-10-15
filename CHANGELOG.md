# Changelog

## [1.2.1](https://github.com/y3owk1n/Vimnav.spoon/compare/v1.2.0...v1.2.1) (2025-10-15)


### Bug Fixes

* completely remove state and move diff states into own modules ([#81](https://github.com/y3owk1n/Vimnav.spoon/issues/81)) ([d810a66](https://github.com/y3owk1n/Vimnav.spoon/commit/d810a66be331e623704fc061a9475c54ef57a561))
* move `eventloop` out from state ([#73](https://github.com/y3owk1n/Vimnav.spoon/issues/73)) ([e7b48d4](https://github.com/y3owk1n/Vimnav.spoon/commit/e7b48d499163aba36ee32796e2beffa7a338c0ac))
* move `mappings` out from state ([#80](https://github.com/y3owk1n/Vimnav.spoon/issues/80)) ([2428d6f](https://github.com/y3owk1n/Vimnav.spoon/commit/2428d6f854eb25639d8fb3d56fbefdfc818702c0))
* move `marks` out from state ([#79](https://github.com/y3owk1n/Vimnav.spoon/issues/79)) ([ad3a2fd](https://github.com/y3owk1n/Vimnav.spoon/commit/ad3a2fd3dae9a90deb6838cff4f9e8255f11c7c0))
* move `menubar` out from state ([#77](https://github.com/y3owk1n/Vimnav.spoon/issues/77)) ([ad75c24](https://github.com/y3owk1n/Vimnav.spoon/commit/ad75c241b50daf9ce3e6814d7f50181dbb2c5007))
* move `overlay` out from state ([#78](https://github.com/y3owk1n/Vimnav.spoon/issues/78)) ([cd5a279](https://github.com/y3owk1n/Vimnav.spoon/commit/cd5a27999a015efe7f70e182da4b4c204be82f62))
* move `timers` out from state ([#75](https://github.com/y3owk1n/Vimnav.spoon/issues/75)) ([d3c26b2](https://github.com/y3owk1n/Vimnav.spoon/commit/d3c26b2a831a92b8941009850a0105d0c5418ec9))
* move `watchers` out from state ([#74](https://github.com/y3owk1n/Vimnav.spoon/issues/74)) ([ffe3080](https://github.com/y3owk1n/Vimnav.spoon/commit/ffe30803cc65a9a08fa46960654f6aa5096ca4c7))
* move `whichkeycanvas` out from state ([#76](https://github.com/y3owk1n/Vimnav.spoon/issues/76)) ([4fa8161](https://github.com/y3owk1n/Vimnav.spoon/commit/4fa81612836d0b692747f27563ade8a732a2c7bb))
* update loggings after split refactoring ([#71](https://github.com/y3owk1n/Vimnav.spoon/issues/71)) ([9c18b77](https://github.com/y3owk1n/Vimnav.spoon/commit/9c18b7795d2f6015472d6d897b2ff734d0402df7))

## [1.2.0](https://github.com/y3owk1n/Vimnav.spoon/compare/v1.1.1...v1.2.0) (2025-10-12)


### Features

* add arrow keys remap and move `back`/`forward` to `<leader>` ([#56](https://github.com/y3owk1n/Vimnav.spoon/issues/56)) ([4a2d062](https://github.com/y3owk1n/Vimnav.spoon/commit/4a2d0624cc9c8a654d367a679536b663ed9589b2))
* add caffeine & screen watcher ([#65](https://github.com/y3owk1n/Vimnav.spoon/issues/65)) ([8e5c32b](https://github.com/y3owk1n/Vimnav.spoon/commit/8e5c32b1a2126831253f3d211ce1a077edae5180))
* add electron and chromium support for enhanced accessibility ([#62](https://github.com/y3owk1n/Vimnav.spoon/issues/62)) ([3f8cd60](https://github.com/y3owk1n/Vimnav.spoon/commit/3f8cd60da1f850dd2cc6c46a8d211bb6fd30aeb9))
* add which-key help with refactoring keymaps with description ([#51](https://github.com/y3owk1n/Vimnav.spoon/issues/51)) ([7299140](https://github.com/y3owk1n/Vimnav.spoon/commit/72991401abd57513dc181200d076f3a7e3bbb27e))
* support simple visual mode for text selection ([#58](https://github.com/y3owk1n/Vimnav.spoon/issues/58)) ([635ebab](https://github.com/y3owk1n/Vimnav.spoon/commit/635ebab98a7799915464f2b130396a10ce84e287))


### Bug Fixes

* also call enableEnhanced* before watcher starts ([#64](https://github.com/y3owk1n/Vimnav.spoon/issues/64)) ([b9eba88](https://github.com/y3owk1n/Vimnav.spoon/commit/b9eba88098582c4d501edb07bf874f193d26ad89))
* avoid clearing cache on focus timer ([#63](https://github.com/y3owk1n/Vimnav.spoon/issues/63)) ([92827fe](https://github.com/y3owk1n/Vimnav.spoon/commit/92827fe6f1e2c2858b315cde1e2dc2d099457324))
* centralise cleanup to avoid messiness ([#66](https://github.com/y3owk1n/Vimnav.spoon/issues/66)) ([2586e20](https://github.com/y3owk1n/Vimnav.spoon/commit/2586e20dfbb111404c15f9e31fc00f87c5fb1fc0))
* centralise state, cache, timer, watcher managers with stop and start function ([#67](https://github.com/y3owk1n/Vimnav.spoon/issues/67)) ([27a776c](https://github.com/y3owk1n/Vimnav.spoon/commit/27a776c02182592824884128f79f48771f5a1798))
* dynamic width for key and description ([#54](https://github.com/y3owk1n/Vimnav.spoon/issues/54)) ([73916cc](https://github.com/y3owk1n/Vimnav.spoon/commit/73916cc802941d6430ed661f7e21b88a904b51bc))
* handle ctrl key for visual mode too ([#60](https://github.com/y3owk1n/Vimnav.spoon/issues/60)) ([d7da762](https://github.com/y3owk1n/Vimnav.spoon/commit/d7da7626c9705fec6298d90e344f7e19f749f4fa))
* move canvas and menubar to state ([#68](https://github.com/y3owk1n/Vimnav.spoon/issues/68)) ([20fbdcc](https://github.com/y3owk1n/Vimnav.spoon/commit/20fbdcc805723f821ddbe9bcd0bdb3e5607fc80f))
* prevent `Utils.keyStroke` to re-enter eventloop ([#55](https://github.com/y3owk1n/Vimnav.spoon/issues/55)) ([be97c15](https://github.com/y3owk1n/Vimnav.spoon/commit/be97c15fcf8ab133f3ef7b92499979b5298f6d8a))
* use `+more` as group description in whichkey ([#53](https://github.com/y3owk1n/Vimnav.spoon/issues/53)) ([f491362](https://github.com/y3owk1n/Vimnav.spoon/commit/f49136215b481840a371742280b6712766782c0b))

## [1.1.1](https://github.com/y3owk1n/Vimnav.spoon/compare/v1.1.0...v1.1.1) (2025-10-03)


### Bug Fixes

* add `x` key mapping for delete a char in insertNormal mode ([#47](https://github.com/y3owk1n/Vimnav.spoon/issues/47)) ([697903f](https://github.com/y3owk1n/Vimnav.spoon/commit/697903f9e54d729b4f3c95e176096d850ca45a52))
* only process focused axwindow ([#45](https://github.com/y3owk1n/Vimnav.spoon/issues/45)) ([e50cc7d](https://github.com/y3owk1n/Vimnav.spoon/commit/e50cc7db2a64e50ed7c793cfb990fa57210f4a61))
* remove leaderkey timeout ([#48](https://github.com/y3owk1n/Vimnav.spoon/issues/48)) ([110d87b](https://github.com/y3owk1n/Vimnav.spoon/commit/110d87bc63eb7ea4a7f8147d8e715e4050a44174))

## [1.1.0](https://github.com/y3owk1n/Vimnav.spoon/compare/v1.0.0...v1.1.0) (2025-10-03)


### Features

* add basic vim movements that is mappable with keyboard shortcuts ([#21](https://github.com/y3owk1n/Vimnav.spoon/issues/21)) ([035e3a3](https://github.com/y3owk1n/Vimnav.spoon/commit/035e3a3a30a062d55d359042ff69de5626571a6b))
* add configurable indicator for `menubar` or `overlay` ([#26](https://github.com/y3owk1n/Vimnav.spoon/issues/26)) ([ef436cb](https://github.com/y3owk1n/Vimnav.spoon/commit/ef436cb3e4fc5b895dce2e8f7cd813fe348c04b0))
* add double left click and map to `F` key ([#42](https://github.com/y3owk1n/Vimnav.spoon/issues/42)) ([8e310ef](https://github.com/y3owk1n/Vimnav.spoon/commit/8e310efee766b60e5b114cf35228d4bdc5c9dfd0))
* add editable related callbacks for other integrations ([#6](https://github.com/y3owk1n/Vimnav.spoon/issues/6)) ([9b215d3](https://github.com/y3owk1n/Vimnav.spoon/commit/9b215d3555d7e094a648d85a9b51ded42862138d))
* add more mappings ([#33](https://github.com/y3owk1n/Vimnav.spoon/issues/33)) ([7a7b68a](https://github.com/y3owk1n/Vimnav.spoon/commit/7a7b68a9576672d12cb10ed3be3cff1df029ee18))
* adhere to hammerspoon API convention & improve self chaining and APIs ([#14](https://github.com/y3owk1n/Vimnav.spoon/issues/14)) ([f7d57a1](https://github.com/y3owk1n/Vimnav.spoon/commit/f7d57a1e42515af336e3d172a738884a4ca214ed))
* make canvas font configurable ([#39](https://github.com/y3owk1n/Vimnav.spoon/issues/39)) ([d0e92cd](https://github.com/y3owk1n/Vimnav.spoon/commit/d0e92cdc1dc182c7d83bd45425b03a53109c0826))
* make font size for marks configurable ([#29](https://github.com/y3owk1n/Vimnav.spoon/issues/29)) ([8760961](https://github.com/y3owk1n/Vimnav.spoon/commit/876096128a6fbf4a4e42580b9a4296de4f9edad1))
* make hint styles configurable ([#38](https://github.com/y3owk1n/Vimnav.spoon/issues/38)) ([fda90cb](https://github.com/y3owk1n/Vimnav.spoon/commit/fda90cb87be14e78f0745d7095044e22da2afcac))
* regrouping config table and fix tblmerge ([#30](https://github.com/y3owk1n/Vimnav.spoon/issues/30)) ([81c8b16](https://github.com/y3owk1n/Vimnav.spoon/commit/81c8b16cb667a9f7c2f8175153d93a82f7fec43a))
* remove double esc logic and use `shift+esc` ([#32](https://github.com/y3owk1n/Vimnav.spoon/issues/32)) ([11e02f1](https://github.com/y3owk1n/Vimnav.spoon/commit/11e02f1fb47c6726d2e56130a5e90585cb7bfd1d))
* slightly rename cmds and allow for noop mapping ([#34](https://github.com/y3owk1n/Vimnav.spoon/issues/34)) ([e37231a](https://github.com/y3owk1n/Vimnav.spoon/commit/e37231a0b598f2a2516f4e5076b4d59d1205d2ba))
* support leaderkey ([#41](https://github.com/y3owk1n/Vimnav.spoon/issues/41)) ([188eb8f](https://github.com/y3owk1n/Vimnav.spoon/commit/188eb8f89e70e7d9f278053670ea4f3c7b953e17))
* support plain function for mappings ([#31](https://github.com/y3owk1n/Vimnav.spoon/issues/31)) ([13b0f74](https://github.com/y3owk1n/Vimnav.spoon/commit/13b0f7462a598b5e4effbbad9302f967077eb923))


### Bug Fixes

* always run unfocus callback ([#10](https://github.com/y3owk1n/Vimnav.spoon/issues/10)) ([dd00108](https://github.com/y3owk1n/Vimnav.spoon/commit/dd00108cebfe3c939a50f1173814dcad6e21fd79))
* avoid spamming editable related callbacks in event loop ([#7](https://github.com/y3owk1n/Vimnav.spoon/issues/7)) ([a88be86](https://github.com/y3owk1n/Vimnav.spoon/commit/a88be86a0025ee2df029cd800ac6cf63ce70602d))
* bypass keys to allow faster response time for navigation within editable elements ([#3](https://github.com/y3owk1n/Vimnav.spoon/issues/3)) ([718c785](https://github.com/y3owk1n/Vimnav.spoon/commit/718c78556a9e166ecaaf79881b62c0afd13fdf07))
* ensure all variant of `insert` mode is checked in focus watcher ([#23](https://github.com/y3owk1n/Vimnav.spoon/issues/23)) ([b1570b5](https://github.com/y3owk1n/Vimnav.spoon/commit/b1570b5fed47fde7ca6062db216b98dcff9acb27))
* ensure escape in normal mode propogates the key to the app ([#27](https://github.com/y3owk1n/Vimnav.spoon/issues/27)) ([d493c04](https://github.com/y3owk1n/Vimnav.spoon/commit/d493c04fd0c75df962d38b2f98bd06dce1a13971))
* ensure focus reset itself ([#5](https://github.com/y3owk1n/Vimnav.spoon/issues/5)) ([708f769](https://github.com/y3owk1n/Vimnav.spoon/commit/708f7690763ed38f1c4b1a7fbec50cfff47dbf1a))
* ensure launchers are detected properly and set to disabled mode ([#24](https://github.com/y3owk1n/Vimnav.spoon/issues/24)) ([e9bf1fe](https://github.com/y3owk1n/Vimnav.spoon/commit/e9bf1fe46fc90c7731c9785000d415174edc7a81))
* ensure to return boolean to the event loop ([#22](https://github.com/y3owk1n/Vimnav.spoon/issues/22)) ([7c6bcb7](https://github.com/y3owk1n/Vimnav.spoon/commit/7c6bcb7c3c5cee9d5c9ae9b124a96aec3393f45d))
* ensure to validate if callback is a function ([#8](https://github.com/y3owk1n/Vimnav.spoon/issues/8)) ([8ffe6ec](https://github.com/y3owk1n/Vimnav.spoon/commit/8ffe6ec59dfc7127bf99eadc143ad0e15afd19bb))
* make config in table extendable with public APIs ([#13](https://github.com/y3owk1n/Vimnav.spoon/issues/13)) ([66cbb33](https://github.com/y3owk1n/Vimnav.spoon/commit/66cbb331a0c88bfb2e31db9d7bb288067b4cfb5f))
* refactor event handlers and magically fix key repeats ([#17](https://github.com/y3owk1n/Vimnav.spoon/issues/17)) ([82df4ac](https://github.com/y3owk1n/Vimnav.spoon/commit/82df4ac9ab9175f72708b7376bf39cbd3e64ef99))
* refactor modes to always return boolean and previous mode for logics ([#18](https://github.com/y3owk1n/Vimnav.spoon/issues/18)) ([2366f1e](https://github.com/y3owk1n/Vimnav.spoon/commit/2366f1e774f5744cbf300a0a44507d9f4da76838))
* remove font approximation, it's nicer ([#40](https://github.com/y3owk1n/Vimnav.spoon/issues/40)) ([7aea459](https://github.com/y3owk1n/Vimnav.spoon/commit/7aea4596971bec8b6fa09a40e07f807b15fb7a44))
* remove multi mode ([#20](https://github.com/y3owk1n/Vimnav.spoon/issues/20)) ([04a5b40](https://github.com/y3owk1n/Vimnav.spoon/commit/04a5b40ead15a7df4d89d6ded4fcfd1d32e7931d))
* should pass char instead of nil ([#19](https://github.com/y3owk1n/Vimnav.spoon/issues/19)) ([8128bcd](https://github.com/y3owk1n/Vimnav.spoon/commit/8128bcd5de350110cae951df1a7e54cff8badfda))
* slight rewrite of how focus detection works ([#9](https://github.com/y3owk1n/Vimnav.spoon/issues/9)) ([e0310de](https://github.com/y3owk1n/Vimnav.spoon/commit/e0310de945cd0a0c93f538a848eb05e6183beaae))
* update some typo during refactoring ([#37](https://github.com/y3owk1n/Vimnav.spoon/issues/37)) ([5cdba49](https://github.com/y3owk1n/Vimnav.spoon/commit/5cdba49423e7e0506d0e6f5a3ecb1ac186d5b76a))
* use timer to track focus, think it's the most reliable way ([#11](https://github.com/y3owk1n/Vimnav.spoon/issues/11)) ([4b6dc3f](https://github.com/y3owk1n/Vimnav.spoon/commit/4b6dc3ff9405702ec7ef124a2061d6328421c008))

## 1.0.0 (2025-09-27)


### Features

* init from config ([#1](https://github.com/y3owk1n/Vimnav.spoon/issues/1)) ([baec540](https://github.com/y3owk1n/Vimnav.spoon/commit/baec540e1539a50a299017774cbd7f112a60ef25))
