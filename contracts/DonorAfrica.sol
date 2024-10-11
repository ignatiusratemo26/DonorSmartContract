// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDonorRegistration.sol";
import "./IFundDistribution.sol";
import "./ISchoolVerification.sol";
import "./IStudentVerification.sol";

contract DonorAfrica is IDonorRegistration, IFundDistribution, ISchoolVerification, IStudentVerification {
    IERC20 public usdcToken; // USDC token contract address

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
        lastDistribution = block.timestamp;
    }

    struct Donor {
        bool isRegistered;
        uint256 totalDonated;
    }

    struct School {
        bool isVerified;
        uint256 totalFundsReceived;
    }

    struct Student {
        bool isVerified;
        address school;
        uint256 fundsClaimed;
        uint256 lastClaimed;
    }

    mapping(address => Donor) public donors;
    mapping(address => School) public schools;
    mapping(address => Student) public students;
    address[] public schoolAddresses; // Array to store verified school addresses

    uint256 public totalDonations;
    uint256 public totalSchools;
    uint256 public lastDistribution;

    // Events
    event DonorRegistered(address donor);
    event SchoolVerified(address school);
    event StudentVerified(address student);
    event DonationMade(address donor, uint256 amount);
    event FundsDistributed(uint256 totalAmount, uint256 numSchools);
    event FundsWithdrawn(address student, uint256 amount);

    // Donor Registration Functions
    function registerDonor() external override {
        require(!donors[msg.sender].isRegistered, "Donor already registered");
        donors[msg.sender] = Donor({isRegistered: true, totalDonated: 0});
        emit DonorRegistered(msg.sender);
    }

    function isDonorRegistered(address _donor) external view override returns (bool) {
        return donors[_donor].isRegistered;
    }

    // Fund Distribution Functions
    function donate(uint256 amount) external override {
        require(donors[msg.sender].isRegistered, "Donor not registered");

        require(usdcToken.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");
        
        donors[msg.sender].totalDonated += amount;
        totalDonations += amount;
        emit DonationMade(msg.sender, amount);
    }

    function distributeFunds() external override {
        // require(block.timestamp >= lastDistribution + 30 days, "Distribution not due");
        require(schoolAddresses.length > 0, "No schools available for distribution");
        uint256 numSchools = schoolAddresses.length;
        uint256 amountPerSchool = totalDonations / numSchools;
        for (uint256 i = 0; i < numSchools; i++) {
            address schoolAddress = schoolAddresses[i];
            require(schools[schoolAddress].isVerified, "School not verified");

            // transfer funds to each verified school
            require(usdcToken.transfer(schoolAddress, amountPerSchool),"USDC Transfer failed");
            schools[schoolAddress].totalFundsReceived += amountPerSchool;
        }
        lastDistribution = block.timestamp;
        emit FundsDistributed(totalDonations, numSchools);
        totalDonations = 0;
    }

    function claimFunds() external override {
        require(students[msg.sender].isVerified, "Student not verified");
        address school = students[msg.sender].school;
        require(schools[school].isVerified, "School not verified");
        require(students[msg.sender].lastClaimed < lastDistribution, "Funds already claimed for this distribution period");

        uint256 amount = 100; // Assume a fixed amount for simplicity
        students[msg.sender].fundsClaimed += amount;
        students[msg.sender].lastClaimed = block.timestamp; // Update the last claimed timestamp
        emit FundsWithdrawn(msg.sender, amount);
    }



/**  The interface takes a parameter, this one does not. So its replaced with the one below 
    
    
    function getMonth() external view returns (uint256) {
        return (block.timestamp / 30 days) % 12 + 1;
    }


*/

    function getMonth(uint256 _timestamp) external pure override returns (uint256) {
        return (_timestamp / 30 days) % 12 + 1;
    }




    // School Verification Functions
    function registerSchool() external {
        require(!schools[msg.sender].isVerified, "School already verified");
        schools[msg.sender] = School({isVerified: true, totalFundsReceived: 0});
        schoolAddresses.push(msg.sender);
        totalSchools++;
        emit SchoolVerified(msg.sender);
    }

    function verifySchool(address _school) external override {
        require(!schools[_school].isVerified, "School already verified");
        schools[_school] = School({isVerified: true, totalFundsReceived: 0});
        schoolAddresses.push(_school);
        totalSchools++;
        emit SchoolVerified(_school);
    }

    function isSchoolVerified(address _school) external view override returns (bool) {
        return schools[_school].isVerified;
    }

    // Student Verification Functions
    function registerStudent(address _school) external {
        require(schools[_school].isVerified, "School not verified");
        require(!students[msg.sender].isVerified, "Student already verified");
        students[msg.sender] = Student({isVerified: true, school: _school, fundsClaimed: 0, lastClaimed: 0});
        emit StudentVerified(msg.sender);
    }

    function verifyStudent(address _student, address _school) external override {
        require(schools[_school].isVerified, "School not verified");
        require(!students[_student].isVerified, "Student already verified");
        students[_student] = Student({isVerified: true, school: _school, fundsClaimed: 0, lastClaimed: 0});
        emit StudentVerified(_student);
    }

    function isStudentVerified(address _student) external view override returns (bool) {
        return students[_student].isVerified;
    }
}