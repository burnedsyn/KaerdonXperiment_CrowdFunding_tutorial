import React, {useState} from 'react';
import { useNavigate } from 'react-router-dom';
import {ethers} from 'ethers';

import { money } from '../assets';
import { CustomButton } from '../components';
import {checkIfImage} from '../utils';

const CreateCampaign = () => {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(false);
  const  [form, setForm] = useState({
    name: '',
    title: '',
    description: '',
    image: '',
    target: '',
    deadline: '',       

  });

  return (
    <div className='bg-secondary flex justify-center items-center flex-col rounded[10px] sm:p-10 p-4 shadow-[-3px_-3px_8px_5px_#51beef33] '>
        {isLoading && 'loading...'}
        <div className=" flex justify-center items-center p-[16px] sm:min-w-[380px] bg-fourth rounded-[10px] ">
          <h1 className="font-epilogue font-bold sm:text-[25px] text-[18px] leading-[38px] text-nine  ">Start a new campaign</h1>
        </div>
        <form onSubmit={handleSubmit}>

        </form>


    </div>
  )
}

export default CreateCampaign