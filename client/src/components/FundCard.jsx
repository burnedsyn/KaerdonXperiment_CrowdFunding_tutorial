import React from 'react'
import { tagType, thirdweb } from '../assets'
import {daysLeft} from '../utils'

const FundCard = ({owner, title, description, target, deadline, amountCollected, image, handleClick}) => {
  const remainingDays = daysLeft(deadline);
    return (
    <div className="sm:w-[288px] w-full rounde[15px] bg-secondary shadow-custom cursor-pointer" onClick={handleClick}  >
        <img src={image} alt={['fund the project ', title]}
        className="w-full h-[158px] object-cover rounded-[15px]" />
        <div className='flex flex-col p-4' >
            <div className="flex flex-row items-center mb-[18px]">
            <img src={tagType} alt="tag" className="w-[17px] h-[17px] object-contain" />
            <p className="font-epilogue font-medium text-[12px] text-nine text-left ml-[12px] mt-[2px]">Education</p>
            </div>

            <div className='block'>
                <h3 className="font-epilogue font-semibold text-[16px] text-white text-left leading-[26px] truncate">{title}</h3>
                <p className="mt-[5px] font-epilogue font-normal font-[12px] text-[#808191] text-left truncate">{description}</p>
            </div>

            <div className="flex flex-wrap gap-2 justify-between mt-[15px]">
                <div className="flex flex-col">
                    <h4 className="font-epilogue font-semibold font-[14px] text-[#b2b3bd]  leading-[22px]">{amountCollected} </h4>
                    <p className="mt-[3px] font-epilogue font-normal font-[12px] text-[#808191] leading-[18px] sm:max-w-[120px] truncate">Raised of {target}</p>
                </div>
                <div className="flex flex-col">
                    <h4 className="font-epilogue font-semibold font-[14px] text-[#b2b3bd]  leading-[22px] ">{remainingDays} </h4>
                    <p className="mt-[3px] font-epilogue font-normal font-[12px] text-[#808191] leading-[18px] sm:max-w-[120px]  truncate ">Days Left</p>
                </div>
            </div>
            <div className="flex items-center mt-[20px] gap-[12px]">
                <div className="w-[30px] h-[30px] rounded-full flex justify-center items-center bg-[13131a]">
                    <img src={thirdweb} alt="user" className="w-1/2 h-1/2 object-contain" />
                </div>
                <p className="flex-1 font-epilogue font-normal text-[12px] text-[#808191] truncate">by <span className="text-[#b2b3bd]">{owner}</span></p>
            </div>
        </div>
    </div>
  ) 
}

export default FundCard