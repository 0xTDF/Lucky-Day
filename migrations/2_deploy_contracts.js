const LuckyDay = artifacts.require("LuckyDay");

module.exports = async (deployer) => {
    await deployer.deploy(LuckyDay)
};