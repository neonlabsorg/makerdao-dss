DAPP_BUILD_EXTRACT=1 dapp build

#rm -rf abi/
mkdir abi/
#mv out/*.abi abi/

DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1 dapp build

export DAPP_SOLC_VERSION=0.6.12
export ETH_FROM=${NEON_ACCOUNTS}
export ETH_PASSWORD=eth_pass
export ETH_KEYSTORE=keystore
export ETH_RPC_URL=${NEON_PROXY_URL}

# curl -i -X POST     -d '{"wallet": "0xa3a0E8Fbe0Ad412D808693EDc2751f0776e13AF1", "amount": 50000}'     'http://localhost:3333/request_neon'
# curl -i -X POST     -d '{"wallet": "0xa3a0E8Fbe0Ad412D808693EDc2751f0776e13AF1", "amount": 50000}'     'http://localhost:3333/request_neon'

export ETH_GAS=300000000
export ETH_GAS_PRICE=200000000000

fail() {
  echo "FAIL $contractName::$method"
  echo "FAIL $contractName::$method" >> neon_tests_result.md
}
pass() {
  echo "PASS $contractName::$method"
  echo "PASS $contractName::$method" >> neon_tests_result.md
}

rely() {
  status=124
  while (($status==124)); do
    timeout 60s seth send $1 'rely(address)' $test_contract
    status=$?
  done
}

setOwner() {
  status=124
  while (($status==124)); do
    timeout 60s seth send $1 'setOwner(address)' $test_contract
    status=$?
  done
}

create() {
  status=124
  while (($status==124)); do
    result=$(timeout 60s dapp create $1 $2 $3 $4 $5 $6 $7 $8 $9)
    status=$?
  done
}

sendtx() {
  status=124
  while (($status==124)); do
    timeout 60s seth send $1 $2 $3 $4 $5 $6 $7 $8 $9
    status=$?
  done
}

testcase() {
  sendtx $test_contract "$method()"
  failed=$(seth call "$test_contract" 'failed()(bool)')
  if [[ "$failed" == true ]]; then
    if [[ "$method" == testFail* ]]; then pass; else fail; fi
  else
    if [[ "$method" == testFail* ]]; then fail; else pass; fi
  fi
}

testcase_with_timestamp() {
  sendtx $test_contract "$method(uint256)" $(seth block latest timestamp)
  failed=$(seth call "$test_contract" 'failed()(bool)')
  if [[ "$failed" == true ]]; then
    if [[ "$method" == testFail* ]]; then pass; else fail; fi
  else
    if [[ "$method" == testFail* ]]; then fail; else pass; fi
  fi
}

run_tests() {
  status=124
  while (($status==124)); do
    test_contract=$(timeout 60s dapp create $contractName)
    status=$?
  done
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md
    
    sendtx $test_contract 'fail()'
    sendtx $test_contract 'setUp()'
    
    failed=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$failed" == true ]]; then
      echo "FAIL $contractName::setUp()"
      echo "FAIL $contractName::setUp()" >> neon_tests_result.md
    else
      testcase
    fi
  done
}

run_tests_with_predeploy_DSToken() {
  test_contract=$(dapp create $contractName)
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'
    dsTokenContractAddress=$(dapp create DSToken '"GEM"')
    echo dsTokenContractAddress: $dsTokenContractAddress
    setOwner $dsTokenContractAddress
    sendtx $test_contract 'setUp(address)' $dsTokenContractAddress
    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp()"
      echo "FAIL $contractName::setUp()" >> neon_tests_result.md
    else
      testcase
    fi
  done
}

run_tests_with_predeploy_TestVat() {
  test_contract=$(dapp create $contractName)
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md
    
    sendtx $test_contract 'fail()'
    testVat=$(dapp create TestVat)
    echo testVat $testVat
    rely $testVat
    sendtx $test_contract 'setUp(address)' $testVat
    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp()"
      echo "FAIL $contractName::setUp()" >> neon_tests_result.md
    else
      testcase
    fi
  done
}

run_bite_tests_with_predeploy() {
  test_contract=$(dapp create $contractName)
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md
    
    sendtx $test_contract 'fail()'

    create TestVat
    testVat=$result
    echo testVat $testVat
    rely $testVat

    create DSToken '"GOV"'
    gov=$result
    echo gov: $gov
    setOwner $gov

    create Flapper $testVat $gov
    flap=$result
    echo flap: $flap
    rely $flap

    create Flopper $testVat $gov
    flop=$result
    echo flop: $flop
    rely $flop

    create TestVow $testVat $flap $flop
    vow=$result
    echo vow: $vow
    rely $vow

    status=124
    while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address)' $testVat $gov $flap $flop $vow
        status=$?
    done

    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Jug $testVat
      jug=$result
      echo jug: $jug
      rely $jug

      create Cat $testVat
      cat=$result
      echo cat: $cat
      rely $cat

      create DSToken '"GEM"'
      gold=$result
      echo gold: $gold
      setOwner $gold

      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create GemJoin $testVat $ilk $gold
      gemA=$result
      echo gemA: $gemA
      rely $gemA

      create Flipper $testVat $cat $ilk
      flip=$result
      echo flip: $flip
      rely $flip

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address)' $jug $cat $gold $gemA $flip
        status=$?
      done

      result=$(seth call "$test_contract" 'failed()(bool)')
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase
      fi
    fi
  done
}

run_clip_tests_with_predeploy1() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract

  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create Spotter $vat
    spot=$result
    echo spot: $spot
    rely $spot

    create Vow $vat 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000
    vow=$result
    echo vow: $vow
    rely $vow

    create DSToken '"GLD"'
    gold=$result
    echo gold: $gold
    setOwner $gold

    ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
    echo gold ---bytes32---> $ilk

    create GemJoin $vat $ilk $gold
    goldJoin=$result
    echo goldJoin: $goldJoin
    rely $goldJoin

    create DSToken '"DAI"'
    dai=$result
    echo dai: $dai
    setOwner $dai

    create DaiJoin $vat $dai
    daiJoin=$result
    echo daiJoin: $daiJoin
    rely $daiJoin
    
    create Exchange $gold $dai 5500000000000000000
    exchange=$result
    echo exchange: $exchange

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $spot $vow $gold $goldJoin $dai $daiJoin $exchange
      status=$?
    done

    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Dog $vat
      dog=$result
      echo dog: $dog
      rely $dog

      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip
      
      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip

      create GuyForClipper $clip
      ali=$result
      echo ali: $ali

      create GuyForClipper $clip
      bob=$result
      echo bob: $bob

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address)' $dog $pip $clip $ali $bob
        status=$?
      done

      result=$(seth call "$test_contract" 'failed()(bool)')
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase
      fi
    fi
  done
}

run_clip_tests_with_predeploy2() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract

  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create Spotter $vat
    spot=$result
    echo spot: $spot
    rely $spot

    create Vow $vat 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000
    vow=$result
    echo vow: $vow
    rely $vow

    create DSToken '"GLD"'
    gold=$result
    echo gold: $gold
    setOwner $gold

    ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
    echo gold ---bytes32---> $ilk

    create GemJoin $vat $ilk $gold
    goldJoin=$result
    echo goldJoin: $goldJoin
    rely $goldJoin

    create DSToken '"DAI"'
    dai=$result
    echo dai: $dai
    setOwner $dai

    create DaiJoin $vat $dai
    daiJoin=$result
    echo daiJoin: $daiJoin
    rely $daiJoin
    
    create Exchange $gold $dai 5500000000000000000
    exchange=$result
    echo exchange: $exchange

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $spot $vow $gold $goldJoin $dai $daiJoin $exchange
      status=$?
    done

    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Dog $vat
      dog=$result
      echo dog: $dog
      rely $dog

      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip
      
      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip

      create Trader $clip $vat $gold $goldJoin $dai $daiJoin $exchange
      trader=$result
      echo trader: $trader

      create GuyForClipper $clip
      ali=$result
      echo ali: $ali

      create GuyForClipper $clip
      bob=$result
      echo bob: $bob

      create StairstepExponentialDecrease
      calc=$result
      echo calc: $calc
      rely $calc

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address, address, address)' $dog $pip $clip $trader $ali $bob $calc
        status=$?
      done

      result=$(seth call "$test_contract" 'failed()(bool)')
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase_with_timestamp
      fi
    fi
  done
}

run_clip_tests_with_predeploy3() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create Spotter $vat
    spot=$result
    echo spot: $spot
    rely $spot

    create Vow $vat 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000
    vow=$result
    echo vow: $vow
    rely $vow

    create DSToken '"GLD"'
    gold=$result
    echo gold: $gold
    setOwner $gold

    ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
    echo gold ---bytes32---> $ilk

    create GemJoin $vat $ilk $gold
    goldJoin=$result
    echo goldJoin: $goldJoin
    rely $goldJoin

    create DSToken '"DAI"'
    dai=$result
    echo dai: $dai
    setOwner $dai

    create DaiJoin $vat $dai
    daiJoin=$result
    echo daiJoin: $daiJoin
    rely $daiJoin
    
    create Exchange $gold $dai 5500000000000000000
    exchange=$result
    echo exchange: $exchange

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $spot $vow $gold $goldJoin $dai $daiJoin $exchange
      status=$?
    done
    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Dog $vat
      dog=$result
      echo dog: $dog
      rely $dog
      
      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip

      create DSValue
      pip2=$result
      echo pip2: $pip2
      setOwner $pip2

      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip
      
      ilk2=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="silver"))')
      echo gold ---bytes32---> $ilk2

      create Clipper $vat $spot $dog $ilk2
      clip2=$result
      echo clip2: $clip2
      rely $clip2
      
      create GuyForClipper $clip
      ali=$result
      echo ali: $ali

      create GuyForClipper $clip
      bob=$result
      echo bob: $bob

      create StairstepExponentialDecrease
      calc=$result
      echo calc: $calc
      rely $calc

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address, address, address, address)' $dog $pip $pip2 $clip $clip2 $ali $bob $calc
        status=$?
      done
      status=124
      while (($status==124)); do
        result=$(timeout 60s seth call "$test_contract" 'failed()(bool)')
        status=$?
      done
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase_with_timestamp
      fi
    fi
  done
}

run_clip_tests_with_predeploy4() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create Spotter $vat
    spot=$result
    echo spot: $spot
    rely $spot

    create Vow $vat 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000
    vow=$result
    echo vow: $vow
    rely $vow

    create DSToken '"GLD"'
    gold=$result
    echo gold: $gold
    setOwner $gold

    ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
    echo gold ---bytes32---> $ilk

    create GemJoin $vat $ilk $gold
    goldJoin=$result
    echo goldJoin: $goldJoin
    rely $goldJoin

    create DSToken '"DAI"'
    dai=$result
    echo dai: $dai
    setOwner $dai

    create DaiJoin $vat $dai
    daiJoin=$result
    echo daiJoin: $daiJoin
    rely $daiJoin

    create Exchange $gold $dai 5500000000000000000
    exchange=$result
    echo exchange: $exchange

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $spot $vow $gold $goldJoin $dai $daiJoin $exchange
      status=$?
    done

    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Dog $vat
      dog=$result
      echo dog: $dog
      rely $dog

      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip
      
      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip

      create GuyForClipper $clip
      ali=$result
      echo ali: $ali

      create GuyForClipper $clip
      bob=$result
      echo bob: $bob

      create PublicClip $vat $spot $dog $ilk
      pclip=$result
      echo pclip: $pclip

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address, address)' $dog $pip $clip $ali $bob $pclip
        status=$?
      done

      result=$(seth call "$test_contract" 'failed()(bool)')
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase
      fi
    fi
  done
}

run_clip_tests_with_predeploy5() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract

  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create Spotter $vat
    spot=$result
    echo spot: $spot
    rely $spot

    create Vow $vat 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000
    vow=$result
    echo vow: $vow
    rely $vow

    create DSToken '"GLD"'
    gold=$result
    echo gold: $gold
    setOwner $gold

    ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
    echo gold ---bytes32---> $ilk

    create GemJoin $vat $ilk $gold
    goldJoin=$result
    echo goldJoin: $goldJoin
    rely $goldJoin

    create DSToken '"DAI"'
    dai=$result
    echo dai: $dai
    setOwner $dai

    create DaiJoin $vat $dai
    daiJoin=$result
    echo daiJoin: $daiJoin
    rely $daiJoin
    
    create Exchange $gold $dai 5500000000000000000
    exchange=$result
    echo exchange: $exchange

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $spot $vow $gold $goldJoin $dai $daiJoin $exchange
      status=$?
    done

    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Dog $vat
      dog=$result
      echo dog: $dog
      rely $dog

      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip
      
      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip

      create GuyForClipper $clip
      ali=$result
      echo ali: $ali

      create GuyForClipper $clip
      bob=$result
      echo bob: $bob

      create StairstepExponentialDecrease
      calc=$result
      echo calc: $calc
      rely $calc

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address, address)' $dog $pip $clip $ali $bob $calc
        status=$?
      done

      result=$(seth call "$test_contract" 'failed()(bool)')
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase_with_timestamp
      fi
    fi
  done
}

run_clip_tests_with_predeploy6() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract
  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create Spotter $vat
    spot=$result
    echo spot: $spot
    rely $spot

    create Vow $vat 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000
    vow=$result
    echo vow: $vow
    rely $vow

    create DSToken '"GLD"'
    gold=$result
    echo gold: $gold
    setOwner $gold

    ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
    echo gold ---bytes32---> $ilk

    create GemJoin $vat $ilk $gold
    goldJoin=$result
    echo goldJoin: $goldJoin
    rely $goldJoin

    create DSToken '"DAI"'
    dai=$result
    echo dai: $dai
    setOwner $dai

    create DaiJoin $vat $dai
    daiJoin=$result
    echo daiJoin: $daiJoin
    rely $daiJoin
    
    create Exchange $gold $dai 5500000000000000000
    exchange=$result
    echo exchange: $exchange

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $spot $vow $gold $goldJoin $dai $daiJoin $exchange
      status=$?
    done
    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Dog $vat
      dog=$result
      echo dog: $dog
      rely $dog
      
      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip

      create DSValue
      pip2=$result
      echo pip2: $pip2
      setOwner $pip2

      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip
      
      ilk2=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="silver"))')
      echo gold ---bytes32---> $ilk2

      create Clipper $vat $spot $dog $ilk2
      clip2=$result
      echo clip2: $clip2
      rely $clip2
      
      create GuyForClipper $clip
      ali=$result
      echo ali: $ali

      create GuyForClipper $clip
      bob=$result
      echo bob: $bob

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address, address, address)' $dog $pip $pip2 $clip $clip2 $ali $bob
        status=$?
      done
      status=124
      while (($status==124)); do
        result=$(timeout 60s seth call "$test_contract" 'failed()(bool)')
        status=$?
      done
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        sendtx $test_contract 'fail()'

        status=124
        while (($status==124)); do
          timeout 60s seth send $test_contract 'setUp3(uint256)' $(seth block latest timestamp)
          status=$?
        done
        status=124
        while (($status==124)); do
          result=$(timeout 60s seth call "$test_contract" 'failed()(bool)')
          status=$?
        done
        if [[ "$result" == true ]]; then
          echo "FAIL $contractName::setUp3()"
          echo "FAIL $contractName::setUp3()" >> neon_tests_result.md
        else
          testcase_with_timestamp
        fi
      fi
    fi
  done
}

run_end_tests_with_predeploy() {
  create $contractName
  test_contract=$result
  echo $contractName address: $test_contract

  for method in $(cat abi/$contractName.abi | python3 -mjson.tool | grep \"name\" | grep \"test | sed 's/"name": "//g' | sed 's/",//g'); do
    echo Start processing $method
#     echo Start processing $method >> neon_tests_result.md

    sendtx $test_contract 'fail()'

    create Vat
    vat=$result
    echo vat: $vat
    rely $vat

    create DSToken '"GOV"'
    gov=$result
    echo gov: $gov
    setOwner $gov

    create Flapper $vat $gov
    flap=$result
    echo flap: $flap
    rely $flap

    create Flopper $vat $gov
    flop=$result
    echo flop: $flop
    rely $flop

    create Vow $vat $flap $flop
    vow=$result
    echo vow: $vow
    rely $vow

    create Pot $vat
    pot=$result
    echo pot: $pot
    rely $pot

    create Cat $vat
    cat=$result
    echo cat: $cat
    rely $cat

    create Dog $vat
    dog=$result
    echo dog: $dog
    rely $dog

    status=124
    while (($status==124)); do
      timeout 60s seth send $test_contract 'setUp1(address, address, address, address, address, address, address, address)' $vat $gov $flap $flop $vow $pot $cat $dog
      status=$?
    done

    result=$(seth call "$test_contract" 'failed()(bool)')
    if [[ "$result" == true ]]; then
      echo "FAIL $contractName::setUp1()"
      echo "FAIL $contractName::setUp1()" >> neon_tests_result.md
    else
      sendtx $test_contract 'fail()'

      create Spotter $vat
      spot=$result
      echo spot: $spot
      rely $spot

      create Cure
      cure=$result
      echo cure: $cure
      rely $cure

      create End
      end=$result
      echo end: $end
      rely $end

      create DSToken '""'
      coin=$result
      echo coin: $coin
      setOwner $coin

      create DSValue
      pip=$result
      echo pip: $pip
      setOwner $pip

      ilk=$(python3 -c 'from web3 import Web3; print(Web3.toHex(text="gold"))')
      echo gold ---bytes32---> $ilk

      create GemJoin $vat $ilk $coin
      gemA=$result
      echo gemA: $gemA
      rely $gemA

      create Flipper $vat $cat $ilk
      flip=$result
      echo flip: $flip
      rely $flip

      create Clipper $vat $spot $dog $ilk
      clip=$result
      echo clip: $clip
      rely $clip

      status=124
      while (($status==124)); do
        timeout 60s seth send $test_contract 'setUp2(address, address, address, address, address, address, address, address)' $spot $cure $end $coin $pip $gemA $flip $clip
        status=$?
      done

      result=$(seth call "$test_contract" 'failed()(bool)')
      if [[ "$result" == true ]]; then
        echo "FAIL $contractName::setUp2()"
        echo "FAIL $contractName::setUp2()" >> neon_tests_result.md
      else
        testcase
      fi
    fi
  done
}

contractName=DaiTest
run_tests
echo
contractName=FlapTest
run_tests
echo
contractName=ClipperAbaciTest
run_tests
echo
contractName=CureTest
run_tests
echo
contractName=JugTest
run_tests
echo
contractName=ForkTest
run_tests
echo
contractName=FrobTest1
run_tests
contractName=FrobTest2
run_tests
contractName=FrobTest3
run_tests
contractName=FrobTest4
run_tests_with_predeploy_DSToken
echo
contractName=JoinTest
run_tests
echo
contractName=FoldTest
run_tests
echo
contractName=DogTest1
run_tests
contractName=DogTest2
run_tests
echo
contractName=FlopTest1
run_tests
contractName=FlopTest2
run_tests
contractName=FlopTest3
run_tests
echo
contractName=FlipTest1
run_tests
contractName=FlipTest2
run_tests
contractName=FlipTest3
run_tests
contractName=FlipTest4
run_tests
echo
contractName=VowTest1
run_tests_with_predeploy_TestVat
contractName=VowTest2
run_tests_with_predeploy_TestVat
echo
contractName=BiteTest
run_bite_tests_with_predeploy
echo
contractName=EndTest
run_end_tests_with_predeploy
echo
contractName=ClipperTest1
run_clip_tests_with_predeploy1
contractName=ClipperTest2
run_clip_tests_with_predeploy2
contractName=ClipperTest3
run_clip_tests_with_predeploy2
contractName=ClipperTest4
run_clip_tests_with_predeploy3
contractName=ClipperTest5
run_clip_tests_with_predeploy2
contractName=ClipperTest6
run_clip_tests_with_predeploy2
contractName=ClipperTest7
run_clip_tests_with_predeploy4
contractName=ClipperTest8
run_clip_tests_with_predeploy5
contractName=ClipperTest9
run_clip_tests_with_predeploy6
echo
contractName=DSRTest
run_tests



