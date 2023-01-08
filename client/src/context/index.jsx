import React, { createContext, useContext } from 'react';

import { useAddress, useContract, useMetamask, useContractWrite} from '@thirdweb-dev/react';

import { ethers } from 'ethers';

const StateContext = createContext();



export const StateContextProvider = ({ children }) => {
    const { contract } = useContract('0x4C0CC6b2075BcD0845A40064fA2B5f5823A50E70');
    const { mutateAsync: createCampaign } = useContractWrite(contract, 'createCampaign');
    
   const address = useAddress();
   const connect = useMetamask();

    const publishCampaign = async (form) => {

        try {
            const data = await createCampaign([
                address, //owner
                form.title, //title
                form.description, //description
                form.target, //goal
                new Date(form.deadline).getTime()/1000, //deadline
                form.image, //image

            ]);
            console.log("contract call success ", data);
        } catch (error) {
            console.log("contract call failure ", error);
        }
    }
    const getCampaigns = async () => {
        try {
            const data = await contract.call('getCampaigns');
            const parsedCampaigns = data.map((campaign,i) => ({
                owner: campaign.owner,
                title: campaign.title,
                description: campaign.description,
                target: ethers.utils.formatEther(campaign.target.toString()),
                deadline: campaign.deadline.toNumber(),
                amountCollected: ethers.utils.formatEther(campaign.amountCollected.toString()),
                image: campaign.image,
                pId: i
                
            }));
            return parsedCampaigns;
        } catch (error) {
            console.log("contract call failure ", error);
        }
    }
    const getUserCampaigns = async () => {
        const getAllCampaigns = await getCampaigns();
        const filteredCampaigns = getAllCampaigns.filter(campaign => campaign.owner === address);
        return filteredCampaigns;
    }
    const donate = async (pId, amount) => { 
        try {
            const data = await contract.call('donateToCampaign', pId, {
                value: ethers.utils.parseEther(amount)
            }  );
            return data;
        } catch (error) {
            console.log("contract call failure ", error);
            }
        }
    const getDonations = async (pId) => {
        const donations= await contract.call('getDonators', pId);
        const numberofDonations = donations[0].length;
        const parsedDonations = [];
        for (let i = 0; i < numberofDonations; i++) {
            
            parsedDonations.push(  {
                donator: donations[0][i],
                donation: ethers.utils.formatEther(donations[1][i].toString()),
            })
        }
        return parsedDonations;
     }

    return (
        <StateContext.Provider value={{ 
            address, 
            contract,
            connect, 
            CreateCampaign: publishCampaign,
            getCampaigns,
            getUserCampaigns,
            donate,
            getDonations
             }}
             >
            {children}
        </StateContext.Provider>
    )
}
export const useStateContext = () => useContext(StateContext);
