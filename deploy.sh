DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=999999 dapp build;

export DAPP_SOLC_VERSION=0.6.12
export ETH_FROM=0xD5097b1E873f8603e501Cace6B29Ef7216e9d3AC
export ETH_PASSWORD=eth_pass
export ETH_KEYSTORE=~/.ethereum/keystore
# export ETH_RPC_URL=https://proxy.devnet.neonlabs.org/solana
export ETH_RPC_URL=http://localhost:9090/solana
export ETH_GAS=300000000
export ETH_GAS_PRICE=200000000000

daiAddress=$(dapp create Dai 99) # 0x839D82c04040B288408c5Dd4E9F00548b5AAc5Fe
vatAddress=$(dapp create Vat) # 0xc5B22825c2A6bd5eEBbf463C29a23f9eb2d40f2a
jugAddress=$(dapp create Jug $vatAddress) # 0x1e0be20e67df82E1f17423b9955cd388E0ABFE86
gemAddress=$(dapp create Gem) # 0x831445963834eD3957d84549fD8670a9C5345aac
flopAddress=$(dapp create Flopper $vatAddress $gemAddress) # 0x071466F5c0b57017f060A5855CB66344F0C7F9Cd
flapAddress=$(dapp create Flapper $vatAddress $gemAddress) # 0xED4252Bfe50eb5f8A4972C093Cc84950Faca163c
vowAddress=$(dapp create Vow $vatAddress $flapAddress $flopAddress) # 0x3e676E0e46fFBe806C1a4AE3d51300F5193620A7
catAddress=$(dapp create Cat $vatAddress) # 0xCE42e34CaB8BaC517dd9b981D8F665cE7608F3e2
dogAddress=$(dapp create Dog $vatAddress) # 0x262a13d40DFf4326e5029A969F3e23452dcF6D45
flipAddress=$(dapp create Flipper $vatAddress $catAddress 0x67656d73) # 0x630b6A2373A006C51272aB7F20F0e151Deb7B835
spotAddress=$(dapp create Spotter $vatAddress) # 0x77fFdB31a6987D9e1Fb86daBAE9Eb7ae78459aee
clipAddress=$(dapp create Clipper $vatAddress $spotAddress $dogAddress 0x676f6c64) # 0x1fae3F9Fc3Dba3F5cfe7bd7fde7C0C3d00a40f12
potAddress=$(dapp create Pot $vatAddress) # 0x3FE468121A57ef4511C9E3db6e7c55676d6538Fb
cureAddress=$(dapp create Cure) # 0x53BF8A3aB55Acd1F995EFe5cd7Bd826DF15CeEdA
endAddress=$(dapp create End) # 0xDd0d78902c6F44c81ded90a31E6b531088DAE433

echo Dai: $daiAddress
echo Vat: $vatAddress
echo Jug: $jugAddress
echo Gem: $gemAddress
echo Flopper: $flopAddress
echo Flapper: $flapAddress
echo Vow: $vowAddress
echo Cat: $catAddress
echo Dog: $dogAddress
echo Flipper: $flipAddress
echo Spotter: $spotAddress
echo Clipper: $clipAddress
echo Pot: $potAddress
echo Cure: $cureAddress
echo End: $endAddress
