const { network } = require("hardhat");
const { verify } = require("../utils/verify");
const { developmentChains } = require("../helper-hardhat-config");

module.exports = async ({ deployments, getNamedAccounts }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    // In case we make modifications to the contract;
    const args = [];

    log("\n======================================================");
    log("Deploying Contract\n");
    const nftMarketPlace = await deploy("NFTMarketPlace", {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    log("\nContract Deployed");
    log("======================================================\n");

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        log("\n======================================================");
        log("Verifying Contract\n");
        await verify(nftMarketPlace.address, args);
        log("\nContract Verified");
        log("======================================================\n");
    }
};

module.exports.tags = ["all", "nftMarketPlace", "main"];
