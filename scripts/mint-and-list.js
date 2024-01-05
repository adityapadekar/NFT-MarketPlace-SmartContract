const { ethers, deployments } = require("hardhat");

const PRICE = ethers.parseEther("0.1");

async function mintAndList() {
    const nftMarketPlace_address = (await deployments.get("NFTMarketPlace"))
        .address;
    const basicNFT_address = (await deployments.get("BasicNFT")).address;

    const basicNFT = await ethers.getContractAt("BasicNFT", basicNFT_address);
    const nftMarketPlace = await ethers.getContractAt(
        "NFTMarketPlace",
        nftMarketPlace_address
    );
    // console.log(basicNFT.address);

    console.log("Minting...");
    const mintTxResponse = await basicNFT.mintNFT();
    const mintTxReceipt = await mintTxResponse.wait(1);
    const tokenId = mintTxReceipt.logs[0].args.tokenId;

    console.log("Approving NFT....");
    const approveTx = await basicNFT.approve(nftMarketPlace_address, tokenId);
    await approveTx.wait(1);

    console.log("Listing NFT..");
    const listingTx = await nftMarketPlace.listItem(
        basicNFT_address,
        tokenId,
        PRICE
    );
    await listingTx.wait(1);

    console.log("Listed NFT..");
}

mintAndList()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
