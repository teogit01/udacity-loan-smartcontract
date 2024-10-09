// Importing necessary modules and functions from Hardhat and Chai for testing
const {
  loadFixture, time
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect, anyValue } = require("chai");
const { ethers } = require("hardhat");
// const { utils } = ethers

// Describing a test suite for the CollateralizedLoan contract
describe("CollateralizedLoan", function () {  
  // A fixture to deploy the contract before each test. This helps in reducing code repetition.
  async function deployCollateralizedLoanFixture() {
    // Deploying the CollateralizedLoan contract and returning necessary variables    
    // TODO: Complete the deployment setup    
    const [borrower, lender] = await ethers.getSigners();    
    const CollateralizedLoan = await ethers.getContractFactory("CollateralizedLoan");
    const loanContract = await CollateralizedLoan.deploy(); // Deploying the contract
    
    return { loanContract, borrower, lender };
  }

  // Test suite for the loan request functionality
  describe("Loan Request", function () {    
    it("Should let a borrower deposit collateral and request a loan", async function () {
      // Loading the fixture
      // TODO: Set up test for depositing collateral and requesting a loan
      // HINT: Use .connect() to simulate actions from different accounts

      const { loanContract, borrower } = await loadFixture(deployCollateralizedLoanFixture);            
      
      const initEther = 1
      const collateralAmount = ethers.parseEther(initEther.toString());
      const loanAmount = ethers.parseEther((initEther * 2).toString());
      const blockTime = await ethers.provider.getBlock('latest')
      const dueTime = blockTime.timestamp + 1
      const _duration = 1000
    
      await expect(loanContract.connect(borrower).depositCollateralAndRequestLoan(10, _duration, {value: collateralAmount}))
      .to.emit(loanContract, 'LoanRequested')
      .withArgs( borrower.address, 1, collateralAmount, loanAmount, 10, dueTime + _duration);

      const loan = await loanContract.loans(1);
      expect(loan.borrower).to.equal(borrower.address);
      expect(loan.collateralAmount).to.equal(collateralAmount);      
    });
  });

  // Test suite for funding a loan
  describe("Funding a Loan", function () {
    it("Allows a lender to fund a requested loan", async function () {
      // Loading the fixture
      // TODO: Set up test for a lender funding a loan
      // HINT: You'll need to check for an event emission to verify the action
      const { loanContract, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);
      const collateralAmount = ethers.parseEther("1");
      
      await loanContract.connect(borrower).depositCollateralAndRequestLoan(10, 1000, { value: collateralAmount });
      
      const loanAmount = ethers.parseEther("2");
      await expect(
        loanContract.connect(lender).fundLoan(1, { value: loanAmount })
      )
      .to.emit(loanContract, "LoanFunded")
      .withArgs(lender.address, 1, loanAmount);

      const loan = await loanContract.loans(1);
      expect(loan.lender).to.equal(lender.address);
      expect(loan.isFunded).to.be.true;
    });
  });

  // Test suite for repaying a loan
  describe("Repaying a Loan", function () {
    it("Enables the borrower to repay the loan fully", async function () {
      // Loading the fixture
      // TODO: Set up test for a borrower repaying the loan
      // HINT: Consider including the calculation of the repayment amount

      const { loanContract, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);
      const collateralAmount = ethers.parseEther("1");
      
      await loanContract.connect(borrower).depositCollateralAndRequestLoan(10, 1000, { value: collateralAmount });
      
      const loanAmount = ethers.parseEther("2");
      await loanContract.connect(lender).fundLoan(1, { value: loanAmount });
      
      const repaymentAmount = ethers.parseEther("2.2");
      await expect(
        loanContract.connect(borrower).repayLoan(1, { value: repaymentAmount })
      )
      .to.emit(loanContract, "LoanRepaid")
      .withArgs(borrower.address, 1, repaymentAmount);

      const loan = await loanContract.loans(1);
      expect(loan.isRepaid).to.be.true;

    });
  });

  // Test suite for claiming collateral
  describe("Claiming Collateral", function () {
    it("Permits the lender to claim collateral if the loan isn't repaid on time", async function () {
      // Loading the fixture
      // TODO: Set up test for claiming collateral
      // HINT: Simulate the passage of time if necessary

      const { loanContract, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);
      const collateralAmount = ethers.parseEther("1");

      await loanContract.connect(borrower).depositCollateralAndRequestLoan(10, 1000, { value: collateralAmount });

      const loanAmount = ethers.parseEther("2");
      await loanContract.connect(lender).fundLoan(1, { value: loanAmount });

      await time.increase(2000); // Simulating time passing

      await expect(loanContract.connect(lender).claimCollateral(1))
      .to.emit(loanContract, "LoanCollateralClaimed")
      .withArgs(lender.address, 1, collateralAmount);

      const loan = await loanContract.loans(1);
      expect(loan.isRepaid).to.be.false;

    });
  });
});
