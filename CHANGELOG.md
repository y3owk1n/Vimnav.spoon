# Changelog

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
