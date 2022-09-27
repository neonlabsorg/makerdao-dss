{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_43_1
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_6_12 + "/bin/solc-0.6.12";
  DAPP_TEST_ADDRESS = "0xD5097b1E873f8603e501Cace6B29Ef7216e9d3AC";
  # No optimizations
  SOLC_FLAGS = "";
  buildInputs = [
    dapp
  ];
}
