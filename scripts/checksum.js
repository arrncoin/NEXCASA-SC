const { getAddress } = require("ethers");

const addr = "0x11cde369597203f385bc164e64e34e1f520e1983";
console.log("Checksum:", getAddress(addr));
