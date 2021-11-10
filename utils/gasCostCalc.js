const gweiToEth = 0.000000001


// INPUTS //
totalGas = 4777263 
gasPrice = 50  // gwei
ethPrice = 4669 // USD

totalUSD = totalGas * gweiToEth * gasPrice * ethPrice
console.log(totalUSD)

// node utils/gasCostCalc.js