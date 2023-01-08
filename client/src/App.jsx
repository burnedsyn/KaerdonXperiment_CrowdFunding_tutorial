import React, {useState} from 'react';
import {Route, Routes} from 'react-router-dom'
import { Sidebar, Navbar  } from './components'
import { CampaignDetails, CreateCampaign, Home, Profile, About } from './pages'
const App = () =>{
  const [isActive, setIsActive] = useState('dashboard');
  const [activeLink, setActiveLink] = useState('dashboard');

  
  return (
    <div className="relative sm:-8 p-4 bg-primary min-h-screen flex flex-row">
     <div className="sm:flex hidden mr-10 relative">
      <Sidebar activeLink={activeLink} />
     </div>
     <div className="flex-1 max-w-sm:w-full max-w-[1280px] mx-auto pr-5 " >
      <Navbar />
      <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/campaign-details/:id" element={<CampaignDetails />} />
          <Route path="/create-campaign" element={<CreateCampaign />}/>
          <Route path="/about" element={<About />} />
      </Routes>
     </div>
    </div>
  )
}

export default App

