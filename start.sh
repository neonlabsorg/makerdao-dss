DAPP_BUILD_EXTRACT=1 dapp build

rm -rf abi/
mkdir abi/
mv out/*.abi abi/

DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=999999 dapp build

export DAPP_SOLC_VERSION=0.6.12
export ETH_FROM=0xD5097b1E873f8603e501Cace6B29Ef7216e9d3AC
export ETH_PASSWORD=eth_pass
export ETH_KEYSTORE=~/.ethereum/keystore
# export ETH_RPC_URL=https://proxy.devnet.neonlabs.org/solana
export ETH_RPC_URL=http://localhost:9090/solana
export ETH_GAS=300000000
export ETH_GAS_PRICE=200000000000

fail() { echo "FAIL $contractName::$method"; }
pass() { echo "PASS $contractName::$method"; }

testcase() {
  seth send $contractAddress "$method()"
  result=$(seth call "$contractAddress" 'failed()(bool)')
  if [[ "$result" == true ]]; then
    if [[ "$method" == testFail* ]]; then pass; else fail; fi
  else
    if [[ "$method" == testFail* ]]; then fail; else pass; fi
  fi
}

run_tests() {
  contractAddress=$(dapp create $contractName)
  echo $contractName address: $contractAddress
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    seth send $contractAddress 'fail()'
    seth send $contractAddress 'setUp()'
    result=$(seth call "$contractAddress" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp()"
    else
      testcase
    fi
  done
}

contractName=DSRTest
run_tests

contractName=DaiTest
run_tests

contractName=ForkTest
run_tests

contractName=JugTest
run_tests

contractName=ClipperTest
run_tests

contractName=ClipperAbaciTest
run_tests

contractName=CureTest
run_tests

contractName=DogTest
run_tests

contractName=EndTest
run_tests

contractName=FlapTest
run_tests

contractName=FlipTest
run_tests

contractName=FlopTest
run_tests

contractName=FrobTest
run_tests

contractName=JoinTest
run_tests

contractName=BiteTest
run_tests

contractName=FoldTest
run_tests

contractName=VowTest
run_tests




