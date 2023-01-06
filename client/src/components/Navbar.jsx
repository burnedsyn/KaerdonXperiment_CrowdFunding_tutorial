import React, {useState} from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { CustomButton } from './';
import { logo, menu, search, thirdweb, old_profile } from '../assets';
import { navlinks } from '../constants';


const Navbar = () => {
  const navigate = useNavigate();
  const [isActive, setIsActive] = useState('dashboard');
  const [toggleDrawer, setToggleDrawer] = useState(false);
  const address='0x123ff112'


  return (
    <div className="flex md:flex-row flex-col-reverse justify-between mb-[35px] gap-6">
      <div className="lg:flex-1 flex flex-row max-w-[458px] py-2 pl-4 pr-2 h-[52px] bg-secondary rounded-[100px]">
      <input type="text" placeholder="Search for campaigns" className="flex w-full font-epilogue font-normal text-[14px] placeholder:text-sixth text-third bg-transparent outline-none rounded-[100px]" />
        <div className="w-[72px] h-full rounded-[20px] bg-fourth flex justify-center items-center cursor-pointer ">
          <img src={search} alt="search" className="w-[15px] h-[15px] rounded-[10px] object-contain" />
        </div>
      </div>
      <div className="sm:flex hidden flex-row justify-end gap-4">
        <CustomButton 
          btnType="button"
          title={ address ? 'create campaign' : 'connect wallet'}  
          styles={address ? 'bg-fourth  text-nine' : 'bg-fourth text-[#FF0000]'} 
          handleClick={() => {
            if(address) {
              navigate('/create-campaign')
            } else {
              'connect()'
            }//fin else
          }}
        />
        <Link to='/profile'>
          <div className='w-[52px] h-[52px] rounded-full flex justify-center items-center bg-secondary cursor-pointer '>
            <img src={old_profile} alt="" className='grayscale' />
          </div>
        </Link>
      </div>
      {/* small screen nav*/}
      <div className="sm:hidden flex flex-row justify-between items-center relative">
          <div className='w-[40px] h-[40px] rounded-[10px] flex justify-center items-center bg-secondary cursor-pointer '>
            <img src={old_profile} alt="" className='grayscale'/>
          </div>  
          <img 
            src={menu}
            alt="menu"
            className='w-[34px] h-[34px] object-contain cursor-pointer'
            onClick={() => setToggleDrawer((prev) => !prev)}
          />

          <div className={`absolute top-[60px] right-0 left-0 bg-secondary z-10 shadow-primary py-4 ${!toggleDrawer ? '-translate-y-[100vh]' : 'translate-y-0'}   transition-all duration-700`} >
              <ul className='mb-4'>
                 {navlinks.map((Link) => (
                  <li 
                  key={Link.name} 
                  className={`flex p-4 ${isActive === Link.name && 'bg-primary'}`} 
                  onClick={() => {
                    setIsActive(Link.name);
                    setToggleDrawer(false);
                    navigate(Link.link);
  
                  }}
                >
                  <img
                    src={Link.imgUrl}
                    alt={Link.name}
                    className={`w-[24px] h-[24px] object-contain ${isActive === Link.name ? 'grayscale-0' : 'grayscale'} `}
                  />
                  <p className={`ml-[20px] font-epilogue font-semibold text-[14px] ${isActive === Link.name ? 'text-nine' : 'text-sixth'}  `}>
                    {Link.name}
                  </p>  
                </li>
                  ))}
              </ul>
              <div className="flex mx-4">
              <CustomButton 
                btnType="button"
                title={ address ? 'create campaign' : 'connect wallet'}  
                styles={address ? 'bg-fourth  text-nine' : 'bg-fourth text-[#FF0000]'} 
                handleClick={() => {
                if(address) {
                  navigate('/create-campaign')
                } else {
                  'connect()'
                }//fin else
                 }}
              />
              </div>
          </div>

      </div>

    </div>
  )
}

export default Navbar