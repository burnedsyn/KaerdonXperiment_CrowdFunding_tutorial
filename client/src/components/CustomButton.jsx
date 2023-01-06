import React from 'react'

const CustomButton = ({btnType, title, handleclick, styles }) => {
  return (
    <button
      type={btnType}
      className={`font-epilogue font-semibold text-[16px] leading-[26px] text-nine min-h-[52px] px-4 rounded-[20px] ${styles}`}
      onClick={handleclick}
    >
      {title}
    </button>
    
  )
}

export default CustomButton