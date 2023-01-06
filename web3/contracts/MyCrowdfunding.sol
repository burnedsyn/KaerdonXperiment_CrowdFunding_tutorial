// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/**
 * @title MyCrowdfunding
 * @author Timothee de Almeida < [tim@1proamonservice.eu] >
 * @dev Implements crowdfunding platform
 * @dev This contract is a simple crowdfunding platform where users can create campaigns and other users can donate to them.
 * 
 */

contract MyCrowdfunding {
    // platform owner address admin of the platform
    address public platformOwner;
    bool public _emergencyStop;
    uint constant MIN_RESUME_INTERVAL = 5 minutes;
    uint constant MIN_CANCEL_INTERVAL = 72 hours;
    uint private lastResumeTimestamp;
    // backer data structure
    struct BackerData {
        address backer;
        uint88 donation;
    }
     //in case of refund 
    struct BackerRefund{
        bool locked;
        uint128 refundAmount;
    }

    // campaign structure which holds the campaign data
    struct Campaign {
        // campaign owner address (20 bytes of 1 slot of 32 bytes)
        address owner;
        // an uint64 is enough to store a timestamp until the year 584554 so it does take 8 bytes of 1 slot of 32 bytes
        uint64 deadline;  
        // campaign status
        // 0 - draft
        // 1 - active
        // 2 - completed
        // 3 - cancelled
        // 4 - withdrawn
        // 5 - refunded
        // 6 - expired
        // 7 - partially withdrawn
        // 255 - panic stop mode (only set or unset by platform or secureContact
        //a uint8 is enough to store a status code, it takes 1 byte of 1 slot of 32 bytes
        uint8 status;

        // here we have used 1 slot so far and we have 3 byte left in the slot to store another variable.
        // we could use this space to store another variable bool for example(1byte) or uint24(3bytes), etc.  

        //that is what we do later in the contract explanation..
        bool mutex;
        uint8 backupStatus; //in  case of emergencystop
        //there is now 1 byte free in this slot

        // target and amountCollected are uint128 enough to store a value of 340282366920938463463374607431768211455.
        uint128 target;        
        uint128 amountCollected;
        uint128 amountWithdrawn;
        // from now we are using 1 slot or more per variable.
        // backers array is a dynamic array of backersData structure    
        BackerData[] backersData;

        //these string are dynamic and will take more than 1 slot of 32 bytes each.
        string image;
        string title;
        string description;        
    }
    // mapping of campaign IDs to campaign data
    mapping(uint => Campaign) public campaigns;
    mapping(uint => address) public campaignOwner;
    //mapping mergency contact
    mapping(address => bool) public emergencyContacts;
    // number of campaigns
    uint public numberOfCampaigns;
    //last withdraw activity campaign & address => timestamps
    mapping(uint => mapping(address => uint)) public lastWithdrawalTimestamp;
    //mapping for partialrefund mapping (capaignId=>mapping(donatorAddress=>BackerRefund))
    mapping(uint => mapping (address=>BackerRefund)) public partialRefundWaiting;

    // events
    event CampaignCreated(uint indexed _campaignId, address indexed _owner, uint _target, uint _deadline);
    event CampaignStatusChanged(uint indexed _campaignId, uint _status);
    event DonationReceived(uint indexed _campaignId, address indexed _backer, uint _amount);
    event Withdrawal(uint256 indexed _campaignId, address indexed _owner, uint256 _amount, uint256 _timestamp);
    event EmergencyStopChanged(address indexed admin, bool value, uint timestamp);
    event CampaignEmergencyStopChanged(uint indexed campaingId, address indexed admin, bool value, uint timestamp);
    event SpeedCancelAlert(uint indexed campaignId,address indexed campaignOwner,uint timestamp);
    event CancelPending(uint indexed campaignId,address indexed campaignOwner,uint timestamp);
    event PartialRefundWaitingNotification(uint indexed campaignId, address indexed backer, uint timestamp);
    event CampaignPartialRefundInitiated(uint campaignId, uint timestamp);
    event BackerRefundWithdrawn(uint indexed campaignId,address indexed backer , uint amount, uint timestamp);
    //Customerrors
    error Unauthorized(address caller);
    error DeadlineError(uint deadline);
    error CampaignStatusError(uint status);
    error LockError();
    error TransferError(uint campaignId, uint amount, address recipient);
    error InvalidWithdrawValue(uint _request, uint _available);
    error EmergencyMode();
    error CampaignEmergencyMode(string message);

    //basic functions
    constructor() {
        platformOwner = msg.sender;
        
    }



    //@dev create a new campaign, will be called by the campaign owner and will be revisited later
    function createCampaign (address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image)  public returns (uint256) {
        //we check if emergency mode is on
        if(_emergencyStop) revert EmergencyMode();
        // we check if deadline is in the future if not we throw an error DeadlineError(uint deadline)
        if(_deadline <= block.timestamp) revert DeadlineError(_deadline);    
        Campaign storage campaign = campaigns[numberOfCampaigns];
        // we have to use storage here because we are modifying the campaign data
        campaign.owner = _owner;
        campaign.deadline = uint64(_deadline);
        campaign.status = 1;
        campaign.mutex = false;
        campaign.backupStatus=1;
        campaign.target = uint128(_target);
        campaign.amountCollected = 0;
        campaign.amountWithdrawn=0;
        campaign.image = _image;
        campaign.title = _title;
        campaign.description =_description;
        campaignOwner[numberOfCampaigns]=_owner;                               
        numberOfCampaigns++;
        emit CampaignCreated(numberOfCampaigns-1, _owner, _target, _deadline);
        return numberOfCampaigns-1;
    }
    
    function donateToCampaign (uint256 _id) public payable {
        //we check if emergency mode is on
        if(_emergencyStop) revert EmergencyMode();
      uint256 amount= msg.value;
      Campaign storage campaign = campaigns[_id];
      // we check if deadline is in the future if not we throw an error DeadlineError(uint deadline)
        if(campaign.deadline <= block.timestamp) revert DeadlineError(campaign.deadline);
        // we check if the campaign is active if not we throw an error CampaignStatusError(uint status)
        if(campaign.status != 1 && campaign.status !=7) revert CampaignStatusError(campaign.status);      
          BackerData memory backerData = BackerData({
              backer: msg.sender,
              donation: uint88(amount)
          });
          campaign.backersData.push(backerData);
          campaign.amountCollected = uint128(campaign.amountCollected+amount);
          emit DonationReceived(_id, msg.sender, amount);
          if(campaign.amountCollected >= campaign.target) {
            // if the campaign has reached the target we change the status to 2
            campaign.status = 2;
            // we emit the CampaignStatusChanged event to notify the blockchain that the campaign status has been changed
            emit CampaignStatusChanged(_id, 2);
        }
      
    }


    function getDonators (uint256 _id) view public returns (BackerData[] memory) {
      Campaign storage campaign = campaigns[_id];
      return campaign.backersData;
    }

    function getCampaigns () public view returns (Campaign[] memory)  {
        uint _numberOfCampaigns = numberOfCampaigns;
        Campaign[] memory allCampaigns = new Campaign[](_numberOfCampaigns);
        for (uint i=0; i<_numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            Campaign memory campaign = Campaign({
                owner: item.owner,
                deadline: item.deadline,
                status: item.status,
                mutex: false,
                backupStatus:item.backupStatus,
                target: item.target,
                amountCollected: item.amountCollected,
                amountWithdrawn: item.amountWithdrawn,
                backersData: item.backersData,
                image: item.image,
                title: item.title,
                description: item.description
            });
            allCampaigns[i] = campaign;
        }
        return allCampaigns;
    }

    function getCampaignOwner (uint _campaignId) public view returns (address) {
        return campaignOwner[_campaignId];
    }


    function withdraw(uint256 _id, uint256 _amount) public {
        //we check if platform emergency mode is on
        if(_emergencyStop) revert EmergencyMode();
        Campaign storage campaign = campaigns[_id];
        // we check the mutex lock for this campaign and verify if it is on
        if(campaign.mutex) revert LockError();
        //we check if campaign emergency mode is on
        if(campaign.status==255) revert EmergencyMode();        
        if (campaign.owner != msg.sender) revert Unauthorized(msg.sender);
        uint _available= campaign.amountCollected-campaign.amountWithdrawn;
        
        // Acquire the mutex lock for this campaign
        campaign.mutex=true;       
        uint status=campaign.status;
        if (status != 1 && status != 2 && status != 7) revert CampaignStatusError(status);
        if (_amount > _available) revert InvalidWithdrawValue(_amount,_available);
        campaign.amountWithdrawn += uint128(_amount);
        // Transfer the Ether to the campaign owner
        (bool success, ) = (msg.sender).call{value: _amount}("");
        if (!success) {
        revert TransferError(_id, _amount, msg.sender);
        }
        emit Withdrawal(_id, msg.sender, _amount, block.timestamp);
        // If the campaign has been fully withdrawn but has not reached its target, set the campaign status to "partially withdrawn 7"
        if (campaign.amountWithdrawn == campaign.amountCollected && campaign.amountCollected < campaign.target) {
            campaign.status = 7;
            emit CampaignStatusChanged(_id, 7);
        } 
        // If the campaign has reached its target and all funds have been withdrawn, set the campaign status to "withdrawn 4"       
        else if ( campaign.amountCollected >= campaign.target && campaign.amountWithdrawn == campaign.amountCollected) {
            campaign.status = 4;
            emit CampaignStatusChanged(_id, 4);
        }
        // Update the last withdrawal timestamp for this campaign and address
        lastWithdrawalTimestamp[_id][msg.sender] = block.timestamp;
        // Release the mutex lock for this campaign

        campaign.mutex = false;

        } 

        //@dev function to stop all actions on the platform
        function emergencyStop() public {
            // only platform owner or emergency contact can call this function
            if(_emergencyStop) revert EmergencyMode();
            if (msg.sender == platformOwner ||  emergencyContacts[msg.sender] == true) {
                _emergencyStop = true;
                emit EmergencyStopChanged(msg.sender, true, block.timestamp);
            }
        }

        //@dev function to resume normal operations on the platform
        function resume() public {
            // only platform owner or emergency contact can call this function
            if (msg.sender == platformOwner || emergencyContacts[msg.sender] == true) {
                // add lock-out period to prevent abusive use
                if (block.timestamp > lastResumeTimestamp + MIN_RESUME_INTERVAL) {
                    _emergencyStop = false;
                    lastResumeTimestamp = block.timestamp;
                    emit EmergencyStopChanged(msg.sender, false, block.timestamp);
                }
            }
        }
        //@dev function to add an address to the emergencyContacts mapping
        function addEmergencyContact(address _contact) public {
            //we check if emergency mode is on
            if(_emergencyStop) revert EmergencyMode();
            // only platform owner can call this function
            if (msg.sender == platformOwner) {
                emergencyContacts[_contact] = true;
            }
        }
        //@dev function to remove an address to the emergencyContacts mapping
        function removeEmergencyContact(address _contact) public {
            //we don't check if emergency mode is on in this case it could be better to let the owner remove an emergency contact even if the platform is in emergency mode, maybe this emergency contact is not available anymore or responsible of the emergency..         
            // only platform owner can call this function
            if (msg.sender == platformOwner) {
                emergencyContacts[_contact] = false;
            }
        }
         //@dev function to stop normal operations on the campaign
        function setCampaignEmergencyStop (uint _campaignId) public {
            //we didn't check if platform emergency mode is on because admin may have to set emergency stop on campaign to resume normal platform operation
            Campaign storage campaign = campaigns[_campaignId];
            //we check if msg.sender is platformOwner or emergencyContacts
            if(msg.sender != platformOwner && !emergencyContacts[msg.sender] && msg.sender != campaign.owner) revert Unauthorized(msg.sender);
           
            
            //we set the campaign status to 255 it is the panic mode emergency stop value of status if yes we revert no need to set already set
            if(campaign.status == 255) revert CampaignEmergencyMode("campaign already in emergency mode");
            campaign.backupStatus=campaign.status;
            campaign.status=255;
            emit CampaignEmergencyStopChanged(_campaignId, msg.sender, true, block.timestamp);
        }
         //@dev function to resume normal operations on the campaign
        function campaignResume(uint _campaignId) public {
            // only platform owner or emergency contact can call this function
            if(msg.sender != platformOwner && !emergencyContacts[msg.sender]) revert Unauthorized(msg.sender);
            //we set the campaign back to backupstate it is the panic mode emergency OFF  status
            Campaign storage campaign = campaigns[_campaignId];
             if(campaign.status != 255) revert CampaignEmergencyMode("campaign not in emergency mode");            
            campaign.status=campaign.backupStatus;   
            emit CampaignEmergencyStopChanged(_campaignId, msg.sender, false, block.timestamp);         
        }


        function cancelCampaign(uint256 _campaignId) public {
            // Get the campaign data
            Campaign storage campaign = campaigns[_campaignId];
            // Check that the caller is a platform admin or the campaign owner
            if(msg.sender != platformOwner && !emergencyContacts[msg.sender] &&  msg.sender != campaign.owner) revert Unauthorized(msg.sender);
            
            // Check that the campaign is still active or partial withdrawn or emergency stop mode
            uint status=campaign.status;
            if (status != 1 && status != 7 && status != 255) revert CampaignStatusError(status);
            //we restrict if campaign.owner == msg.sender
            if(msg.sender==campaign.owner) {
                if (status==255) {
                    emit CancelPending(_campaignId, msg.sender, block.timestamp);
                   return ;
                }
                if(status==7){
                    if(lastWithdrawalTimestamp[_campaignId][msg.sender] > block.timestamp - MIN_CANCEL_INTERVAL){
                        emit SpeedCancelAlert(_campaignId,msg.sender,block.timestamp);
                    }
                    campaign.backupStatus=campaign.status;
                    campaign.status=255;
                    emit CampaignEmergencyStopChanged(_campaignId, msg.sender, true, block.timestamp);
                    emit CancelPending(_campaignId, msg.sender, block.timestamp);
                    return ;
                }
            }
            
            // Set the campaign status to "cancelled"
            campaign.status = 3;
            // Emit an event to record the change in status
            emit CampaignStatusChanged(_campaignId, 3);
            return ;
        }

        function partialRefund(uint campaignId) public {

            // only platform owner or emergency contact can call this function
            if(msg.sender != platformOwner && !emergencyContacts[msg.sender]) revert Unauthorized(msg.sender);
            Campaign storage campaign = campaigns[campaignId];
            if (campaign.amountWithdrawn == campaign.amountCollected) {               
                return; // nothing to do
            }

            uint refundAmount = campaign.amountCollected - campaign.amountWithdrawn;
            uint percentage = 100 * refundAmount / campaign.amountCollected;
            uint tmp=campaign.backersData.length;
            // we check the mutex lock for this campaign and verify if it is on
            if(campaign.mutex) revert LockError();
            campaign.mutex=true;
            //we give property of the refundamount to backers through this mapping 
            for (uint i = 0; i < tmp; i++) {
                BackerData storage backer = campaign.backersData[i];
                uint backerRefundAmount = backer.donation * percentage / 100;
                BackerRefund memory refundprocess = BackerRefund({
              locked: false,
              refundAmount: uint128(backerRefundAmount)
          });
                partialRefundWaiting[campaignId][backer.backer]=refundprocess;
                backer.donation -= uint88(backerRefundAmount);
                emit PartialRefundWaitingNotification(campaignId, backer.backer, block.timestamp);                
            }
            // we substract the refundAmount from the collectedAmount
            campaign.amountCollected -= uint128(refundAmount);
            emit CampaignPartialRefundInitiated(campaignId,block.timestamp);
            // we free the mutex
            campaign.mutex=false;

        }

        function backerRefundWithdraw(uint campaignId) public {
            //we check if emergency mode is on
            if(_emergencyStop) revert EmergencyMode();
            BackerRefund storage refundprocess = partialRefundWaiting[campaignId][msg.sender];
            if(refundprocess.locked) revert LockError();
            refundprocess.locked=true;
            if ( refundprocess.refundAmount > 0) {
                uint _amount=refundprocess.refundAmount;
                // Transfer the Ether to the campaign owner
                (bool success, ) = (msg.sender).call{value: _amount}("");
                if (!success) {
                    revert TransferError(campaignId, _amount, msg.sender);
                 }
                emit BackerRefundWithdrawn(campaignId, msg.sender, _amount, block.timestamp);
                delete partialRefundWaiting[campaignId][msg.sender];
            }

        }

}