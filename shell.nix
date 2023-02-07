{ dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.hevm-0_43_1
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_6_12 + "/bin/solc-0.6.12";
  DAPP_TEST_ADDRESS = "${NEON_ACCOUNT_PUB_KEY}";
  # No optimizations
  SOLC_FLAGS = "";
  buildInputs = [
    dapp
  ];
}
