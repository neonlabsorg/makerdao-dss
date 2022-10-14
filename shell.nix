{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_43_1
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_6_12 + "/bin/solc-0.6.12";
  DAPP_TEST_ADDRESS = "0xa3a0E8Fbe0Ad412D808693EDc2751f0776e13AF1";
  # No optimizations
  SOLC_FLAGS = "";
  buildInputs = [
    dapp
  ];
}
