import hre from "hardhat";

async function main(): Promise<void> {
    const Crowdfund = await hre.ethers.getContractFactory("Crowdfund");
    const contract = await Crowdfund.deploy();
    await contract.waitForDeployment();
    const address: string = await contract.getAddress();
    console.log("Crowdfund deployed to:", address);
}

main().catch(console.error);
