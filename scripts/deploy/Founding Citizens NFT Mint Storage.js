module.exports = async ({getNamedAccounts, deployments}) => {
    const {deploy} = deployments;
    const {account0} = await getNamedAccounts();

    await deploy('Founding Citizens NFT Mint Storage', {
      from: account0,
      log: true,
    });
  };
