import React, {useState, useEffect} from 'react';
import { useStateContext } from '../context';

const Homes = () => {
const [isLoading, setIsLoading] = useState(false);
const [campaigns, setCampaigns] = useState([]);

const { address, contract, getCampaigns } = useStateContext();


  return (
    <div>

      
    </div>
  )
}

export default Homes